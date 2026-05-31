import { HttpStatus } from '@nestjs/common';

import { ApiException } from '../../src/common/api-error';
import { AuthorizationService } from '../../src/modules/authorization/authorization.service';
import { AccessControlRepository } from '../../src/modules/authorization/repositories';

describe('AuthorizationService', () => {
  let accessRepository: jest.Mocked<AccessControlRepository>;
  let service: AuthorizationService;

  beforeEach(() => {
    accessRepository = createMockAccessRepository();
    service = new AuthorizationService(accessRepository);
  });

  it('allows a map owner to read and write the map', async () => {
    accessRepository.findMapAccessRecord.mockResolvedValue(
      mapRecord({
        ownerId: 'user-1',
      }),
    );

    await expect(service.canReadMap('user-1', 'map-1')).resolves.toBe(true);
    await expect(service.canWriteMap('user-1', 'map-1')).resolves.toBe(true);
  });

  it('allows a duo member to read a map and create pins without map ownership', async () => {
    accessRepository.findMapAccessRecord.mockResolvedValue(
      mapRecord({
        type: 'duo',
        ownerId: 'owner-1',
        members: [
          {
            userId: 'user-1',
            role: 'member',
          },
        ],
      }),
    );

    await expect(service.canReadMap('user-1', 'map-1')).resolves.toBe(true);
    await expect(service.canWriteMap('user-1', 'map-1')).resolves.toBe(false);
    await expect(service.canCreatePin('user-1', 'map-1')).resolves.toBe(true);
  });

  it('throws forbidden when a map exists but the user is not a member', async () => {
    accessRepository.findMapAccessRecord.mockResolvedValue(
      mapRecord({
        ownerId: 'owner-1',
      }),
    );

    await expectApiException(
      service.assertCanReadMap('user-1', 'map-1'),
      HttpStatus.FORBIDDEN,
      'forbidden',
    );
  });

  it('checks pin access through the parent map', async () => {
    accessRepository.findPinAccessRecord.mockResolvedValue({
      map: mapRecord({
        ownerId: 'user-1',
      }),
    });

    await expect(service.canReadPin('user-1', 'pin-1')).resolves.toBe(true);
    await expect(service.canWritePin('user-1', 'pin-1')).resolves.toBe(true);
  });

  it('hides missing or inaccessible pins as not_found', async () => {
    accessRepository.findPinAccessRecord.mockResolvedValue(null);

    await expectApiException(
      service.assertCanReadPin('user-1', 'pin-1'),
      HttpStatus.NOT_FOUND,
      'not_found',
    );
  });

  it('returns forbidden when modifying an existing pin without map access', async () => {
    accessRepository.findPinAccessRecord.mockResolvedValue({
      map: mapRecord({
        ownerId: 'owner-1',
      }),
    });

    await expectApiException(
      service.assertCanModifyPin('user-1', 'pin-1'),
      HttpStatus.FORBIDDEN,
      'forbidden',
    );
  });

  it('keeps media upload access hidden when the pin map is inaccessible', async () => {
    accessRepository.findPinAccessRecord.mockResolvedValue({
      map: mapRecord({
        ownerId: 'owner-1',
      }),
    });

    await expectApiException(
      service.assertCanUploadMedia('user-1', 'pin-1'),
      HttpStatus.NOT_FOUND,
      'not_found',
    );
  });

  it('rejects access to another user account', () => {
    expect(() => service.assertCanAccessAccount('user-1', 'user-2')).toThrow(
      ApiException,
    );
  });

  it('resolves only active share links', async () => {
    accessRepository.findShareLinkAccessRecord.mockResolvedValue({
      revoked: false,
    });

    await expect(service.resolveShareLinkAccess('share-token')).resolves.toEqual(
      {
        allowed: true,
        role: 'share_link',
      },
    );
  });
});

function createMockAccessRepository(): jest.Mocked<AccessControlRepository> {
  return {
    findMapAccessRecord: jest.fn(),
    findPinAccessRecord: jest.fn(),
    findInvitationAccessRecord: jest.fn(),
    findShareLinkAccessRecord: jest.fn(),
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
