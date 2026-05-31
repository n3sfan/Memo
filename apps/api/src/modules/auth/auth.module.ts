import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';

import { PrismaModule } from '../../infra/prisma';
import { RedisModule } from '../../infra/redis';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './jwt-auth.guard';
import { OAuthProvidersModule } from './oauth';
import {
  AUTH_USER_REPOSITORY,
  PrismaAuthUserRepository,
} from './repositories';
import { AuthTokenService, OAuthStateStore } from './session';

@Module({
  imports: [JwtModule.register({}), OAuthProvidersModule, PrismaModule, RedisModule],
  controllers: [AuthController],
  providers: [
    AuthService,
    AuthTokenService,
    OAuthStateStore,
    JwtAuthGuard,
    PrismaAuthUserRepository,
    {
      provide: AUTH_USER_REPOSITORY,
      useExisting: PrismaAuthUserRepository,
    },
  ],
  exports: [AuthService, AuthTokenService, JwtAuthGuard, JwtModule],
})
export class AuthModule {}
