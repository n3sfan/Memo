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
import {
  CurrentUser as CurrentUserValue,
} from '../auth/current-user';
import { CurrentUser } from '../auth/current-user.decorator';
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
    @CurrentUser() user: CurrentUserValue,
    @Param('mapId') mapId: string,
    @Query() query: BboxPinsQueryDto,
    @Headers('x-request-id') requestId?: string,
  ): Promise<ApiEnvelope<PinsListResponseDto>> {
    const data = await this.pinsService.listByBbox(user, mapId, query);

    return createEnvelope(data, requestId);
  }

  @Post('maps/:mapId/pins')
  async createPin(
    @CurrentUser() user: CurrentUserValue,
    @Param('mapId') mapId: string,
    @Body() request: CreatePinRequestDto,
    @Headers('x-request-id') requestId?: string,
  ): Promise<ApiEnvelope<PinDto>> {
    const data = await this.pinsService.createPin(user, mapId, request);

    return createEnvelope(data, requestId);
  }

  @Get('pins/:pinId')
  async getPin(
    @CurrentUser() user: CurrentUserValue,
    @Param('pinId') pinId: string,
    @Headers('x-request-id') requestId?: string,
  ): Promise<ApiEnvelope<PinDto>> {
    const data = await this.pinsService.getPin(user, pinId);

    return createEnvelope(data, requestId);
  }

  @Patch('pins/:pinId')
  async updatePin(
    @CurrentUser() user: CurrentUserValue,
    @Param('pinId') pinId: string,
    @Body() request: UpdatePinRequestDto,
    @Headers('x-request-id') requestId?: string,
  ): Promise<ApiEnvelope<PinDto>> {
    const data = await this.pinsService.updatePin(user, pinId, request);

    return createEnvelope(data, requestId);
  }

  @Delete('pins/:pinId')
  async deletePin(
    @CurrentUser() user: CurrentUserValue,
    @Param('pinId') pinId: string,
    @Headers('x-request-id') requestId?: string,
  ): Promise<ApiEnvelope<DeletePinResponseDto>> {
    const data = await this.pinsService.deletePin(user, pinId);

    return createEnvelope(data, requestId);
  }
}
