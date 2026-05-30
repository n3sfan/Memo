import { Injectable } from '@nestjs/common';

import { notImplemented } from '../../../common/not-implemented';
import {
  OAuthCallbackInput,
  OAuthCallbackResult,
  OAuthProviderClient,
  OAuthStartInput,
  OAuthStartResult,
} from './oauth-provider.port';

@Injectable()
export class GoogleOAuthProviderClient implements OAuthProviderClient {
  readonly provider = 'google' as const;

  start(input: OAuthStartInput): Promise<OAuthStartResult> {
    void input;

    return notImplemented('GoogleOAuthProviderClient.start');
  }

  complete(input: OAuthCallbackInput): Promise<OAuthCallbackResult> {
    void input;

    return notImplemented('GoogleOAuthProviderClient.complete');
  }
}
