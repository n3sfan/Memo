import { defineConfig } from 'prisma/config';

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: {
    path: 'prisma/migrations',
  },
  datasource: {
    url:
      process.env.DATABASE_URL ??
      'postgresql://memory_map:change-me@127.0.0.1:5432/memory_map?schema=public',
  },
});
