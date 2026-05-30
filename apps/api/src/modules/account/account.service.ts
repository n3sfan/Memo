import { Injectable } from '@nestjs/common';

import { notImplemented } from '../../common/not-implemented';
import { AccountExportDto, DeleteAccountResponseDto } from './dto/account.dto';

@Injectable()
export class AccountService {
  exportAccount(): Promise<AccountExportDto> {
    return notImplemented('AccountService.exportAccount');
  }

  deleteAccount(): Promise<DeleteAccountResponseDto> {
    return notImplemented('AccountService.deleteAccount');
  }
}
