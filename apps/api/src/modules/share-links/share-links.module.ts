import { Module } from '@nestjs/common';

import { R2Module } from '../../infra/r2';
import { AuthModule } from '../auth/auth.module';
import { AuthorizationModule } from '../authorization/authorization.module';
import {
  PrismaShareLinkRepository,
  SHARE_LINK_REPOSITORY,
} from './repositories';
import { ShareLinksController } from './share-links.controller';
import { ShareLinksService } from './share-links.service';

@Module({
  imports: [AuthModule, AuthorizationModule, R2Module],
  controllers: [ShareLinksController],
  providers: [
    PrismaShareLinkRepository,
    {
      provide: SHARE_LINK_REPOSITORY,
      useExisting: PrismaShareLinkRepository,
    },
    ShareLinksService,
  ],
  exports: [ShareLinksService],
})
export class ShareLinksModule {}
