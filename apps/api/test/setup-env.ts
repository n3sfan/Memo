process.env.DATABASE_URL ??=
  'postgresql://memory_map:test@127.0.0.1:5432/memory_map?schema=public';
process.env.JWT_ACCESS_SECRET ??= 'test-access-secret-32-bytes-minimum';
process.env.JWT_REFRESH_SECRET ??= 'test-refresh-secret-32-bytes-minimum';
