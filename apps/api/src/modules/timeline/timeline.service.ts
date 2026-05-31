import { Inject, Injectable } from '@nestjs/common';

import { CursorQueryDto } from '../../common/dto/pagination.dto';
import { CurrentUser } from '../auth/current-user';
import { AuthorizationService } from '../authorization/authorization.service';
import {
  PIN_REPOSITORY,
  PinRepository,
} from '../pins/repositories';
import { TimelinePageDto } from './dto/timeline.dto';
import {
  decodeTimelineCursor,
  encodeTimelineCursor,
  normalizeTimelineLimit,
  normalizeTimelineOrder,
} from './timeline-cursor';

@Injectable()
export class TimelineService {
  constructor(
    @Inject(PIN_REPOSITORY)
    private readonly pinRepository: PinRepository,
    private readonly authorization: AuthorizationService,
  ) {}

  async listTimeline(
    user: CurrentUser,
    mapId: string,
    query: CursorQueryDto,
  ): Promise<TimelinePageDto> {
    await this.authorization.assertCanReadMap(user.id, mapId);

    const order = normalizeTimelineOrder(query.order);
    const limit = normalizeTimelineLimit(query.limit);
    const cursor = decodeTimelineCursor(query.cursor, order);
    const pins = await this.pinRepository.listTimelinePage(mapId, {
      order,
      cursor,
      limit: limit + 1,
    });
    const hasMore = pins.length > limit;
    const items = hasMore ? pins.slice(0, limit) : pins;
    const lastItem = items[items.length - 1];

    return {
      items,
      nextCursor: hasMore && lastItem ? encodeTimelineCursor(lastItem, order) : null,
      hasMore,
    };
  }
}
