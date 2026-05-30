import { Inject, Injectable } from '@nestjs/common';

import { throwValidationError } from '../../../common/api-error';
import { OAuthProvider } from '../dto/auth.dto';
import {
  OAUTH_PROVIDER_CLIENTS,
  OAuthProviderClient,
} from './oauth-provider.port';

@Injectable()
export class OAuthProviderRegistry {
  constructor(
    @Inject(OAUTH_PROVIDER_CLIENTS)
    private readonly clients: OAuthProviderClient[],
  ) {}

  get(provider: OAuthProvider): OAuthProviderClient {
    const client = this.clients.find((candidate) => {
      return candidate.provider === provider;
    });

    if (!client) {
      throwValidationError('Unsupported OAuth provider.', { provider });
    }

    return client;
  }
}
