import { ExecutionContext, HttpStatus } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';

import { ApiException } from '../../src/common/api-error';
import { InMemoryKeyValueStore } from '../../src/infra/redis';
import { RequestWithCurrentUser } from '../../src/modules/auth/current-user';
import { JwtAuthGuard } from '../../src/modules/auth/jwt-auth.guard';
import { AuthTokenService } from '../../src/modules/auth/session';

const baseUser = {
  id: 'user-1',
  provider: 'google',
  providerUserId: 'google-user-1',
  email: 'memo@example.com',
  displayName: 'Memo User',
  avatarUrl: null,
};

describe('JwtAuthGuard', () => {
  const secret = 'unit-test-access-secret';
  let jwtService: JwtService;
  let tokenService: AuthTokenService;
  let keyValueStore: InMemoryKeyValueStore;
  let guard: JwtAuthGuard;

  beforeEach(() => {
    process.env.JWT_ACCESS_SECRET = secret;
    process.env.JWT_REFRESH_SECRET = 'unit-test-refresh-secret';
    jwtService = new JwtService();
    keyValueStore = new InMemoryKeyValueStore();
    tokenService = new AuthTokenService(jwtService, keyValueStore);
    guard = new JwtAuthGuard(tokenService);
  });

  it('rejects requests without a bearer token', async () => {
    await expectUnauthorized(createContext({}));
  });

  it('rejects malformed bearer tokens', async () => {
    await expectUnauthorized(
      createContext({
        authorization: 'Basic abc',
      }),
    );
  });

  it('rejects tokens signed with another secret', async () => {
    const token = jwtService.sign(
      {
        sub: 'user-1',
        jti: 'token-1',
        typ: 'access',
      },
      {
        secret: 'wrong-secret',
      },
    );

    await expectUnauthorized(
      createContext({
        authorization: `Bearer ${token}`,
      }),
    );
  });

  it('rejects expired tokens', async () => {
    const token = jwtService.sign(
      {
        sub: 'user-1',
        jti: 'token-1',
        typ: 'access',
        exp: Math.floor(Date.now() / 1000) - 60,
      },
      {
        secret,
      },
    );

    await expectUnauthorized(
      createContext({
        authorization: `Bearer ${token}`,
      }),
    );
  });

  it('rejects revoked access tokens', async () => {
    const token = await tokenService.createSession(baseUser);
    const verified = await tokenService.verifyAccessToken(token.accessToken);
    await tokenService.revoke('access', verified.jti, verified.expiresAt);

    await expectUnauthorized(
      createContext({ authorization: `Bearer ${token.accessToken}` }),
    );
  });

  it('attaches current user and token metadata for a valid token', async () => {
    const session = await tokenService.createSession(baseUser);
    const request = createRequest({
      authorization: `Bearer ${session.accessToken}`,
    });

    await expect(guard.canActivate(createContextFromRequest(request))).resolves.toBe(
      true,
    );

    expect(request.user).toEqual({
      id: 'user-1',
      email: 'memo@example.com',
      displayName: 'Memo User',
      provider: 'google',
    });
    expect(request.accessTokenJti).toEqual(expect.any(String));
    expect(request.accessTokenExpiresAt).toBeInstanceOf(Date);
  });

  async function expectUnauthorized(context: ExecutionContext): Promise<void> {
    try {
      await guard.canActivate(context);
      throw new Error('Expected guard to reject the request.');
    } catch (error) {
      expect(error).toBeInstanceOf(ApiException);
      expect((error as ApiException).apiErrorCode).toBe('unauthorized');
      expect((error as ApiException).getStatus()).toBe(HttpStatus.UNAUTHORIZED);
    }
  }
});

function createContext(
  headers: Record<string, string | undefined>,
): ExecutionContext {
  return createContextFromRequest(createRequest(headers));
}

function createRequest(
  headers: Record<string, string | undefined>,
): RequestWithCurrentUser {
  return {
    headers,
  };
}

function createContextFromRequest(
  request: RequestWithCurrentUser,
): ExecutionContext {
  return {
    switchToHttp: () => ({
      getRequest: () => request,
    }),
  } as ExecutionContext;
}
