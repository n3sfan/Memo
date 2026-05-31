import {
  CreatePinRequestDto,
  PinDto,
  UpdatePinRequestDto,
} from '../dto/pins.dto';

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

export interface PinRepository {
  createPin(input: CreatePinInput): Promise<PinDto>;
  findPinById(pinId: string): Promise<PinDto | null>;
  updatePin(pinId: string, request: UpdatePinRequestDto): Promise<PinDto | null>;
  deletePin(pinId: string): Promise<DeletePinResult>;
}
