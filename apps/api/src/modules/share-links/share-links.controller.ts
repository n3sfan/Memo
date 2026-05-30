import { Body, Controller, Delete, Get, Headers, Param, Post, UseGuards } from '@nestjs/common';

import { ApiEnvelope, createEnvelope } from '../../common/api-envelope';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import {
  CreateShareLinkRequestDto,
  PublicSharedPinDto,
  RevokeShareLinkResponseDto,
  ShareLinkDto,
} from './dto/share-links.dto';
import { ShareLinksService } from './share-links.service';

@Controller()
export class ShareLinksController {
  constructor(private readonly shareLinksService: ShareLinksService) {}

  @UseGuards(JwtAuthGuard)
  @Post('pins/:pinId/share-links')
  async createShareLink(
    @Param('pinId') pinId: string,
    @Body() request: CreateShareLinkRequestDto,
    @Headers('x-request-id') requestId?: string,
  ): Promise<ApiEnvelope<ShareLinkDto>> {
    const data = await this.shareLinksService.createShareLink(pinId, request);

    return createEnvelope(data, requestId);
  }

  @Get('share/:token')
  async resolvePublicPin(
    @Param('token') token: string,
    @Headers('x-request-id') requestId?: string,
  ): Promise<ApiEnvelope<PublicSharedPinDto>> {
    const data = await this.shareLinksService.resolvePublicPin(token);

    return createEnvelope(data, requestId);
  }

  @UseGuards(JwtAuthGuard)
  @Delete('share-links/:shareLinkId')
  async revokeShareLink(
    @Param('shareLinkId') shareLinkId: string,
    @Headers('x-request-id') requestId?: string,
  ): Promise<ApiEnvelope<RevokeShareLinkResponseDto>> {
    const data = await this.shareLinksService.revokeShareLink(shareLinkId);

    return createEnvelope(data, requestId);
  }
}
