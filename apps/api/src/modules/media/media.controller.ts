import {
  Body,
  Controller,
  Delete,
  Get,
  Headers,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';

import { ApiEnvelope, createEnvelope } from '../../common/api-envelope';
import {
  CurrentUser as CurrentUserValue,
} from '../auth/current-user';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import {
  DeleteMediaResponseDto,
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
    @CurrentUser() user: CurrentUserValue,
    @Param('pinId') pinId: string,
    @Body() request: PresignMediaRequestDto,
    @Headers('x-request-id') requestId?: string,
  ): Promise<ApiEnvelope<PresignMediaResponseDto>> {
    const data = await this.mediaService.createPresignedUpload(
      user,
      pinId,
      request,
    );

    return createEnvelope(data, requestId);
  }

  @Post('pins/:pinId/media')
  async registerMedia(
    @CurrentUser() user: CurrentUserValue,
    @Param('pinId') pinId: string,
    @Body() request: RegisterMediaRequestDto,
    @Headers('x-request-id') requestId?: string,
  ): Promise<ApiEnvelope<MediaDto>> {
    const data = await this.mediaService.registerMedia(user, pinId, request);

    return createEnvelope(data, requestId);
  }

  @Get('media/:mediaId/presign')
  async createReadUrl(
    @CurrentUser() user: CurrentUserValue,
    @Param('mediaId') mediaId: string,
    @Headers('x-request-id') requestId?: string,
  ): Promise<ApiEnvelope<MediaReadUrlResponseDto>> {
    const data = await this.mediaService.createReadUrl(user, mediaId);

    return createEnvelope(data, requestId);
  }

  @Delete('media/:mediaId')
  async deleteMedia(
    @CurrentUser() user: CurrentUserValue,
    @Param('mediaId') mediaId: string,
    @Headers('x-request-id') requestId?: string,
  ): Promise<ApiEnvelope<DeleteMediaResponseDto>> {
    const data = await this.mediaService.deleteMedia(user, mediaId);

    return createEnvelope(data, requestId);
  }
}
