import { Inject, Injectable } from '@nestjs/common';
import { randomBytes } from 'node:crypto';

import {
  throwConflict,
  throwForbidden,
  throwLinkRevoked,
  throwNotFound,
  throwValidationError,
} from '../../common/api-error';
import { OBJECT_STORAGE, ObjectStoragePort } from '../../infra/r2';
import { CurrentUser } from '../auth/current-user';
import { AuthorizationService } from '../authorization/authorization.service';
import {
  PinDto,
  PublicPinDto,
} from '../pins/dto/pins.dto';
import {
  CreateShareLinkRequestDto,
  PublicSharedPinDto,
  RevokeShareLinkResponseDto,
  ShareLinkDto,
} from './dto/share-links.dto';
import {
  SHARE_LINK_REPOSITORY,
  ShareLinkRecord,
  ShareLinkRepository,
  ShareLinkTokenConflictError,
} from './repositories';

const SHARE_TOKEN_RANDOM_BYTES = 9;
const SHARE_TOKEN_LENGTH = 12;
const SHARE_TOKEN_MAX_ATTEMPTS = 10;

@Injectable()
export class ShareLinksService {
  constructor(
    @Inject(SHARE_LINK_REPOSITORY)
    private readonly shareLinkRepository: ShareLinkRepository,
    private readonly authorization: AuthorizationService,
    @Inject(OBJECT_STORAGE)
    private readonly objectStorage: ObjectStoragePort,
  ) {}

  async createShareLink(
    user: CurrentUser,
    pinId: string,
    request: CreateShareLinkRequestDto,
  ): Promise<ShareLinkDto> {
    this.assertNoExpiration(request);
    await this.authorization.assertCanReadPin(user.id, pinId);

    return this.createShareLinkWithUniqueToken(pinId, user.id);
  }

  async resolvePublicPin(token: string): Promise<PublicSharedPinDto> {
    const link = await this.shareLinkRepository.findPublicShareByToken(token);

    if (!link) {
      throwNotFound('Share link not found.');
    }

    if (link.revoked) {
      throwLinkRevoked();
    }

    return {
      shareLinkId: link.id,
      pin: await this.toPublicPinDto(link.pin),
    };
  }

  async revokeShareLink(
    user: CurrentUser,
    shareLinkId: string,
  ): Promise<RevokeShareLinkResponseDto> {
    const link =
      await this.shareLinkRepository.findShareLinkById(shareLinkId);

    if (!link) {
      throwNotFound('Share link not found.');
    }

    if (link.createdBy !== user.id) {
      throwForbidden('You cannot revoke this share link.');
    }

    if (!link.revoked) {
      await this.shareLinkRepository.revokeShareLink(shareLinkId);
    }

    return {
      revoked: true,
    };
  }

  private assertNoExpiration(request: CreateShareLinkRequestDto): void {
    if (Object.prototype.hasOwnProperty.call(request, 'expiresAt')) {
      throwValidationError('Share link expiration is not supported yet.', {
        expiresAt: request.expiresAt,
      });
    }
  }

  private async createShareLinkWithUniqueToken(
    pinId: string,
    createdBy: string,
  ): Promise<ShareLinkDto> {
    for (let attempt = 0; attempt < SHARE_TOKEN_MAX_ATTEMPTS; attempt += 1) {
      const token = this.createToken();
      const existing =
        await this.shareLinkRepository.findShareLinkByToken(token);

      if (existing) {
        continue;
      }

      try {
        const link = await this.shareLinkRepository.createShareLink({
          pinId,
          createdBy,
          token,
        });

        return this.toShareLinkDto(link);
      } catch (error) {
        if (error instanceof ShareLinkTokenConflictError) {
          continue;
        }

        throw error;
      }
    }

    throwConflict('Could not create a unique share link token.');
  }

  private createToken(): string {
    return randomBytes(SHARE_TOKEN_RANDOM_BYTES)
      .toString('base64url')
      .slice(0, SHARE_TOKEN_LENGTH);
  }

  private toShareLinkDto(link: ShareLinkRecord): ShareLinkDto {
    return {
      id: link.id,
      pinId: link.pinId,
      token: link.token,
      url: `${this.publicBaseUrl()}/p/${encodeURIComponent(link.token)}`,
      revoked: link.revoked,
      createdAt: link.createdAt,
      expiresAt: null,
    };
  }

  private publicBaseUrl(): string {
    return (process.env.SHARE_PUBLIC_BASE_URL || 'https://memo.app').replace(
      /\/+$/,
      '',
    );
  }

  private async toPublicPinDto(pin: PinDto): Promise<PublicPinDto> {
    return {
      id: pin.id,
      title: pin.title,
      note: pin.note,
      memoryDate: pin.memoryDate,
      lat: pin.lat,
      lng: pin.lng,
      media: await Promise.all(
        pin.media.map(async (media) => {
          const presigned = await this.objectStorage.createPresignedRead(
            media.objectKey,
          );

          return {
            id: media.id,
            pinId: media.pinId,
            mediaType: media.mediaType,
            mimeType: media.mimeType,
            sizeBytes: media.sizeBytes,
            createdAt: media.createdAt,
            url: presigned.readUrl,
          };
        }),
      ),
      createdAt: pin.createdAt,
      updatedAt: pin.updatedAt,
    };
  }
}
