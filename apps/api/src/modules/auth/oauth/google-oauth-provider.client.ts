import { Injectable } from '@nestjs/common';

import { throwOAuthFailed } from '../../../common/api-error';
import {
  OAuthCallbackInput,
  OAuthCallbackResult,
  OAuthProviderClient,
  OAuthStartInput,
  OAuthStartResult,
} from './oauth-provider.port';

@Injectable()
export class GoogleOAuthProviderClient implements OAuthProviderClient {
  readonly provider = 'google' as const;

  async start(input: OAuthStartInput): Promise<OAuthStartResult> {
    const clientId = process.env.GOOGLE_OAUTH_CLIENT_ID;
    const redirectUri = input.redirectUri ?? process.env.GOOGLE_OAUTH_REDIRECT_URI;
    if (!clientId || !redirectUri) {
      throwOAuthFailed('Google OAuth is not configured.');
    }

    const url = new URL('https://accounts.google.com/o/oauth2/v2/auth');
    url.searchParams.set('client_id', clientId);
    url.searchParams.set('redirect_uri', redirectUri);
    url.searchParams.set('response_type', 'code');
    url.searchParams.set('scope', 'openid email profile');
    url.searchParams.set('state', input.state);
    url.searchParams.set('access_type', 'offline');
    url.searchParams.set('prompt', 'consent');

    return { authorizationUrl: url.toString(), state: input.state };
  }

  complete(input: OAuthCallbackInput): Promise<OAuthCallbackResult> {
    return this.exchangeCode(input);
  }

  private async exchangeCode(
    input: OAuthCallbackInput,
  ): Promise<OAuthCallbackResult> {
    const clientId = process.env.GOOGLE_OAUTH_CLIENT_ID;
    const clientSecret = process.env.GOOGLE_OAUTH_CLIENT_SECRET;
    const redirectUri = input.redirectUri ?? process.env.GOOGLE_OAUTH_REDIRECT_URI;
    if (!clientId || !clientSecret || !redirectUri) {
      throwOAuthFailed('Google OAuth is not configured.');
    }

    const token = await this.postForm('https://oauth2.googleapis.com/token', {
      grant_type: 'authorization_code',
      code: input.code,
      client_id: clientId,
      client_secret: clientSecret,
      redirect_uri: redirectUri,
    });
    const accessToken = this.requiredString(token.access_token);

    const userInfo = await this.getJson(
      'https://openidconnect.googleapis.com/v1/userinfo',
      accessToken,
    );
    const providerUserId = this.requiredString(userInfo.sub);

    return {
      profile: {
        provider: this.provider,
        providerUserId,
        email: this.optionalString(userInfo.email),
        displayName: this.optionalString(userInfo.name),
        avatarUrl: this.optionalString(userInfo.picture),
      },
    };
  }

  private async postForm(
    url: string,
    body: Record<string, string>,
  ): Promise<Record<string, unknown>> {
    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'content-type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams(body),
      });

      return this.readJsonResponse(response);
    } catch {
      throwOAuthFailed('Google OAuth token exchange failed.');
    }
  }

  private async getJson(
    url: string,
    accessToken: string,
  ): Promise<Record<string, unknown>> {
    try {
      const response = await fetch(url, {
        headers: {
          authorization: `Bearer ${accessToken}`,
        },
      });

      return this.readJsonResponse(response);
    } catch {
      throwOAuthFailed('Google OAuth profile lookup failed.');
    }
  }

  private async readJsonResponse(
    response: Response,
  ): Promise<Record<string, unknown>> {
    if (!response.ok) {
      throwOAuthFailed('Google OAuth provider returned an error.');
    }
    const body = (await response.json()) as unknown;
    if (!this.isRecord(body)) {
      throwOAuthFailed('Google OAuth provider response is invalid.');
    }

    return body;
  }

  private requiredString(value: unknown): string {
    if (typeof value !== 'string' || !value) {
      throwOAuthFailed('Google OAuth provider response is invalid.');
    }

    return value;
  }

  private optionalString(value: unknown): string | null {
    return typeof value === 'string' && value ? value : null;
  }

  private isRecord(value: unknown): value is Record<string, unknown> {
    return typeof value === 'object' && value !== null && !Array.isArray(value);
  }
}
