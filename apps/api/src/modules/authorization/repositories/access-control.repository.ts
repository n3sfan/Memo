export const ACCESS_CONTROL_REPOSITORY = Symbol('ACCESS_CONTROL_REPOSITORY');

export interface MapAccessRecord {
  id: string;
  ownerId: string;
  type: string;
  members: Array<{
    userId: string;
    role: string;
  }>;
}

export interface InvitationAccessRecord {
  map: MapAccessRecord;
}

export interface PinAccessRecord {
  map: MapAccessRecord;
}

export interface ShareLinkAccessRecord {
  revoked: boolean;
}

export interface AccessControlRepository {
  findMapAccessRecord(mapId: string): Promise<MapAccessRecord | null>;
  findPinAccessRecord(pinId: string): Promise<PinAccessRecord | null>;
  findInvitationAccessRecord(
    invitationId: string,
  ): Promise<InvitationAccessRecord | null>;
  findShareLinkAccessRecord(
    token: string,
  ): Promise<ShareLinkAccessRecord | null>;
}
