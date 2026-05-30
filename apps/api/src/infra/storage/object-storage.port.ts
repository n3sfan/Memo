export const OBJECT_STORAGE = Symbol('OBJECT_STORAGE');

export type ObjectStorageMediaType = 'image' | 'audio';

export interface CreatePresignedUploadInput {
  mediaType: ObjectStorageMediaType;
  mimeType: string;
  sizeBytes: number;
  fileName?: string;
  objectKey: string;
}

export interface PresignedUpload {
  uploadUrl: string;
  objectKey: string;
  expiresAt: Date;
}

export interface PresignedRead {
  readUrl: string;
  expiresAt: Date;
}

export interface ObjectStoragePort {
  createPresignedUpload(
    input: CreatePresignedUploadInput,
  ): Promise<PresignedUpload>;
  createPresignedRead(objectKey: string): Promise<PresignedRead>;
  deleteObject(objectKey: string): Promise<void>;
}
