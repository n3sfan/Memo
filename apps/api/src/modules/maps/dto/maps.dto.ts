export type MapType = 'personal' | 'duo';

export class MapDto {
  id!: string;
  type!: MapType;
  ownerId!: string;
  name?: string | null;
}

export class MapsListResponseDto {
  maps!: MapDto[];
}

export class CreateDuoMapRequestDto {
  name?: string;
}

export class InvitationDto {
  id!: string;
  mapId!: string;
  code!: string;
  status!: 'pending' | 'accepted' | 'revoked' | 'expired';
  expiresAt!: string;
  createdAt!: string;
}

export class AcceptInvitationResponseDto {
  map!: MapDto;
  membershipRole!: string;
}

export class MapMemberDto {
  mapId!: string;
  userId!: string;
  role!: string;
  joinedAt!: string;
}

export class RemoveMapMemberResponseDto {
  removed!: true;
}
