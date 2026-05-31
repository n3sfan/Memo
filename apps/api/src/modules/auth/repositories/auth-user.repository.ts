import { OAuthUserProfile } from '../oauth';

export const AUTH_USER_REPOSITORY = Symbol('AUTH_USER_REPOSITORY');

export interface AuthUserRecord {
  id: string;
  provider: string;
  providerUserId: string;
  email: string | null;
  displayName: string | null;
  avatarUrl: string | null;
}

export interface UpsertAuthUserResult {
  user: AuthUserRecord;
  created: boolean;
}

export interface AuthUserRepository {
  upsertOAuthUser(profile: OAuthUserProfile): Promise<UpsertAuthUserResult>;
}
