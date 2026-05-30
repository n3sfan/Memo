import { Injectable } from '@nestjs/common';

import { notImplemented } from '../../common/not-implemented';
import {
  BboxPinsQueryDto,
  CreatePinRequestDto,
  DeletePinResponseDto,
  PinDto,
  PinsListResponseDto,
  UpdatePinRequestDto,
} from './dto/pins.dto';

@Injectable()
export class PinsService {
  listByBbox(
    mapId: string,
    query: BboxPinsQueryDto,
  ): Promise<PinsListResponseDto> {
    void mapId;
    void query;

    return notImplemented('PinsService.listByBbox');
  }

  createPin(mapId: string, request: CreatePinRequestDto): Promise<PinDto> {
    void mapId;
    void request;

    return notImplemented('PinsService.createPin');
  }

  getPin(pinId: string): Promise<PinDto> {
    void pinId;

    return notImplemented('PinsService.getPin');
  }

  updatePin(pinId: string, request: UpdatePinRequestDto): Promise<PinDto> {
    void pinId;
    void request;

    return notImplemented('PinsService.updatePin');
  }

  deletePin(pinId: string): Promise<DeletePinResponseDto> {
    void pinId;

    return notImplemented('PinsService.deletePin');
  }
}
