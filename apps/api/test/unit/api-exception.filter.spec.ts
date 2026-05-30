import {
  ArgumentsHost,
  HttpException,
  HttpStatus,
  NotFoundException,
} from '@nestjs/common';

import { ApiException } from '../../src/common/api-error';
import { ApiExceptionFilter } from '../../src/common/api-exception.filter';

describe('ApiExceptionFilter', () => {
  let filter: ApiExceptionFilter;

  beforeEach(() => {
    filter = new ApiExceptionFilter();
  });

  it('uses ApiException code, details and request id when available', () => {
    const { host, status, json } = createHost({
      'x-request-id': 'req_existing',
    });

    filter.catch(
      new ApiException(HttpStatus.CONFLICT, 'conflict', 'Already exists.', {
        field: 'email',
      }),
      host,
    );

    expect(status).toHaveBeenCalledWith(HttpStatus.CONFLICT);
    expect(json).toHaveBeenCalledWith({
      error: 'conflict',
      message: 'Already exists.',
      details: {
        field: 'email',
      },
      requestId: 'req_existing',
    });
  });

  it('maps standard http exceptions to contract error codes', () => {
    const { host, json } = createHost({});

    filter.catch(new NotFoundException('Missing map.'), host);

    expect(json).toHaveBeenCalledWith(
      expect.objectContaining({
        error: 'not_found',
        message: 'Missing map.',
        details: {},
      }),
    );
    expect(json.mock.calls[0][0].requestId).toMatch(/^req_/);
  });

  it('hides raw unknown errors behind internal_error', () => {
    const { host, status, json } = createHost({});

    filter.catch(new Error('database password leaked'), host);

    expect(status).toHaveBeenCalledWith(HttpStatus.INTERNAL_SERVER_ERROR);
    expect(json).toHaveBeenCalledWith(
      expect.objectContaining({
        error: 'internal_error',
        message: 'Internal server error.',
      }),
    );
  });

  it('maps generic HttpException 500 to internal_error', () => {
    const { host, json } = createHost({});

    filter.catch(
      new HttpException('Unexpected failure.', HttpStatus.INTERNAL_SERVER_ERROR),
      host,
    );

    expect(json).toHaveBeenCalledWith(
      expect.objectContaining({
        error: 'internal_error',
        message: 'Unexpected failure.',
      }),
    );
  });
});

function createHost(headers: Record<string, string | undefined>): {
  host: ArgumentsHost;
  status: jest.Mock;
  json: jest.Mock;
} {
  const json = jest.fn();
  const status = jest.fn(() => ({
    json,
  }));

  return {
    host: {
      switchToHttp: () => ({
        getRequest: () => ({
          headers,
        }),
        getResponse: () => ({
          status,
        }),
      }),
    } as ArgumentsHost,
    status,
    json,
  };
}
