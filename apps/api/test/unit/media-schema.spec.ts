import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const apiRoot = join(__dirname, '..', '..');
const prismaSchemaPath = join(apiRoot, 'prisma', 'schema.prisma');
const migrationsPath = join(apiRoot, 'prisma', 'migrations');

function readMigrations(): string {
  return readdirSync(migrationsPath, { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => join(migrationsPath, entry.name, 'migration.sql'))
    .map((path) => readFileSync(path, 'utf8'))
    .join('\n');
}

describe('media schema storage policy', () => {
  it('stores media references and metadata without binary columns', () => {
    const schema = readFileSync(prismaSchemaPath, 'utf8');
    const migrations = readMigrations();
    const combined = `${schema}\n${migrations}`.toLowerCase();

    expect(combined).toContain('model mediafile');
    expect(combined).toContain('objectkey');
    expect(combined).toContain('object_key text not null');
    expect(combined).not.toMatch(/\b(bytea|blob|binary|bytes)\b/);
  });
});
