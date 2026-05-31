import { Module } from '@nestjs/common';

import { AuthModule } from '../auth/auth.module';
import { AuthorizationModule } from '../authorization/authorization.module';
import { PinsController } from './pins.controller';
import { PIN_REPOSITORY, PrismaPinRepository } from './repositories';
import { PinsService } from './pins.service';

@Module({
  imports: [AuthModule, AuthorizationModule],
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
