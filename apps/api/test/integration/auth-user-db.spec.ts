import { PrismaService } from '../../src/infra/prisma';
import { PrismaAuthUserRepository } from '../../src/modules/auth/repositories';

const describeDb =
  process.env.RUN_DB_INTEGRATION_TESTS === 'true' ? describe : describe.skip;

describeDb('PrismaAuthUserRepository DB integration', () => {
  let prisma: PrismaService;
  let repository: PrismaAuthUserRepository;

  const providerUserId = 'google-user-auth-db-spec';

  beforeAll(async () => {
    prisma = new PrismaService();
    await prisma.$connect();
    repository = new PrismaAuthUserRepository(prisma);
  });

  beforeEach(async () => {
    await deleteTestUser(prisma, providerUserId);
  });

  afterEach(async () => {
    await deleteTestUser(prisma, providerUserId);
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  it('creates a Google OAuth user with a default personal map and owner membership', async () => {
    const result = await repository.upsertOAuthUser({
      provider: 'google',
      providerUserId,
      email: 'auth-db-spec@example.com',
      displayName: 'Auth DB Spec',
      avatarUrl: null,
    });

    expect(result).toMatchObject({
      created: true,
      user: {
        provider: 'google',
        providerUserId,
        email: 'auth-db-spec@example.com',
        displayName: 'Auth DB Spec',
        avatarUrl: null,
      },
    });

    const maps = await prisma.memoryMap.findMany({
      where: { ownerId: result.user.id },
      include: { members: true },
    });

    expect(maps).toHaveLength(1);
    expect(maps[0]).toMatchObject({
      type: 'personal',
      ownerId: result.user.id,
      members: [
        {
          userId: result.user.id,
          role: 'owner',
        },
      ],
    });
  });
});

async function deleteTestUser(
  prisma: PrismaService,
  providerUserId: string,
): Promise<void> {
  await prisma.user.deleteMany({
    where: {
      provider: 'google',
      providerUserId,
    },
  });
}
