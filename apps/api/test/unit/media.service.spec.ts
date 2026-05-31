import { HttpStatus } from '@nestjs/common';

import { ApiException } from '../../src/common/api-error';
import {
  ObjectStoragePort,
  PresignedRead,
  PresignedUpload,
} from '../../src/infra/r2';
import { CurrentUser } from '../../src/modules/auth/current-user';
import { AuthorizationService } from '../../src/modules/authorization/authorization.service';
import { MediaService } from '../../src/modules/media/media.service';
import {
  MediaRepository,
  MediaRecord,
} from '../../src/modules/media/repositories';

describe('MediaService', () => {
  const user: CurrentUser = {
    id: 'user-1',
    email: 'user@example.test',
    displayName: 'Memo User',
    provider: 'google',
  };

  let mediaRepository: jest.Mocked<MediaRepository>;
  let objectStorage: jest.Mocked<ObjectStoragePort>;
  let authorization: jest.Mocked<
    Pick<AuthorizationService, 'assertCanUploadMedia' | 'assertCanReadMedia'>
  >;
  let service: MediaService;

  beforeEach(() => {
    process.env.MEDIA_MAX_BYTES = '1000';
    mediaRepository = createMediaRepositoryMock();
    objectStorage = createObjectStorageMock();
    authorization = {
      assertCanUploadMedia: jest.fn(),
      assertCanReadMedia: jest.fn(),
    };
    service = new MediaService(
      mediaRepository,
      objectStorage,
      authorization as unknown as AuthorizationService,
    );
  });

  afterEach(() => {
    delete process.env.MEDIA_MAX_BYTES;
  });

  it('rejects oversized upload presign requests with payload_too_large before storage access', async () => {
    await expectApiException(
      service.createPresignedUpload(user, 'pin-1', {
        mediaType: 'image',
        mimeType: 'image/jpeg',
        sizeBytes: 1001,
        fileName: 'photo.jpg',
      }),
      HttpStatus.PAYLOAD_TOO_LARGE,
      'payload_too_large',
    );

    expect(authorization.assertCanUploadMedia).not.toHaveBeenCalled();
    expect(objectStorage.createPresignedUpload).not.toHaveBeenCalled();
    expect(mediaRepository.createMedia).not.toHaveBeenCalled();
  });

  it('authorizes and returns a presigned upload without creating media metadata', async () => {
    const expiresAt = new Date('2026-06-01T00:15:00.000Z');
    objectStorage.createPresignedUpload.mockResolvedValue({
      uploadUrl: 'https://r2.example/upload',
      objectKey: 'ignored-by-service',
      expiresAt,
    } satisfies PresignedUpload);

    const response = await service.createPresignedUpload(user, 'pin-1', {
      mediaType: 'image',
      mimeType: 'image/jpeg',
      sizeBytes: 512,
      fileName: 'summer photo.jpg',
    });

    expect(authorization.assertCanUploadMedia).toHaveBeenCalledWith(
      'user-1',
      'pin-1',
    );
    expect(objectStorage.createPresignedUpload).toHaveBeenCalledWith(
      expect.objectContaining({
        mediaType: 'image',
        mimeType: 'image/jpeg',
        sizeBytes: 512,
        objectKey: expect.stringMatching(
          /^pins\/pin-1\/[0-9a-f-]+-summer-photo\.jpg$/,
        ),
      }),
    );
    expect(mediaRepository.createMedia).not.toHaveBeenCalled();
    expect(response).toEqual({
      uploadUrl: 'https://r2.example/upload',
      objectKey: expect.stringMatching(
        /^pins\/pin-1\/[0-9a-f-]+-summer-photo\.jpg$/,
      ),
      expiresAt: expiresAt.toISOString(),
    });
  });

  it('registers uploaded media metadata for the pin object key prefix', async () => {
    const createdAt = '2026-06-01T00:20:00.000Z';
    mediaRepository.createMedia.mockResolvedValue({
      id: 'media-1',
      pinId: 'pin-1',
      mediaType: 'image',
      objectKey: 'pins/pin-1/uploaded-photo.jpg',
      mimeType: 'image/jpeg',
      sizeBytes: 512,
      createdAt,
    });

    await expect(
      service.registerMedia(user, 'pin-1', {
        mediaType: 'image',
        objectKey: 'pins/pin-1/uploaded-photo.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: 512,
      }),
    ).resolves.toEqual({
      id: 'media-1',
      pinId: 'pin-1',
      mediaType: 'image',
      objectKey: 'pins/pin-1/uploaded-photo.jpg',
      mimeType: 'image/jpeg',
      sizeBytes: 512,
      createdAt,
    });

    expect(authorization.assertCanUploadMedia).toHaveBeenCalledWith(
      'user-1',
      'pin-1',
    );
    expect(mediaRepository.createMedia).toHaveBeenCalledWith({
      pinId: 'pin-1',
      mediaType: 'image',
      objectKey: 'pins/pin-1/uploaded-photo.jpg',
      mimeType: 'image/jpeg',
      sizeBytes: 512,
    });
  });

  it('rejects registering an object key that does not belong to the pin', async () => {
    await expectApiException(
      service.registerMedia(user, 'pin-1', {
        mediaType: 'image',
        objectKey: 'pins/other-pin/photo.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: 512,
      }),
      HttpStatus.UNPROCESSABLE_ENTITY,
      'validation_error',
    );

    expect(authorization.assertCanUploadMedia).not.toHaveBeenCalled();
    expect(mediaRepository.createMedia).not.toHaveBeenCalled();
  });

  it('returns a presigned read URL after authorizing access through the parent pin', async () => {
    mediaRepository.findMediaById.mockResolvedValue(
      mediaRecord({
        id: 'media-1',
        pinId: 'pin-1',
        objectKey: 'pins/pin-1/photo.jpg',
      }),
    );
    const expiresAt = new Date('2026-06-01T00:30:00.000Z');
    objectStorage.createPresignedRead.mockResolvedValue({
      readUrl: 'https://r2.example/read',
      expiresAt,
    } satisfies PresignedRead);

    await expect(service.createReadUrl(user, 'media-1')).resolves.toEqual({
      url: 'https://r2.example/read',
      expiresAt: expiresAt.toISOString(),
    });

    expect(authorization.assertCanReadMedia).toHaveBeenCalledWith(
      'user-1',
      'pin-1',
    );
    expect(objectStorage.createPresignedRead).toHaveBeenCalledWith(
      'pins/pin-1/photo.jpg',
    );
  });
});

function createMediaRepositoryMock(): jest.Mocked<MediaRepository> {
  return {
    createMedia: jest.fn(),
    findMediaById: jest.fn(),
  };
}

function createObjectStorageMock(): jest.Mocked<ObjectStoragePort> {
  return {
    createPresignedUpload: jest.fn(),
    createPresignedRead: jest.fn(),
    deleteObject: jest.fn(),
  };
}

function mediaRecord(overrides: Partial<MediaRecord> = {}): MediaRecord {
  return {
    id: 'media-1',
    pinId: 'pin-1',
    mediaType: 'image',
    objectKey: 'pins/pin-1/photo.jpg',
    mimeType: 'image/jpeg',
    sizeBytes: 512,
    createdAt: '2026-06-01T00:20:00.000Z',
    ...overrides,
  };
}

async function expectApiException(
  promise: Promise<unknown>,
  status: HttpStatus,
  code: string,
): Promise<void> {
  try {
    await promise;
    throw new Error('Expected ApiException.');
  } catch (error) {
    expect(error).toBeInstanceOf(ApiException);
    expect((error as ApiException).getStatus()).toBe(status);
    expect((error as ApiException).apiErrorCode).toBe(code);
  }
}
