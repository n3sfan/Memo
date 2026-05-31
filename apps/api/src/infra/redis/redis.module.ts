import { Global, Module } from '@nestjs/common';

import { KEY_VALUE_STORE } from './key-value-store.port';
import { RedisKeyValueStore } from './redis-key-value.store';

@Global()
@Module({
  providers: [
    {
      provide: KEY_VALUE_STORE,
      useFactory: () => new RedisKeyValueStore(process.env.REDIS_URL),
    },
  ],
  exports: [KEY_VALUE_STORE],
})
export class RedisModule {}
