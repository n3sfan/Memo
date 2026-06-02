import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { createConnection, Socket } from 'net';

import { KeyValueStore } from './key-value-store.port';

type RedisValue = string | number | null;

@Injectable()
export class RedisKeyValueStore implements KeyValueStore, OnModuleDestroy {
  private readonly sockets = new Set<Socket>();
  private readonly redisUrl: URL;

  constructor(redisUrl = process.env.REDIS_URL ?? 'redis://127.0.0.1:6379/0') {
    this.redisUrl = new URL(redisUrl);
  }

  async set(
    key: string,
    value: string,
    options: { ttlSeconds?: number; onlyIfMissing?: boolean } = {},
  ): Promise<boolean> {
    const args = ['SET', key, value];
    if (options.ttlSeconds) {
      args.push('EX', String(Math.max(1, Math.ceil(options.ttlSeconds))));
    }
    if (options.onlyIfMissing) {
      args.push('NX');
    }

    return (await this.command(args)) === 'OK';
  }

  async get(key: string): Promise<string | null> {
    const value = await this.command(['GET', key]);
    return typeof value === 'string' ? value : null;
  }

  async getDel(key: string): Promise<string | null> {
    const value = await this.command(['GETDEL', key]);
    return typeof value === 'string' ? value : null;
  }

  async delete(key: string): Promise<void> {
    await this.command(['DEL', key]);
  }

  onModuleDestroy(): void {
    for (const socket of this.sockets) {
      socket.destroy();
    }
    this.sockets.clear();
  }

  private command(args: string[]): Promise<RedisValue> {
    return new Promise((resolve, reject) => {
      const socket = createConnection({
        host: this.redisUrl.hostname,
        port: Number(this.redisUrl.port || 6379),
      });
      this.sockets.add(socket);
      let buffer = Buffer.alloc(0);
      const timeout = setTimeout(() => {
        socket.destroy();
        reject(new Error('Redis command timed out.'));
      }, 5000);

      const cleanup = (): void => {
        clearTimeout(timeout);
        this.sockets.delete(socket);
        socket.destroy();
      };

      socket.once('error', (error) => {
        cleanup();
        reject(error);
      });
      socket.on('data', (chunk) => {
        buffer = Buffer.concat([buffer, chunk]);
        const parsed = this.tryParse(buffer);
        if (!parsed.complete) {
          return;
        }
        cleanup();
        if (parsed.error) {
          reject(parsed.error);
        } else {
          resolve(parsed.value);
        }
      });
      socket.once('connect', () => {
        socket.write(this.encode(args));
      });
    });
  }

  private encode(args: string[]): string {
    return `*${args.length}\r\n${args
      .map((arg) => `$${Buffer.byteLength(arg)}\r\n${arg}\r\n`)
      .join('')}`;
  }

  private tryParse(buffer: Buffer):
    | { complete: false }
    | { complete: true; value: RedisValue; error?: undefined }
    | { complete: true; value?: undefined; error: Error } {
    if (buffer.length < 3) {
      return { complete: false };
    }

    const type = String.fromCharCode(buffer[0]);
    const lineEnd = buffer.indexOf('\r\n');
    if (lineEnd < 0) {
      return { complete: false };
    }
    const line = buffer.subarray(1, lineEnd).toString('utf8');

    if (type === '+') {
      return { complete: true, value: line };
    }
    if (type === '-') {
      return { complete: true, error: new Error(line) };
    }
    if (type === ':') {
      return { complete: true, value: Number(line) };
    }
    if (type === '$') {
      const length = Number(line);
      if (length === -1) {
        return { complete: true, value: null };
      }
      const start = lineEnd + 2;
      const end = start + length;
      if (buffer.length < end + 2) {
        return { complete: false };
      }
      return {
        complete: true,
        value: buffer.subarray(start, end).toString('utf8'),
      };
    }

    return { complete: true, error: new Error('Unsupported Redis response.') };
  }
}
