import {
  HttpStatus,
  INestApplication,
  NotImplementedException,
} from "@nestjs/common";
import { JwtService } from "@nestjs/jwt";
import { Test } from "@nestjs/testing";
import request = require("supertest");

import { ApiException, throwLinkRevoked } from "../../src/common/api-error";
import { ApiExceptionFilter } from "../../src/common/api-exception.filter";
import { InMemoryKeyValueStore, KEY_VALUE_STORE } from "../../src/infra/redis";
import { JwtAuthGuard } from "../../src/modules/auth/jwt-auth.guard";
import { AuthTokenService } from "../../src/modules/auth/session";
import { MapsController } from "../../src/modules/maps/maps.controller";
import { MapsService } from "../../src/modules/maps/maps.service";
import { PinsController } from "../../src/modules/pins/pins.controller";
import { PinsService } from "../../src/modules/pins/pins.service";
import { ShareLinksController } from "../../src/modules/share-links/share-links.controller";
import { ShareLinksService } from "../../src/modules/share-links/share-links.service";
import { TimelineController } from "../../src/modules/timeline/timeline.controller";
import { TimelineService } from "../../src/modules/timeline/timeline.service";

describe("API contract smoke tests", () => {
  let app: INestApplication;
  let tokenService: AuthTokenService;
  let mapsService: jest.Mocked<MapsService>;
  let pinsService: jest.Mocked<PinsService>;
  let shareLinksService: jest.Mocked<ShareLinksService>;
  let timelineService: jest.Mocked<TimelineService>;

  beforeEach(async () => {
    mapsService = createMapsServiceMock();
    pinsService = createPinsServiceMock();
    shareLinksService = createShareLinksServiceMock();
    timelineService = createTimelineServiceMock();

    const moduleRef = await Test.createTestingModule({
      controllers: [
        MapsController,
        PinsController,
        ShareLinksController,
        TimelineController,
      ],
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
          provide: ShareLinksService,
          useValue: shareLinksService,
        },
        {
          provide: TimelineService,
          useValue: timelineService,
        },
      ],
    }).compile();

    tokenService = moduleRef.get(AuthTokenService);
    app = moduleRef.createNestApplication();
    app.setGlobalPrefix("api/v1");
    app.useGlobalFilters(new ApiExceptionFilter());
    await app.init();
  });

  afterEach(async () => {
    await app.close();
  });

  it("returns the standard success envelope for protected routes", async () => {
    mapsService.listMaps.mockResolvedValue({
      maps: [
        {
          id: "map_1",
          type: "personal",
          ownerId: "user_1",
          name: "Personal map",
        },
      ],
    });

    const response = await request(app.getHttpServer())
      .get("/api/v1/maps")
      .set("authorization", `Bearer ${await accessToken()}`)
      .set("x-request-id", "req_contract_success")
      .expect(200);

    expect(response.body).toEqual({
      data: {
        maps: [
          {
            id: "map_1",
            type: "personal",
            ownerId: "user_1",
            name: "Personal map",
          },
        ],
      },
      requestId: "req_contract_success",
    });
  });

  it("rejects missing bearer tokens with the standard error envelope", async () => {
    const response = await request(app.getHttpServer())
      .get("/api/v1/maps")
      .set("x-request-id", "req_contract_missing_token")
      .expect(401);

    expect(response.body).toEqual({
      error: "unauthorized",
      message: "Missing Authorization bearer token.",
      details: {},
      requestId: "req_contract_missing_token",
    });
    expect(mapsService.listMaps).not.toHaveBeenCalled();
  });

  it("generates a request id when the client does not provide one", async () => {
    const response = await request(app.getHttpServer())
      .get("/api/v1/maps")
      .expect(401);

    expect(response.body).toEqual({
      error: "unauthorized",
      message: "Missing Authorization bearer token.",
      details: {},
      requestId: expect.stringMatching(/^req_/),
    });
  });

  it("rejects invalid bearer tokens before feature logic runs", async () => {
    const response = await request(app.getHttpServer())
      .get("/api/v1/maps")
      .set("authorization", "Bearer invalid-token")
      .set("x-request-id", "req_contract_invalid_token")
      .expect(401);

    expect(response.body).toEqual({
      error: "unauthorized",
      message: "Invalid or expired access token.",
      details: {},
      requestId: "req_contract_invalid_token",
    });
    expect(mapsService.listMaps).not.toHaveBeenCalled();
  });

  it("rejects revoked bearer tokens before feature logic runs", async () => {
    const token = await accessToken();
    const verified = await tokenService.verifyAccessToken(token);
    await tokenService.revoke("access", verified.jti, verified.expiresAt);

    const response = await request(app.getHttpServer())
      .get("/api/v1/maps")
      .set("authorization", `Bearer ${token}`)
      .set("x-request-id", "req_contract_revoked_token")
      .expect(401);

    expect(response.body).toEqual({
      error: "unauthorized",
      message: "Revoked access token.",
      details: {},
      requestId: "req_contract_revoked_token",
    });
    expect(mapsService.listMaps).not.toHaveBeenCalled();
  });

  it("keeps skeleton protected routes behind auth and maps 501 consistently", async () => {
    mapsService.getDefaultMap.mockImplementation(() => {
      throw new NotImplementedException(
        "MapsService.getDefaultMap is scaffolded but not implemented",
      );
    });

    const response = await request(app.getHttpServer())
      .get("/api/v1/maps/default")
      .set("authorization", `Bearer ${await accessToken()}`)
      .set("x-request-id", "req_contract_not_implemented")
      .expect(501);

    expect(response.body).toEqual({
      error: "not_implemented",
      message: "MapsService.getDefaultMap is scaffolded but not implemented",
      details: {},
      requestId: "req_contract_not_implemented",
    });
  });

  it("returns the standard envelope for bbox pin queries", async () => {
    pinsService.listByBbox.mockResolvedValue({
      pins: [],
    });

    const response = await request(app.getHttpServer())
      .get("/api/v1/maps/map_1/pins?bbox=106,10,109,12")
      .set("authorization", `Bearer ${await accessToken()}`)
      .set("x-request-id", "req_contract_bbox")
      .expect(200);

    expect(response.body).toEqual({
      data: {
        pins: [],
      },
      requestId: "req_contract_bbox",
    });
  });

  it("returns the standard envelope for timeline queries", async () => {
    timelineService.listTimeline.mockResolvedValue({
      items: [],
      nextCursor: null,
      hasMore: false,
    });

    const response = await request(app.getHttpServer())
      .get("/api/v1/maps/map_1/timeline?order=desc&limit=50")
      .set("authorization", `Bearer ${await accessToken()}`)
      .set("x-request-id", "req_contract_timeline")
      .expect(200);

    expect(response.body).toEqual({
      data: {
        items: [],
        nextCursor: null,
        hasMore: false,
      },
      requestId: "req_contract_timeline",
    });
  });

  it("returns the standard envelope for creating a Duo Map", async () => {
    mapsService.createDuoMap.mockResolvedValue({
      id: "map_duo_1",
      type: "duo",
      ownerId: "user_1",
      name: null,
      members: [
        {
          mapId: "map_duo_1",
          userId: "user_1",
          role: "owner",
          joinedAt: "2026-06-06T00:00:00.000Z",
        },
      ],
      pendingInvitation: null,
    });

    const response = await request(app.getHttpServer())
      .post("/api/v1/maps/duo")
      .set("authorization", `Bearer ${await accessToken()}`)
      .set("x-request-id", "req_contract_duo_create")
      .send({ name: "Our map" })
      .expect(201);

    expect(response.body).toEqual({
      data: {
        id: "map_duo_1",
        type: "duo",
        ownerId: "user_1",
        name: null,
        members: [
          {
            mapId: "map_duo_1",
            userId: "user_1",
            role: "owner",
            joinedAt: "2026-06-06T00:00:00.000Z",
          },
        ],
        pendingInvitation: null,
      },
      requestId: "req_contract_duo_create",
    });
  });

  it("returns the Duo 409 domain error in the standard envelope", async () => {
    mapsService.createInvitation.mockImplementation(() => {
      throw new ApiException(
        HttpStatus.CONFLICT,
        "invitation_pending_exists",
        "A pending invitation already exists for this map.",
      );
    });

    const response = await request(app.getHttpServer())
      .post("/api/v1/maps/map_duo_1/invitations")
      .set("authorization", `Bearer ${await accessToken()}`)
      .set("x-request-id", "req_contract_duo_409")
      .expect(409);

    expect(response.body).toEqual({
      error: "invitation_pending_exists",
      message: "A pending invitation already exists for this map.",
      details: {},
      requestId: "req_contract_duo_409",
    });
  });

  it("returns the Duo 410 domain error in the standard envelope", async () => {
    mapsService.acceptInvitation.mockImplementation(() => {
      throw new ApiException(
        HttpStatus.GONE,
        "invalid_invitation",
        "Invitation is invalid, expired, revoked or already used.",
      );
    });

    const response = await request(app.getHttpServer())
      .post("/api/v1/invitations/INV-USED/accept")
      .set("authorization", `Bearer ${await accessToken()}`)
      .set("x-request-id", "req_contract_duo_410")
      .expect(410);

    expect(response.body).toEqual({
      error: "invalid_invitation",
      message: "Invitation is invalid, expired, revoked or already used.",
      details: {},
      requestId: "req_contract_duo_410",
    });
  });

  it("returns the standard envelope for public share-link resolve", async () => {
    shareLinksService.resolvePublicPin.mockResolvedValue({
      shareLinkId: "share_1",
      pin: {
        id: "pin_1",
        title: "Shared pin",
        note: "Only this memory.",
        memoryDate: "2026-05-30T00:00:00.000Z",
        lat: 11.9404,
        lng: 108.4583,
        media: [],
        createdAt: "2026-05-30T10:00:00.000Z",
        updatedAt: "2026-05-30T10:00:00.000Z",
      },
    });

    const response = await request(app.getHttpServer())
      .get("/api/v1/share/share-token")
      .set("x-request-id", "req_contract_share_public")
      .expect(200);

    expect(response.body).toEqual({
      data: {
        shareLinkId: "share_1",
        pin: {
          id: "pin_1",
          title: "Shared pin",
          note: "Only this memory.",
          memoryDate: "2026-05-30T00:00:00.000Z",
          lat: 11.9404,
          lng: 108.4583,
          media: [],
          createdAt: "2026-05-30T10:00:00.000Z",
          updatedAt: "2026-05-30T10:00:00.000Z",
        },
      },
      requestId: "req_contract_share_public",
    });
  });

  it("returns the standard error envelope for revoked public share links", async () => {
    shareLinksService.resolvePublicPin.mockImplementation(() => {
      throwLinkRevoked();
    });

    const response = await request(app.getHttpServer())
      .get("/api/v1/share/revoked-token")
      .set("x-request-id", "req_contract_share_revoked")
      .expect(410);

    expect(response.body).toEqual({
      error: "link_revoked",
      message: "Share link has been revoked.",
      details: {},
      requestId: "req_contract_share_revoked",
    });
  });

  async function accessToken(): Promise<string> {
    const session = await tokenService.createSession({
      id: "user_1",
      provider: "google",
      providerUserId: "google_user_1",
      email: "user@example.com",
      displayName: "Memo User",
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
  } as unknown as jest.Mocked<MapsService>;
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

function createShareLinksServiceMock(): jest.Mocked<ShareLinksService> {
  return {
    createShareLink: jest.fn(),
    resolvePublicPin: jest.fn(),
    revokeShareLink: jest.fn(),
  } as unknown as jest.Mocked<ShareLinksService>;
}

function createTimelineServiceMock(): jest.Mocked<TimelineService> {
  return {
    listTimeline: jest.fn(),
  } as unknown as jest.Mocked<TimelineService>;
}
