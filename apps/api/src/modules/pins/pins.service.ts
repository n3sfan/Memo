import { Inject, Injectable } from '@nestjs/common';

import { notImplemented } from '../../common/not-implemented';
import {
  throwNotFound,
  throwValidationError,
} from '../../common/api-error';
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
import { PIN_REPOSITORY, PinRepository } from './repositories';

@Injectable()
export class PinsService {
  constructor(
    @Inject(PIN_REPOSITORY)
    private readonly pinRepository: PinRepository,
    private readonly authorization: AuthorizationService,
  ) {}

  listByBbox(
    user: CurrentUser,
    mapId: string,
    query: BboxPinsQueryDto,
  ): Promise<PinsListResponseDto> {
    void user;
    void mapId;
    void query;

    return notImplemented('PinsService.listByBbox');
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
    await this.pinRepository.deletePin(pinId);

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
