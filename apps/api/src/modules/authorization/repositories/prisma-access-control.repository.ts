import { Injectable } from '@nestjs/common';

import { PrismaService } from '../../../infra/prisma';
import {
  AccessControlRepository,
  InvitationAccessRecord,
  MapAccessRecord,
  PinAccessRecord,
  ShareLinkAccessRecord,
} from './access-control.repository';

@Injectable()
export class PrismaAccessControlRepository implements AccessControlRepository {
  constructor(private readonly prisma: PrismaService) {}

  findMapAccessRecord(mapId: string): Promise<MapAccessRecord | null> {
    return this.prisma.memoryMap.findUnique({
      where: { id: mapId },
      select: this.mapAccessSelect(),
    });
  }

  findPinAccessRecord(pinId: string): Promise<PinAccessRecord | null> {
    return this.prisma.pin.findUnique({
      where: { id: pinId },
      select: {
        map: {
          select: this.mapAccessSelect(),
        },
      },
    });
  }

  findInvitationAccessRecord(
    invitationId: string,
  ): Promise<InvitationAccessRecord | null> {
    return this.prisma.invitation.findUnique({
      where: { id: invitationId },
      select: {
        map: {
          select: this.mapAccessSelect(),
        },
      },
    });
  }

  findShareLinkAccessRecord(
    token: string,
  ): Promise<ShareLinkAccessRecord | null> {
    return this.prisma.shareLink.findUnique({
      where: { token },
      select: {
        revoked: true,
      },
    });
  }

  private mapAccessSelect(): {
    id: true;
    ownerId: true;
    type: true;
    members: {
      select: {
        userId: true;
        role: true;
      };
    };
  } {
    return {
      id: true,
      ownerId: true,
      type: true,
      members: {
        select: {
          userId: true,
          role: true,
        },
      },
    };
  }
}
