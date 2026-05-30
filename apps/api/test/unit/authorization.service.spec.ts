import { HttpStatus } from '@nestjs/common';

import { ApiException } from '../../src/common/api-error';
import { PrismaService } from '../../src/infra/prisma';
import { AuthorizationService } from '../../src/modules/authorization/authorization.service';

describe('AuthorizationService', () => {
  let prisma: MockPrismaService;
  let service: AuthorizationService;

  beforeEach(() => {
    prisma = createMockPrisma();
    service = new AuthorizationService(prisma as unknown as PrismaService);
  });

  it('allows a map owner to read and write the map', async () => {
    prisma.memoryMap.findUnique.mockResolvedValue(
      mapRecord({
        ownerId: 'user-1',
      }),
    );

    await expect(service.canReadMap('user-1', 'map-1')).resolves.toBe(true);
    await expect(service.canWriteMap('user-1', 'map-1')).resolves.toBe(true);
  });

  it('allows a duo member to read a map and create pins without map ownership', async () => {
    prisma.memoryMap.findUnique.mockResolvedValue(
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
    prisma.memoryMap.findUnique.mockResolvedValue(
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
    prisma.pin.findUnique.mockResolvedValue({
      map: mapRecord({
        ownerId: 'user-1',
      }),
    });

    await expect(service.canReadPin('user-1', 'pin-1')).resolves.toBe(true);
    await expect(service.canWritePin('user-1', 'pin-1')).resolves.toBe(true);
  });

  it('hides missing or inaccessible pins as not_found', async () => {
    prisma.pin.findUnique.mockResolvedValue(null);

    await expectApiException(
      service.assertCanReadPin('user-1', 'pin-1'),
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
    prisma.shareLink.findUnique.mockResolvedValue({
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

interface MockPrismaService {
  memoryMap: {
    findUnique: jest.Mock;
  };
  pin: {
    findUnique: jest.Mock;
  };
  invitation: {
    findUnique: jest.Mock;
  };
  shareLink: {
    findUnique: jest.Mock;
  };
}

function createMockPrisma(): MockPrismaService {
  return {
    memoryMap: {
      findUnique: jest.fn(),
    },
    pin: {
      findUnique: jest.fn(),
    },
    invitation: {
      findUnique: jest.fn(),
    },
    shareLink: {
      findUnique: jest.fn(),
    },
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
