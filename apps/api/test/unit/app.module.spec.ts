import { Test } from '@nestjs/testing';

import { AppModule } from '../../src/app.module';
import { HealthController } from '../../src/common/health.controller';

describe('AppModule', () => {
  it('wires the health controller', async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    expect(moduleRef.get(HealthController).check()).toEqual({ status: 'ok' });
  });
});
