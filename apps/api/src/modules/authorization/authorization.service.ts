import { Inject, Injectable } from '@nestjs/common';

import {
  throwForbidden,
  throwNotFound,
} from '../../common/api-error';
import { CurrentUser } from '../auth/current-user';
import {
  ResourceAccessDto,
  ResourceAccessRole,
} from './dto/authorization.dto';
import {
  ACCESS_CONTROL_REPOSITORY,
  AccessControlRepository,
  MapAccessRecord,
} from './repositories';

@Injectable()
export class AuthorizationService {
  constructor(
    @Inject(ACCESS_CONTROL_REPOSITORY)
    private readonly accessRepository: AccessControlRepository,
  ) {}

  async resolveMapAccess(
    user: CurrentUser,
    mapId: string,
  ): Promise<ResourceAccessDto> {
    return this.permissionToDto(await this.resolveMapPermission(user.id, mapId));
  }

  async resolvePinAccess(
    user: CurrentUser,
    pinId: string,
  ): Promise<ResourceAccessDto> {
    return this.permissionToDto(await this.resolvePinPermission(user.id, pinId));
  }

  async resolveShareLinkAccess(token: string): Promise<ResourceAccessDto> {
    const shareLink =
      await this.accessRepository.findShareLinkAccessRecord(token);

    return {
      allowed: Boolean(shareLink && !shareLink.revoked),
      role: shareLink && !shareLink.revoked ? 'share_link' : undefined,
    };
  }

  async canReadMap(userId: string, mapId: string): Promise<boolean> {
    return (await this.resolveMapPermission(userId, mapId)).allowed;
  }

  async canWriteMap(userId: string, mapId: string): Promise<boolean> {
    const permission = await this.resolveMapPermission(userId, mapId);

    return permission.allowed && permission.role === 'owner';
  }

  async canCreatePin(userId: string, mapId: string): Promise<boolean> {
    return this.canReadMap(userId, mapId);
  }

  async canReadPin(userId: string, pinId: string): Promise<boolean> {
    return (await this.resolvePinPermission(userId, pinId)).allowed;
  }

  async canWritePin(userId: string, pinId: string): Promise<boolean> {
    return (await this.resolvePinPermission(userId, pinId)).allowed;
  }

  async canUploadMedia(userId: string, pinId: string): Promise<boolean> {
    return this.canWritePin(userId, pinId);
  }

  canAccessAccount(userId: string, accountUserId: string): boolean {
    return userId === accountUserId;
  }

  async canManageInvitation(
    userId: string,
    invitationId: string,
  ): Promise<boolean> {
    const invitation =
      await this.accessRepository.findInvitationAccessRecord(invitationId);

    if (!invitation) {
      return false;
    }

    return this.permissionForMapRecord(userId, invitation.map).role === 'owner';
  }

  async assertCanReadMap(userId: string, mapId: string): Promise<void> {
    this.assertMapPermission(
      await this.resolveMapPermission(userId, mapId),
      'You do not have access to this map.',
    );
  }

  async assertCanWriteMap(userId: string, mapId: string): Promise<void> {
    const permission = await this.resolveMapPermission(userId, mapId);
    this.assertMapPermission(permission, 'You cannot modify this map.');

    if (permission.role !== 'owner') {
      throwForbidden('Only the map owner can modify this map.');
    }
  }

  async assertCanCreatePin(userId: string, mapId: string): Promise<void> {
    this.assertMapPermission(
      await this.resolveMapPermission(userId, mapId),
      'You cannot create pins on this map.',
    );
  }

  async assertCanReadPin(userId: string, pinId: string): Promise<void> {
    this.assertHiddenPermission(
      await this.resolvePinPermission(userId, pinId),
      'Pin not found.',
    );
  }

  async assertCanWritePin(userId: string, pinId: string): Promise<void> {
    this.assertHiddenPermission(
      await this.resolvePinPermission(userId, pinId),
      'Pin not found.',
    );
  }

  async assertCanModifyPin(userId: string, pinId: string): Promise<void> {
    this.assertWritePermission(
      await this.resolvePinPermission(userId, pinId),
      'Pin not found.',
      'You cannot modify this pin.',
    );
  }

  async assertCanUploadMedia(userId: string, pinId: string): Promise<void> {
    await this.assertCanWritePin(userId, pinId);
  }

  assertCanAccessAccount(userId: string, accountUserId: string): void {
    if (!this.canAccessAccount(userId, accountUserId)) {
      throwForbidden('You can only access your own account.');
    }
  }

  private async resolveMapPermission(
    userId: string,
    mapId: string,
  ): Promise<ResourcePermission> {
    const map = await this.accessRepository.findMapAccessRecord(mapId);

    if (!map) {
      return {
        exists: false,
        allowed: false,
      };
    }

    return this.permissionForMapRecord(userId, map);
  }

  private async resolvePinPermission(
    userId: string,
    pinId: string,
  ): Promise<ResourcePermission> {
    const pin = await this.accessRepository.findPinAccessRecord(pinId);

    if (!pin) {
      return {
        exists: false,
        allowed: false,
      };
    }

    return this.permissionForMapRecord(userId, pin.map);
  }

  private permissionForMapRecord(
    userId: string,
    map: MapAccessRecord,
  ): ResourcePermission {
    if (map.ownerId === userId) {
      return {
        exists: true,
        allowed: true,
        role: 'owner',
      };
    }

    const membership = map.members.find((member) => member.userId === userId);
    if (map.type === 'duo' && membership) {
      return {
        exists: true,
        allowed: true,
        role: 'duo_member',
      };
    }

    return {
      exists: true,
      allowed: false,
    };
  }

  private assertMapPermission(
    permission: ResourcePermission,
    forbiddenMessage: string,
  ): void {
    if (!permission.exists) {
      throwNotFound('Map not found.');
    }

    if (!permission.allowed) {
      throwForbidden(forbiddenMessage);
    }
  }

  private assertHiddenPermission(
    permission: ResourcePermission,
    notFoundMessage: string,
  ): void {
    if (!permission.exists || !permission.allowed) {
      throwNotFound(notFoundMessage);
    }
  }

  private assertWritePermission(
    permission: ResourcePermission,
    notFoundMessage: string,
    forbiddenMessage: string,
  ): void {
    if (!permission.exists) {
      throwNotFound(notFoundMessage);
    }

    if (!permission.allowed) {
      throwForbidden(forbiddenMessage);
    }
  }

  private permissionToDto(permission: ResourcePermission): ResourceAccessDto {
    return {
      allowed: permission.allowed,
      role: permission.role,
    };
  }
}

interface ResourcePermission {
  exists: boolean;
  allowed: boolean;
  role?: ResourceAccessRole;
}
