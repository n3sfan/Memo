import { Injectable } from '@nestjs/common';

import { notImplemented } from '../../common/not-implemented';
import {
  LogoutResponseDto,
  OAuthCallbackRequestDto,
  OAuthProvider,
  OAuthStartRequestDto,
  OAuthStartResponseDto,
  RefreshSessionRequestDto,
  SessionResponseDto,
} from './dto/auth.dto';

@Injectable()
export class AuthService {
  startOAuth(
    provider: OAuthProvider,
    request: OAuthStartRequestDto,
  ): Promise<OAuthStartResponseDto> {
    void provider;
    void request;

    return notImplemented('AuthService.startOAuth');
  }

  completeOAuth(
    provider: OAuthProvider,
    request: OAuthCallbackRequestDto,
  ): Promise<SessionResponseDto> {
    void provider;
    void request;

    return notImplemented('AuthService.completeOAuth');
  }

  refreshSession(request: RefreshSessionRequestDto): Promise<SessionResponseDto> {
    void request;

    return notImplemented('AuthService.refreshSession');
  }

  logout(): Promise<LogoutResponseDto> {
    return notImplemented('AuthService.logout');
  }
}
