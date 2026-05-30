import { Controller, Delete, Get, Headers, UseGuards } from '@nestjs/common';

import { ApiEnvelope, createEnvelope } from '../../common/api-envelope';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AccountService } from './account.service';
import { AccountExportDto, DeleteAccountResponseDto } from './dto/account.dto';

@UseGuards(JwtAuthGuard)
@Controller('account')
export class AccountController {
  constructor(private readonly accountService: AccountService) {}

  @Get('export')
  async exportAccount(
    @Headers('x-request-id') requestId?: string,
  ): Promise<ApiEnvelope<AccountExportDto>> {
    const data = await this.accountService.exportAccount();

    return createEnvelope(data, requestId);
  }

  @Delete()
  async deleteAccount(
    @Headers('x-request-id') requestId?: string,
  ): Promise<ApiEnvelope<DeleteAccountResponseDto>> {
    const data = await this.accountService.deleteAccount();

    return createEnvelope(data, requestId);
  }
}
