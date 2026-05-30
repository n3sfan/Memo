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
export class AppleOAuthProviderClient implements OAuthProviderClient {
  readonly provider = 'apple' as const;

  start(input: OAuthStartInput): Promise<OAuthStartResult> {
    void input;

    return notImplemented('AppleOAuthProviderClient.start');
  }

  complete(input: OAuthCallbackInput): Promise<OAuthCallbackResult> {
    void input;

    return notImplemented('AppleOAuthProviderClient.complete');
  }
}
