import { Inject, Injectable } from "@nestjs/common";

import { throwOAuthFailed, throwValidationError } from "../../common/api-error";
import {
  LogoutRequestDto,
  LogoutResponseDto,
  OAuthCallbackRequestDto,
  OAuthProvider,
  OAuthStartRequestDto,
  OAuthStartResponseDto,
  RefreshSessionRequestDto,
  SessionResponseDto,
} from "./dto/auth.dto";
import { OAuthProviderRegistry } from "./oauth";
import { AUTH_USER_REPOSITORY, AuthUserRepository } from "./repositories";
import { AuthTokenService, OAuthStateStore } from "./session";
import { RequestWithCurrentUser } from "./current-user";

@Injectable()
export class AuthService {
  constructor(
    private readonly oauthProviders: OAuthProviderRegistry,
    private readonly oauthStateStore: OAuthStateStore,
    private readonly tokenService: AuthTokenService,
    @Inject(AUTH_USER_REPOSITORY)
    private readonly userRepository: AuthUserRepository,
  ) {}

  async startOAuth(
    provider: OAuthProvider,
    request: OAuthStartRequestDto,
  ): Promise<OAuthStartResponseDto> {
    const client = this.oauthProviders.get(provider);
    const state = await this.oauthStateStore.create(
      provider,
      request.redirectUri,
    );

    return client.start({ state, redirectUri: request.redirectUri });
  }

  async completeOAuth(
    provider: OAuthProvider,
    request: OAuthCallbackRequestDto,
  ): Promise<SessionResponseDto> {
    if (request.error) {
      throwOAuthFailed("OAuth provider rejected the request.", {
        provider,
        error: request.error,
      });
    }
    if (!request.code || !request.state) {
      throwOAuthFailed("OAuth callback is missing code or state.");
    }

    const client = this.oauthProviders.get(provider);
    await this.oauthStateStore.consume(
      request.state,
      provider,
      request.redirectUri,
    );

    const result = await client.complete({
      code: request.code,
      state: request.state,
      redirectUri: request.redirectUri,
    });
    const { user } = await this.userRepository.upsertOAuthUser(result.profile);

    return this.tokenService.createSession(user);
  }

  buildOAuthAppRedirect(
    provider: OAuthProvider,
    request: OAuthCallbackRequestDto,
  ): string {
    const baseUrl =
      process.env.OAUTH_APP_REDIRECT_BASE_URL ?? "http://localhost:5000";
    const url = new URL(`/oauth/${provider}`, baseUrl);

    this.copyQueryValue(url, "code", request.code);
    this.copyQueryValue(url, "state", request.state);
    this.copyQueryValue(url, "error", request.error);
    this.copyQueryValue(url, "error_description", request.errorDescription);

    return url.toString();
  }

  async refreshSession(
    request: RefreshSessionRequestDto,
  ): Promise<SessionResponseDto> {
    if (!request.refreshToken) {
      throwValidationError("Refresh token is required.");
    }

    const verified = await this.tokenService.verifyRefreshToken(
      request.refreshToken,
    );
    await this.tokenService.revoke("refresh", verified.jti, verified.expiresAt);

    return this.tokenService.createSession(verified.user);
  }

  async logout(
    request: RequestWithCurrentUser,
    body: LogoutRequestDto = {},
  ): Promise<LogoutResponseDto> {
    if (!request.accessTokenJti || !request.accessTokenExpiresAt) {
      throwValidationError("Access token metadata is missing.");
    }

    await this.tokenService.revoke(
      "access",
      request.accessTokenJti,
      request.accessTokenExpiresAt,
    );

    if (body.refreshToken) {
      await this.tokenService.revokeToken(body.refreshToken, "refresh");
    }

    return { revoked: true };
  }

  private copyQueryValue(
    url: URL,
    key: string,
    value: string | undefined,
  ): void {
    if (value) {
      url.searchParams.set(key, value);
    }
  }
}
