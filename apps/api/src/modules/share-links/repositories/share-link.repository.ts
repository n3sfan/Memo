import { PinDto } from '../../pins/dto/pins.dto';

export const SHARE_LINK_REPOSITORY = Symbol('SHARE_LINK_REPOSITORY');

export interface CreateShareLinkInput {
  pinId: string;
  createdBy: string;
  token: string;
}

export interface ShareLinkRecord {
  id: string;
  pinId: string;
  createdBy: string;
  token: string;
  revoked: boolean;
  createdAt: string;
}

export interface PublicShareLinkRecord extends ShareLinkRecord {
  pin: PinDto;
}

export class ShareLinkTokenConflictError extends Error {
  constructor(readonly token: string) {
    super('Share link token already exists.');
    this.name = 'ShareLinkTokenConflictError';
  }
}

export interface ShareLinkRepository {
  createShareLink(input: CreateShareLinkInput): Promise<ShareLinkRecord>;
  findShareLinkByToken(token: string): Promise<ShareLinkRecord | null>;
  findShareLinkById(shareLinkId: string): Promise<ShareLinkRecord | null>;
  revokeShareLink(shareLinkId: string): Promise<ShareLinkRecord | null>;
  findPublicShareByToken(token: string): Promise<PublicShareLinkRecord | null>;
}
