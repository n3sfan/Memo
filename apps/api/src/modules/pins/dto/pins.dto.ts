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

export class PinDto {
  id!: string;
  mapId!: string;
  title!: string;
  note?: string | null;
  memoryDate?: string | null;
  lat!: number;
  lng!: number;
  media!: PinMediaDto[];
  createdAt!: string;
  updatedAt!: string;
  clientId?: string | null;
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
