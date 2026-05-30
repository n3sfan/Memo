import { NotImplementedException } from '@nestjs/common';

export function notImplemented<TValue>(scope: string): TValue {
  throw new NotImplementedException(`${scope} is scaffolded but not implemented`);
}
