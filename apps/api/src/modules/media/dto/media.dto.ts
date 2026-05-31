export type MediaType = 'image' | 'text' | 'audio';

export class PresignMediaRequestDto {
  mediaType!: MediaType;
  mimeType!: string;
  sizeBytes!: number;
  fileName!: string;
}

export class PresignMediaResponseDto {
  uploadUrl!: string;
  objectKey!: string;
  expiresAt!: string;
}

export class RegisterMediaRequestDto {
  mediaType!: MediaType;
  objectKey!: string;
  mimeType!: string;
  sizeBytes!: number;
}

export class MediaDto {
  id!: string;
  pinId!: string;
  mediaType!: MediaType;
  objectKey!: string;
  mimeType!: string;
  sizeBytes!: number;
  createdAt!: string;
  url?: string;
}

export class MediaReadUrlResponseDto {
  url!: string;
  expiresAt!: string;
}
