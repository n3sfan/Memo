import { HttpStatus } from '@nestjs/common';

import { ApiException } from '../../src/common/api-error';
import { ObjectStoragePort } from '../../src/infra/r2';
import { CurrentUser } from '../../src/modules/auth/current-user';
import { AuthorizationService } from '../../src/modules/authorization/authorization.service';
import {
  CreatePinRequestDto,
  PinsListResponseDto,
  PinDto,
  UpdatePinRequestDto,
} from '../../src/modules/pins/dto/pins.dto';
import { PinsService } from '../../src/modules/pins/pins.service';

interface PinsServiceUnderTest {
  listByBbox(
    user: CurrentUser,
    mapId: string,
    query: {
      bbox?: string;
    },
  ): Promise<PinsListResponseDto>;
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
  listPinsInBbox: jest.Mock;
  listTimelinePage: jest.Mock;
  createPin: jest.Mock;
  updatePin: jest.Mock;
  deletePin: jest.Mock;
}

type AuthorizationMock = jest.Mocked<Pick<
  AuthorizationService,
  'assertCanReadMap' | 'assertCanCreatePin' | 'assertCanModifyPin'
>>;

describe('PinsService', () => {
  let authorization: AuthorizationMock;
  let objectStorage: jest.Mocked<Pick<ObjectStoragePort, 'deleteObject'>>;
  let pinRepository: PinRepositoryMock;
  let service: PinsServiceUnderTest;

  const user: CurrentUser = {
    id: '8fe3fd79-c605-4f2c-a022-849ef619f6fe',
    email: 'memo@example.com',
  };

  beforeEach(() => {
    authorization = {
      assertCanReadMap: jest.fn(),
      assertCanCreatePin: jest.fn(),
      assertCanModifyPin: jest.fn(),
    };
    objectStorage = {
      deleteObject: jest.fn(),
    };
    pinRepository = {
      listPinsInBbox: jest.fn(),
      listTimelinePage: jest.fn(),
      createPin: jest.fn(),
      updatePin: jest.fn(),
      deletePin: jest.fn(),
    };
    service = new (PinsService as unknown as new (
      repository: PinRepositoryMock,
      authorization: AuthorizationMock,
      objectStorage: jest.Mocked<Pick<ObjectStoragePort, 'deleteObject'>>,
    ) => PinsServiceUnderTest)(pinRepository, authorization, objectStorage);
  });

  it('lists viewport pins after authorizing map read access', async () => {
    const pins = [
      pinDto({
        id: 'pin-in-bbox',
        lat: 10.7769,
        lng: 106.7009,
      }),
    ];
    pinRepository.listPinsInBbox.mockResolvedValue(pins);

    await expect(
      service.listByBbox(user, 'map-1', {
        bbox: '106.6,10.7,106.8,10.8',
      }),
    ).resolves.toEqual({
      pins,
    });

    expect(authorization.assertCanReadMap).toHaveBeenCalledWith(
      user.id,
      'map-1',
    );
    expect(pinRepository.listPinsInBbox).toHaveBeenCalledWith('map-1', {
      minLng: 106.6,
      minLat: 10.7,
      maxLng: 106.8,
      maxLat: 10.8,
    });
  });

  it('rejects invalid bbox values before querying pins', async () => {
    await expect(
      service.listByBbox(user, 'map-1', {
        bbox: '106.8,10.7,106.6,10.8',
      }),
    ).rejects.toMatchApiException(HttpStatus.UNPROCESSABLE_ENTITY, 'validation_error');

    expect(pinRepository.listPinsInBbox).not.toHaveBeenCalled();
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

  it('removes linked media objects after deleting their pin references', async () => {
    pinRepository.deletePin.mockResolvedValue({
      deleted: true,
      removedMediaObjectKeys: [
        'pins/pin-1/photo.jpg',
        'pins/pin-1/audio.m4a',
      ],
    });

    await expect(service.deletePin(user, 'pin-1')).resolves.toEqual({
      deleted: true,
    });

    expect(objectStorage.deleteObject).toHaveBeenCalledTimes(2);
    expect(objectStorage.deleteObject).toHaveBeenNthCalledWith(
      1,
      'pins/pin-1/photo.jpg',
    );
    expect(objectStorage.deleteObject).toHaveBeenNthCalledWith(
      2,
      'pins/pin-1/audio.m4a',
    );
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
