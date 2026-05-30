import {
  Body,
  Controller,
  Delete,
  Get,
  Headers,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';

import { ApiEnvelope, createEnvelope } from '../../common/api-envelope';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import {
  BboxPinsQueryDto,
  CreatePinRequestDto,
  DeletePinResponseDto,
  PinDto,
  PinsListResponseDto,
  UpdatePinRequestDto,
} from './dto/pins.dto';
import { PinsService } from './pins.service';

@UseGuards(JwtAuthGuard)
@Controller()
export class PinsController {
  constructor(private readonly pinsService: PinsService) {}

  @Get('maps/:mapId/pins')
  async listByBbox(
    @Param('mapId') mapId: string,
    @Query() query: BboxPinsQueryDto,
    @Headers('x-request-id') requestId?: string,
  ): Promise<ApiEnvelope<PinsListResponseDto>> {
    const data = await this.pinsService.listByBbox(mapId, query);

    return createEnvelope(data, requestId);
  }

  @Post('maps/:mapId/pins')
  async createPin(
    @Param('mapId') mapId: string,
    @Body() request: CreatePinRequestDto,
    @Headers('x-request-id') requestId?: string,
  ): Promise<ApiEnvelope<PinDto>> {
    const data = await this.pinsService.createPin(mapId, request);

    return createEnvelope(data, requestId);
  }

  @Get('pins/:pinId')
  async getPin(
    @Param('pinId') pinId: string,
    @Headers('x-request-id') requestId?: string,
  ): Promise<ApiEnvelope<PinDto>> {
    const data = await this.pinsService.getPin(pinId);

    return createEnvelope(data, requestId);
  }

  @Patch('pins/:pinId')
  async updatePin(
    @Param('pinId') pinId: string,
    @Body() request: UpdatePinRequestDto,
    @Headers('x-request-id') requestId?: string,
  ): Promise<ApiEnvelope<PinDto>> {
    const data = await this.pinsService.updatePin(pinId, request);

    return createEnvelope(data, requestId);
  }

  @Delete('pins/:pinId')
  async deletePin(
    @Param('pinId') pinId: string,
    @Headers('x-request-id') requestId?: string,
  ): Promise<ApiEnvelope<DeletePinResponseDto>> {
    const data = await this.pinsService.deletePin(pinId);

    return createEnvelope(data, requestId);
  }
}
