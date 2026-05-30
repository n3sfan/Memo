import { Module } from '@nestjs/common';

import { PrismaModule } from '../../infra/prisma';
import { AuthorizationService } from './authorization.service';

@Module({
  imports: [PrismaModule],
  providers: [AuthorizationService],
  exports: [AuthorizationService],
})
export class AuthorizationModule {}
