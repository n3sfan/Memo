import { HttpStatus } from '@nestjs/common';

import { ApiException } from '../../src/common/api-error';
import { PrismaService } from '../../src/infra/prisma';
import { ObjectStoragePort } from '../../src/infra/r2';
import { CurrentUser } from '../../src/modules/auth/current-user';
import { AuthorizationService } from '../../src/modules/authorization/authorization.service';
import { PrismaAccessControlRepository } from '../../src/modules/authorization/repositories';
import { PrismaPinRepository } from '../../src/modules/pins/repositories';
import { PinsService } from '../../src/modules/pins/pins.service';

const describeDb =
  process.env.RUN_DB_INTEGRATION_TESTS === 'true' ? describe : describe.skip;

describeDb('Pins PostGIS DB integration', () => {
  let prisma: PrismaService;
  let service: PinsService;
  let objectStorage: jest.Mocked<Pick<ObjectStoragePort, 'deleteObject'>>;

  const owner: CurrentUser = {
    id: '11111111-1111-4111-8111-111111111111',
    email: 'owner@example.com',
  };
  const stranger: CurrentUser = {
    id: '22222222-2222-4222-8222-222222222222',
    email: 'stranger@example.com',
  };
  const mapId = '33333333-3333-4333-8333-333333333333';

  beforeAll(async () => {
    prisma = new PrismaService();
    await prisma.$connect();

    const pinRepository = new PrismaPinRepository(prisma);
    const authorization = new AuthorizationService(
      new PrismaAccessControlRepository(prisma),
    );
    objectStorage = {
      deleteObject: jest.fn(),
    };
    service = new PinsService(
      pinRepository,
      authorization,
      objectStorage as unknown as ObjectStoragePort,
    );
  });

  beforeEach(async () => {
    await resetDatabase(prisma);
    await seedMap(prisma, {
      mapId,
      ownerId: owner.id,
      strangerId: stranger.id,
    });
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await prisma.$disconnect();
  });

  it('creates and updates a pin with PostGIS geometry coordinates', async () => {
    const created = await service.createPin(owner, mapId, {
      title: 'Saigon cafe',
      note: 'Morning memory',
      memoryDate: '2026-06-02T00:00:00.000Z',
      lat: 10.762622,
      lng: 106.660172,
      clientId: 'local_pin_db_1',
    });

    expect(created).toMatchObject({
      mapId,
      title: 'Saigon cafe',
      note: 'Morning memory',
      memoryDate: '2026-06-02T00:00:00.000Z',
      lat: 10.762622,
      lng: 106.660172,
      media: [],
    });

    await expectPoint(prisma, created.id, {
      lat: 10.762622,
      lng: 106.660172,
    });

    const updated = await service.updatePin(owner, created.id, {
      title: 'Da Lat memory',
      lat: 11.9404,
      lng: 108.4583,
    });

    expect(updated).toMatchObject({
      id: created.id,
      title: 'Da Lat memory',
      lat: 11.9404,
      lng: 108.4583,
    });
    await expectPoint(prisma, created.id, {
      lat: 11.9404,
      lng: 108.4583,
    });
  });

  it('returns 422 for invalid coordinates before writing to the database', async () => {
    await expect(
      service.createPin(owner, mapId, {
        title: 'Invalid',
        lat: 91,
        lng: 106.660172,
      }),
    ).rejects.toMatchApiException(
      HttpStatus.UNPROCESSABLE_ENTITY,
      'validation_error',
    );

    await expect(countRows(prisma, 'pins')).resolves.toBe(0);
  });

  it('returns 403 for edit and delete attempts without map permission', async () => {
    const created = await service.createPin(owner, mapId, {
      title: 'Private pin',
      lat: 10.762622,
      lng: 106.660172,
    });

    await expect(
      service.updatePin(stranger, created.id, {
        title: 'Not allowed',
      }),
    ).rejects.toMatchApiException(HttpStatus.FORBIDDEN, 'forbidden');

    await expect(service.deletePin(stranger, created.id)).rejects.toMatchApiException(
      HttpStatus.FORBIDDEN,
      'forbidden',
    );
  });

  it('deletes linked media references when deleting a pin', async () => {
    const created = await service.createPin(owner, mapId, {
      title: 'Pin with media',
      lat: 10.762622,
      lng: 106.660172,
    });

    await prisma.$executeRaw`
      INSERT INTO media_files (
        id,
        pin_id,
        type,
        object_key,
        mime,
        size_bytes,
        status
      )
      VALUES (
        '44444444-4444-4444-8444-444444444444'::uuid,
        ${created.id}::uuid,
        'image',
        'users/owner/pins/photo.jpg',
        'image/jpeg',
        12345,
        'ready'
      )
    `;

    await expect(countRows(prisma, 'media_files')).resolves.toBe(1);

    await expect(service.deletePin(owner, created.id)).resolves.toEqual({
      deleted: true,
    });

    await expect(countRows(prisma, 'pins')).resolves.toBe(0);
    await expect(countRows(prisma, 'media_files')).resolves.toBe(0);
    expect(objectStorage.deleteObject).toHaveBeenCalledWith(
      'users/owner/pins/photo.jpg',
    );
  });
});

expect.extend({
  toMatchApiException(
    received: unknown,
    status: HttpStatus,
    apiErrorCode: string,
  ) {
    const pass =
      received instanceof ApiException &&
      received.getStatus() === status &&
      received.apiErrorCode === apiErrorCode;

    return {
      pass,
      message: () =>
        `expected ${String(received)} to be ApiException(${status}, ${apiErrorCode})`,
    };
  },
});

declare global {
  namespace jest {
    interface Matchers<R> {
      toMatchApiException(status: HttpStatus, apiErrorCode: string): R;
    }
  }
}

async function resetDatabase(prisma: PrismaService): Promise<void> {
  await prisma.$executeRaw`
    TRUNCATE TABLE
      share_links,
      invitations,
      media_files,
      pins,
      map_members,
      maps,
      users
    RESTART IDENTITY CASCADE
  `;
}

async function seedMap(
  prisma: PrismaService,
  input: {
    mapId: string;
    ownerId: string;
    strangerId: string;
  },
): Promise<void> {
  await prisma.$executeRaw`
    INSERT INTO users (id, provider, provider_user_id, email, display_name)
    VALUES
      (${input.ownerId}::uuid, 'google', 'owner-provider-id', 'owner@example.com', 'Owner'),
      (${input.strangerId}::uuid, 'google', 'stranger-provider-id', 'stranger@example.com', 'Stranger')
  `;

  await prisma.$executeRaw`
    INSERT INTO maps (id, type, owner_id)
    VALUES (${input.mapId}::uuid, 'personal', ${input.ownerId}::uuid)
  `;

  await prisma.$executeRaw`
    INSERT INTO map_members (map_id, user_id, role)
    VALUES (${input.mapId}::uuid, ${input.ownerId}::uuid, 'owner')
  `;
}

async function expectPoint(
  prisma: PrismaService,
  pinId: string,
  expected: {
    lat: number;
    lng: number;
  },
): Promise<void> {
  const rows = await prisma.$queryRaw<
    Array<{
      x: number;
      y: number;
      srid: number;
    }>
  >`
    SELECT ST_X(geom) AS x, ST_Y(geom) AS y, ST_SRID(geom) AS srid
    FROM pins
    WHERE id = ${pinId}::uuid
  `;

  expect(rows).toHaveLength(1);
  expect(Number(rows[0].x)).toBeCloseTo(expected.lng, 6);
  expect(Number(rows[0].y)).toBeCloseTo(expected.lat, 6);
  expect(Number(rows[0].srid)).toBe(4326);
}

async function countRows(
  prisma: PrismaService,
  table: 'pins' | 'media_files',
): Promise<number> {
  const rows = await prisma.$queryRawUnsafe<Array<{ count: bigint }>>(
    `SELECT COUNT(*)::bigint AS count FROM ${table}`,
  );

  return Number(rows[0].count);
}
