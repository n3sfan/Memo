import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const migrationPath = join(
  __dirname,
  '..',
  '..',
  'prisma',
  'migrations',
  '20260529170000_init_schema',
  'migration.sql',
);

describe('database baseline migration', () => {
  const migration = readFileSync(migrationPath, 'utf8').toLowerCase();

  it('enables PostGIS and defines the pin geometry column', () => {
    expect(migration).toContain('create extension if not exists postgis');
    expect(migration).toContain('geom geometry(point, 4326) not null');
  });

  it('enforces coordinate and text-enum constraints', () => {
    expect(migration).toContain('check (lat between -90 and 90)');
    expect(migration).toContain('check (lng between -180 and 180)');
    expect(migration).toContain("check (type in ('personal', 'duo'))");
    expect(migration).toContain("check (role in ('owner', 'member'))");
    expect(migration).toContain("check (status in ('pending', 'ready'))");
  });

  it('creates required spatial, timeline, and invitation indexes', () => {
    expect(migration).toContain('create index idx_pins_geom on pins using gist (geom)');
    expect(migration).toContain(
      'create index idx_pins_map_memory on pins (map_id, memory_date desc)',
    );
    expect(migration).toContain('create unique index uniq_pending_invitation');
    expect(migration).toContain("where status = 'pending'");
  });
});
