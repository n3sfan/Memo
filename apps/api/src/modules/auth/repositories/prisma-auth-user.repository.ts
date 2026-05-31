import { Injectable } from '@nestjs/common';

import { PrismaService } from '../../../infra/prisma';
import { OAuthUserProfile } from '../oauth';
import {
  AuthUserRecord,
  AuthUserRepository,
  UpsertAuthUserResult,
} from './auth-user.repository';

interface UserRecord {
  id: string;
  provider: string;
  providerUserId: string;
  email: string | null;
  displayName: string | null;
}

@Injectable()
export class PrismaAuthUserRepository implements AuthUserRepository {
  constructor(private readonly prisma: PrismaService) {}

  async upsertOAuthUser(
    profile: OAuthUserProfile,
  ): Promise<UpsertAuthUserResult> {
    const existing = await this.prisma.user.findUnique({
      where: {
        provider_providerUserId: {
          provider: profile.provider,
          providerUserId: profile.providerUserId,
        },
      },
      select: this.userSelect(),
    });

    if (existing) {
      const user = await this.prisma.user.update({
        where: { id: existing.id },
        data: {
          email: profile.email,
          displayName: profile.displayName,
          deletedAt: null,
        },
        select: this.userSelect(),
      });

      return { user: this.toRecord(user), created: false };
    }

    const user = await this.prisma.$transaction(async (transaction) => {
      const created = await transaction.user.create({
        data: {
          provider: profile.provider,
          providerUserId: profile.providerUserId,
          email: profile.email,
          displayName: profile.displayName,
        },
        select: this.userSelect(),
      });

      await transaction.memoryMap.create({
        data: {
          type: 'personal',
          ownerId: created.id,
          members: {
            create: {
              userId: created.id,
              role: 'owner',
            },
          },
        },
        select: { id: true },
      });

      return created;
    });

    return { user: this.toRecord(user), created: true };
  }

  private userSelect(): {
    id: true;
    provider: true;
    providerUserId: true;
    email: true;
    displayName: true;
  } {
    return {
      id: true,
      provider: true,
      providerUserId: true,
      email: true,
      displayName: true,
    };
  }

  private toRecord(user: UserRecord): AuthUserRecord {
    return {
      id: user.id,
      provider: user.provider,
      providerUserId: user.providerUserId,
      email: user.email,
      displayName: user.displayName,
      avatarUrl: null,
    };
  }
}
