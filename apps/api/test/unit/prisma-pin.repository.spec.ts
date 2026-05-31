import { PrismaPinRepository } from '../../src/modules/pins/repositories/prisma-pin.repository';

describe('PrismaPinRepository', () => {
  it('queries viewport pins with a PostGIS envelope', async () => {
    const prisma = createPrismaMock();
    prisma.$queryRaw.mockResolvedValue([pinRow()]);
    const repository = new PrismaPinRepository(prisma as never);

    await expect(
      repository.listPinsInBbox('3b013d64-5d61-42bd-9443-6b17e9ca98526', {
        minLng: 106.6,
        minLat: 10.7,
        maxLng: 106.8,
        maxLat: 10.8,
      }),
    ).resolves.toHaveLength(1);

    const { sql, values } = rawSqlCall(prisma.$queryRaw);
    expect(sql).toContain('ST_MakeEnvelope(');
    expect(sql).toContain('p.geom &&');
    expect(values).toEqual(
      expect.arrayContaining([106.6, 10.7, 106.8, 10.8]),
    );
  });

  it('queries timeline pages using stable NULLS LAST ordering', async () => {
    const prisma = createPrismaMock();
    prisma.$queryRaw.mockResolvedValue([pinRow()]);
    const repository = new PrismaPinRepository(prisma as never);

    await repository.listTimelinePage(
      '3b013d64-5d61-42bd-9443-6b17e9ca98526',
      {
        order: 'desc',
        limit: 51,
      },
    );

    const { sql, values } = rawSqlCall(prisma.$queryRaw);
    expect(sql).toContain('ORDER BY p.memory_date DESC NULLS LAST, p.id DESC');
    expect(sql).toContain('LIMIT');
    expect(values).toContain(51);
  });

  it('creates a pin with a PostGIS point built from lng then lat', async () => {
    const prisma = createPrismaMock();
    prisma.$queryRaw.mockResolvedValue([
      pinRow({
        lat: 10.762622,
        lng: 106.660172,
      }),
    ]);
    const repository = new PrismaPinRepository(prisma as never);

    await expect(
      repository.createPin({
        mapId: '3b013d64-5d61-42bd-9443-6b17e9ca98526',
        createdBy: '8fe3fd79-c605-4f2c-a022-849ef619f6fe',
        request: {
          title: 'Cafe memory',
          note: 'Morning coffee',
          memoryDate: '2026-06-02T00:00:00.000Z',
          lat: 10.762622,
          lng: 106.660172,
          clientId: 'local_pin_1',
        },
      }),
    ).resolves.toMatchObject({
      lat: 10.762622,
      lng: 106.660172,
    });

    const { sql, values } = rawSqlCall(prisma.$queryRaw);
    expect(sql).toContain('ST_SetSRID(ST_MakePoint(');
    expect(sql).toContain('RETURNING');
    expect(values).toEqual(
      expect.arrayContaining([106.660172, 10.762622]),
    );
    expect(values.lastIndexOf(106.660172)).toBeLessThan(
      values.lastIndexOf(10.762622),
    );
  });

  it('updates geom when both lat and lng change', async () => {
    const prisma = createPrismaMock();
    prisma.$queryRaw.mockResolvedValue([
      pinRow({
        lat: 11.9404,
        lng: 108.4583,
      }),
    ]);
    const repository = new PrismaPinRepository(prisma as never);

    await expect(
      repository.updatePin('pin-1', {
        title: 'Da Lat',
        lat: 11.9404,
        lng: 108.4583,
      }),
    ).resolves.toMatchObject({
      lat: 11.9404,
      lng: 108.4583,
    });

    const { sql, values } = rawSqlCall(prisma.$queryRaw);
    expect(sql).toContain('ST_SetSRID(ST_MakePoint(');
    expect(values.lastIndexOf(108.4583)).toBeLessThan(
      values.lastIndexOf(11.9404),
    );
  });

  it('removes linked media references when deleting a pin', async () => {
    const prisma = createPrismaMock();
    prisma.mediaFile.findMany.mockResolvedValue([
      {
        objectKey: 'users/user-1/pins/pin-1/photo.jpg',
      },
      {
        objectKey: 'users/user-1/pins/pin-1/audio.m4a',
      },
    ]);
    prisma.pin.delete.mockResolvedValue({
      id: 'pin-1',
    });
    const repository = new PrismaPinRepository(prisma as never);

    await expect(repository.deletePin('pin-1')).resolves.toEqual({
      deleted: true,
      removedMediaObjectKeys: [
        'users/user-1/pins/pin-1/photo.jpg',
        'users/user-1/pins/pin-1/audio.m4a',
      ],
    });

    expect(prisma.$transaction).toHaveBeenCalledTimes(1);
    expect(prisma.mediaFile.findMany).toHaveBeenCalledWith({
      where: { pinId: 'pin-1' },
      select: { objectKey: true },
    });
    expect(prisma.mediaFile.deleteMany).toHaveBeenCalledWith({
      where: { pinId: 'pin-1' },
    });
    expect(prisma.pin.delete).toHaveBeenCalledWith({
      where: { id: 'pin-1' },
      select: { id: true },
    });
  });
});

function createPrismaMock() {
  const prisma = {
    $queryRaw: jest.fn(),
    $transaction: jest.fn(),
    mediaFile: {
      findMany: jest.fn(),
      deleteMany: jest.fn(),
    },
    pin: {
      delete: jest.fn(),
    },
  };

  prisma.$transaction.mockImplementation(
    async (callback: (transaction: typeof prisma) => Promise<unknown>) =>
      callback(prisma),
  );

  return prisma;
}

function rawSqlCall(queryRaw: jest.Mock): {
  sql: string;
  values: unknown[];
} {
  const [strings, ...values] = queryRaw.mock.calls[0] as [
    TemplateStringsArray,
    ...unknown[],
  ];

  return {
    sql: Array.from(strings).join('?'),
    values,
  };
}

interface PinRowFixture {
  id: string;
  map_id: string;
  title: string;
  note: string | null;
  memory_date: Date | null;
  lat: number;
  lng: number;
  created_at: Date;
  updated_at: Date;
  media: unknown[];
}

function pinRow(overrides: Partial<PinRowFixture> = {}): PinRowFixture {
  return {
    id: 'pin-1',
    map_id: 'map-1',
    title: 'Cafe memory',
    note: 'Morning coffee',
    memory_date: new Date('2026-06-02T00:00:00.000Z'),
    lat: 10.762622,
    lng: 106.660172,
    created_at: new Date('2026-06-02T10:00:00.000Z'),
    updated_at: new Date('2026-06-02T10:00:00.000Z'),
    media: [],
    ...overrides,
  };
}
