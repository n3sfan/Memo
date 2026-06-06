export type MapType = 'personal' | 'duo';

export type InvitationStatus = 'pending' | 'accepted' | 'revoked' | 'expired';
export type MapMemberRole = 'owner' | 'member';

export class InvitationDto {
  id!: string;
  mapId!: string;
  code!: string;
  status!: InvitationStatus;
  expiresAt!: string;
  createdAt!: string;
}

export class MapMemberDto {
  mapId!: string;
  userId!: string;
  role!: MapMemberRole;
  joinedAt!: string;
}

export class MapDto {
  id!: string;
  type!: MapType;
  ownerId!: string;
  name?: string | null;
  members?: MapMemberDto[];
  pendingInvitation?: InvitationDto | null;
}

export class MapsListResponseDto {
  maps!: MapDto[];
}

export class CreateDuoMapRequestDto {
  name?: string;
}

export class AcceptInvitationResponseDto {
  map!: MapDto;
  membershipRole!: MapMemberRole;
}

export class RemoveMapMemberResponseDto {
  removed!: true;
}
