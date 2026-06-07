import { Inject, Injectable } from '@nestjs/common';
import { randomBytes } from 'crypto';

import { EmptyResultDto } from '../../common/dto/result.dto';
import {
  throwForbidden,
  throwInvalidInvitation,
  throwInvitationPendingExists,
  throwMapFull,
  throwNotFound,
  throwValidationError,
} from '../../common/api-error';
import { CurrentUser } from '../auth/current-user';
import { AuthorizationService } from '../authorization/authorization.service';
import {
  AcceptInvitationResponseDto,
  CreateDuoMapRequestDto,
  InvitationDto,
  MapDto,
  MapsListResponseDto,
  RemoveMapMemberResponseDto,
} from './dto/maps.dto';
import {
  MAP_REPOSITORY,
  MapRepository,
  PendingInvitationConflictError,
} from './repositories';

const INVITATION_TTL_MS = 7 * 24 * 60 * 60 * 1000;
const INVITATION_CODE_BYTES = 4;

@Injectable()
export class MapsService {
  constructor(
    @Inject(MAP_REPOSITORY)
    private readonly mapRepository: MapRepository,
    private readonly authorization: AuthorizationService,
  ) {}

  async listMaps(user: CurrentUser): Promise<MapsListResponseDto> {
    return {
      maps: await this.mapRepository.listMapsForUser(user.id, this.now()),
    };
  }

  async getDefaultMap(user: CurrentUser): Promise<MapDto> {
    const map = await this.mapRepository.findDefaultMapForUser(
      user.id,
      this.now(),
    );

    if (!map) {
      throwNotFound('Default map not found.');
    }

    return map;
  }

  createDuoMap(
    user: CurrentUser,
    request: CreateDuoMapRequestDto,
  ): Promise<MapDto> {
    return this.mapRepository.createDuoMap(user.id, request, this.now());
  }

  async createInvitation(
    user: CurrentUser,
    mapId: string,
  ): Promise<InvitationDto> {
    const now = this.now();
    await this.authorization.assertCanWriteMap(user.id, mapId);
    const map = await this.requireDuoMap(mapId, now);
    if ((map.members ?? []).length >= 2) {
      throwMapFull();
    }

    await this.mapRepository.expirePendingInvitationsForMap(mapId, now);
    const refreshedMap = await this.requireDuoMap(mapId, now);
    if (refreshedMap.pendingInvitation) {
      throwInvitationPendingExists();
    }

    try {
      return await this.mapRepository.createInvitation({
        mapId,
        createdBy: user.id,
        code: this.generateInvitationCode(),
        expiresAt: new Date(now.getTime() + INVITATION_TTL_MS),
      });
    } catch (error) {
      if (error instanceof PendingInvitationConflictError) {
        throwInvitationPendingExists();
      }

      throw error;
    }
  }

  async revokeInvitation(
    user: CurrentUser,
    mapId: string,
    invitationId: string,
  ): Promise<EmptyResultDto> {
    await this.authorization.assertCanWriteMap(user.id, mapId);
    await this.requireDuoMap(mapId, this.now());

    const revoked = await this.mapRepository.revokeInvitation(
      mapId,
      invitationId,
      this.now(),
    );

    if (!revoked) {
      throwInvalidInvitation();
    }

    return { ok: true };
  }

  async acceptInvitation(
    user: CurrentUser,
    code: string,
  ): Promise<AcceptInvitationResponseDto> {
    const normalizedCode = this.normalizeInvitationCode(code);
    if (!normalizedCode) {
      throwInvalidInvitation();
    }

    const result = await this.mapRepository.acceptInvitation({
      code: normalizedCode,
      userId: user.id,
      now: this.now(),
    });

    if (result.status === 'invalid_invitation') {
      throwInvalidInvitation();
    }

    if (result.status === 'map_full') {
      throwMapFull();
    }

    return {
      map: result.map,
      membershipRole: result.membershipRole,
    };
  }

  async removeMember(
    user: CurrentUser,
    mapId: string,
    userId: string,
  ): Promise<RemoveMapMemberResponseDto> {
    await this.authorization.assertCanWriteMap(user.id, mapId);
    await this.requireDuoMap(mapId, this.now());

    if (user.id === userId) {
      throwForbidden('The owner cannot remove themselves from a Duo Map.');
    }

    const removed = await this.mapRepository.removeMember(mapId, userId);
    if (!removed) {
      throwNotFound('Map member not found.');
    }

    return { removed: true };
  }

  private async requireDuoMap(mapId: string, now: Date): Promise<MapDto> {
    const map = await this.mapRepository.findMapById(mapId, now);

    if (!map) {
      throwNotFound('Map not found.');
    }

    if (map.type !== 'duo') {
      throwValidationError('Invitations are only supported for Duo Maps.');
    }

    return map;
  }

  private generateInvitationCode(): string {
    return `INV-${randomBytes(INVITATION_CODE_BYTES)
      .toString('hex')
      .toUpperCase()}`;
  }

  private normalizeInvitationCode(code: string): string {
    return code.trim().toUpperCase();
  }

  private now(): Date {
    return new Date();
  }
}
