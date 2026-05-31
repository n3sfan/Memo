import { Injectable } from '@nestjs/common';

import { PrismaService } from '../../../infra/prisma';
import {
  PinDto,
  PinMediaDto,
  UpdatePinRequestDto,
} from '../dto/pins.dto';
import {
  CreatePinInput,
  DeletePinResult,
  PinRepository,
} from './pin.repository';

interface PinSqlRow {
  id: string;
  map_id: string;
  title: string | null;
  note: string | null;
  memory_date: Date | string | null;
  lat: number;
  lng: number;
  created_at: Date | string;
  updated_at: Date | string;
  media: unknown;
}

interface PrismaPinRecord {
  id: string;
  mapId: string;
  title: string | null;
  note: string | null;
  memoryDate: Date | null;
  lat: number;
  lng: number;
  createdAt: Date;
  updatedAt: Date;
  media: PrismaMediaRecord[];
}

interface PrismaMediaRecord {
  id: string;
  pinId: string;
  type: string;
  objectKey: string;
  mime: string | null;
  sizeBytes: bigint | number | null;
  createdAt: Date;
}

@Injectable()
export class PrismaPinRepository implements PinRepository {
  constructor(private readonly prisma: PrismaService) {}

  async createPin(input: CreatePinInput): Promise<PinDto> {
    const memoryDate = this.optionalDate(input.request.memoryDate);
    const rows = await this.prisma.$queryRaw<PinSqlRow[]>`
      INSERT INTO pins (
        map_id,
        created_by,
        title,
        note,
        memory_date,
        lat,
        lng,
        geom
      )
      VALUES (
        ${input.mapId}::uuid,
        ${input.createdBy}::uuid,
        ${input.request.title},
        ${input.request.note ?? null},
        ${memoryDate}::timestamptz,
        ${input.request.lat},
        ${input.request.lng},
        ST_SetSRID(ST_MakePoint(${input.request.lng}, ${input.request.lat}), 4326)
      )
      RETURNING
        id,
        map_id,
        title,
        note,
        memory_date,
        lat,
        lng,
        created_at,
        updated_at,
        '[]'::json AS media
    `;

    return this.requireSinglePin(rows);
  }

  async findPinById(pinId: string): Promise<PinDto | null> {
    const pin = await this.prisma.pin.findUnique({
      where: { id: pinId },
      select: this.pinSelect(),
    });

    return pin ? this.pinFromPrismaRecord(pin) : null;
  }

  async updatePin(
    pinId: string,
    request: UpdatePinRequestDto,
  ): Promise<PinDto | null> {
    const hasNote = Object.prototype.hasOwnProperty.call(request, 'note');
    const hasMemoryDate = Object.prototype.hasOwnProperty.call(
      request,
      'memoryDate',
    );
    const hasCoordinates =
      request.lat !== undefined && request.lng !== undefined;
    const memoryDate = this.optionalDate(request.memoryDate);

    const rows = await this.prisma.$queryRaw<PinSqlRow[]>`
      UPDATE pins
      SET
        title = COALESCE(${request.title ?? null}, title),
        note = CASE WHEN ${hasNote} THEN ${request.note ?? null} ELSE note END,
        memory_date = CASE
          WHEN ${hasMemoryDate} THEN ${memoryDate}::timestamptz
          ELSE memory_date
        END,
        lat = CASE WHEN ${hasCoordinates} THEN ${request.lat ?? null} ELSE lat END,
        lng = CASE WHEN ${hasCoordinates} THEN ${request.lng ?? null} ELSE lng END,
        geom = CASE
          WHEN ${hasCoordinates}
            THEN ST_SetSRID(ST_MakePoint(${request.lng ?? null}, ${request.lat ?? null}), 4326)
          ELSE geom
        END,
        updated_at = now()
      WHERE id = ${pinId}::uuid
      RETURNING
        id,
        map_id,
        title,
        note,
        memory_date,
        lat,
        lng,
        created_at,
        updated_at,
        COALESCE(
          (
            SELECT json_agg(
              json_build_object(
                'id', mf.id,
                'pinId', mf.pin_id,
                'mediaType', mf.type,
                'objectKey', mf.object_key,
                'mimeType', mf.mime,
                'sizeBytes', mf.size_bytes,
                'createdAt', mf.created_at
              )
              ORDER BY mf.created_at ASC
            )
            FROM media_files mf
            WHERE mf.pin_id = pins.id
          ),
          '[]'::json
        ) AS media
    `;

    return rows[0] ? this.pinFromSqlRow(rows[0]) : null;
  }

  async deletePin(pinId: string): Promise<DeletePinResult> {
    return this.prisma.$transaction(async (transaction) => {
      const media = await transaction.mediaFile.findMany({
        where: { pinId },
        select: { objectKey: true },
      });

      await transaction.mediaFile.deleteMany({
        where: { pinId },
      });

      await transaction.pin.delete({
        where: { id: pinId },
        select: { id: true },
      });

      return {
        deleted: true,
        removedMediaObjectKeys: media.map((item) => item.objectKey),
      };
    });
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

  private requireSinglePin(rows: PinSqlRow[]): PinDto {
    const pin = rows[0];

    if (!pin) {
      throw new Error('Pin write did not return a row.');
    }

    return this.pinFromSqlRow(pin);
  }

  private pinFromPrismaRecord(pin: PrismaPinRecord): PinDto {
    return {
      id: pin.id,
      mapId: pin.mapId,
      title: pin.title ?? '',
      note: pin.note,
      memoryDate: this.optionalIsoString(pin.memoryDate),
      lat: pin.lat,
      lng: pin.lng,
      media: pin.media.map((media) => this.mediaFromPrismaRecord(media)),
      createdAt: pin.createdAt.toISOString(),
      updatedAt: pin.updatedAt.toISOString(),
      clientId: null,
    };
  }

  private pinFromSqlRow(row: PinSqlRow): PinDto {
    return {
      id: row.id,
      mapId: row.map_id,
      title: row.title ?? '',
      note: row.note,
      memoryDate: this.optionalIsoString(row.memory_date),
      lat: Number(row.lat),
      lng: Number(row.lng),
      media: this.mediaFromJson(row.media),
      createdAt: this.isoString(row.created_at),
      updatedAt: this.isoString(row.updated_at),
      clientId: null,
    };
  }

  private mediaFromPrismaRecord(media: PrismaMediaRecord): PinMediaDto {
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

  private mediaFromJson(value: unknown): PinMediaDto[] {
    if (!Array.isArray(value)) {
      return [];
    }

    return value.map((item) => {
      const media = item as Record<string, unknown>;

      return {
        id: String(media.id),
        pinId: String(media.pinId),
        mediaType: this.mediaType(String(media.mediaType)),
        objectKey: String(media.objectKey),
        mimeType: typeof media.mimeType === 'string' ? media.mimeType : '',
        sizeBytes: Number(media.sizeBytes ?? 0),
        createdAt: this.isoString(media.createdAt as Date | string),
      };
    });
  }

  private mediaType(value: string): 'image' | 'text' | 'audio' {
    if (value === 'image' || value === 'text' || value === 'audio') {
      return value;
    }

    return 'text';
  }

  private optionalDate(value: string | null | undefined): Date | null {
    return value ? new Date(value) : null;
  }

  private optionalIsoString(value: Date | string | null): string | null {
    return value ? this.isoString(value) : null;
  }

  private isoString(value: Date | string): string {
    return value instanceof Date ? value.toISOString() : new Date(value).toISOString();
  }
}
