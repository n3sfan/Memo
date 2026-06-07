import { INestApplication } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import request = require('supertest');

import { ApiExceptionFilter } from '../../src/common/api-exception.filter';
import { OBJECT_STORAGE, ObjectStoragePort } from '../../src/infra/r2';
import { InMemoryKeyValueStore, KEY_VALUE_STORE } from '../../src/infra/redis';
import { JwtAuthGuard } from '../../src/modules/auth/jwt-auth.guard';
import { AuthTokenService } from '../../src/modules/auth/session';
import { AuthorizationService } from '../../src/modules/authorization/authorization.service';
import {
  ACCESS_CONTROL_REPOSITORY,
  AccessControlRepository,
} from '../../src/modules/authorization/repositories';
import {
  SHARE_LINK_REPOSITORY,
  PublicShareLinkRecord,
  ShareLinkRecord,
  ShareLinkRepository,
} from '../../src/modules/share-links/repositories';
import { ShareLinksController } from '../../src/modules/share-links/share-links.controller';
import { ShareLinksService } from '../../src/modules/share-links/share-links.service';

describe('Share Links API', () => {
  let app: INestApplication;
  let jwtService: JwtService;
  let accessRepository: jest.Mocked<AccessControlRepository>;
  let shareLinkRepository: jest.Mocked<ShareLinkRepository>;
  let objectStorage: jest.Mocked<Pick<ObjectStoragePort, 'createPresignedRead'>>;

  beforeEach(async () => {
    process.env.SHARE_PUBLIC_BASE_URL = 'https://share.memo.test';
    accessRepository = createAccessRepositoryMock();
    shareLinkRepository = createShareLinkRepositoryMock();
    objectStorage = {
      createPresignedRead: jest.fn(),
    };

    const moduleRef = await Test.createTestingModule({
      controllers: [ShareLinksController],
      providers: [
        ShareLinksService,
        JwtAuthGuard,
        JwtService,
        AuthTokenService,
        AuthorizationService,
        {
          provide: KEY_VALUE_STORE,
          useValue: new InMemoryKeyValueStore(),
        },
        {
          provide: ACCESS_CONTROL_REPOSITORY,
          useValue: accessRepository,
        },
        {
          provide: SHARE_LINK_REPOSITORY,
          useValue: shareLinkRepository,
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
    delete process.env.SHARE_PUBLIC_BASE_URL;
    await app.close();
  });

  it('requires authentication before creating a share link', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/pins/pin-1/share-links')
      .set('x-request-id', 'req_share_missing_auth')
      .send({})
      .expect(401);

    expect(response.body).toEqual({
      error: 'unauthorized',
      message: 'Missing Authorization bearer token.',
      details: {},
      requestId: 'req_share_missing_auth',
    });
    expect(accessRepository.findPinAccessRecord).not.toHaveBeenCalled();
    expect(shareLinkRepository.createShareLink).not.toHaveBeenCalled();
  });

  it('creates a share link for an authorized pin', async () => {
    accessRepository.findPinAccessRecord.mockResolvedValue({
      map: mapRecord({
        ownerId: 'user-1',
      }),
    });
    shareLinkRepository.findShareLinkByToken.mockResolvedValue(null);
    shareLinkRepository.createShareLink.mockImplementation(async (input) =>
      shareLinkRecord({
        pinId: input.pinId,
        createdBy: input.createdBy,
        token: input.token,
      }),
    );

    const response = await request(app.getHttpServer())
      .post('/api/v1/pins/pin-1/share-links')
      .set('authorization', `Bearer ${accessToken('user-1')}`)
      .set('x-request-id', 'req_share_create')
      .send({})
      .expect(201);

    expect(response.body).toEqual({
      data: {
        id: 'share-1',
        pinId: 'pin-1',
        token: expect.stringMatching(/^[A-Za-z0-9_-]{12}$/),
        url: expect.stringMatching(
          /^https:\/\/share\.memo\.test\/p\/[A-Za-z0-9_-]{12}$/,
        ),
        revoked: false,
        createdAt: '2026-06-01T00:00:00.000Z',
        expiresAt: null,
      },
      requestId: 'req_share_create',
    });
  });

  it('resolves one public pin without authentication and strips private fields', async () => {
    shareLinkRepository.findPublicShareByToken.mockResolvedValue(
      publicShareRecord(),
    );
    objectStorage.createPresignedRead.mockResolvedValue({
      readUrl: 'https://r2.example/read/photo.jpg',
      expiresAt: new Date('2026-06-01T00:15:00.000Z'),
    });

    const response = await request(app.getHttpServer())
      .get('/api/v1/share/share-token')
      .set('x-request-id', 'req_share_public')
      .expect(200);

    expect(response.body).toEqual({
      data: {
        shareLinkId: 'share-1',
        pin: {
          id: 'pin-1',
          title: 'Da Lat morning',
          note: 'Coffee near the lake.',
          memoryDate: '2026-05-20T00:00:00.000Z',
          lat: 11.9404,
          lng: 108.4583,
          media: [
            {
              id: 'media-1',
              pinId: 'pin-1',
              mediaType: 'image',
              mimeType: 'image/jpeg',
              sizeBytes: 512,
              createdAt: '2026-06-01T00:00:00.000Z',
              url: 'https://r2.example/read/photo.jpg',
            },
          ],
          createdAt: '2026-06-01T00:00:00.000Z',
          updatedAt: '2026-06-01T00:05:00.000Z',
        },
      },
      requestId: 'req_share_public',
    });
    expect(JSON.stringify(response.body)).not.toContain('mapId');
    expect(JSON.stringify(response.body)).not.toContain('clientId');
    expect(JSON.stringify(response.body)).not.toContain('objectKey');
    expect(JSON.stringify(response.body)).not.toContain('owner');
    expect(JSON.stringify(response.body)).not.toContain('members');
  });

  it('returns link_revoked for revoked public tokens', async () => {
    shareLinkRepository.findPublicShareByToken.mockResolvedValue(
      publicShareRecord({
        revoked: true,
      }),
    );

    const response = await request(app.getHttpServer())
      .get('/api/v1/share/revoked-token')
      .set('x-request-id', 'req_share_revoked')
      .expect(410);

    expect(response.body).toEqual({
      error: 'link_revoked',
      message: 'Share link has been revoked.',
      details: {},
      requestId: 'req_share_revoked',
    });
  });

  it('revokes a creator-owned link idempotently', async () => {
    shareLinkRepository.findShareLinkById.mockResolvedValue(
      shareLinkRecord({
        id: 'share-1',
        createdBy: 'user-1',
      }),
    );
    shareLinkRepository.revokeShareLink.mockResolvedValue(
      shareLinkRecord({
        id: 'share-1',
        createdBy: 'user-1',
        revoked: true,
      }),
    );

    const response = await request(app.getHttpServer())
      .delete('/api/v1/share-links/share-1')
      .set('authorization', `Bearer ${accessToken('user-1')}`)
      .set('x-request-id', 'req_share_revoke')
      .expect(200);

    expect(response.body).toEqual({
      data: {
        revoked: true,
      },
      requestId: 'req_share_revoke',
    });
    expect(shareLinkRepository.revokeShareLink).toHaveBeenCalledWith('share-1');
  });

  function accessToken(userId: string): string {
    return jwtService.sign(
      {
        sub: userId,
        jti: `${userId}-access-token`,
        typ: 'access',
        email: `${userId}@example.test`,
        displayName: 'Memo User',
        provider: 'google',
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

function createShareLinkRepositoryMock(): jest.Mocked<ShareLinkRepository> {
  return {
    createShareLink: jest.fn(),
    findShareLinkByToken: jest.fn(),
    findShareLinkById: jest.fn(),
    revokeShareLink: jest.fn(),
    findPublicShareByToken: jest.fn(),
  };
}

function shareLinkRecord(
  overrides: Partial<ShareLinkRecord> = {},
): ShareLinkRecord {
  return {
    id: 'share-1',
    pinId: 'pin-1',
    createdBy: 'user-1',
    token: 'share-token',
    revoked: false,
    createdAt: '2026-06-01T00:00:00.000Z',
    ...overrides,
  };
}

function publicShareRecord(
  overrides: Partial<PublicShareLinkRecord> = {},
): PublicShareLinkRecord {
  return {
    ...shareLinkRecord(),
    pin: {
      id: 'pin-1',
      mapId: 'map-private-1',
      title: 'Da Lat morning',
      note: 'Coffee near the lake.',
      memoryDate: '2026-05-20T00:00:00.000Z',
      lat: 11.9404,
      lng: 108.4583,
      media: [
        {
          id: 'media-1',
          pinId: 'pin-1',
          mediaType: 'image',
          objectKey: 'pins/pin-1/photo.jpg',
          mimeType: 'image/jpeg',
          sizeBytes: 512,
          createdAt: '2026-06-01T00:00:00.000Z',
        },
      ],
      createdAt: '2026-06-01T00:00:00.000Z',
      updatedAt: '2026-06-01T00:05:00.000Z',
      clientId: null,
    },
    ...overrides,
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
