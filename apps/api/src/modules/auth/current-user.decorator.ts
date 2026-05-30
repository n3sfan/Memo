import { createParamDecorator, ExecutionContext } from '@nestjs/common';

import type {
  CurrentUser as CurrentUserValue,
  RequestWithCurrentUser,
} from './current-user';

export const CurrentUser = createParamDecorator<
  keyof CurrentUserValue | undefined,
  CurrentUserValue | CurrentUserValue[keyof CurrentUserValue] | undefined
>((property, context) => {
  const request = context.switchToHttp().getRequest<RequestWithCurrentUser>();
  const user = request.user;

  if (!property) {
    return user;
  }

  return user?.[property];
});
