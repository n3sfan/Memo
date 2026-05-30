import { Module } from '@nestjs/common';

import { AppleOAuthProviderClient } from './apple-oauth-provider.client';
import { GoogleOAuthProviderClient } from './google-oauth-provider.client';
import { OAUTH_PROVIDER_CLIENTS } from './oauth-provider.port';
import { OAuthProviderRegistry } from './oauth-provider.registry';

@Module({
  providers: [
    AppleOAuthProviderClient,
    GoogleOAuthProviderClient,
    {
      provide: OAUTH_PROVIDER_CLIENTS,
      useFactory: (
        apple: AppleOAuthProviderClient,
        google: GoogleOAuthProviderClient,
      ) => {
        return [apple, google];
      },
      inject: [AppleOAuthProviderClient, GoogleOAuthProviderClient],
    },
    OAuthProviderRegistry,
  ],
  exports: [OAuthProviderRegistry],
})
export class OAuthProvidersModule {}
