import {
  CreatePinRequestDto,
  PinDto,
  UpdatePinRequestDto,
} from '../dto/pins.dto';
import type { Bbox } from '../bbox';
import type {
  TimelineCursor,
  TimelineOrder,
} from '../../timeline/timeline-cursor';

export const PIN_REPOSITORY = Symbol('PIN_REPOSITORY');

export interface CreatePinInput {
  mapId: string;
  createdBy: string;
  request: CreatePinRequestDto;
}

export interface DeletePinResult {
  deleted: true;
  removedMediaObjectKeys: string[];
}

export interface TimelinePageInput {
  order: TimelineOrder;
  cursor?: TimelineCursor;
  limit: number;
}

export interface PinRepository {
  listPinsInBbox(mapId: string, bbox: Bbox): Promise<PinDto[]>;
  listTimelinePage(
    mapId: string,
    input: TimelinePageInput,
  ): Promise<PinDto[]>;
  createPin(input: CreatePinInput): Promise<PinDto>;
  findPinById(pinId: string): Promise<PinDto | null>;
  updatePin(pinId: string, request: UpdatePinRequestDto): Promise<PinDto | null>;
  deletePin(pinId: string): Promise<DeletePinResult>;
}
