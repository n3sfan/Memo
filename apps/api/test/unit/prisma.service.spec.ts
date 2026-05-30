import { resolvePrismaConnectionString } from '../../src/infra/prisma/prisma.service';

describe('resolvePrismaConnectionString', () => {
  it('uses DATABASE_URL when provided', () => {
    expect(
      resolvePrismaConnectionString({
        DATABASE_URL: 'postgresql://direct-url',
        POSTGRES_DB: 'memory_map',
        POSTGRES_USER: 'memory_map',
        POSTGRES_PASSWORD: 'secret',
      }),
    ).toBe('postgresql://direct-url');
  });

  it('derives a local Postgres URL from docker env keys', () => {
    expect(
      resolvePrismaConnectionString({
        POSTGRES_DB: 'memory_map',
        POSTGRES_USER: 'memory_map',
        POSTGRES_PASSWORD: 'secret value',
        POSTGRES_HOST_PORT: '55432',
      }),
    ).toBe(
      'postgresql://memory_map:secret%20value@127.0.0.1:55432/memory_map?schema=public',
    );
  });

  it('returns undefined when required database keys are missing', () => {
    expect(
      resolvePrismaConnectionString({
        POSTGRES_DB: 'memory_map',
        POSTGRES_USER: 'memory_map',
      }),
    ).toBeUndefined();
  });
});
