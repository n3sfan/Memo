import { Module } from '@nestjs/common';

import { PrismaModule } from '../../infra/prisma';
import { AuthorizationService } from './authorization.service';
import {
  ACCESS_CONTROL_REPOSITORY,
  PrismaAccessControlRepository,
} from './repositories';

@Module({
  imports: [PrismaModule],
  providers: [
    AuthorizationService,
    PrismaAccessControlRepository,
    {
      provide: ACCESS_CONTROL_REPOSITORY,
      useExisting: PrismaAccessControlRepository,
    },
  ],
  exports: [AuthorizationService],
})
export class AuthorizationModule {}
