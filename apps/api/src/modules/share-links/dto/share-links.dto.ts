import { PinDto } from '../../pins/dto/pins.dto';

export class CreateShareLinkRequestDto {
  expiresAt?: string;
}

export class ShareLinkDto {
  id!: string;
  pinId!: string;
  token!: string;
  url!: string;
  revoked!: boolean;
  createdAt!: string;
  expiresAt?: string | null;
}

export class PublicSharedPinDto {
  pin!: PinDto;
  shareLinkId!: string;
}

export class RevokeShareLinkResponseDto {
  revoked!: true;
}
