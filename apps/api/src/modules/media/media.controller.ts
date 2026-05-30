import { Body, Controller, Get, Headers, Param, Post, UseGuards } from '@nestjs/common';

import { ApiEnvelope, createEnvelope } from '../../common/api-envelope';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import {
  MediaDto,
  MediaReadUrlResponseDto,
  PresignMediaRequestDto,
  PresignMediaResponseDto,
  RegisterMediaRequestDto,
} from './dto/media.dto';
import { MediaService } from './media.service';

@UseGuards(JwtAuthGuard)
@Controller()
export class MediaController {
  constructor(private readonly mediaService: MediaService) {}

  @Post('pins/:pinId/media/presign')
  async createPresignedUpload(
    @Param('pinId') pinId: string,
    @Body() request: PresignMediaRequestDto,
    @Headers('x-request-id') requestId?: string,
  ): Promise<ApiEnvelope<PresignMediaResponseDto>> {
    const data = await this.mediaService.createPresignedUpload(pinId, request);

    return createEnvelope(data, requestId);
  }

  @Post('pins/:pinId/media')
  async registerMedia(
    @Param('pinId') pinId: string,
    @Body() request: RegisterMediaRequestDto,
    @Headers('x-request-id') requestId?: string,
  ): Promise<ApiEnvelope<MediaDto>> {
    const data = await this.mediaService.registerMedia(pinId, request);

    return createEnvelope(data, requestId);
  }

  @Get('media/:mediaId/presign')
  async createReadUrl(
    @Param('mediaId') mediaId: string,
    @Headers('x-request-id') requestId?: string,
  ): Promise<ApiEnvelope<MediaReadUrlResponseDto>> {
    const data = await this.mediaService.createReadUrl(mediaId);

    return createEnvelope(data, requestId);
  }
}
