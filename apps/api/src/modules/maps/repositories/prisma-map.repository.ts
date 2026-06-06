import { Injectable } from "@nestjs/common";
import { Prisma, PrismaClient } from "@prisma/client";

import { PrismaService } from "../../../infra/prisma";
import {
  CreateDuoMapRequestDto,
  InvitationDto,
  InvitationStatus,
  MapDto,
  MapMemberDto,
  MapMemberRole,
  MapType,
} from "../dto/maps.dto";
import {
  AcceptInvitationInput,
  AcceptInvitationResult,
  CreateInvitationInput,
  MapRepository,
  PendingInvitationConflictError,
} from "./map.repository";

type PrismaTransaction = Omit<
  PrismaClient,
  "$connect" | "$disconnect" | "$on" | "$transaction" | "$use" | "$extends"
>;

interface MapRecord {
  id: string;
  type: string;
  ownerId: string;
  members: MemberRecord[];
  invitations: InvitationRecord[];
}

interface MemberRecord {
  mapId: string;
  userId: string;
  role: string;
  joinedAt: Date;
}

interface InvitationRecord {
  id: string;
  mapId: string;
  code: string;
  status: string;
  expiresAt: Date;
  createdAt: Date;
}

interface InvitationLockRow {
  id: string;
  map_id: string;
  status: string;
  expires_at: Date | string;
}

@Injectable()
export class PrismaMapRepository implements MapRepository {
  constructor(private readonly prisma: PrismaService) {}

  async listMapsForUser(userId: string, now: Date): Promise<MapDto[]> {
    await this.expirePendingInvitationsForUserMaps(userId, now);

    const maps = await this.prisma.memoryMap.findMany({
      where: {
        members: {
          some: { userId },
        },
      },
      orderBy: { createdAt: "asc" },
      select: this.mapSelect(now),
    });

    return maps.map((map) => this.mapFromRecord(map));
  }

  async findDefaultMapForUser(
    userId: string,
    now: Date,
  ): Promise<MapDto | null> {
    const map = await this.prisma.memoryMap.findFirst({
      where: {
        ownerId: userId,
        type: "personal",
      },
      orderBy: { createdAt: "asc" },
      select: this.mapSelect(now),
    });

    return map ? this.mapFromRecord(map) : null;
  }

  async findMapById(mapId: string, now: Date): Promise<MapDto | null> {
    await this.expirePendingInvitationsForMap(mapId, now);

    const map = await this.prisma.memoryMap.findUnique({
      where: { id: mapId },
      select: this.mapSelect(now),
    });

    return map ? this.mapFromRecord(map) : null;
  }

  countMapMembers(mapId: string): Promise<number> {
    return this.prisma.mapMember.count({
      where: { mapId },
    });
  }

  async expirePendingInvitationsForMap(
    mapId: string,
    now: Date,
  ): Promise<void> {
    await this.prisma.invitation.updateMany({
      where: {
        mapId,
        status: "pending",
        expiresAt: {
          lte: now,
        },
      },
      data: {
        status: "expired",
      },
    });
  }

  async createDuoMap(
    ownerId: string,
    request: CreateDuoMapRequestDto,
    now: Date,
  ): Promise<MapDto> {
    void request;

    const map = await this.prisma.$transaction(async (transaction) => {
      const created = await transaction.memoryMap.create({
        data: {
          type: "duo",
          ownerId,
          members: {
            create: {
              userId: ownerId,
              role: "owner",
            },
          },
        },
        select: {
          id: true,
        },
      });

      return transaction.memoryMap.findUniqueOrThrow({
        where: { id: created.id },
        select: this.mapSelect(now),
      });
    });

    return this.mapFromRecord(map);
  }

  async createInvitation(input: CreateInvitationInput): Promise<InvitationDto> {
    try {
      const invitation = await this.prisma.invitation.create({
        data: {
          mapId: input.mapId,
          createdBy: input.createdBy,
          code: input.code,
          expiresAt: input.expiresAt,
        },
      });

      return this.invitationFromRecord(invitation);
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === "P2002"
      ) {
        throw new PendingInvitationConflictError();
      }

      throw error;
    }
  }

  async revokeInvitation(
    mapId: string,
    invitationId: string,
    now: Date,
  ): Promise<boolean> {
    await this.expirePendingInvitationsForMap(mapId, now);

    const result = await this.prisma.invitation.updateMany({
      where: {
        id: invitationId,
        mapId,
        status: "pending",
        expiresAt: {
          gt: now,
        },
      },
      data: {
        status: "revoked",
      },
    });

    return result.count > 0;
  }

  async acceptInvitation(
    input: AcceptInvitationInput,
  ): Promise<AcceptInvitationResult> {
    return this.prisma.$transaction(async (transaction) => {
      const invitations = await transaction.$queryRaw<InvitationLockRow[]>`
        SELECT id, map_id, status, expires_at
        FROM invitations
        WHERE code = ${input.code}
        FOR UPDATE
      `;
      const invitation = invitations[0];

      if (!invitation) {
        return { status: "invalid_invitation" };
      }

      if (
        invitation.status === "pending" &&
        this.dateFromValue(invitation.expires_at).getTime() <=
          input.now.getTime()
      ) {
        await transaction.invitation.update({
          where: { id: invitation.id },
          data: { status: "expired" },
        });

        return { status: "invalid_invitation" };
      }

      if (invitation.status !== "pending") {
        return { status: "invalid_invitation" };
      }

      const existingMember = await transaction.mapMember.findUnique({
        where: {
          mapId_userId: {
            mapId: invitation.map_id,
            userId: input.userId,
          },
        },
        select: { userId: true },
      });

      if (existingMember) {
        return { status: "invalid_invitation" };
      }

      const memberCount = await transaction.mapMember.count({
        where: { mapId: invitation.map_id },
      });

      if (memberCount >= 2) {
        return { status: "map_full" };
      }

      await transaction.mapMember.create({
        data: {
          mapId: invitation.map_id,
          userId: input.userId,
          role: "member",
        },
      });

      await transaction.invitation.update({
        where: { id: invitation.id },
        data: { status: "accepted" },
      });

      const map = await transaction.memoryMap.findUniqueOrThrow({
        where: { id: invitation.map_id },
        select: this.mapSelect(input.now),
      });

      return {
        status: "accepted",
        map: this.mapFromRecord(map),
        membershipRole: "member",
      };
    });
  }

  async removeMember(mapId: string, userId: string): Promise<boolean> {
    const result = await this.prisma.mapMember.deleteMany({
      where: {
        mapId,
        userId,
        role: "member",
      },
    });

    return result.count > 0;
  }

  private async expirePendingInvitationsForUserMaps(
    userId: string,
    now: Date,
  ): Promise<void> {
    await this.prisma.invitation.updateMany({
      where: {
        status: "pending",
        expiresAt: {
          lte: now,
        },
        map: {
          members: {
            some: { userId },
          },
        },
      },
      data: {
        status: "expired",
      },
    });
  }

  private mapSelect(now: Date): {
    id: true;
    type: true;
    ownerId: true;
    members: {
      orderBy: {
        joinedAt: "asc";
      };
      select: {
        mapId: true;
        userId: true;
        role: true;
        joinedAt: true;
      };
    };
    invitations: {
      where: {
        status: "pending";
        expiresAt: {
          gt: Date;
        };
      };
      orderBy: {
        createdAt: "desc";
      };
      take: 1;
      select: {
        id: true;
        mapId: true;
        code: true;
        status: true;
        expiresAt: true;
        createdAt: true;
      };
    };
  } {
    return {
      id: true,
      type: true,
      ownerId: true,
      members: {
        orderBy: {
          joinedAt: "asc",
        },
        select: {
          mapId: true,
          userId: true,
          role: true,
          joinedAt: true,
        },
      },
      invitations: {
        where: {
          status: "pending",
          expiresAt: {
            gt: now,
          },
        },
        orderBy: {
          createdAt: "desc",
        },
        take: 1,
        select: {
          id: true,
          mapId: true,
          code: true,
          status: true,
          expiresAt: true,
          createdAt: true,
        },
      },
    };
  }

  private mapFromRecord(map: MapRecord): MapDto {
    return {
      id: map.id,
      type: this.mapType(map.type),
      ownerId: map.ownerId,
      name: null,
      members: map.members.map((member) => this.memberFromRecord(member)),
      pendingInvitation: map.invitations[0]
        ? this.invitationFromRecord(map.invitations[0])
        : null,
    };
  }

  private memberFromRecord(member: MemberRecord): MapMemberDto {
    return {
      mapId: member.mapId,
      userId: member.userId,
      role: this.memberRole(member.role),
      joinedAt: member.joinedAt.toISOString(),
    };
  }

  private invitationFromRecord(invitation: InvitationRecord): InvitationDto {
    return {
      id: invitation.id,
      mapId: invitation.mapId,
      code: invitation.code,
      status: this.invitationStatus(invitation.status),
      expiresAt: invitation.expiresAt.toISOString(),
      createdAt: invitation.createdAt.toISOString(),
    };
  }

  private mapType(value: string): MapType {
    return value === "duo" ? "duo" : "personal";
  }

  private memberRole(value: string): MapMemberRole {
    return value === "owner" ? "owner" : "member";
  }

  private invitationStatus(value: string): InvitationStatus {
    if (
      value === "pending" ||
      value === "accepted" ||
      value === "revoked" ||
      value === "expired"
    ) {
      return value;
    }

    return "expired";
  }

  private dateFromValue(value: Date | string): Date {
    return value instanceof Date ? value : new Date(value);
  }
}
