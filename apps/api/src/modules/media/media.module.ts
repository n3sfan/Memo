import { Module } from '@nestjs/common';

import { PrismaModule } from '../../infra/prisma';
import { R2Module } from '../../infra/r2';
import { AuthModule } from '../auth/auth.module';
import { AuthorizationModule } from '../authorization/authorization.module';
import { MediaController } from './media.controller';
import { MediaService } from './media.service';
import {
  MEDIA_REPOSITORY,
  PrismaMediaRepository,
} from './repositories';

@Module({
  imports: [AuthModule, AuthorizationModule, PrismaModule, R2Module],
  controllers: [MediaController],
  providers: [
    PrismaMediaRepository,
    {
      provide: MEDIA_REPOSITORY,
      useExisting: PrismaMediaRepository,
    },
    MediaService,
  ],
  exports: [MediaService],
})
export class MediaModule {}
