import { PinDto } from '../../pins/dto/pins.dto';

export class TimelinePageDto {
  items!: PinDto[];
  nextCursor!: string | null;
  hasMore!: boolean;
}
