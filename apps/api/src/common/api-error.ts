import { HttpException, HttpStatus } from '@nestjs/common';

export type ApiErrorCode =
  | 'oauth_failed'
  | 'unauthorized'
  | 'forbidden'
  | 'not_found'
  | 'validation_error'
  | 'conflict'
  | 'internal_error'
  | 'payload_too_large'
  | 'not_implemented'
  | 'invitation_pending_exists'
  | 'invalid_invitation'
  | 'map_full'
  | 'link_revoked'
  | 'unexpected_error';

export type ApiErrorDetails = Record<string, unknown>;

export class ApiException extends HttpException {
  constructor(
    status: HttpStatus,
    readonly apiErrorCode: ApiErrorCode,
    message: string,
    readonly details: ApiErrorDetails = {},
  ) {
    super(
      {
        error: apiErrorCode,
        message,
        details,
      },
      status,
    );
  }
}

export function throwUnauthorized(
  message = 'Authentication is required.',
  details: ApiErrorDetails = {},
): never {
  throw new ApiException(
    HttpStatus.UNAUTHORIZED,
    'unauthorized',
    message,
    details,
  );
}

export function throwForbidden(
  message = 'You do not have access to this resource.',
  details: ApiErrorDetails = {},
): never {
  throw new ApiException(HttpStatus.FORBIDDEN, 'forbidden', message, details);
}

export function throwNotFound(
  message = 'Resource not found.',
  details: ApiErrorDetails = {},
): never {
  throw new ApiException(HttpStatus.NOT_FOUND, 'not_found', message, details);
}

export function throwValidationError(
  message = 'Validation failed.',
  details: ApiErrorDetails = {},
): never {
  throw new ApiException(
    HttpStatus.UNPROCESSABLE_ENTITY,
    'validation_error',
    message,
    details,
  );
}

export function throwConflict(
  message = 'Resource conflict.',
  details: ApiErrorDetails = {},
): never {
  throw new ApiException(HttpStatus.CONFLICT, 'conflict', message, details);
}

export function throwInternalError(
  message = 'Internal server error.',
  details: ApiErrorDetails = {},
): never {
  throw new ApiException(
    HttpStatus.INTERNAL_SERVER_ERROR,
    'internal_error',
    message,
    details,
  );
}

export function throwPayloadTooLarge(
  message = 'Payload too large.',
  details: ApiErrorDetails = {},
): never {
  throw new ApiException(
    HttpStatus.PAYLOAD_TOO_LARGE,
    'payload_too_large',
    message,
    details,
  );
}
