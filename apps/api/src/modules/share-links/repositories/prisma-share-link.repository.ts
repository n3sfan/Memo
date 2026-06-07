import { Injectable } from '@nestjs/common';

import { PrismaService } from '../../../infra/prisma';
import {
  PinDto,
  PinMediaDto,
} from '../../pins/dto/pins.dto';
import {
  CreateShareLinkInput,
  PublicShareLinkRecord,
  ShareLinkRecord,
  ShareLinkRepository,
  ShareLinkTokenConflictError,
} from './share-link.repository';

type ShareLinkPrismaRecord = {
  id: string;
  pinId: string;
  createdBy: string;
  token: string;
  revoked: boolean;
  createdAt: Date;
};

type PublicShareLinkPrismaRecord = ShareLinkPrismaRecord & {
  pin: {
    id: string;
    mapId: string;
    title: string | null;
    note: string | null;
    memoryDate: Date | null;
    lat: number;
    lng: number;
    createdAt: Date;
    updatedAt: Date;
    media: Array<{
      id: string;
      pinId: string;
      type: string;
      objectKey: string;
      mime: string | null;
      sizeBytes: bigint | number | null;
      createdAt: Date;
    }>;
  };
};

@Injectable()
export class PrismaShareLinkRepository implements ShareLinkRepository {
  constructor(private readonly prisma: PrismaService) {}

  async createShareLink(
    input: CreateShareLinkInput,
  ): Promise<ShareLinkRecord> {
    try {
      const link = await this.prisma.shareLink.create({
        data: {
          pinId: input.pinId,
          createdBy: input.createdBy,
          token: input.token,
        },
        select: this.shareLinkSelect(),
      });

      return this.toShareLinkRecord(link);
    } catch (error) {
      if (this.isTokenUniqueViolation(error)) {
        throw new ShareLinkTokenConflictError(input.token);
      }

      throw error;
    }
  }

  async findShareLinkById(
    shareLinkId: string,
  ): Promise<ShareLinkRecord | null> {
    const link = await this.prisma.shareLink.findUnique({
      where: {
        id: shareLinkId,
      },
      select: this.shareLinkSelect(),
    });

    return link ? this.toShareLinkRecord(link) : null;
  }

  async findShareLinkByToken(
    token: string,
  ): Promise<ShareLinkRecord | null> {
    const link = await this.prisma.shareLink.findUnique({
      where: {
        token,
      },
      select: this.shareLinkSelect(),
    });

    return link ? this.toShareLinkRecord(link) : null;
  }

  async revokeShareLink(
    shareLinkId: string,
  ): Promise<ShareLinkRecord | null> {
    const link = await this.prisma.shareLink.update({
      where: {
        id: shareLinkId,
      },
      data: {
        revoked: true,
      },
      select: this.shareLinkSelect(),
    });

    return this.toShareLinkRecord(link);
  }

  async findPublicShareByToken(
    token: string,
  ): Promise<PublicShareLinkRecord | null> {
    const link = await this.prisma.shareLink.findUnique({
      where: {
        token,
      },
      select: {
        ...this.shareLinkSelect(),
        pin: {
          select: this.pinSelect(),
        },
      },
    });

    return link ? this.toPublicShareLinkRecord(link) : null;
  }

  private shareLinkSelect(): {
    id: true;
    pinId: true;
    createdBy: true;
    token: true;
    revoked: true;
    createdAt: true;
  } {
    return {
      id: true,
      pinId: true,
      createdBy: true,
      token: true,
      revoked: true,
      createdAt: true,
    };
  }

  private pinSelect(): {
    id: true;
    mapId: true;
    title: true;
    note: true;
    memoryDate: true;
    lat: true;
    lng: true;
    createdAt: true;
    updatedAt: true;
    media: {
      orderBy: {
        createdAt: 'asc';
      };
      select: {
        id: true;
        pinId: true;
        type: true;
        objectKey: true;
        mime: true;
        sizeBytes: true;
        createdAt: true;
      };
    };
  } {
    return {
      id: true,
      mapId: true,
      title: true,
      note: true,
      memoryDate: true,
      lat: true,
      lng: true,
      createdAt: true,
      updatedAt: true,
      media: {
        orderBy: {
          createdAt: 'asc',
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
      },
    };
  }

  private toPublicShareLinkRecord(
    link: PublicShareLinkPrismaRecord,
  ): PublicShareLinkRecord {
    return {
      ...this.toShareLinkRecord(link),
      pin: this.toPinDto(link.pin),
    };
  }

  private toShareLinkRecord(link: ShareLinkPrismaRecord): ShareLinkRecord {
    return {
      id: link.id,
      pinId: link.pinId,
      createdBy: link.createdBy,
      token: link.token,
      revoked: link.revoked,
      createdAt: link.createdAt.toISOString(),
    };
  }

  private toPinDto(pin: PublicShareLinkPrismaRecord['pin']): PinDto {
    return {
      id: pin.id,
      mapId: pin.mapId,
      title: pin.title ?? '',
      note: pin.note,
      memoryDate: pin.memoryDate?.toISOString() ?? null,
      lat: pin.lat,
      lng: pin.lng,
      media: pin.media.map((media) => this.toPinMediaDto(media)),
      createdAt: pin.createdAt.toISOString(),
      updatedAt: pin.updatedAt.toISOString(),
      clientId: null,
    };
  }

  private toPinMediaDto(
    media: PublicShareLinkPrismaRecord['pin']['media'][number],
  ): PinMediaDto {
    return {
      id: media.id,
      pinId: media.pinId,
      mediaType: this.mediaType(media.type),
      objectKey: media.objectKey,
      mimeType: media.mime ?? '',
      sizeBytes: Number(media.sizeBytes ?? 0),
      createdAt: media.createdAt.toISOString(),
    };
  }

  private mediaType(value: string): 'image' | 'text' | 'audio' {
    if (value === 'image' || value === 'text' || value === 'audio') {
      return value;
    }

    return 'text';
  }

  private isTokenUniqueViolation(error: unknown): boolean {
    if (
      typeof error !== 'object' ||
      error === null ||
      !('code' in error) ||
      (error as { code?: unknown }).code !== 'P2002'
    ) {
      return false;
    }

    const target = (error as { meta?: { target?: unknown } }).meta?.target;
    if (Array.isArray(target)) {
      return target.includes('token');
    }

    return typeof target === 'string' && target.includes('token');
  }
}
