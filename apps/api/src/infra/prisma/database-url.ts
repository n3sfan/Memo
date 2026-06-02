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
