import { Injectable } from '@nestjs/common';

import { notImplemented } from '../../common/not-implemented';
import {
  MediaDto,
  MediaReadUrlResponseDto,
  PresignMediaRequestDto,
  PresignMediaResponseDto,
  RegisterMediaRequestDto,
} from './dto/media.dto';

@Injectable()
export class MediaService {
  createPresignedUpload(
    pinId: string,
    request: PresignMediaRequestDto,
  ): Promise<PresignMediaResponseDto> {
    void pinId;
    void request;

    return notImplemented('MediaService.createPresignedUpload');
  }

  registerMedia(pinId: string, request: RegisterMediaRequestDto): Promise<MediaDto> {
    void pinId;
    void request;

    return notImplemented('MediaService.registerMedia');
  }

  createReadUrl(mediaId: string): Promise<MediaReadUrlResponseDto> {
    void mediaId;

    return notImplemented('MediaService.createReadUrl');
  }
}
