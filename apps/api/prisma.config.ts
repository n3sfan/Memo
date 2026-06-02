import { defineConfig } from 'prisma/config';

import { resolvePrismaConnectionString } from './src/infra/prisma/database-url';

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: {
    path: 'prisma/migrations',
  },
  datasource: {
    url:
      resolvePrismaConnectionString() ??
      'postgresql://memory_map:change-me@127.0.0.1:5432/memory_map?schema=public',
  },
});
