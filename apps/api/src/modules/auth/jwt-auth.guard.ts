import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';

import { throwUnauthorized } from '../../common/api-error';
import { RequestWithCurrentUser } from './current-user';
import { AuthTokenService } from './session';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(private readonly tokenService: AuthTokenService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<RequestWithCurrentUser>();
    const token = this.extractBearerToken(request);
    const verified = await this.tokenService.verifyAccessToken(token);

    request.user = verified.user;
    request.accessTokenJti = verified.jti;
    request.accessTokenExpiresAt = verified.expiresAt;

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
}
