import { Module } from '@nestjs/common';

import { R2Module } from '../../infra/r2';
import { AuthModule } from '../auth/auth.module';
import { AuthorizationModule } from '../authorization/authorization.module';
import { PinsController } from './pins.controller';
import { PIN_REPOSITORY, PrismaPinRepository } from './repositories';
import { PinsService } from './pins.service';

@Module({
  imports: [AuthModule, AuthorizationModule, R2Module],
  controllers: [PinsController],
  providers: [
    PinsService,
    PrismaPinRepository,
    {
      provide: PIN_REPOSITORY,
      useExisting: PrismaPinRepository,
    },
  ],
  exports: [PinsService],
})
export class PinsModule {}
