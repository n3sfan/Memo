import { Injectable } from '@nestjs/common';
import { createPublicKey, JsonWebKey } from 'crypto';
import { decode, JwtPayload, verify } from 'jsonwebtoken';

import { throwOAuthFailed } from '../../../common/api-error';
import {
  OAuthCallbackInput,
  OAuthCallbackResult,
  OAuthProviderClient,
  OAuthStartInput,
  OAuthStartResult,
} from './oauth-provider.port';

@Injectable()
export class AppleOAuthProviderClient implements OAuthProviderClient {
  readonly provider = 'apple' as const;

  async start(input: OAuthStartInput): Promise<OAuthStartResult> {
    const clientId = process.env.APPLE_OAUTH_CLIENT_ID;
    const redirectUri = input.redirectUri ?? process.env.APPLE_OAUTH_REDIRECT_URI;
    if (!clientId || !redirectUri) {
      throwOAuthFailed('Apple OAuth is not configured.');
    }

    const url = new URL('https://appleid.apple.com/auth/authorize');
    url.searchParams.set('client_id', clientId);
    url.searchParams.set('redirect_uri', redirectUri);
    url.searchParams.set('response_type', 'code');
    url.searchParams.set('response_mode', 'form_post');
    url.searchParams.set('scope', 'name email');
    url.searchParams.set('state', input.state);

    return { authorizationUrl: url.toString(), state: input.state };
  }

  complete(input: OAuthCallbackInput): Promise<OAuthCallbackResult> {
    return this.exchangeCode(input);
  }

  private async exchangeCode(
    input: OAuthCallbackInput,
  ): Promise<OAuthCallbackResult> {
    const clientId = process.env.APPLE_OAUTH_CLIENT_ID;
    const clientSecret = process.env.APPLE_OAUTH_CLIENT_SECRET;
    const redirectUri = input.redirectUri ?? process.env.APPLE_OAUTH_REDIRECT_URI;
    if (!clientId || !clientSecret || !redirectUri) {
      throwOAuthFailed('Apple OAuth is not configured.');
    }

    const token = await this.postForm('https://appleid.apple.com/auth/token', {
      grant_type: 'authorization_code',
      code: input.code,
      client_id: clientId,
      client_secret: clientSecret,
      redirect_uri: redirectUri,
    });
    const idToken = this.requiredString(token.id_token);
    const claims = await this.verifyIdToken(idToken, clientId);

    return {
      profile: {
        provider: this.provider,
        providerUserId: claims.sub,
        email: claims.email,
        displayName: null,
        avatarUrl: null,
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
      throwOAuthFailed('Apple OAuth token exchange failed.');
    }
  }

  private async readJsonResponse(
    response: Response,
  ): Promise<Record<string, unknown>> {
    if (!response.ok) {
      throwOAuthFailed('Apple OAuth provider returned an error.');
    }
    const body = (await response.json()) as unknown;
    if (!this.isRecord(body)) {
      throwOAuthFailed('Apple OAuth provider response is invalid.');
    }

    return body;
  }

  private async verifyIdToken(
    idToken: string,
    clientId: string,
  ): Promise<{ sub: string; email: string | null }> {
    const decoded = decode(idToken, { complete: true });
    if (!decoded || typeof decoded === 'string') {
      throwOAuthFailed('Apple OAuth id token is invalid.');
    }
    const kid = decoded.header.kid;
    if (typeof kid !== 'string' || !kid) {
      throwOAuthFailed('Apple OAuth id token key id is invalid.');
    }

    const jwk = await this.findAppleJwk(kid);
    const publicKey = createPublicKey({
      key: jwk as JsonWebKey,
      format: 'jwk',
    });

    let claims: JwtPayload | string;
    try {
      claims = verify(idToken, publicKey, {
        algorithms: ['RS256'],
        issuer: 'https://appleid.apple.com',
        audience: clientId,
      });
    } catch {
      throwOAuthFailed('Apple OAuth id token verification failed.');
    }

    if (typeof claims === 'string') {
      throwOAuthFailed('Apple OAuth id token is invalid.');
    }

    return {
      sub: this.requiredString(claims.sub),
      email: this.optionalString(claims.email),
    };
  }

  private async findAppleJwk(kid: string): Promise<Record<string, unknown>> {
    const keysResponse = await this.getJson('https://appleid.apple.com/auth/keys');
    const keys = keysResponse.keys;
    if (!Array.isArray(keys)) {
      throwOAuthFailed('Apple OAuth JWKS response is invalid.');
    }

    const jwk = keys.find((item) => {
      return this.isRecord(item) && item.kid === kid;
    });
    if (!this.isRecord(jwk)) {
      throwOAuthFailed('Apple OAuth signing key was not found.');
    }

    return jwk;
  }

  private async getJson(url: string): Promise<Record<string, unknown>> {
    try {
      const response = await fetch(url);
      return this.readJsonResponse(response);
    } catch {
      throwOAuthFailed('Apple OAuth JWKS lookup failed.');
    }
  }

  private requiredString(value: unknown): string {
    if (typeof value !== 'string' || !value) {
      throwOAuthFailed('Apple OAuth provider response is invalid.');
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
