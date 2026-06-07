export class PinMediaDto {
  id!: string;
  pinId!: string;
  mediaType!: 'image' | 'text' | 'audio';
  objectKey!: string;
  mimeType!: string;
  sizeBytes!: number;
  createdAt!: string;
  url?: string;
}

export class PublicPinMediaDto {
  id!: string;
  pinId!: string;
  mediaType!: 'image' | 'text' | 'audio';
  mimeType!: string;
  sizeBytes!: number;
  createdAt!: string;
  url!: string;
}

export class PinCoreDto {
  id!: string;
  title!: string;
  note?: string | null;
  memoryDate?: string | null;
  lat!: number;
  lng!: number;
  createdAt!: string;
  updatedAt!: string;
}

export class PinDto extends PinCoreDto {
  mapId!: string;
  media!: PinMediaDto[];
  clientId?: string | null;
}

export class PublicPinDto extends PinCoreDto {
  media!: PublicPinMediaDto[];
}

export class PinsListResponseDto {
  pins!: PinDto[];
}

export class CreatePinRequestDto {
  title!: string;
  note?: string;
  memoryDate?: string;
  lat!: number;
  lng!: number;
  clientId?: string;
}

export class UpdatePinRequestDto {
  title?: string;
  note?: string | null;
  memoryDate?: string | null;
  lat?: number;
  lng?: number;
}

export class BboxPinsQueryDto {
  bbox?: string;
}

export class DeletePinResponseDto {
  deleted!: true;
}
