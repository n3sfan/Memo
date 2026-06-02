import { OAuthProvider } from '../dto/auth.dto';

export const OAUTH_PROVIDER_CLIENTS = Symbol('OAUTH_PROVIDER_CLIENTS');

export interface OAuthStartInput {
  state: string;
  redirectUri?: string;
}

export interface OAuthStartResult {
  authorizationUrl: string;
  state: string;
}

export interface OAuthCallbackInput {
  code: string;
  state: string;
  redirectUri?: string;
}

export interface OAuthUserProfile {
  provider: OAuthProvider;
  providerUserId: string;
  email: string | null;
  displayName: string | null;
  avatarUrl?: string | null;
}

export interface OAuthCallbackResult {
  profile: OAuthUserProfile;
}

export interface OAuthProviderClient {
  readonly provider: OAuthProvider;
  start(input: OAuthStartInput): Promise<OAuthStartResult>;
  complete(input: OAuthCallbackInput): Promise<OAuthCallbackResult>;
}
