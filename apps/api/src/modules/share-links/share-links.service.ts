import { Injectable } from '@nestjs/common';

import { notImplemented } from '../../common/not-implemented';
import {
  CreateShareLinkRequestDto,
  PublicSharedPinDto,
  RevokeShareLinkResponseDto,
  ShareLinkDto,
} from './dto/share-links.dto';

@Injectable()
export class ShareLinksService {
  createShareLink(
    pinId: string,
    request: CreateShareLinkRequestDto,
  ): Promise<ShareLinkDto> {
    void pinId;
    void request;

    return notImplemented('ShareLinksService.createShareLink');
  }

  resolvePublicPin(token: string): Promise<PublicSharedPinDto> {
    void token;

    return notImplemented('ShareLinksService.resolvePublicPin');
  }

  revokeShareLink(shareLinkId: string): Promise<RevokeShareLinkResponseDto> {
    void shareLinkId;

    return notImplemented('ShareLinksService.revokeShareLink');
  }
}
