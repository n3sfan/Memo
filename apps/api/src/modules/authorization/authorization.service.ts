import { Injectable } from '@nestjs/common';

import { notImplemented } from '../../common/not-implemented';
import { CurrentUser } from '../auth/current-user';
import { ResourceAccessDto } from './dto/authorization.dto';

@Injectable()
export class AuthorizationService {
  resolveMapAccess(
    user: CurrentUser,
    mapId: string,
  ): Promise<ResourceAccessDto> {
    void user;
    void mapId;

    return notImplemented('AuthorizationService.resolveMapAccess');
  }

  resolvePinAccess(
    user: CurrentUser,
    pinId: string,
  ): Promise<ResourceAccessDto> {
    void user;
    void pinId;

    return notImplemented('AuthorizationService.resolvePinAccess');
  }

  resolveShareLinkAccess(token: string): Promise<ResourceAccessDto> {
    void token;

    return notImplemented('AuthorizationService.resolveShareLinkAccess');
  }
}
