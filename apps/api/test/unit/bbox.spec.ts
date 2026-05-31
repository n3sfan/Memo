import { HttpStatus } from '@nestjs/common';

import { ApiException } from '../../src/common/api-error';
import { parseBbox } from '../../src/modules/pins/bbox';

describe('parseBbox', () => {
  it('parses minLng,minLat,maxLng,maxLat', () => {
    expect(parseBbox('106.6,10.7,106.8,10.8')).toEqual({
      minLng: 106.6,
      minLat: 10.7,
      maxLng: 106.8,
      maxLat: 10.8,
    });
  });

  it.each([
    undefined,
    '',
    '106.6,10.7,106.8',
    '106.6,10.7,not-a-number,10.8',
    '106.8,10.7,106.6,10.8',
    '106.6,10.8,106.8,10.7',
    '-181,10.7,106.8,10.8',
    '106.6,-91,106.8,10.8',
  ])('rejects invalid bbox %p', (bbox) => {
    expect(() => parseBbox(bbox)).toThrowApiException(
      HttpStatus.UNPROCESSABLE_ENTITY,
      'validation_error',
    );
  });
});

expect.extend({
  toThrowApiException(
    received: () => unknown,
    status: HttpStatus,
    apiErrorCode: string,
  ) {
    try {
      received();
    } catch (error) {
      const pass =
        error instanceof ApiException &&
        error.getStatus() === status &&
        error.apiErrorCode === apiErrorCode;

      return {
        pass,
        message: () =>
          `expected thrown error to be ApiException(${status}, ${apiErrorCode})`,
      };
    }

    return {
      pass: false,
      message: () => 'expected function to throw',
    };
  },
});

declare global {
  namespace jest {
    interface Matchers<R> {
      toThrowApiException(status: HttpStatus, apiErrorCode: string): R;
    }
  }
}
