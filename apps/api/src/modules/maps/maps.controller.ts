import {
  Body,
  Controller,
  Delete,
  Headers,
  Param,
  Post,
  Get,
  UseGuards,
} from '@nestjs/common';

import { ApiEnvelope, createEnvelope } from '../../common/api-envelope';
import { EmptyResultDto } from '../../common/dto/result.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import {
  AcceptInvitationResponseDto,
  CreateDuoMapRequestDto,
  InvitationDto,
  MapDto,
  MapsListResponseDto,
  RemoveMapMemberResponseDto,
} from './dto/maps.dto';
import { MapsService } from './maps.service';

@UseGuards(JwtAuthGuard)
@Controller()
export class MapsController {
  constructor(private readonly mapsService: MapsService) {}

  @Get('maps')
  async listMaps(
    @Headers('x-request-id') requestId?: string,
  ): Promise<ApiEnvelope<MapsListResponseDto>> {
    const data = await this.mapsService.listMaps();

    return createEnvelope(data, requestId);
  }

  @Get('maps/default')
  async getDefaultMap(
    @Headers('x-request-id') requestId?: string,
  ): Promise<ApiEnvelope<MapDto>> {
    const data = await this.mapsService.getDefaultMap();

    return createEnvelope(data, requestId);
  }

  @Post('maps/duo')
  async createDuoMap(
    @Body() request: CreateDuoMapRequestDto,
    @Headers('x-request-id') requestId?: string,
  ): Promise<ApiEnvelope<MapDto>> {
    const data = await this.mapsService.createDuoMap(request);

    return createEnvelope(data, requestId);
  }

  @Post('maps/:mapId/invitations')
  async createInvitation(
    @Param('mapId') mapId: string,
    @Headers('x-request-id') requestId?: string,
  ): Promise<ApiEnvelope<InvitationDto>> {
    const data = await this.mapsService.createInvitation(mapId);

    return createEnvelope(data, requestId);
  }

  @Delete('maps/:mapId/invitations/:invitationId')
  async revokeInvitation(
    @Param('mapId') mapId: string,
    @Param('invitationId') invitationId: string,
    @Headers('x-request-id') requestId?: string,
  ): Promise<ApiEnvelope<EmptyResultDto>> {
    const data = await this.mapsService.revokeInvitation(mapId, invitationId);

    return createEnvelope(data, requestId);
  }

  @Post('invitations/:code/accept')
  async acceptInvitation(
    @Param('code') code: string,
    @Headers('x-request-id') requestId?: string,
  ): Promise<ApiEnvelope<AcceptInvitationResponseDto>> {
    const data = await this.mapsService.acceptInvitation(code);

    return createEnvelope(data, requestId);
  }

  @Delete('maps/:mapId/members/:userId')
  async removeMember(
    @Param('mapId') mapId: string,
    @Param('userId') userId: string,
    @Headers('x-request-id') requestId?: string,
  ): Promise<ApiEnvelope<RemoveMapMemberResponseDto>> {
    const data = await this.mapsService.removeMember(mapId, userId);

    return createEnvelope(data, requestId);
  }
}
