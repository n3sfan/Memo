import {
  PrismaShareLinkRepository,
  ShareLinkTokenConflictError,
} from '../../src/modules/share-links/repositories';

describe('PrismaShareLinkRepository', () => {
  it('maps token unique constraint races to share token conflict errors', async () => {
    const prisma = createPrismaMock();
    prisma.shareLink.create.mockRejectedValue({
      code: 'P2002',
      meta: {
        target: ['token'],
      },
    });
    const repository = new PrismaShareLinkRepository(prisma as never);

    await expect(
      repository.createShareLink({
        pinId: 'pin-1',
        createdBy: 'user-1',
        token: 'abc123def456',
      }),
    ).rejects.toBeInstanceOf(ShareLinkTokenConflictError);
  });
});

function createPrismaMock(): {
  shareLink: {
    create: jest.Mock;
  };
} {
  return {
    shareLink: {
      create: jest.fn(),
    },
  };
}
