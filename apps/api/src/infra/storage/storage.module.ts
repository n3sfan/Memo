import { Module } from '@nestjs/common';

import { OBJECT_STORAGE } from './object-storage.port';
import { R2ObjectStorageAdapter } from './r2-object-storage.adapter';

@Module({
  providers: [
    R2ObjectStorageAdapter,
    {
      provide: OBJECT_STORAGE,
      useExisting: R2ObjectStorageAdapter,
    },
  ],
  exports: [OBJECT_STORAGE],
})
export class StorageModule {}
