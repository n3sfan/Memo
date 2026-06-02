import { INestApplication } from "@nestjs/common";
import { JwtService } from "@nestjs/jwt";
import { Test } from "@nestjs/testing";
import request = require("supertest");

import { ApiExceptionFilter } from "../../src/common/api-exception.filter";
import { InMemoryKeyValueStore, KEY_VALUE_STORE } from "../../src/infra/redis";
import { AuthController } from "../../src/modules/auth/auth.controller";
import { AuthService } from "../../src/modules/auth/auth.service";
import { JwtAuthGuard } from "../../src/modules/auth/jwt-auth.guard";
import {
  OAUTH_PROVIDER_CLIENTS,
  OAuthProviderClient,
  OAuthProviderRegistry,
} from "../../src/modules/auth/oauth";
import {
  AUTH_USER_REPOSITORY,
  AuthUserRepository,
} from "../../src/modules/auth/repositories";
import {
  AuthTokenService,
  OAuthStateStore,
} from "../../src/modules/auth/session";

describe("Auth API", () => {
  let app: INestApplication;
  let tokenService: AuthTokenService;
  let google: jest.Mocked<OAuthProviderClient>;
  let apple: jest.Mocked<OAuthProviderClient>;
  let userRepository: jest.Mocked<AuthUserRepository>;

  beforeEach(async () => {
    process.env.JWT_ACCESS_SECRET = "auth-api-access-secret";
    process.env.JWT_REFRESH_SECRET = "auth-api-refresh-secret";
    google = createProvider("google");
    apple = createProvider("apple");
    userRepository = {
      upsertOAuthUser: jest.fn().mockResolvedValue({
        created: true,
        user: {
          id: "user-1",
          provider: "google",
          providerUserId: "google-user-1",
          email: "memo@example.com",
          displayName: "Memo User",
          avatarUrl: null,
        },
      }),
    };

    const moduleRef = await Test.createTestingModule({
      controllers: [AuthController],
      providers: [
        AuthService,
        OAuthProviderRegistry,
        JwtAuthGuard,
        JwtService,
        AuthTokenService,
        OAuthStateStore,
        {
          provide: KEY_VALUE_STORE,
          useValue: new InMemoryKeyValueStore(),
        },
        {
          provide: OAUTH_PROVIDER_CLIENTS,
          useValue: [google, apple],
        },
        {
          provide: AUTH_USER_REPOSITORY,
          useValue: userRepository,
        },
      ],
    }).compile();

    app = moduleRef.createNestApplication();
    tokenService = moduleRef.get(AuthTokenService);
    app.setGlobalPrefix("api/v1");
    app.useGlobalFilters(new ApiExceptionFilter());
    await app.init();
  });

  afterEach(async () => {
    await app.close();
  });

  it("returns Google and Apple authorization URLs with state", async () => {
    const googleResponse = await request(app.getHttpServer())
      .post("/api/v1/auth/oauth/google/start")
      .set("x-request-id", "req_google_start")
      .send({ redirectUri: "memo://oauth/google" })
      .expect(201);
    const appleResponse = await request(app.getHttpServer())
      .post("/api/v1/auth/oauth/apple/start")
      .set("x-request-id", "req_apple_start")
      .send({ redirectUri: "memo://oauth/apple" })
      .expect(201);

    expect(googleResponse.body).toEqual({
      data: {
        authorizationUrl: expect.stringContaining("google.example"),
        state: expect.stringMatching(/^oauth_/),
      },
      requestId: "req_google_start",
    });
    expect(appleResponse.body).toEqual({
      data: {
        authorizationUrl: expect.stringContaining("apple.example"),
        state: expect.stringMatching(/^oauth_/),
      },
      requestId: "req_apple_start",
    });
  });

  it("redirects browser OAuth callbacks back to the app route", async () => {
    process.env.OAUTH_APP_REDIRECT_BASE_URL = "http://localhost:5000";

    await request(app.getHttpServer())
      .get("/api/v1/auth/oauth/google/callback")
      .query({
        code: "oauth-code",
        state: "oauth-state",
        error_description: "ignored",
      })
      .expect(302)
      .expect(
        "location",
        "http://localhost:5000/oauth/google?code=oauth-code&state=oauth-state&error_description=ignored",
      );
  });

  it("redirects provider form_post OAuth callbacks back to the app route", async () => {
    process.env.OAUTH_APP_REDIRECT_BASE_URL = "http://localhost:5000";

    await request(app.getHttpServer())
      .post("/api/v1/auth/oauth/apple/callback")
      .type("form")
      .send({
        code: "apple-code",
        state: "apple-state",
        error_description: "optional provider message",
      })
      .expect(302)
      .expect(
        "location",
        "http://localhost:5000/oauth/apple?code=apple-code&state=apple-state&error_description=optional+provider+message",
      );

    expect(apple.complete).not.toHaveBeenCalled();
    expect(userRepository.upsertOAuthUser).not.toHaveBeenCalled();
  });

  it("returns a session after successful callback", async () => {
    const start = await request(app.getHttpServer())
      .post("/api/v1/auth/oauth/google/start")
      .send({ redirectUri: "memo://oauth/google" })
      .expect(201);

    const response = await request(app.getHttpServer())
      .post("/api/v1/auth/oauth/google/callback")
      .set("x-request-id", "req_google_callback")
      .send({
        code: "oauth-code",
        state: start.body.data.state,
        redirectUri: "memo://oauth/google",
      })
      .expect(201);

    expect(response.body).toEqual({
      data: {
        accessToken: expect.any(String),
        refreshToken: expect.any(String),
        expiresIn: 900,
        user: {
          id: "user-1",
          email: "memo@example.com",
          displayName: "Memo User",
          avatarUrl: null,
        },
      },
      requestId: "req_google_callback",
    });
  });

  it("returns oauth_failed and no token when callback is cancelled", async () => {
    const response = await request(app.getHttpServer())
      .post("/api/v1/auth/oauth/google/callback")
      .set("x-request-id", "req_google_cancelled")
      .send({ error: "access_denied", state: "oauth_state" })
      .expect(401);

    expect(response.body).toEqual({
      error: "oauth_failed",
      message: "OAuth provider rejected the request.",
      details: { provider: "google", error: "access_denied" },
      requestId: "req_google_cancelled",
    });
    expect(response.body.data).toBeUndefined();
    expect(userRepository.upsertOAuthUser).not.toHaveBeenCalled();
  });

  it("completes the full Google OAuth browser pipeline without internal_error", async () => {
    process.env.OAUTH_APP_REDIRECT_BASE_URL = "http://localhost:5000";
    const redirectUri =
      "http://localhost:3000/api/v1/auth/oauth/google/callback";

    const start = await request(app.getHttpServer())
      .post("/api/v1/auth/oauth/google/start")
      .send({ redirectUri })
      .expect(201);

    const providerCallback = await request(app.getHttpServer())
      .get("/api/v1/auth/oauth/google/callback")
      .query({
        code: "oauth-code",
        state: start.body.data.state,
      })
      .expect(302);
    const appCallbackUrl = new URL(providerCallback.headers.location);

    expect(appCallbackUrl.origin).toBe("http://localhost:5000");
    expect(appCallbackUrl.pathname).toBe("/oauth/google");
    expect(appCallbackUrl.searchParams.get("code")).toBe("oauth-code");
    expect(appCallbackUrl.searchParams.get("state")).toBe(
      start.body.data.state,
    );

    const session = await request(app.getHttpServer())
      .post("/api/v1/auth/oauth/google/callback")
      .set("x-request-id", "req_google_full_pipeline")
      .send({
        code: appCallbackUrl.searchParams.get("code"),
        state: appCallbackUrl.searchParams.get("state"),
        redirectUri,
      })
      .expect(201);

    expect(session.body.error).toBeUndefined();
    expect(session.body).toEqual({
      data: {
        accessToken: expect.any(String),
        refreshToken: expect.any(String),
        expiresIn: 900,
        user: {
          id: "user-1",
          email: "memo@example.com",
          displayName: "Memo User",
          avatarUrl: null,
        },
      },
      requestId: "req_google_full_pipeline",
    });
    expect(google.complete).toHaveBeenCalledWith({
      code: "oauth-code",
      state: start.body.data.state,
      redirectUri,
    });
    await expect(
      tokenService.verifyAccessToken(session.body.data.accessToken),
    ).resolves.toMatchObject({
      user: {
        id: "user-1",
        email: "memo@example.com",
        displayName: "Memo User",
        provider: "google",
      },
    });
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
