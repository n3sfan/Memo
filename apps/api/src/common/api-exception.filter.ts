import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from '@nestjs/common';

import { ApiErrorBody } from './api-envelope';

interface HttpRequestLike {
  headers: Record<string, string | string[] | undefined>;
}

interface HttpResponseLike {
  status(statusCode: number): {
    json(body: ApiErrorBody): void;
  };
}

@Catch(HttpException)
export class ApiExceptionFilter implements ExceptionFilter<HttpException> {
  catch(exception: HttpException, host: ArgumentsHost): void {
    const http = host.switchToHttp();
    const request = http.getRequest<HttpRequestLike>();
    const response = http.getResponse<HttpResponseLike>();
    const status = exception.getStatus();

    response.status(status).json({
      error: this.errorCodeForStatus(status),
      message: this.messageFromException(exception),
      details: {},
      requestId: this.requestIdFromHeaders(request.headers),
    });
  }

  private errorCodeForStatus(status: number): string {
    if (status === HttpStatus.NOT_IMPLEMENTED) {
      return 'not_implemented';
    }
    if (status === HttpStatus.UNAUTHORIZED) {
      return 'unauthorized';
    }
    if (status === HttpStatus.FORBIDDEN) {
      return 'forbidden';
    }
    if (status === HttpStatus.PAYLOAD_TOO_LARGE) {
      return 'payload_too_large';
    }
    if (status === HttpStatus.UNPROCESSABLE_ENTITY) {
      return 'validation_error';
    }

    return 'unexpected_error';
  }

  private messageFromException(exception: HttpException): string {
    const response = exception.getResponse();
    if (typeof response === 'string') {
      return response;
    }
    if (
      typeof response === 'object' &&
      response !== null &&
      'message' in response
    ) {
      const message = response.message;
      if (Array.isArray(message)) {
        return message.join(', ');
      }
      if (typeof message === 'string') {
        return message;
      }
    }

    return exception.message;
  }

  private requestIdFromHeaders(
    headers: Record<string, string | string[] | undefined>,
  ): string {
    const requestId = headers['x-request-id'];
    if (Array.isArray(requestId)) {
      return requestId[0] ?? '';
    }

    return requestId ?? '';
  }
}
