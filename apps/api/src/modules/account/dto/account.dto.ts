import { MapDto } from '../../maps/dto/maps.dto';
import { PinDto } from '../../pins/dto/pins.dto';

export class AccountExportDto {
  userId!: string;
  exportedAt!: string;
  maps!: MapDto[];
  pins!: PinDto[];
}

export class DeleteAccountResponseDto {
  deletionRequested!: true;
}
