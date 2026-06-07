import { Module } from '@nestjs/common';

import { AuthModule } from '../auth/auth.module';
import { AuthorizationModule } from '../authorization/authorization.module';
import { MapsController } from './maps.controller';
import { MAP_REPOSITORY, PrismaMapRepository } from './repositories';
import { MapsService } from './maps.service';

@Module({
  imports: [AuthModule, AuthorizationModule],
  controllers: [MapsController],
  providers: [
    PrismaMapRepository,
    {
      provide: MAP_REPOSITORY,
      useExisting: PrismaMapRepository,
    },
    MapsService,
  ],
  exports: [MapsService, MAP_REPOSITORY],
})
export class MapsModule {}
