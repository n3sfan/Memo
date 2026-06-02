import { Injectable } from '@nestjs/common';

import { KeyValueStore } from './key-value-store.port';

interface Entry {
  value: string;
  expiresAt: number | null;
}

@Injectable()
export class InMemoryKeyValueStore implements KeyValueStore {
  private readonly entries = new Map<string, Entry>();

  async set(
    key: string,
    value: string,
    options: { ttlSeconds?: number; onlyIfMissing?: boolean } = {},
  ): Promise<boolean> {
    this.deleteExpired(key);
    if (options.onlyIfMissing && this.entries.has(key)) {
      return false;
    }

    this.entries.set(key, {
      value,
      expiresAt: options.ttlSeconds
        ? Date.now() + options.ttlSeconds * 1000
        : null,
    });
    return true;
  }

  async get(key: string): Promise<string | null> {
    this.deleteExpired(key);
    return this.entries.get(key)?.value ?? null;
  }

  async getDel(key: string): Promise<string | null> {
    const value = await this.get(key);
    this.entries.delete(key);
    return value;
  }

  async delete(key: string): Promise<void> {
    this.entries.delete(key);
  }

  private deleteExpired(key: string): void {
    const entry = this.entries.get(key);
    if (entry?.expiresAt !== null && entry?.expiresAt !== undefined) {
      if (entry.expiresAt <= Date.now()) {
        this.entries.delete(key);
      }
    }
  }
}
