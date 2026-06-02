import { HttpStatus } from "@nestjs/common";
import { JwtService } from "@nestjs/jwt";

import { ApiException } from "../../src/common/api-error";
import { InMemoryKeyValueStore } from "../../src/infra/redis";
import { AuthService } from "../../src/modules/auth/auth.service";
import { OAuthProviderRegistry } from "../../src/modules/auth/oauth";
import { OAuthProviderClient } from "../../src/modules/auth/oauth/oauth-provider.port";
import { AuthUserRepository } from "../../src/modules/auth/repositories";
import {
  AuthTokenService,
  OAuthStateStore,
} from "../../src/modules/auth/session";

const user = {
  id: "user-1",
  provider: "google",
  providerUserId: "google-user-1",
  email: "memo@example.com",
  displayName: "Memo User",
  avatarUrl: null,
};

describe("AuthService", () => {
  let google: jest.Mocked<OAuthProviderClient>;
  let apple: jest.Mocked<OAuthProviderClient>;
  let userRepository: jest.Mocked<AuthUserRepository>;
  let tokenService: AuthTokenService;
  let service: AuthService;

  beforeEach(() => {
    process.env.JWT_ACCESS_SECRET = "auth-service-access-secret";
    process.env.JWT_REFRESH_SECRET = "auth-service-refresh-secret";

    google = createProvider("google");
    apple = createProvider("apple");
    userRepository = {
      upsertOAuthUser: jest.fn().mockResolvedValue({ user, created: true }),
    };

    const store = new InMemoryKeyValueStore();
    tokenService = new AuthTokenService(new JwtService(), store);
    service = new AuthService(
      createRegistry({ google, apple }),
      new OAuthStateStore(store),
      tokenService,
      userRepository,
    );
  });

  it("starts Google and Apple through the same provider contract", async () => {
    const googleStart = await service.startOAuth("google", {
      redirectUri: "memo://oauth/google",
    });
    const appleStart = await service.startOAuth("apple", {
      redirectUri: "memo://oauth/apple",
    });

    expect(google.start).toHaveBeenCalledWith({
      state: googleStart.state,
      redirectUri: "memo://oauth/google",
    });
    expect(apple.start).toHaveBeenCalledWith({
      state: appleStart.state,
      redirectUri: "memo://oauth/apple",
    });
    expect(googleStart.authorizationUrl).toContain(googleStart.state);
    expect(appleStart.authorizationUrl).toContain(appleStart.state);
  });

  it("completes OAuth, upserts the user, and returns a session", async () => {
    const start = await service.startOAuth("google", {
      redirectUri: "memo://oauth/google",
    });

    const session = await service.completeOAuth("google", {
      code: "oauth-code",
      state: start.state,
      redirectUri: "memo://oauth/google",
    });

    expect(google.complete).toHaveBeenCalledWith({
      code: "oauth-code",
      state: start.state,
      redirectUri: "memo://oauth/google",
    });
    expect(userRepository.upsertOAuthUser).toHaveBeenCalledWith({
      provider: "google",
      providerUserId: "google-user-1",
      email: "memo@example.com",
      displayName: "Memo User",
      avatarUrl: null,
    });
    expect(session.user).toEqual({
      id: "user-1",
      email: "memo@example.com",
      displayName: "Memo User",
      avatarUrl: null,
    });
    await expect(
      tokenService.verifyAccessToken(session.accessToken),
    ).resolves.toMatchObject({
      user: {
        id: "user-1",
        email: "memo@example.com",
        displayName: "Memo User",
        provider: "google",
      },
    });
  });

  it("rejects reused or invalid state before provider callback", async () => {
    await expectApiException(
      service.completeOAuth("google", { code: "code", state: "bad-state" }),
      HttpStatus.UNAUTHORIZED,
      "oauth_failed",
    );

    expect(google.complete).not.toHaveBeenCalled();
  });

  it("maps cancelled provider callback to oauth_failed without tokens", async () => {
    await expectApiException(
      service.completeOAuth("google", {
        error: "access_denied",
        state: "state",
      }),
      HttpStatus.UNAUTHORIZED,
      "oauth_failed",
    );

    expect(userRepository.upsertOAuthUser).not.toHaveBeenCalled();
  });

  it("builds app redirect URLs for browser OAuth callbacks", () => {
    process.env.OAUTH_APP_REDIRECT_BASE_URL = "http://localhost:5000";

    expect(
      service.buildOAuthAppRedirect("google", {
        code: "oauth-code",
        state: "oauth-state",
      }),
    ).toBe(
      "http://localhost:5000/oauth/google?code=oauth-code&state=oauth-state",
    );
  });

  it("refreshes a session and revokes the used refresh token", async () => {
    const session = await tokenService.createSession(user);
    const refreshed = await service.refreshSession({
      refreshToken: session.refreshToken,
    });

    await expect(
      tokenService.verifyRefreshToken(session.refreshToken),
    ).rejects.toMatchObject({ apiErrorCode: "unauthorized" });
    await expect(
      tokenService.verifyRefreshToken(refreshed.refreshToken),
    ).resolves.toMatchObject({ user: { id: "user-1" } });
  });

  it("logout revokes current access token and provided refresh token", async () => {
    const session = await tokenService.createSession(user);
    const access = await tokenService.verifyAccessToken(session.accessToken);

    await expect(
      service.logout(
        {
          headers: {},
          accessTokenJti: access.jti,
          accessTokenExpiresAt: access.expiresAt,
        },
        { refreshToken: session.refreshToken },
      ),
    ).resolves.toEqual({ revoked: true });

    await expect(
      tokenService.verifyAccessToken(session.accessToken),
    ).rejects.toMatchObject({ apiErrorCode: "unauthorized" });
    await expect(
      tokenService.verifyRefreshToken(session.refreshToken),
    ).rejects.toMatchObject({ apiErrorCode: "unauthorized" });
  });
});

function createProvider(
  provider: "google" | "apple",
): jest.Mocked<OAuthProviderClient> {
  return {
    provider,
    start: jest.fn(async (input) => ({
      authorizationUrl: `https://${provider}.example/auth?state=${input.state}`,
      state: input.state,
    })),
    complete: jest.fn(async (_input) => ({
      profile: {
        provider,
        providerUserId: `${provider}-user-1`,
        email: "memo@example.com",
        displayName: "Memo User",
        avatarUrl: null,
      },
    })),
  };
}

function createRegistry(clients: {
  google: OAuthProviderClient;
  apple: OAuthProviderClient;
}): OAuthProviderRegistry {
  return {
    get: (provider) => clients[provider],
  } as OAuthProviderRegistry;
}

async function expectApiException(
  promise: Promise<unknown>,
  status: HttpStatus,
  code: string,
): Promise<void> {
  try {
    await promise;
    throw new Error("Expected ApiException.");
  } catch (error) {
    expect(error).toBeInstanceOf(ApiException);
    expect((error as ApiException).getStatus()).toBe(status);
    expect((error as ApiException).apiErrorCode).toBe(code);
  }
}
