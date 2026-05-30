import { Module } from '@nestjs/common';

import { HealthController } from './common/health.controller';
import { AccountModule } from './modules/account/account.module';
import { AuthModule } from './modules/auth/auth.module';
import { AuthorizationModule } from './modules/authorization/authorization.module';
import { MapsModule } from './modules/maps/maps.module';
import { MediaModule } from './modules/media/media.module';
import { PinsModule } from './modules/pins/pins.module';
import { ShareLinksModule } from './modules/share-links/share-links.module';
import { TimelineModule } from './modules/timeline/timeline.module';

@Module({
  imports: [
    AccountModule,
    AuthModule,
    AuthorizationModule,
    MapsModule,
    MediaModule,
    PinsModule,
    ShareLinksModule,
    TimelineModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}
