import { INestApplication, NotImplementedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import request = require('supertest');

import { ApiExceptionFilter } from '../../src/common/api-exception.filter';
import { InMemoryKeyValueStore, KEY_VALUE_STORE } from '../../src/infra/redis';
import { JwtAuthGuard } from '../../src/modules/auth/jwt-auth.guard';
import { AuthTokenService } from '../../src/modules/auth/session';
import { MapsController } from '../../src/modules/maps/maps.controller';
import { MapsService } from '../../src/modules/maps/maps.service';
import { PinsController } from '../../src/modules/pins/pins.controller';
import { PinsService } from '../../src/modules/pins/pins.service';
import { TimelineController } from '../../src/modules/timeline/timeline.controller';
import { TimelineService } from '../../src/modules/timeline/timeline.service';

describe('API contract smoke tests', () => {
  let app: INestApplication;
  let tokenService: AuthTokenService;
  let mapsService: jest.Mocked<MapsService>;
  let pinsService: jest.Mocked<PinsService>;
  let timelineService: jest.Mocked<TimelineService>;

  beforeEach(async () => {
    mapsService = createMapsServiceMock();
    pinsService = createPinsServiceMock();
    timelineService = createTimelineServiceMock();

    const moduleRef = await Test.createTestingModule({
      controllers: [MapsController, PinsController, TimelineController],
      providers: [
        JwtAuthGuard,
        JwtService,
        AuthTokenService,
        {
          provide: KEY_VALUE_STORE,
          useValue: new InMemoryKeyValueStore(),
        },
        {
          provide: MapsService,
          useValue: mapsService,
        },
        {
          provide: PinsService,
          useValue: pinsService,
        },
        {
          provide: TimelineService,
          useValue: timelineService,
        },
      ],
    }).compile();

    tokenService = moduleRef.get(AuthTokenService);
    app = moduleRef.createNestApplication();
    app.setGlobalPrefix('api/v1');
    app.useGlobalFilters(new ApiExceptionFilter());
    await app.init();
  });

  afterEach(async () => {
    await app.close();
  });

  it('returns the standard success envelope for protected routes', async () => {
    mapsService.listMaps.mockResolvedValue({
      maps: [
        {
          id: 'map_1',
          type: 'personal',
          ownerId: 'user_1',
          name: 'Personal map',
        },
      ],
    });

    const response = await request(app.getHttpServer())
      .get('/api/v1/maps')
      .set('authorization', `Bearer ${await accessToken()}`)
      .set('x-request-id', 'req_contract_success')
      .expect(200);

    expect(response.body).toEqual({
      data: {
        maps: [
          {
            id: 'map_1',
            type: 'personal',
            ownerId: 'user_1',
            name: 'Personal map',
          },
        ],
      },
      requestId: 'req_contract_success',
    });
  });

  it('rejects missing bearer tokens with the standard error envelope', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/v1/maps')
      .set('x-request-id', 'req_contract_missing_token')
      .expect(401);

    expect(response.body).toEqual({
      error: 'unauthorized',
      message: 'Missing Authorization bearer token.',
      details: {},
      requestId: 'req_contract_missing_token',
    });
    expect(mapsService.listMaps).not.toHaveBeenCalled();
  });

  it('generates a request id when the client does not provide one', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/v1/maps')
      .expect(401);

    expect(response.body).toEqual({
      error: 'unauthorized',
      message: 'Missing Authorization bearer token.',
      details: {},
      requestId: expect.stringMatching(/^req_/),
    });
  });

  it('rejects invalid bearer tokens before feature logic runs', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/v1/maps')
      .set('authorization', 'Bearer invalid-token')
      .set('x-request-id', 'req_contract_invalid_token')
      .expect(401);

    expect(response.body).toEqual({
      error: 'unauthorized',
      message: 'Invalid or expired access token.',
      details: {},
      requestId: 'req_contract_invalid_token',
    });
    expect(mapsService.listMaps).not.toHaveBeenCalled();
  });

  it('rejects revoked bearer tokens before feature logic runs', async () => {
    const token = await accessToken();
    const verified = await tokenService.verifyAccessToken(token);
    await tokenService.revoke('access', verified.jti, verified.expiresAt);

    const response = await request(app.getHttpServer())
      .get('/api/v1/maps')
      .set('authorization', `Bearer ${token}`)
      .set('x-request-id', 'req_contract_revoked_token')
      .expect(401);

    expect(response.body).toEqual({
      error: 'unauthorized',
      message: 'Revoked access token.',
      details: {},
      requestId: 'req_contract_revoked_token',
    });
    expect(mapsService.listMaps).not.toHaveBeenCalled();
  });

  it('keeps skeleton protected routes behind auth and maps 501 consistently', async () => {
    mapsService.getDefaultMap.mockImplementation(() => {
      throw new NotImplementedException(
        'MapsService.getDefaultMap is scaffolded but not implemented',
      );
    });

    const response = await request(app.getHttpServer())
      .get('/api/v1/maps/default')
      .set('authorization', `Bearer ${await accessToken()}`)
      .set('x-request-id', 'req_contract_not_implemented')
      .expect(501);

    expect(response.body).toEqual({
      error: 'not_implemented',
      message: 'MapsService.getDefaultMap is scaffolded but not implemented',
      details: {},
      requestId: 'req_contract_not_implemented',
    });
  });

  it('returns the standard envelope for bbox pin queries', async () => {
    pinsService.listByBbox.mockResolvedValue({
      pins: [],
    });

    const response = await request(app.getHttpServer())
      .get('/api/v1/maps/map_1/pins?bbox=106,10,109,12')
      .set('authorization', `Bearer ${await accessToken()}`)
      .set('x-request-id', 'req_contract_bbox')
      .expect(200);

    expect(response.body).toEqual({
      data: {
        pins: [],
      },
      requestId: 'req_contract_bbox',
    });
  });

  it('returns the standard envelope for timeline queries', async () => {
    timelineService.listTimeline.mockResolvedValue({
      items: [],
      nextCursor: null,
      hasMore: false,
    });

    const response = await request(app.getHttpServer())
      .get('/api/v1/maps/map_1/timeline?order=desc&limit=50')
      .set('authorization', `Bearer ${await accessToken()}`)
      .set('x-request-id', 'req_contract_timeline')
      .expect(200);

    expect(response.body).toEqual({
      data: {
        items: [],
        nextCursor: null,
        hasMore: false,
      },
      requestId: 'req_contract_timeline',
    });
  });

  async function accessToken(): Promise<string> {
    const session = await tokenService.createSession({
      id: 'user_1',
      provider: 'google',
      providerUserId: 'google_user_1',
      email: 'user@example.com',
      displayName: 'Memo User',
      avatarUrl: null,
    });

    return session.accessToken;
  }
});

function createMapsServiceMock(): jest.Mocked<MapsService> {
  return {
    listMaps: jest.fn(),
    getDefaultMap: jest.fn(),
    createDuoMap: jest.fn(),
    createInvitation: jest.fn(),
    revokeInvitation: jest.fn(),
    acceptInvitation: jest.fn(),
    removeMember: jest.fn(),
  };
}

function createPinsServiceMock(): jest.Mocked<PinsService> {
  return {
    listByBbox: jest.fn(),
    createPin: jest.fn(),
    getPin: jest.fn(),
    updatePin: jest.fn(),
    deletePin: jest.fn(),
  } as unknown as jest.Mocked<PinsService>;
}

function createTimelineServiceMock(): jest.Mocked<TimelineService> {
  return {
    listTimeline: jest.fn(),
  } as unknown as jest.Mocked<TimelineService>;
}
