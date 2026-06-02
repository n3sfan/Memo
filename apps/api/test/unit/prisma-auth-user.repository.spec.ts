import { PrismaService } from '../../src/infra/prisma';
import { PrismaAuthUserRepository } from '../../src/modules/auth/repositories';

describe('PrismaAuthUserRepository', () => {
  it('creates a user with a default personal map and owner membership', async () => {
    const prisma = createPrismaMock();
    prisma.user.findUnique.mockResolvedValue(null);
    prisma.user.create.mockResolvedValue(userRecord());
    const repository = new PrismaAuthUserRepository(
      prisma as unknown as PrismaService,
    );

    await expect(
      repository.upsertOAuthUser({
        provider: 'google',
        providerUserId: 'google-user-1',
        email: 'memo@example.com',
        displayName: 'Memo User',
        avatarUrl: null,
      }),
    ).resolves.toEqual({
      created: true,
      user: {
        id: 'user-1',
        provider: 'google',
        providerUserId: 'google-user-1',
        email: 'memo@example.com',
        displayName: 'Memo User',
        avatarUrl: null,
      },
    });

    expect(prisma.$transaction).toHaveBeenCalledTimes(1);
    expect(prisma.user.create).toHaveBeenCalledWith({
      data: {
        provider: 'google',
        providerUserId: 'google-user-1',
        email: 'memo@example.com',
        displayName: 'Memo User',
      },
      select: userSelect(),
    });
    expect(prisma.memoryMap.create).toHaveBeenCalledWith({
      data: {
        type: 'personal',
        ownerId: 'user-1',
        members: {
          create: {
            userId: 'user-1',
            role: 'owner',
          },
        },
      },
      select: { id: true },
    });
  });

  it('updates an existing OAuth user without creating another map', async () => {
    const prisma = createPrismaMock();
    prisma.user.findUnique.mockResolvedValue(userRecord());
    prisma.user.update.mockResolvedValue(
      userRecord({ email: 'updated@example.com' }),
    );
    const repository = new PrismaAuthUserRepository(
      prisma as unknown as PrismaService,
    );

    await expect(
      repository.upsertOAuthUser({
        provider: 'google',
        providerUserId: 'google-user-1',
        email: 'updated@example.com',
        displayName: 'Updated User',
        avatarUrl: null,
      }),
    ).resolves.toEqual({
      created: false,
      user: {
        id: 'user-1',
        provider: 'google',
        providerUserId: 'google-user-1',
        email: 'updated@example.com',
        displayName: 'Memo User',
        avatarUrl: null,
      },
    });

    expect(prisma.memoryMap.create).not.toHaveBeenCalled();
    expect(prisma.user.update).toHaveBeenCalledWith({
      where: { id: 'user-1' },
      data: {
        email: 'updated@example.com',
        displayName: 'Updated User',
        deletedAt: null,
      },
      select: userSelect(),
    });
  });
});

function createPrismaMock() {
  const prisma = {
    $transaction: jest.fn(),
    user: {
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    memoryMap: {
      create: jest.fn(),
    },
  };

  prisma.$transaction.mockImplementation(
    async (callback: (transaction: typeof prisma) => Promise<unknown>) =>
      callback(prisma),
  );

  return prisma;
}

function userRecord(overrides: Partial<ReturnType<typeof baseUserRecord>> = {}) {
  return {
    ...baseUserRecord(),
    ...overrides,
  };
}

function baseUserRecord() {
  return {
    id: 'user-1',
    provider: 'google',
    providerUserId: 'google-user-1',
    email: 'memo@example.com',
    displayName: 'Memo User',
  };
}

function userSelect() {
  return {
    id: true,
    provider: true,
    providerUserId: true,
    email: true,
    displayName: true,
  };
}
