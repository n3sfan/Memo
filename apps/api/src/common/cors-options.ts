import { CorsOptions } from '@nestjs/common/interfaces/external/cors-options.interface';

const LOCAL_WEB_ORIGIN_PATTERN = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/;

export function buildCorsOptions(): CorsOptions {
  const allowedOrigins = configuredCorsOrigins();

  return {
    origin(origin, callback) {
      if (!origin || isAllowedOrigin(origin, allowedOrigins)) {
        callback(null, true);
        return;
      }

      callback(new Error('CORS origin is not allowed'), false);
    },
    methods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['content-type', 'authorization', 'x-request-id'],
  };
}

export function isAllowedOrigin(
  origin: string,
  configuredOrigins = configuredCorsOrigins(),
): boolean {
  return configuredOrigins.has(origin) || LOCAL_WEB_ORIGIN_PATTERN.test(origin);
}

function configuredCorsOrigins(): Set<string> {
  const raw = process.env.CORS_ORIGINS ?? '';

  return new Set(
    raw
      .split(',')
      .map((origin) => origin.trim())
      .filter(Boolean),
  );
}
