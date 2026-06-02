import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';

import { resolvePrismaConnectionString } from './database-url';
export { resolvePrismaConnectionString } from './database-url';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  constructor() {
    const connectionString = resolvePrismaConnectionString();

    if (!connectionString) {
      throw new Error(
        'DATABASE_URL or POSTGRES_DB, POSTGRES_USER, and POSTGRES_PASSWORD are required to initialize PrismaService',
      );
    }

    super({
      adapter: new PrismaPg({ connectionString }),
    });
  }

  async onModuleInit(): Promise<void> {
    await this.$connect();
  }

  async onModuleDestroy(): Promise<void> {
    await this.$disconnect();
  }
}
