import { Injectable } from '@nestjs/common';

import { PrismaService } from '../../../infra/prisma';
import { MediaType } from '../dto/media.dto';
import {
  CreateMediaInput,
  MediaRecord,
  MediaRepository,
} from './media.repository';

@Injectable()
export class PrismaMediaRepository implements MediaRepository {
  constructor(private readonly prisma: PrismaService) {}

  async createMedia(input: CreateMediaInput): Promise<MediaRecord> {
    const media = await this.prisma.mediaFile.create({
      data: {
        pinId: input.pinId,
        type: input.mediaType,
        objectKey: input.objectKey,
        mime: input.mimeType,
        sizeBytes: BigInt(input.sizeBytes),
        status: 'ready',
      },
      select: this.mediaSelect(),
    });

    return this.toMediaRecord(media);
  }

  async findMediaById(mediaId: string): Promise<MediaRecord | null> {
    const media = await this.prisma.mediaFile.findUnique({
      where: {
        id: mediaId,
      },
      select: this.mediaSelect(),
    });

    return media ? this.toMediaRecord(media) : null;
  }

  private mediaSelect(): {
    id: true;
    pinId: true;
    type: true;
    objectKey: true;
    mime: true;
    sizeBytes: true;
    createdAt: true;
  } {
    return {
      id: true,
      pinId: true,
      type: true,
      objectKey: true,
      mime: true,
      sizeBytes: true,
      createdAt: true,
    };
  }

  private toMediaRecord(media: {
    id: string;
    pinId: string;
    type: string;
    objectKey: string;
    mime: string | null;
    sizeBytes: bigint | null;
    createdAt: Date;
  }): MediaRecord {
    return {
      id: media.id,
      pinId: media.pinId,
      mediaType: media.type as MediaType,
      objectKey: media.objectKey,
      mimeType: media.mime ?? '',
      sizeBytes: Number(media.sizeBytes ?? 0n),
      createdAt: media.createdAt.toISOString(),
    };
  }
}
