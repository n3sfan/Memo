import { MediaDto, MediaType } from '../dto/media.dto';

export const MEDIA_REPOSITORY = Symbol('MEDIA_REPOSITORY');

export type MediaRecord = MediaDto;

export interface CreateMediaInput {
  pinId: string;
  mediaType: MediaType;
  objectKey: string;
  mimeType: string;
  sizeBytes: number;
}

export interface MediaRepository {
  createMedia(input: CreateMediaInput): Promise<MediaRecord>;
  findMediaById(mediaId: string): Promise<MediaRecord | null>;
}
