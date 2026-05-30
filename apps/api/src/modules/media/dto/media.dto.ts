export class PresignMediaRequestDto {
  mediaType!: 'image' | 'text' | 'audio';
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
  mediaType!: 'image' | 'text' | 'audio';
  objectKey!: string;
  mimeType!: string;
  sizeBytes!: number;
}

export class MediaDto {
  id!: string;
  pinId!: string;
  mediaType!: 'image' | 'text' | 'audio';
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
