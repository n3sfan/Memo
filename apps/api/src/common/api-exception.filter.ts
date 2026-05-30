import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { randomUUID } from 'crypto';

import { ApiErrorCode, ApiException } from './api-error';
import { ApiErrorBody } from './api-envelope';

interface HttpRequestLike {
  headers: Record<string, string | string[] | undefined>;
}

interface HttpResponseLike {
  status(statusCode: number): {
    json(body: ApiErrorBody): void;
  };
}

@Catch()
export class ApiExceptionFilter implements ExceptionFilter<unknown> {
  catch(exception: unknown, host: ArgumentsHost): void {
    const http = host.switchToHttp();
    const request = http.getRequest<HttpRequestLike>();
    const response = http.getResponse<HttpResponseLike>();
    const status = this.statusFromException(exception);

    response.status(status).json({
      error: this.errorCodeFromException(exception, status),
      message: this.messageFromException(exception),
      details: this.detailsFromException(exception),
      requestId: this.requestIdFromHeaders(request.headers),
    });
  }

  private statusFromException(exception: unknown): number {
    if (exception instanceof HttpException) {
      return exception.getStatus();
    }

    return HttpStatus.INTERNAL_SERVER_ERROR;
  }

  private errorCodeFromException(
    exception: unknown,
    status: number,
  ): ApiErrorCode {
    if (exception instanceof ApiException) {
      return exception.apiErrorCode;
    }

    if (status === HttpStatus.NOT_IMPLEMENTED) {
      return 'not_implemented';
    }
    if (status === HttpStatus.UNAUTHORIZED) {
      return 'unauthorized';
    }
    if (status === HttpStatus.FORBIDDEN) {
      return 'forbidden';
    }
    if (status === HttpStatus.NOT_FOUND) {
      return 'not_found';
    }
    if (status === HttpStatus.CONFLICT) {
      return 'conflict';
    }
    if (status === HttpStatus.PAYLOAD_TOO_LARGE) {
      return 'payload_too_large';
    }
    if (
      status === HttpStatus.BAD_REQUEST ||
      status === HttpStatus.UNPROCESSABLE_ENTITY
    ) {
      return 'validation_error';
    }
    if (status >= HttpStatus.INTERNAL_SERVER_ERROR) {
      return 'internal_error';
    }

    return 'unexpected_error';
  }

  private messageFromException(exception: unknown): string {
    if (!(exception instanceof HttpException)) {
      return 'Internal server error.';
    }

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

  private detailsFromException(exception: unknown): Record<string, unknown> {
    if (exception instanceof ApiException) {
      return exception.details;
    }

    const response =
      exception instanceof HttpException ? exception.getResponse() : undefined;

    if (
      typeof response === 'object' &&
      response !== null &&
      'details' in response &&
      typeof response.details === 'object' &&
      response.details !== null &&
      !Array.isArray(response.details)
    ) {
      return response.details as Record<string, unknown>;
    }

    return {};
  }

  private requestIdFromHeaders(
    headers: Record<string, string | string[] | undefined>,
  ): string {
    const requestId = headers['x-request-id'];
    if (Array.isArray(requestId)) {
      return requestId[0] || this.generateRequestId();
    }

    return requestId || this.generateRequestId();
  }

  private generateRequestId(): string {
    return `req_${randomUUID()}`;
  }
}
