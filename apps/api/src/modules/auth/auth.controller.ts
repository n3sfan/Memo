import {
  Body,
  Controller,
  Get,
  Headers,
  Param,
  Post,
  Query,
  Req,
  Res,
  UseGuards,
} from "@nestjs/common";

import { ApiEnvelope, createEnvelope } from "../../common/api-envelope";
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
import { AuthService } from "./auth.service";
import { RequestWithCurrentUser } from "./current-user";
import { JwtAuthGuard } from "./jwt-auth.guard";

@Controller("auth")
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post("oauth/:provider/start")
  async startOAuth(
    @Param("provider") provider: OAuthProvider,
    @Body() request: OAuthStartRequestDto,
    @Headers("x-request-id") requestId?: string,
  ): Promise<ApiEnvelope<OAuthStartResponseDto>> {
    const data = await this.authService.startOAuth(provider, request);

    return createEnvelope(data, requestId);
  }

  @Get("oauth/:provider/callback")
  redirectOAuthCallback(
    @Param("provider") provider: OAuthProvider,
    @Query() request: OAuthCallbackRequestDto,
    @Res() response: RedirectResponse,
  ): void {
    response.redirect(
      this.authService.buildOAuthAppRedirect(provider, request),
    );
  }

  @Post("oauth/:provider/callback")
  async completeOAuth(
    @Param("provider") provider: OAuthProvider,
    @Body() request: OAuthCallbackRequestDto,
    @Res({ passthrough: true }) response: RedirectResponse,
    @Headers("content-type") contentType?: string,
    @Headers("x-request-id") requestId?: string,
  ): Promise<ApiEnvelope<SessionResponseDto> | void> {
    if (this.isBrowserOAuthCallback(request, contentType)) {
      response.redirect(
        this.authService.buildOAuthAppRedirect(provider, request),
      );
      return;
    }

    const data = await this.authService.completeOAuth(provider, request);

    return createEnvelope(data, requestId);
  }

  @Post("refresh")
  async refreshSession(
    @Body() request: RefreshSessionRequestDto,
    @Headers("x-request-id") requestId?: string,
  ): Promise<ApiEnvelope<SessionResponseDto>> {
    const data = await this.authService.refreshSession(request);

    return createEnvelope(data, requestId);
  }

  @UseGuards(JwtAuthGuard)
  @Post("logout")
  async logout(
    @Req() request: RequestWithCurrentUser,
    @Body() body: LogoutRequestDto,
    @Headers("x-request-id") requestId?: string,
  ): Promise<ApiEnvelope<LogoutResponseDto>> {
    const data = await this.authService.logout(request, body);

    return createEnvelope(data, requestId);
  }

  private isBrowserOAuthCallback(
    request: OAuthCallbackRequestDto,
    contentType?: string,
  ): boolean {
    return (
      !request.redirectUri &&
      Boolean(request.code || request.error) &&
      Boolean(contentType?.includes("application/x-www-form-urlencoded"))
    );
  }
}

interface RedirectResponse {
  redirect(url: string): void;
}
