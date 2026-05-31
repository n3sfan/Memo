import { HttpStatus } from '@nestjs/common';

import { ApiException } from '../../src/common/api-error';
import { CurrentUser } from '../../src/modules/auth/current-user';
import { AuthorizationService } from '../../src/modules/authorization/authorization.service';
import { PinDto } from '../../src/modules/pins/dto/pins.dto';
import { PinRepository } from '../../src/modules/pins/repositories';
import { TimelineService } from '../../src/modules/timeline/timeline.service';
import {
  decodeTimelineCursor,
  encodeTimelineCursor,
} from '../../src/modules/timeline/timeline-cursor';

describe('TimelineService', () => {
  let authorization: jest.Mocked<Pick<AuthorizationService, 'assertCanReadMap'>>;
  let pinRepository: jest.Mocked<Pick<PinRepository, 'listTimelinePage'>>;
  let service: TimelineService;

  const user: CurrentUser = {
    id: '8fe3fd79-c605-4f2c-a022-849ef619f6fe',
    email: 'memo@example.com',
  };

  beforeEach(() => {
    authorization = {
      assertCanReadMap: jest.fn(),
    };
    pinRepository = {
      listTimelinePage: jest.fn(),
    };
    service = new TimelineService(
      pinRepository as unknown as PinRepository,
      authorization as unknown as AuthorizationService,
    );
  });

  it('lists a timeline page with default desc order and limit', async () => {
    const pins = [pinDto({ id: 'pin-1' })];
    pinRepository.listTimelinePage.mockResolvedValue(pins);

    await expect(
      service.listTimeline(user, 'map-1', {}),
    ).resolves.toEqual({
      items: pins,
      nextCursor: null,
      hasMore: false,
    });

    expect(authorization.assertCanReadMap).toHaveBeenCalledWith(
      user.id,
      'map-1',
    );
    expect(pinRepository.listTimelinePage).toHaveBeenCalledWith('map-1', {
      order: 'desc',
      cursor: undefined,
      limit: 51,
    });
  });

  it('returns an opaque next cursor when another page exists', async () => {
    const visible = pinDto({
      id: '11111111-1111-4111-8111-111111111111',
      memoryDate: '2026-06-02T00:00:00.000Z',
    });
    pinRepository.listTimelinePage.mockResolvedValue([
      visible,
      pinDto({
        id: '22222222-2222-4222-8222-222222222222',
        memoryDate: '2026-06-01T00:00:00.000Z',
      }),
    ]);

    const page = await service.listTimeline(user, 'map-1', {
      limit: '1',
    });

    expect(page.items).toEqual([visible]);
    expect(page.hasMore).toBe(true);
    expect(decodeTimelineCursor(page.nextCursor ?? undefined, 'desc')).toEqual({
      memoryDate: visible.memoryDate,
      id: visible.id,
      order: 'desc',
    });
  });

  it('passes decoded cursors through to the repository', async () => {
    const cursor = encodeTimelineCursor(
      pinDto({
        id: '11111111-1111-4111-8111-111111111111',
        memoryDate: null,
      }),
      'asc',
    );
    pinRepository.listTimelinePage.mockResolvedValue([]);

    await service.listTimeline(user, 'map-1', {
      cursor,
      order: 'asc',
      limit: '25',
    });

    expect(pinRepository.listTimelinePage).toHaveBeenCalledWith('map-1', {
      order: 'asc',
      cursor: {
        memoryDate: null,
        id: '11111111-1111-4111-8111-111111111111',
        order: 'asc',
      },
      limit: 26,
    });
  });

  it('rejects cursor/order mismatches', async () => {
    const cursor = encodeTimelineCursor(pinDto(), 'asc');

    await expect(
      service.listTimeline(user, 'map-1', {
        cursor,
        order: 'desc',
      }),
    ).rejects.toMatchApiException(
      HttpStatus.UNPROCESSABLE_ENTITY,
      'validation_error',
    );

    expect(pinRepository.listTimelinePage).not.toHaveBeenCalled();
  });
});

expect.extend({
  toMatchApiException(
    received: unknown,
    status: HttpStatus,
    apiErrorCode: string,
  ) {
    const pass =
      received instanceof ApiException &&
      received.getStatus() === status &&
      received.apiErrorCode === apiErrorCode;

    return {
      pass,
      message: () =>
        `expected ${String(received)} to be ApiException(${status}, ${apiErrorCode})`,
    };
  },
});

declare global {
  namespace jest {
    interface Matchers<R> {
      toMatchApiException(status: HttpStatus, apiErrorCode: string): R;
    }
  }
}

function pinDto(overrides: Partial<PinDto> = {}): PinDto {
  return {
    id: 'pin-1',
    mapId: 'map-1',
    title: 'Cafe memory',
    note: 'Morning coffee',
    memoryDate: '2026-06-02T00:00:00.000Z',
    lat: 10.762622,
    lng: 106.660172,
    media: [],
    createdAt: '2026-06-02T10:00:00.000Z',
    updatedAt: '2026-06-02T10:00:00.000Z',
    clientId: null,
    ...overrides,
  };
}
