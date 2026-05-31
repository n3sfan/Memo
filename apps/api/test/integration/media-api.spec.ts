import { INestApplication } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import request = require('supertest');

import { ApiExceptionFilter } from '../../src/common/api-exception.filter';
import {
  OBJECT_STORAGE,
  ObjectStoragePort,
} from '../../src/infra/r2';
import { JwtAuthGuard } from '../../src/modules/auth/jwt-auth.guard';
import { AuthorizationService } from '../../src/modules/authorization/authorization.service';
import {
  ACCESS_CONTROL_REPOSITORY,
  AccessControlRepository,
} from '../../src/modules/authorization/repositories';
import { MediaController } from '../../src/modules/media/media.controller';
import { MediaService } from '../../src/modules/media/media.service';
import {
  MEDIA_REPOSITORY,
  MediaRepository,
} from '../../src/modules/media/repositories';

describe('Media API', () => {
  let app: INestApplication;
  let jwtService: JwtService;
  let accessRepository: jest.Mocked<AccessControlRepository>;
  let mediaRepository: jest.Mocked<MediaRepository>;
  let objectStorage: jest.Mocked<ObjectStoragePort>;

  beforeEach(async () => {
    process.env.MEDIA_MAX_BYTES = '1000';
    accessRepository = createAccessRepositoryMock();
    mediaRepository = createMediaRepositoryMock();
    objectStorage = createObjectStorageMock();

    const moduleRef = await Test.createTestingModule({
      controllers: [MediaController],
      providers: [
        MediaService,
        JwtAuthGuard,
        JwtService,
        AuthorizationService,
        {
          provide: ACCESS_CONTROL_REPOSITORY,
          useValue: accessRepository,
        },
        {
          provide: MEDIA_REPOSITORY,
          useValue: mediaRepository,
        },
        {
          provide: OBJECT_STORAGE,
          useValue: objectStorage,
        },
      ],
    }).compile();

    jwtService = moduleRef.get(JwtService);
    app = moduleRef.createNestApplication();
    app.setGlobalPrefix('api/v1');
    app.useGlobalFilters(new ApiExceptionFilter());
    await app.init();
  });

  afterEach(async () => {
    delete process.env.MEDIA_MAX_BYTES;
    await app.close();
  });

  it('returns a presigned upload URL and object key without registering media metadata', async () => {
    accessRepository.findPinAccessRecord.mockResolvedValue({
      map: mapRecord({
        ownerId: 'user-1',
      }),
    });
    objectStorage.createPresignedUpload.mockResolvedValue({
      uploadUrl: 'https://r2.example/upload',
      objectKey: 'ignored-by-service',
      expiresAt: new Date('2026-06-01T00:15:00.000Z'),
    });

    const response = await request(app.getHttpServer())
      .post('/api/v1/pins/pin-1/media/presign')
      .set('authorization', `Bearer ${accessToken('user-1')}`)
      .set('x-request-id', 'req_media_presign')
      .send({
        mediaType: 'image',
        mimeType: 'image/jpeg',
        sizeBytes: 512,
        fileName: 'photo.jpg',
      })
      .expect(201);

    expect(response.body).toEqual({
      data: {
        uploadUrl: 'https://r2.example/upload',
        objectKey: expect.stringMatching(/^pins\/pin-1\/[0-9a-f-]+-photo\.jpg$/),
        expiresAt: '2026-06-01T00:15:00.000Z',
      },
      requestId: 'req_media_presign',
    });
    expect(mediaRepository.createMedia).not.toHaveBeenCalled();
  });

  it('returns payload_too_large for oversized media before storage access', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/pins/pin-1/media/presign')
      .set('authorization', `Bearer ${accessToken('user-1')}`)
      .set('x-request-id', 'req_media_too_large')
      .send({
        mediaType: 'image',
        mimeType: 'image/jpeg',
        sizeBytes: 1001,
        fileName: 'photo.jpg',
      })
      .expect(413);

    expect(response.body).toEqual({
      error: 'payload_too_large',
      message: 'Media file exceeds the maximum allowed size.',
      details: {
        maxBytes: 1000,
        sizeBytes: 1001,
      },
      requestId: 'req_media_too_large',
    });
    expect(accessRepository.findPinAccessRecord).not.toHaveBeenCalled();
    expect(objectStorage.createPresignedUpload).not.toHaveBeenCalled();
  });

  it('returns forbidden when an authenticated user cannot read media through the parent pin', async () => {
    mediaRepository.findMediaById.mockResolvedValue({
      id: 'media-1',
      pinId: 'pin-1',
      mediaType: 'image',
      objectKey: 'pins/pin-1/photo.jpg',
      mimeType: 'image/jpeg',
      sizeBytes: 512,
      createdAt: '2026-06-01T00:20:00.000Z',
    });
    accessRepository.findPinAccessRecord.mockResolvedValue({
      map: mapRecord({
        ownerId: 'owner-1',
      }),
    });

    const response = await request(app.getHttpServer())
      .get('/api/v1/media/media-1/presign')
      .set('authorization', `Bearer ${accessToken('user-1')}`)
      .set('x-request-id', 'req_media_forbidden')
      .expect(403);

    expect(response.body).toEqual({
      error: 'forbidden',
      message: 'You cannot access this media.',
      details: {},
      requestId: 'req_media_forbidden',
    });
    expect(objectStorage.createPresignedRead).not.toHaveBeenCalled();
  });

  function accessToken(userId: string): string {
    return jwtService.sign(
      {
        sub: userId,
        email: `${userId}@example.test`,
        displayName: 'Memo User',
      },
      {
        secret: process.env.JWT_ACCESS_SECRET,
        expiresIn: '5m',
      },
    );
  }
});

function createAccessRepositoryMock(): jest.Mocked<AccessControlRepository> {
  return {
    findMapAccessRecord: jest.fn(),
    findPinAccessRecord: jest.fn(),
    findInvitationAccessRecord: jest.fn(),
    findShareLinkAccessRecord: jest.fn(),
  };
}

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

function mapRecord({
  id = 'map-1',
  ownerId,
  type = 'personal',
  members = [],
}: {
  id?: string;
  ownerId: string;
  type?: string;
  members?: Array<{
    userId: string;
    role: string;
  }>;
}): {
  id: string;
  ownerId: string;
  type: string;
  members: Array<{
    userId: string;
    role: string;
  }>;
} {
  return {
    id,
    ownerId,
    type,
    members,
  };
}
