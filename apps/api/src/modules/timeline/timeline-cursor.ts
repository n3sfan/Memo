import { throwValidationError } from '../../common/api-error';
import { PinDto } from '../pins/dto/pins.dto';

export type TimelineOrder = 'asc' | 'desc';

export interface TimelineCursor {
  memoryDate: string | null;
  id: string;
  order: TimelineOrder;
}

export function normalizeTimelineOrder(order?: string): TimelineOrder {
  if (!order) {
    return 'desc';
  }

  if (order === 'asc' || order === 'desc') {
    return order;
  }

  throwValidationError('Invalid timeline order.', {
    order,
    allowed: ['asc', 'desc'],
  });
}

export function normalizeTimelineLimit(raw?: string): number {
  if (!raw) {
    return 50;
  }

  const limit = Number(raw);

  if (!Number.isInteger(limit) || limit < 1) {
    throwValidationError('Invalid timeline limit.', {
      limit: raw,
    });
  }

  return Math.min(limit, 100);
}

export function decodeTimelineCursor(
  raw: string | undefined,
  order: TimelineOrder,
): TimelineCursor | undefined {
  if (!raw) {
    return undefined;
  }

  try {
    const json = JSON.parse(
      Buffer.from(raw, 'base64url').toString('utf8'),
    ) as Partial<TimelineCursor>;

    if (
      (json.memoryDate !== null && typeof json.memoryDate !== 'string') ||
      typeof json.id !== 'string' ||
      (json.order !== 'asc' && json.order !== 'desc')
    ) {
      throw new Error('Invalid cursor payload.');
    }

    if (json.memoryDate !== null && Number.isNaN(Date.parse(json.memoryDate))) {
      throw new Error('Invalid cursor memoryDate.');
    }

    if (json.order !== order) {
      throwValidationError('Timeline cursor order does not match query order.', {
        cursorOrder: json.order,
        order,
      });
    }

    return {
      memoryDate: json.memoryDate,
      id: json.id,
      order: json.order,
    };
  } catch (error) {
    if (isApiExceptionLike(error)) {
      throw error;
    }

    throwValidationError('Invalid timeline cursor.', {
      cursor: raw,
    });
  }
}

export function encodeTimelineCursor(
  pin: Pick<PinDto, 'id' | 'memoryDate'>,
  order: TimelineOrder,
): string {
  const cursor: TimelineCursor = {
    memoryDate: pin.memoryDate ?? null,
    id: pin.id,
    order,
  };

  return Buffer.from(JSON.stringify(cursor), 'utf8').toString('base64url');
}

function isApiExceptionLike(error: unknown): boolean {
  return (
    typeof error === 'object' &&
    error !== null &&
    'apiErrorCode' in error
  );
}
