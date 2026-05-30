import { ExecutionContext, HttpStatus } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';

import { ApiException } from '../../src/common/api-error';
import { RequestWithCurrentUser } from '../../src/modules/auth/current-user';
import { JwtAuthGuard } from '../../src/modules/auth/jwt-auth.guard';

describe('JwtAuthGuard', () => {
  const secret = 'unit-test-access-secret';
  let jwtService: JwtService;
  let guard: JwtAuthGuard;

  beforeEach(() => {
    process.env.JWT_ACCESS_SECRET = secret;
    jwtService = new JwtService();
    guard = new JwtAuthGuard(jwtService);
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

  it('attaches the current user for a valid token', async () => {
    const request = createRequest({
      authorization: `Bearer ${jwtService.sign(
        {
          sub: 'user-1',
          email: 'memo@example.com',
          displayName: 'Memo User',
          provider: 'google',
        },
        {
          secret,
          expiresIn: '1h',
        },
      )}`,
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
