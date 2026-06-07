import { HttpStatus } from "@nestjs/common";

import { ApiException } from "../../src/common/api-error";
import { CurrentUser } from "../../src/modules/auth/current-user";
import { AuthorizationService } from "../../src/modules/authorization/authorization.service";
import { MapDto } from "../../src/modules/maps/dto/maps.dto";
import {
  MapRepository,
  PendingInvitationConflictError,
} from "../../src/modules/maps/repositories";
import { MapsService } from "../../src/modules/maps/maps.service";

type AuthorizationMock = jest.Mocked<
  Pick<AuthorizationService, "assertCanWriteMap">
>;
type MapRepositoryMock = jest.Mocked<MapRepository>;

describe("MapsService", () => {
  let authorization: AuthorizationMock;
  let repository: MapRepositoryMock;
  let service: MapsService;

  const owner: CurrentUser = {
    id: "user-owner",
    email: "owner@example.com",
  };
  const partner: CurrentUser = {
    id: "user-partner",
    email: "partner@example.com",
  };

  beforeEach(() => {
    authorization = {
      assertCanWriteMap: jest.fn(),
    };
    repository = createMapRepositoryMock();
    service = new MapsService(
      repository,
      authorization as unknown as AuthorizationService,
    );
  });

  it("creates a Duo Map with owner membership through the repository", async () => {
    const map = duoMap({ members: [member("map-duo-1", owner.id, "owner")] });
    repository.createDuoMap.mockResolvedValue(map);

    await expect(
      service.createDuoMap(owner, { name: "Our memories" }),
    ).resolves.toEqual(map);

    expect(repository.createDuoMap).toHaveBeenCalledWith(
      owner.id,
      { name: "Our memories" },
      expect.any(Date),
    );
  });

  it("returns 409 when a second pending invitation is requested", async () => {
    repository.findMapById.mockResolvedValue(
      duoMap({
        pendingInvitation: {
          id: "inv-1",
          mapId: "map-duo-1",
          code: "INV-EXISTS",
          status: "pending",
          expiresAt: "2026-06-13T00:00:00.000Z",
          createdAt: "2026-06-06T00:00:00.000Z",
        },
      }),
    );

    await expect(
      service.createInvitation(owner, "map-duo-1"),
    ).rejects.toMatchApiException(
      HttpStatus.CONFLICT,
      "invitation_pending_exists",
    );

    expect(authorization.assertCanWriteMap).toHaveBeenCalledWith(
      owner.id,
      "map-duo-1",
    );
    expect(repository.createInvitation).not.toHaveBeenCalled();
  });

  it("maps repository pending-invitation races to the 409 domain error", async () => {
    repository.findMapById.mockResolvedValue(duoMap());
    repository.createInvitation.mockRejectedValue(
      new PendingInvitationConflictError(),
    );

    await expect(
      service.createInvitation(owner, "map-duo-1"),
    ).rejects.toMatchApiException(
      HttpStatus.CONFLICT,
      "invitation_pending_exists",
    );
  });

  it("returns 409 when accepting a valid invitation would overfill the Duo Map", async () => {
    repository.acceptInvitation.mockResolvedValue({ status: "map_full" });

    await expect(
      service.acceptInvitation(partner, "INV-FULL"),
    ).rejects.toMatchApiException(HttpStatus.CONFLICT, "map_full");
  });

  it("returns 410 for expired, revoked, used or malformed invitations", async () => {
    repository.acceptInvitation.mockResolvedValue({
      status: "invalid_invitation",
    });

    await expect(
      service.acceptInvitation(partner, "INV-USED"),
    ).rejects.toMatchApiException(HttpStatus.GONE, "invalid_invitation");

    await expect(
      service.acceptInvitation(partner, "   "),
    ).rejects.toMatchApiException(HttpStatus.GONE, "invalid_invitation");
  });

  it("accepts an invitation and returns member role plus map details", async () => {
    const map = duoMap({
      members: [
        member("map-duo-1", owner.id, "owner"),
        member("map-duo-1", partner.id, "member"),
      ],
    });
    repository.acceptInvitation.mockResolvedValue({
      status: "accepted",
      map,
      membershipRole: "member",
    });

    await expect(service.acceptInvitation(partner, "inv-ok")).resolves.toEqual({
      map,
      membershipRole: "member",
    });

    expect(repository.acceptInvitation).toHaveBeenCalledWith({
      code: "INV-OK",
      userId: partner.id,
      now: expect.any(Date),
    });
  });

  it("removes only a second Duo member, never the owner themself", async () => {
    repository.findMapById.mockResolvedValue(duoMap());

    await expect(
      service.removeMember(owner, "map-duo-1", owner.id),
    ).rejects.toMatchApiException(HttpStatus.FORBIDDEN, "forbidden");

    repository.removeMember.mockResolvedValue(true);

    await expect(
      service.removeMember(owner, "map-duo-1", partner.id),
    ).resolves.toEqual({ removed: true });
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

function createMapRepositoryMock(): MapRepositoryMock {
  return {
    listMapsForUser: jest.fn(),
    findDefaultMapForUser: jest.fn(),
    findMapById: jest.fn(),
    countMapMembers: jest.fn(),
    expirePendingInvitationsForMap: jest.fn(),
    createDuoMap: jest.fn(),
    createInvitation: jest.fn(),
    revokeInvitation: jest.fn(),
    acceptInvitation: jest.fn(),
    removeMember: jest.fn(),
  };
}

function duoMap(overrides: Partial<MapDto> = {}): MapDto {
  return {
    id: "map-duo-1",
    type: "duo",
    ownerId: "user-owner",
    name: null,
    members: [member("map-duo-1", "user-owner", "owner")],
    pendingInvitation: null,
    ...overrides,
  };
}

function member(
  mapId: string,
  userId: string,
  role: "owner" | "member",
): {
  mapId: string;
  userId: string;
  role: "owner" | "member";
  joinedAt: string;
} {
  return {
    mapId,
    userId,
    role,
    joinedAt: "2026-06-06T00:00:00.000Z",
  };
}
