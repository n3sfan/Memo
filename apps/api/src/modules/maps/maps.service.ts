import { Injectable } from '@nestjs/common';

import { EmptyResultDto } from '../../common/dto/result.dto';
import { notImplemented } from '../../common/not-implemented';
import {
  AcceptInvitationResponseDto,
  CreateDuoMapRequestDto,
  InvitationDto,
  MapDto,
  MapsListResponseDto,
  RemoveMapMemberResponseDto,
} from './dto/maps.dto';

@Injectable()
export class MapsService {
  listMaps(): Promise<MapsListResponseDto> {
    return notImplemented('MapsService.listMaps');
  }

  getDefaultMap(): Promise<MapDto> {
    return notImplemented('MapsService.getDefaultMap');
  }

  createDuoMap(request: CreateDuoMapRequestDto): Promise<MapDto> {
    void request;

    return notImplemented('MapsService.createDuoMap');
  }

  createInvitation(mapId: string): Promise<InvitationDto> {
    void mapId;

    return notImplemented('MapsService.createInvitation');
  }

  revokeInvitation(
    mapId: string,
    invitationId: string,
  ): Promise<EmptyResultDto> {
    void mapId;
    void invitationId;

    return notImplemented('MapsService.revokeInvitation');
  }

  acceptInvitation(code: string): Promise<AcceptInvitationResponseDto> {
    void code;

    return notImplemented('MapsService.acceptInvitation');
  }

  removeMember(
    mapId: string,
    userId: string,
  ): Promise<RemoveMapMemberResponseDto> {
    void mapId;
    void userId;

    return notImplemented('MapsService.removeMember');
  }
}
