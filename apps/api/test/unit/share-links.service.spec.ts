import { HttpStatus } from '@nestjs/common';

import { ApiException } from '../../src/common/api-error';
import { ObjectStoragePort } from '../../src/infra/r2';
import { CurrentUser } from '../../src/modules/auth/current-user';
import { AuthorizationService } from '../../src/modules/authorization/authorization.service';
import { ShareLinksService } from '../../src/modules/share-links/share-links.service';
import {
  ShareLinkRepository,
  ShareLinkRecord,
  PublicShareLinkRecord,
  ShareLinkTokenConflictError,
} from '../../src/modules/share-links/repositories';

describe('ShareLinksService', () => {
  const user: CurrentUser = {
    id: 'user-1',
    email: 'user@example.test',
    displayName: 'Memo User',
    provider: 'google',
  };

  let repository: jest.Mocked<ShareLinkRepository>;
  let authorization: jest.Mocked<Pick<AuthorizationService, 'assertCanReadPin'>>;
  let objectStorage: jest.Mocked<Pick<ObjectStoragePort, 'createPresignedRead'>>;
  let service: ShareLinksService;

  beforeEach(() => {
    process.env.SHARE_PUBLIC_BASE_URL = 'https://share.memo.test/app';
    repository = createRepositoryMock();
    authorization = {
      assertCanReadPin: jest.fn(),
    };
    objectStorage = {
      createPresignedRead: jest.fn(),
    };
    service = new ShareLinksService(
      repository,
      authorization as unknown as AuthorizationService,
      objectStorage as unknown as ObjectStoragePort,
    );
  });

  afterEach(() => {
    delete process.env.SHARE_PUBLIC_BASE_URL;
  });

  it('creates a 12 character share link after pin read authorization', async () => {
    repository.findShareLinkByToken.mockResolvedValue(null);
    repository.createShareLink.mockImplementation(async (input) =>
      shareLinkRecord({
        pinId: input.pinId,
        createdBy: input.createdBy,
        token: input.token,
      }),
    );

    const response = await service.createShareLink(user, 'pin-1', {});

    expect(authorization.assertCanReadPin).toHaveBeenCalledWith('user-1', 'pin-1');
    expect(repository.createShareLink).toHaveBeenCalledWith({
      pinId: 'pin-1',
      createdBy: 'user-1',
      token: expect.stringMatching(/^[A-Za-z0-9_-]{12}$/),
    });
    expect(response).toEqual({
      id: 'share-1',
      pinId: 'pin-1',
      token: expect.stringMatching(/^[A-Za-z0-9_-]{12}$/),
      url: expect.stringMatching(
        /^https:\/\/share\.memo\.test\/app\/p\/[A-Za-z0-9_-]{12}$/,
      ),
      revoked: false,
      createdAt: '2026-06-01T00:00:00.000Z',
      expiresAt: null,
    });
  });

  it('retries when a generated share token already exists', async () => {
    repository.findShareLinkByToken
      .mockResolvedValueOnce(shareLinkRecord({ token: 'existing-one' }))
      .mockResolvedValueOnce(null);
    repository.createShareLink.mockImplementation(async (input) =>
      shareLinkRecord({
        pinId: input.pinId,
        createdBy: input.createdBy,
        token: input.token,
      }),
    );

    const response = await service.createShareLink(user, 'pin-1', {});

    expect(repository.findShareLinkByToken).toHaveBeenCalledTimes(2);
    const firstToken = repository.findShareLinkByToken.mock.calls[0][0];
    const secondToken = repository.findShareLinkByToken.mock.calls[1][0];
    expect(firstToken).toMatch(/^[A-Za-z0-9_-]{12}$/);
    expect(secondToken).toMatch(/^[A-Za-z0-9_-]{12}$/);
    expect(repository.createShareLink).toHaveBeenCalledWith({
      pinId: 'pin-1',
      createdBy: 'user-1',
      token: secondToken,
    });
    expect(response.token).toBe(secondToken);
  });

  it('retries when another request inserts the generated token first', async () => {
    repository.findShareLinkByToken.mockResolvedValue(null);
    repository.createShareLink
      .mockRejectedValueOnce(new ShareLinkTokenConflictError('race-token'))
      .mockImplementationOnce(async (input) =>
        shareLinkRecord({
          pinId: input.pinId,
          createdBy: input.createdBy,
          token: input.token,
        }),
      );

    const response = await service.createShareLink(user, 'pin-1', {});

    expect(repository.createShareLink).toHaveBeenCalledTimes(2);
    const firstToken = repository.createShareLink.mock.calls[0][0].token;
    const secondToken = repository.createShareLink.mock.calls[1][0].token;
    expect(firstToken).toMatch(/^[A-Za-z0-9_-]{12}$/);
    expect(secondToken).toMatch(/^[A-Za-z0-9_-]{12}$/);
    expect(response.token).toBe(secondToken);
  });

  it('rejects unsupported share link expiration before authorization', async () => {
    await expectApiException(
      service.createShareLink(user, 'pin-1', {
        expiresAt: '2026-07-01T00:00:00.000Z',
      }),
      HttpStatus.UNPROCESSABLE_ENTITY,
      'validation_error',
    );

    expect(authorization.assertCanReadPin).not.toHaveBeenCalled();
    expect(repository.createShareLink).not.toHaveBeenCalled();
  });

  it('revoke is idempotent for the creator', async () => {
    repository.findShareLinkById.mockResolvedValue(
      shareLinkRecord({
        id: 'share-1',
        createdBy: 'user-1',
        revoked: true,
      }),
    );

    await expect(service.revokeShareLink(user, 'share-1')).resolves.toEqual({
      revoked: true,
    });
    expect(repository.revokeShareLink).not.toHaveBeenCalled();
  });

  it('rejects revoking another user share link', async () => {
    repository.findShareLinkById.mockResolvedValue(
      shareLinkRecord({
        id: 'share-1',
        createdBy: 'owner-1',
      }),
    );

    await expectApiException(
      service.revokeShareLink(user, 'share-1'),
      HttpStatus.FORBIDDEN,
      'forbidden',
    );
    expect(repository.revokeShareLink).not.toHaveBeenCalled();
  });

  it('returns not_found for unknown public share tokens', async () => {
    repository.findPublicShareByToken.mockResolvedValue(null);

    await expectApiException(
      service.resolvePublicPin('missing-token'),
      HttpStatus.NOT_FOUND,
      'not_found',
    );
  });

  it('returns link_revoked for revoked public share tokens', async () => {
    repository.findPublicShareByToken.mockResolvedValue(
      publicShareRecord({
        revoked: true,
      }),
    );

    await expectApiException(
      service.resolvePublicPin('revoked-token'),
      HttpStatus.GONE,
      'link_revoked',
    );
  });

  it('maps a valid public share to one sanitized pin with presigned media urls', async () => {
    repository.findPublicShareByToken.mockResolvedValue(publicShareRecord());
    objectStorage.createPresignedRead.mockResolvedValue({
      readUrl: 'https://r2.example/read/photo.jpg',
      expiresAt: new Date('2026-06-01T00:15:00.000Z'),
    });

    const response = await service.resolvePublicPin('share-token');

    expect(objectStorage.createPresignedRead).toHaveBeenCalledWith(
      'pins/pin-1/photo.jpg',
    );
    expect(response).toEqual({
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
    });
    expect(JSON.stringify(response)).not.toContain('mapId');
    expect(JSON.stringify(response)).not.toContain('objectKey');
    expect(JSON.stringify(response)).not.toContain('owner');
    expect(JSON.stringify(response)).not.toContain('members');
  });
});

function createRepositoryMock(): jest.Mocked<ShareLinkRepository> {
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
