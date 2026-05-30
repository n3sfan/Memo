import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';

import { throwInternalError, throwUnauthorized } from '../../common/api-error';
import { CurrentUser, RequestWithCurrentUser } from './current-user';

interface JwtAccessTokenPayload {
  sub?: unknown;
  id?: unknown;
  email?: unknown;
  displayName?: unknown;
  provider?: unknown;
}

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(private readonly jwtService: JwtService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<RequestWithCurrentUser>();
    const token = this.extractBearerToken(request);
    const secret = process.env.JWT_ACCESS_SECRET;

    if (!secret) {
      throwInternalError('JWT access secret is not configured.');
    }

    const payload = await this.verifyToken(token, secret);
    request.user = this.userFromPayload(payload);

    return true;
  }

  private extractBearerToken(request: RequestWithCurrentUser): string {
    const authorization =
      request.headers?.authorization ?? request.headers?.Authorization;
    const header = Array.isArray(authorization)
      ? authorization[0]
      : authorization;

    if (!header) {
      throwUnauthorized('Missing Authorization bearer token.');
    }

    const [scheme, token, extra] = header.trim().split(/\s+/);
    if (scheme?.toLowerCase() !== 'bearer' || !token || extra) {
      throwUnauthorized('Invalid Authorization bearer token.');
    }

    return token;
  }

  private async verifyToken(
    token: string,
    secret: string,
  ): Promise<JwtAccessTokenPayload> {
    try {
      return await this.jwtService.verifyAsync<JwtAccessTokenPayload>(token, {
        secret,
        algorithms: ['HS256'],
      });
    } catch {
      throwUnauthorized('Invalid or expired access token.');
    }
  }

  private userFromPayload(payload: JwtAccessTokenPayload): CurrentUser {
    const id = typeof payload.sub === 'string' ? payload.sub : payload.id;

    if (typeof id !== 'string' || !id) {
      throwUnauthorized('Access token subject is invalid.');
    }

    return {
      id,
      email: this.optionalString(payload.email),
      displayName: this.optionalString(payload.displayName),
      provider: this.optionalString(payload.provider),
    };
  }

  private optionalString(value: unknown): string | null {
    return typeof value === 'string' ? value : null;
  }
}
