export const KEY_VALUE_STORE = Symbol('KEY_VALUE_STORE');

export interface KeyValueStore {
  set(
    key: string,
    value: string,
    options?: { ttlSeconds?: number; onlyIfMissing?: boolean },
  ): Promise<boolean>;
  get(key: string): Promise<string | null>;
  getDel(key: string): Promise<string | null>;
  delete(key: string): Promise<void>;
}
