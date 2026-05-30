import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';

export function resolvePrismaConnectionString(
  env: NodeJS.ProcessEnv = process.env,
): string | undefined {
  if (env.DATABASE_URL?.trim()) {
    return env.DATABASE_URL;
  }

  const database = env.POSTGRES_DB;
  const user = env.POSTGRES_USER;
  const password = env.POSTGRES_PASSWORD;

  if (!database || !user || !password) {
    return undefined;
  }

  const host = env.POSTGRES_HOST ?? '127.0.0.1';
  const port = env.POSTGRES_HOST_PORT ?? env.POSTGRES_PORT ?? '5432';
  const schema = env.POSTGRES_SCHEMA ?? 'public';

  return `postgresql://${encodeURIComponent(user)}:${encodeURIComponent(
    password,
  )}@${host}:${port}/${encodeURIComponent(database)}?schema=${encodeURIComponent(
    schema,
  )}`;
}

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
