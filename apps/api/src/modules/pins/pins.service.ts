import { Inject, Injectable } from '@nestjs/common';

import {
  throwNotFound,
  throwValidationError,
} from '../../common/api-error';
import { OBJECT_STORAGE, ObjectStoragePort } from '../../infra/r2';
import { CurrentUser } from '../auth/current-user';
import { AuthorizationService } from '../authorization/authorization.service';
import {
  BboxPinsQueryDto,
  CreatePinRequestDto,
  DeletePinResponseDto,
  PinDto,
  PinsListResponseDto,
  UpdatePinRequestDto,
} from './dto/pins.dto';
import { parseBbox } from './bbox';
import { PIN_REPOSITORY, PinRepository } from './repositories';

@Injectable()
export class PinsService {
  constructor(
    @Inject(PIN_REPOSITORY)
    private readonly pinRepository: PinRepository,
    private readonly authorization: AuthorizationService,
    @Inject(OBJECT_STORAGE)
    private readonly objectStorage: ObjectStoragePort,
  ) {}

  async listByBbox(
    user: CurrentUser,
    mapId: string,
    query: BboxPinsQueryDto,
  ): Promise<PinsListResponseDto> {
    await this.authorization.assertCanReadMap(user.id, mapId);
    const bbox = parseBbox(query.bbox);

    return {
      pins: await this.pinRepository.listPinsInBbox(mapId, bbox),
    };
  }

  async createPin(
    user: CurrentUser,
    mapId: string,
    request: CreatePinRequestDto,
  ): Promise<PinDto> {
    this.assertCoordinates(request.lat, request.lng);
    await this.authorization.assertCanCreatePin(user.id, mapId);

    return this.pinRepository.createPin({
      mapId,
      createdBy: user.id,
      request,
    });
  }

  async getPin(user: CurrentUser, pinId: string): Promise<PinDto> {
    await this.authorization.assertCanReadPin(user.id, pinId);
    const pin = await this.pinRepository.findPinById(pinId);

    if (!pin) {
      throwNotFound('Pin not found.');
    }

    return pin;
  }

  async updatePin(
    user: CurrentUser,
    pinId: string,
    request: UpdatePinRequestDto,
  ): Promise<PinDto> {
    this.assertUpdateCoordinates(request);
    await this.authorization.assertCanModifyPin(user.id, pinId);
    const pin = await this.pinRepository.updatePin(pinId, request);

    if (!pin) {
      throwNotFound('Pin not found.');
    }

    return pin;
  }

  async deletePin(
    user: CurrentUser,
    pinId: string,
  ): Promise<DeletePinResponseDto> {
    await this.authorization.assertCanModifyPin(user.id, pinId);
    const result = await this.pinRepository.deletePin(pinId);

    await Promise.all(
      result.removedMediaObjectKeys.map((objectKey) =>
        this.objectStorage.deleteObject(objectKey),
      ),
    );

    return {
      deleted: true,
    };
  }

  private assertUpdateCoordinates(request: UpdatePinRequestDto): void {
    const hasLat = Object.prototype.hasOwnProperty.call(request, 'lat');
    const hasLng = Object.prototype.hasOwnProperty.call(request, 'lng');

    if (hasLat !== hasLng) {
      throwValidationError(
        'Both lat and lng are required when updating pin coordinates.',
        {
          lat: request.lat,
          lng: request.lng,
        },
      );
    }

    if (hasLat && hasLng) {
      this.assertCoordinates(request.lat, request.lng);
    }
  }

  private assertCoordinates(lat: unknown, lng: unknown): void {
    if (
      typeof lat !== 'number' ||
      typeof lng !== 'number' ||
      !Number.isFinite(lat) ||
      !Number.isFinite(lng) ||
      lat < -90 ||
      lat > 90 ||
      lng < -180 ||
      lng > 180
    ) {
      throwValidationError('Invalid coordinates.', {
        lat,
        lng,
      });
    }
  }
}
