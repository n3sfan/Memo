import { Controller, Get, Headers, Param, Query, UseGuards } from '@nestjs/common';

import { ApiEnvelope, createEnvelope } from '../../common/api-envelope';
import { CursorQueryDto } from '../../common/dto/pagination.dto';
import { CurrentUser as CurrentUserValue } from '../auth/current-user';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { TimelinePageDto } from './dto/timeline.dto';
import { TimelineService } from './timeline.service';

@UseGuards(JwtAuthGuard)
@Controller()
export class TimelineController {
  constructor(private readonly timelineService: TimelineService) {}

  @Get('maps/:mapId/timeline')
  async listTimeline(
    @CurrentUser() user: CurrentUserValue,
    @Param('mapId') mapId: string,
    @Query() query: CursorQueryDto,
    @Headers('x-request-id') requestId?: string,
  ): Promise<ApiEnvelope<TimelinePageDto>> {
    const data = await this.timelineService.listTimeline(user, mapId, query);

    return createEnvelope(data, requestId);
  }
}
