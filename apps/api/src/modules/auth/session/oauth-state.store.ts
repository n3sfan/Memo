import { Inject, Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';

import { KEY_VALUE_STORE, KeyValueStore } from '../../../infra/redis';
import { throwOAuthFailed } from '../../../common/api-error';
import { OAuthProvider } from '../dto/auth.dto';

interface StoredOAuthState {
  provider: OAuthProvider;
  redirectUri?: string;
}

@Injectable()
export class OAuthStateStore {
  private readonly ttlSeconds = 600;

  constructor(
    @Inject(KEY_VALUE_STORE) private readonly keyValueStore: KeyValueStore,
  ) {}

  async create(
    provider: OAuthProvider,
    redirectUri?: string,
  ): Promise<string> {
    const state = `oauth_${randomUUID()}`;
    await this.keyValueStore.set(
      this.key(state),
      JSON.stringify({ provider, redirectUri } satisfies StoredOAuthState),
      { ttlSeconds: this.ttlSeconds, onlyIfMissing: true },
    );
    return state;
  }

  async consume(
    state: string,
    provider: OAuthProvider,
    redirectUri?: string,
  ): Promise<void> {
    const encoded = await this.keyValueStore.getDel(this.key(state));
    if (!encoded) {
      throwOAuthFailed('OAuth state is invalid or expired.');
    }

    const stored = this.decode(encoded);
    if (stored.provider !== provider) {
      throwOAuthFailed('OAuth state provider mismatch.');
    }
    if (stored.redirectUri && stored.redirectUri !== redirectUri) {
      throwOAuthFailed('OAuth redirect URI mismatch.');
    }
  }

  private key(state: string): string {
    return `auth:oauth-state:${state}`;
  }

  private decode(encoded: string): StoredOAuthState {
    try {
      const value = JSON.parse(encoded) as Partial<StoredOAuthState>;
      if (value.provider === 'google' || value.provider === 'apple') {
        return {
          provider: value.provider,
          redirectUri:
            typeof value.redirectUri === 'string'
              ? value.redirectUri
              : undefined,
        };
      }
    } catch {
      // Fall through to OAuth failure below.
    }

    throwOAuthFailed('OAuth state is invalid or expired.');
  }
}
