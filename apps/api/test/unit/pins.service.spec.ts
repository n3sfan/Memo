import { HttpStatus } from '@nestjs/common';

import { ApiException } from '../../src/common/api-error';
import { CurrentUser } from '../../src/modules/auth/current-user';
import { AuthorizationService } from '../../src/modules/authorization/authorization.service';
import {
  CreatePinRequestDto,
  PinDto,
  UpdatePinRequestDto,
} from '../../src/modules/pins/dto/pins.dto';
import { PinsService } from '../../src/modules/pins/pins.service';

interface PinsServiceUnderTest {
  createPin(
    user: CurrentUser,
    mapId: string,
    request: CreatePinRequestDto,
  ): Promise<PinDto>;
  updatePin(
    user: CurrentUser,
    pinId: string,
    request: UpdatePinRequestDto,
  ): Promise<PinDto>;
  deletePin(
    user: CurrentUser,
    pinId: string,
  ): Promise<{
    deleted: true;
  }>;
}

interface PinRepositoryMock {
  createPin: jest.Mock;
  updatePin: jest.Mock;
  deletePin: jest.Mock;
}

type AuthorizationMock = jest.Mocked<Pick<
  AuthorizationService,
  'assertCanCreatePin' | 'assertCanModifyPin'
>>;

describe('PinsService', () => {
  let authorization: AuthorizationMock;
  let pinRepository: PinRepositoryMock;
  let service: PinsServiceUnderTest;

  const user: CurrentUser = {
    id: '8fe3fd79-c605-4f2c-a022-849ef619f6fe',
    email: 'memo@example.com',
  };

  beforeEach(() => {
    authorization = {
      assertCanCreatePin: jest.fn(),
      assertCanModifyPin: jest.fn(),
    };
    pinRepository = {
      createPin: jest.fn(),
      updatePin: jest.fn(),
      deletePin: jest.fn(),
    };
    service = new (PinsService as unknown as new (
      repository: PinRepositoryMock,
      authorization: AuthorizationMock,
    ) => PinsServiceUnderTest)(pinRepository, authorization);
  });

  it('rejects invalid create coordinates before authorizing or persisting', async () => {
    await expect(
      service.createPin(user, 'map-1', {
        title: 'Invalid point',
        lat: 91,
        lng: 106.7,
      }),
    ).rejects.toMatchApiException(HttpStatus.UNPROCESSABLE_ENTITY, 'validation_error');

    expect(authorization.assertCanCreatePin).not.toHaveBeenCalled();
    expect(pinRepository.createPin).not.toHaveBeenCalled();
  });

  it('creates a pin through the repository and returns stored coordinates', async () => {
    const storedPin = pinDto({
      lat: 10.762622,
      lng: 106.660172,
    });
    pinRepository.createPin.mockResolvedValue(storedPin);

    await expect(
      service.createPin(user, 'map-1', {
        title: 'Cafe memory',
        note: 'Morning coffee',
        memoryDate: '2026-06-02T00:00:00.000Z',
        lat: 10.762622,
        lng: 106.660172,
        clientId: 'local_pin_1',
      }),
    ).resolves.toEqual(storedPin);

    expect(authorization.assertCanCreatePin).toHaveBeenCalledWith(
      user.id,
      'map-1',
    );
    expect(pinRepository.createPin).toHaveBeenCalledWith({
      mapId: 'map-1',
      createdBy: user.id,
      request: {
        title: 'Cafe memory',
        note: 'Morning coffee',
        memoryDate: '2026-06-02T00:00:00.000Z',
        lat: 10.762622,
        lng: 106.660172,
        clientId: 'local_pin_1',
      },
    });
  });

  it('rejects partial coordinate updates because geom needs a full point', async () => {
    await expect(
      service.updatePin(user, 'pin-1', {
        lat: 10.8,
      }),
    ).rejects.toMatchApiException(HttpStatus.UNPROCESSABLE_ENTITY, 'validation_error');

    expect(authorization.assertCanModifyPin).not.toHaveBeenCalled();
    expect(pinRepository.updatePin).not.toHaveBeenCalled();
  });

  it('does not update a pin when authorization rejects write access', async () => {
    authorization.assertCanModifyPin.mockRejectedValue(
      new ApiException(
        HttpStatus.FORBIDDEN,
        'forbidden',
        'You cannot modify this pin.',
      ),
    );

    await expect(
      service.updatePin(user, 'pin-1', {
        title: 'Changed title',
      }),
    ).rejects.toMatchApiException(HttpStatus.FORBIDDEN, 'forbidden');

    expect(authorization.assertCanModifyPin).toHaveBeenCalledWith(
      user.id,
      'pin-1',
    );
    expect(pinRepository.updatePin).not.toHaveBeenCalled();
  });

  it('deletes a pin through the repository after write authorization', async () => {
    pinRepository.deletePin.mockResolvedValue({
      deleted: true,
      removedMediaObjectKeys: ['users/user-1/pins/pin-1/photo.jpg'],
    });

    await expect(service.deletePin(user, 'pin-1')).resolves.toEqual({
      deleted: true,
    });

    expect(authorization.assertCanModifyPin).toHaveBeenCalledWith(
      user.id,
      'pin-1',
    );
    expect(pinRepository.deletePin).toHaveBeenCalledWith('pin-1');
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
    clientId: 'local_pin_1',
    ...overrides,
  };
}
