export type OAuthProvider = 'google' | 'apple';

export class OAuthStartRequestDto {
  redirectUri?: string;
}

export class OAuthStartResponseDto {
  authorizationUrl!: string;
  state!: string;
}

export class OAuthCallbackRequestDto {
  code!: string;
  state!: string;
  redirectUri?: string;
}

export class RefreshSessionRequestDto {
  refreshToken?: string;
}

export class UserProfileDto {
  id!: string;
  email!: string | null;
  displayName!: string | null;
  avatarUrl?: string | null;
}

export class SessionResponseDto {
  accessToken!: string;
  refreshToken!: string;
  expiresIn!: number;
  user!: UserProfileDto;
}

export class LogoutResponseDto {
  revoked!: true;
}
