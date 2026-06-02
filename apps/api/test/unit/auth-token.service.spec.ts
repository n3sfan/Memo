import { HttpStatus } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';

import { ApiException } from '../../src/common/api-error';
import { InMemoryKeyValueStore } from '../../src/infra/redis';
import { AuthTokenService } from '../../src/modules/auth/session';

const user = {
  id: 'user-1',
  provider: 'google',
  providerUserId: 'google-user-1',
  email: 'memo@example.com',
  displayName: 'Memo User',
  avatarUrl: null,
};

describe('AuthTokenService', () => {
  let jwtService: JwtService;
  let keyValueStore: InMemoryKeyValueStore;
  let service: AuthTokenService;

  beforeEach(() => {
    process.env.JWT_ACCESS_SECRET = 'token-service-access-secret';
    process.env.JWT_REFRESH_SECRET = 'token-service-refresh-secret';
    process.env.JWT_ACCESS_TTL_SECONDS = '60';
    jwtService = new JwtService();
    keyValueStore = new InMemoryKeyValueStore();
    service = new AuthTokenService(jwtService, keyValueStore);
  });

  afterEach(() => {
    delete process.env.JWT_ACCESS_TTL_SECONDS;
  });

  it('issues access and refresh tokens with type and token id claims', async () => {
    const session = await service.createSession(user);
    const access = jwtService.decode(session.accessToken) as Record<string, unknown>;
    const refresh = jwtService.decode(session.refreshToken) as Record<string, unknown>;

    expect(session.expiresIn).toBe(60);
    expect(access).toMatchObject({
      sub: 'user-1',
      typ: 'access',
      provider: 'google',
      email: 'memo@example.com',
      displayName: 'Memo User',
    });
    expect(access.jti).toEqual(expect.any(String));
    expect(refresh).toMatchObject({ sub: 'user-1', typ: 'refresh' });
    expect(refresh.jti).toEqual(expect.any(String));
  });

  it('rejects wrong token type', async () => {
    const session = await service.createSession(user);

    await expectApiException(
      service.verifyAccessToken(session.refreshToken),
      HttpStatus.UNAUTHORIZED,
      'unauthorized',
    );
  });

  it('rejects revoked refresh tokens', async () => {
    const session = await service.createSession(user);
    const verified = await service.verifyRefreshToken(session.refreshToken);
    await service.revoke('refresh', verified.jti, verified.expiresAt);

    await expectApiException(
      service.verifyRefreshToken(session.refreshToken),
      HttpStatus.UNAUTHORIZED,
      'unauthorized',
    );
  });

  it('rejects expired tokens', async () => {
    const expired = jwtService.sign(
      {
        sub: 'user-1',
        jti: 'expired-token',
        typ: 'access',
        exp: Math.floor(Date.now() / 1000) - 60,
      },
      { secret: process.env.JWT_ACCESS_SECRET },
    );

    await expectApiException(
      service.verifyAccessToken(expired),
      HttpStatus.UNAUTHORIZED,
      'unauthorized',
    );
  });
});

async function expectApiException(
  promise: Promise<unknown>,
  status: HttpStatus,
  code: string,
): Promise<void> {
  try {
    await promise;
    throw new Error('Expected ApiException.');
  } catch (error) {
    expect(error).toBeInstanceOf(ApiException);
    expect((error as ApiException).getStatus()).toBe(status);
    expect((error as ApiException).apiErrorCode).toBe(code);
  }
}
