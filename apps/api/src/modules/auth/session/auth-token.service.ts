import { Inject, Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { randomUUID } from 'crypto';

import { throwInternalError, throwUnauthorized } from '../../../common/api-error';
import { KEY_VALUE_STORE, KeyValueStore } from '../../../infra/redis';
import { CurrentUser } from '../current-user';
import { SessionResponseDto } from '../dto/auth.dto';
import { AuthUserRecord } from '../repositories';

export type TokenType = 'access' | 'refresh';

export interface AuthTokenPayload {
  sub?: unknown;
  jti?: unknown;
  typ?: unknown;
  exp?: unknown;
  email?: unknown;
  displayName?: unknown;
  provider?: unknown;
}

export interface VerifiedAccessToken {
  user: CurrentUser;
  jti: string;
  expiresAt: Date;
}

export interface VerifiedRefreshToken {
  user: AuthUserRecord;
  jti: string;
  expiresAt: Date;
}

interface VerifiedTokenPayload {
  sub: string;
  jti: string;
  typ: TokenType;
  exp: number;
  email: string | null;
  displayName: string | null;
  provider: string | null;
}

@Injectable()
export class AuthTokenService {
  constructor(
    private readonly jwtService: JwtService,
    @Inject(KEY_VALUE_STORE) private readonly keyValueStore: KeyValueStore,
  ) {}

  async createSession(user: AuthUserRecord): Promise<SessionResponseDto> {
    const accessTtl = this.accessTtlSeconds();
    const refreshTtl = this.refreshTtlSeconds();

    const [accessToken, refreshToken] = await Promise.all([
      this.signToken('access', user, accessTtl),
      this.signToken('refresh', user, refreshTtl),
    ]);

    return {
      accessToken,
      refreshToken,
      expiresIn: accessTtl,
      user: {
        id: user.id,
        email: user.email,
        displayName: user.displayName,
        avatarUrl: user.avatarUrl,
      },
    };
  }

  async verifyAccessToken(token: string): Promise<VerifiedAccessToken> {
    const payload = await this.verifyToken(token, 'access');
    await this.rejectRevoked('access', payload.jti, payload.exp);

    return {
      user: {
        id: payload.sub,
        email: payload.email,
        displayName: payload.displayName,
        provider: payload.provider,
      },
      jti: payload.jti,
      expiresAt: new Date(payload.exp * 1000),
    };
  }

  async verifyRefreshToken(token: string): Promise<VerifiedRefreshToken> {
    const payload = await this.verifyToken(token, 'refresh');
    await this.rejectRevoked('refresh', payload.jti, payload.exp);

    return {
      user: {
        id: payload.sub,
        provider: payload.provider ?? '',
        providerUserId: '',
        email: payload.email,
        displayName: payload.displayName,
        avatarUrl: null,
      },
      jti: payload.jti,
      expiresAt: new Date(payload.exp * 1000),
    };
  }

  async revoke(type: TokenType, jti: string, expiresAt: Date): Promise<void> {
    const ttlSeconds = Math.ceil((expiresAt.getTime() - Date.now()) / 1000);
    if (ttlSeconds <= 0) {
      return;
    }
    await this.keyValueStore.set(this.revokedKey(type, jti), '1', {
      ttlSeconds,
    });
  }

  async revokeToken(token: string, type: TokenType): Promise<void> {
    const payload = await this.verifyToken(token, type);
    await this.revoke(type, payload.jti, new Date(payload.exp * 1000));
  }

  accessTtlSeconds(): number {
    return this.positiveIntegerEnv('JWT_ACCESS_TTL_SECONDS', 900);
  }

  private refreshTtlSeconds(): number {
    return this.positiveIntegerEnv('JWT_REFRESH_TTL_SECONDS', 2592000);
  }

  private async signToken(
    type: TokenType,
    user: AuthUserRecord,
    ttlSeconds: number,
  ): Promise<string> {
    return this.jwtService.signAsync(
      {
        sub: user.id,
        jti: randomUUID(),
        typ: type,
        provider: user.provider,
        email: user.email,
        displayName: user.displayName,
      },
      {
        secret: this.secret(type),
        expiresIn: ttlSeconds,
        algorithm: 'HS256',
      },
    );
  }

  private async verifyToken(
    token: string,
    type: TokenType,
  ): Promise<VerifiedTokenPayload> {
    let payload: AuthTokenPayload;
    try {
      payload = await this.jwtService.verifyAsync<AuthTokenPayload>(token, {
        secret: this.secret(type),
        algorithms: ['HS256'],
      });
    } catch {
      throwUnauthorized(`Invalid or expired ${type} token.`);
    }

    const normalized = this.normalizePayload(payload, type);
    if (!normalized) {
      throwUnauthorized(`${this.capitalize(type)} token payload is invalid.`);
    }

    return normalized;
  }

  private normalizePayload(
    payload: AuthTokenPayload,
    type: TokenType,
  ): VerifiedTokenPayload | null {
    if (
      typeof payload.sub !== 'string' ||
      typeof payload.jti !== 'string' ||
      payload.typ !== type ||
      typeof payload.exp !== 'number'
    ) {
      return null;
    }

    return {
      sub: payload.sub,
      jti: payload.jti,
      typ: type,
      exp: payload.exp,
      email: this.optionalString(payload.email),
      displayName: this.optionalString(payload.displayName),
      provider: this.optionalString(payload.provider),
    };
  }

  private async rejectRevoked(
    type: TokenType,
    jti: string,
    exp: number,
  ): Promise<void> {
    if (exp * 1000 <= Date.now()) {
      throwUnauthorized(`Invalid or expired ${type} token.`);
    }
    if (await this.keyValueStore.get(this.revokedKey(type, jti))) {
      throwUnauthorized(`Revoked ${type} token.`);
    }
  }

  private revokedKey(type: TokenType, jti: string): string {
    return `auth:revoked:${type}:${jti}`;
  }

  private secret(type: TokenType): string {
    const key = type === 'access' ? 'JWT_ACCESS_SECRET' : 'JWT_REFRESH_SECRET';
    const secret = process.env[key];
    if (!secret) {
      throwInternalError(`${key} is not configured.`);
    }
    return secret;
  }

  private positiveIntegerEnv(name: string, fallback: number): number {
    const value = Number(process.env[name]);
    return Number.isInteger(value) && value > 0 ? value : fallback;
  }

  private optionalString(value: unknown): string | null {
    return typeof value === 'string' ? value : null;
  }

  private capitalize(value: string): string {
    return value.charAt(0).toUpperCase() + value.slice(1);
  }
}
