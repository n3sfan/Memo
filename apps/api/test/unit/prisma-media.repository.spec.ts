import { PrismaService } from '../../src/infra/prisma';
import { PrismaMediaRepository } from '../../src/modules/media/repositories';

describe('PrismaMediaRepository', () => {
  it('stores media metadata and object reference without binary payload', async () => {
    const prisma = createPrismaMock();
    const repository = new PrismaMediaRepository(
      prisma as unknown as PrismaService,
    );
    const createdAt = new Date('2026-06-01T00:20:00.000Z');
    prisma.mediaFile.create.mockResolvedValue({
      id: 'media-1',
      pinId: 'pin-1',
      type: 'image',
      objectKey: 'pins/pin-1/photo.jpg',
      mime: 'image/jpeg',
      sizeBytes: 512n,
      createdAt,
    });

    await expect(
      repository.createMedia({
        pinId: 'pin-1',
        mediaType: 'image',
        objectKey: 'pins/pin-1/photo.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: 512,
      }),
    ).resolves.toEqual({
      id: 'media-1',
      pinId: 'pin-1',
      mediaType: 'image',
      objectKey: 'pins/pin-1/photo.jpg',
      mimeType: 'image/jpeg',
      sizeBytes: 512,
      createdAt: '2026-06-01T00:20:00.000Z',
    });

    expect(prisma.mediaFile.create).toHaveBeenCalledWith({
      data: {
        pinId: 'pin-1',
        type: 'image',
        objectKey: 'pins/pin-1/photo.jpg',
        mime: 'image/jpeg',
        sizeBytes: 512n,
        status: 'ready',
      },
      select: {
        id: true,
        pinId: true,
        type: true,
        objectKey: true,
        mime: true,
        sizeBytes: true,
        createdAt: true,
      },
    });
  });

  it('deletes a media metadata reference by id', async () => {
    const prisma = createPrismaMock();
    const repository = new PrismaMediaRepository(
      prisma as unknown as PrismaService,
    ) as PrismaMediaRepository & {
      deleteMediaById(mediaId: string): Promise<void>;
    };

    await expect(repository.deleteMediaById('media-1')).resolves.toBeUndefined();

    expect(prisma.mediaFile.delete).toHaveBeenCalledWith({
      where: {
        id: 'media-1',
      },
      select: {
        id: true,
      },
    });
  });
});

function createPrismaMock(): {
  mediaFile: {
    create: jest.Mock;
    findUnique: jest.Mock;
    delete: jest.Mock;
  };
} {
  return {
    mediaFile: {
      create: jest.fn(),
      findUnique: jest.fn(),
      delete: jest.fn(),
    },
  };
}
