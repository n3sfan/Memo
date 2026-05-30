import { Injectable } from '@nestjs/common';

import { CursorQueryDto } from '../../common/dto/pagination.dto';
import { notImplemented } from '../../common/not-implemented';
import { TimelinePageDto } from './dto/timeline.dto';

@Injectable()
export class TimelineService {
  listTimeline(
    mapId: string,
    query: CursorQueryDto,
  ): Promise<TimelinePageDto> {
    void mapId;
    void query;

    return notImplemented('TimelineService.listTimeline');
  }
}
