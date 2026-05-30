import { Injectable } from '@nestjs/common';

import { notImplemented } from '../../common/not-implemented';
import {
  CreatePresignedUploadInput,
  ObjectStoragePort,
  PresignedRead,
  PresignedUpload,
} from './object-storage.port';

@Injectable()
export class R2ObjectStorageAdapter implements ObjectStoragePort {
  createPresignedUpload(
    input: CreatePresignedUploadInput,
  ): Promise<PresignedUpload> {
    void input;

    return notImplemented('R2ObjectStorageAdapter.createPresignedUpload');
  }

  createPresignedRead(objectKey: string): Promise<PresignedRead> {
    void objectKey;

    return notImplemented('R2ObjectStorageAdapter.createPresignedRead');
  }

  deleteObject(objectKey: string): Promise<void> {
    void objectKey;

    return notImplemented('R2ObjectStorageAdapter.deleteObject');
  }
}
