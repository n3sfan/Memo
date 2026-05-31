import { Inject, Injectable } from '@nestjs/common';
import { randomUUID } from 'node:crypto';

import {
  throwNotFound,
  throwPayloadTooLarge,
  throwValidationError,
} from '../../common/api-error';
import { OBJECT_STORAGE, ObjectStoragePort } from '../../infra/r2';
import { CurrentUser } from '../auth/current-user';
import { AuthorizationService } from '../authorization/authorization.service';
import {
  MediaDto,
  MediaType,
  MediaReadUrlResponseDto,
  PresignMediaRequestDto,
  PresignMediaResponseDto,
  RegisterMediaRequestDto,
} from './dto/media.dto';
import { MEDIA_REPOSITORY, MediaRepository } from './repositories';

const DEFAULT_MEDIA_MAX_BYTES = 10 * 1024 * 1024;
const MEDIA_TYPES: readonly MediaType[] = ['image', 'text', 'audio'];

@Injectable()
export class MediaService {
  constructor(
    @Inject(MEDIA_REPOSITORY)
    private readonly mediaRepository: MediaRepository,
    @Inject(OBJECT_STORAGE)
    private readonly objectStorage: ObjectStoragePort,
    private readonly authorization: AuthorizationService,
  ) {}

  async createPresignedUpload(
    user: CurrentUser,
    pinId: string,
    request: PresignMediaRequestDto,
  ): Promise<PresignMediaResponseDto> {
    this.assertMediaRequest(request);
    await this.authorization.assertCanUploadMedia(user.id, pinId);

    const objectKey = this.createObjectKey(pinId, request.fileName);
    const presigned = await this.objectStorage.createPresignedUpload({
      mediaType: request.mediaType,
      mimeType: request.mimeType,
      sizeBytes: request.sizeBytes,
      fileName: request.fileName,
      objectKey,
    });

    return {
      uploadUrl: presigned.uploadUrl,
      objectKey,
      expiresAt: presigned.expiresAt.toISOString(),
    };
  }

  async registerMedia(
    user: CurrentUser,
    pinId: string,
    request: RegisterMediaRequestDto,
  ): Promise<MediaDto> {
    this.assertMediaRequest(request);
    this.assertObjectKeyBelongsToPin(pinId, request.objectKey);
    await this.authorization.assertCanUploadMedia(user.id, pinId);

    return this.mediaRepository.createMedia({
      pinId,
      mediaType: request.mediaType,
      objectKey: request.objectKey,
      mimeType: request.mimeType,
      sizeBytes: request.sizeBytes,
    });
  }

  async createReadUrl(
    user: CurrentUser,
    mediaId: string,
  ): Promise<MediaReadUrlResponseDto> {
    const media = await this.mediaRepository.findMediaById(mediaId);

    if (!media) {
      throwNotFound('Media not found.');
    }

    await this.authorization.assertCanReadMedia(user.id, media.pinId);
    const presigned = await this.objectStorage.createPresignedRead(
      media.objectKey,
    );

    return {
      url: presigned.readUrl,
      expiresAt: presigned.expiresAt.toISOString(),
    };
  }

  private assertMediaRequest(
    request: PresignMediaRequestDto | RegisterMediaRequestDto,
  ): void {
    this.assertMediaType(request.mediaType);
    this.assertMimeType(request.mediaType, request.mimeType);
    this.assertSizeBytes(request.sizeBytes);
  }

  private assertMediaType(mediaType: unknown): asserts mediaType is MediaType {
    if (
      typeof mediaType !== 'string' ||
      !MEDIA_TYPES.includes(mediaType as MediaType)
    ) {
      throwValidationError('Unsupported media type.', {
        mediaType,
      });
    }
  }

  private assertMimeType(mediaType: MediaType, mimeType: unknown): void {
    if (typeof mimeType !== 'string' || !mimeType.trim()) {
      throwValidationError('Invalid media MIME type.', {
        mimeType,
      });
    }

    const normalized = mimeType.toLowerCase();
    const prefix = `${mediaType}/`;
    if (!normalized.startsWith(prefix)) {
      throwValidationError('MIME type does not match media type.', {
        mediaType,
        mimeType,
      });
    }
  }

  private assertSizeBytes(sizeBytes: unknown): void {
    if (
      typeof sizeBytes !== 'number' ||
      !Number.isSafeInteger(sizeBytes) ||
      sizeBytes <= 0
    ) {
      throwValidationError('Invalid media size.', {
        sizeBytes,
      });
    }

    const maxBytes = this.maxBytes();
    if (sizeBytes > maxBytes) {
      throwPayloadTooLarge('Media file exceeds the maximum allowed size.', {
        maxBytes,
        sizeBytes,
      });
    }
  }

  private assertObjectKeyBelongsToPin(pinId: string, objectKey: unknown): void {
    const prefix = this.objectKeyPrefix(pinId);

    if (typeof objectKey !== 'string' || !objectKey.startsWith(prefix)) {
      throwValidationError('Object key does not belong to this pin.', {
        objectKey,
        pinId,
      });
    }
  }

  private createObjectKey(pinId: string, fileName: string): string {
    return `${this.objectKeyPrefix(pinId)}${randomUUID()}-${this.safeFileName(
      fileName,
    )}`;
  }

  private objectKeyPrefix(pinId: string): string {
    return `pins/${pinId}/`;
  }

  private safeFileName(fileName: unknown): string {
    if (typeof fileName !== 'string' || !fileName.trim()) {
      return 'media';
    }

    const baseName = fileName.trim().split(/[\\/]/).pop() ?? 'media';
    const safe = baseName
      .toLowerCase()
      .replace(/[^a-z0-9._-]+/g, '-')
      .replace(/-+/g, '-')
      .replace(/^-|-$/g, '');

    return safe || 'media';
  }

  private maxBytes(): number {
    const configured = Number(process.env.MEDIA_MAX_BYTES);

    if (Number.isSafeInteger(configured) && configured > 0) {
      return configured;
    }

    return DEFAULT_MEDIA_MAX_BYTES;
  }
}
