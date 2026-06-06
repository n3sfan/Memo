import {
  CreateDuoMapRequestDto,
  InvitationDto,
  MapDto,
} from '../dto/maps.dto';

export const MAP_REPOSITORY = Symbol('MAP_REPOSITORY');

export class PendingInvitationConflictError extends Error {
  constructor() {
    super('Pending invitation already exists.');
  }
}

export interface AcceptInvitationInput {
  code: string;
  userId: string;
  now: Date;
}

export type AcceptInvitationResult =
  | {
      status: 'accepted';
      map: MapDto;
      membershipRole: 'member';
    }
  | {
      status: 'invalid_invitation';
    }
  | {
      status: 'map_full';
    };

export interface CreateInvitationInput {
  mapId: string;
  createdBy: string;
  code: string;
  expiresAt: Date;
}

export interface MapRepository {
  listMapsForUser(userId: string, now: Date): Promise<MapDto[]>;
  findDefaultMapForUser(userId: string, now: Date): Promise<MapDto | null>;
  findMapById(mapId: string, now: Date): Promise<MapDto | null>;
  countMapMembers(mapId: string): Promise<number>;
  expirePendingInvitationsForMap(mapId: string, now: Date): Promise<void>;
  createDuoMap(
    ownerId: string,
    request: CreateDuoMapRequestDto,
    now: Date,
  ): Promise<MapDto>;
  createInvitation(input: CreateInvitationInput): Promise<InvitationDto>;
  revokeInvitation(
    mapId: string,
    invitationId: string,
    now: Date,
  ): Promise<boolean>;
  acceptInvitation(input: AcceptInvitationInput): Promise<AcceptInvitationResult>;
  removeMember(mapId: string, userId: string): Promise<boolean>;
}
