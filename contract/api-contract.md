# Memo MVP API Contract

This contract is the SCRUM-16 source of truth for mobile and backend MVP work.

## Transport

- Base URL is provided to mobile with `--dart-define=API_BASE_URL=...`.
- Local default: `http://127.0.0.1:3000/api/v1`.
- JSON field names are `camelCase`.
- Date/time fields are ISO-8601 UTC strings.
- Coordinates are always returned as `lat` and `lng`.
- Bbox query serialization is `minLng,minLat,maxLng,maxLat`.

## Success Envelope

Every successful API response must use the same envelope:

```json
{
  "data": {},
  "requestId": "req_..."
}
```

List responses still use the envelope:

```json
{
  "data": {
    "pins": []
  },
  "requestId": "req_..."
}
```

## Error Envelope

Every API error should use:

```json
{
  "error": "validation_error",
  "message": "Invalid coordinates",
  "details": {},
  "requestId": "req_..."
}
```

Common MVP error codes:

- `oauth_failed`
- `unauthorized`
- `forbidden`
- `not_found`
- `validation_error`
- `conflict`
- `internal_error`
- `payload_too_large`
- `not_implemented`
- `invitation_pending_exists`
- `invalid_invitation`
- `map_full`
- `link_revoked`

Status conventions:

- `401 unauthorized`: missing, malformed, invalid or expired bearer token.
- `403 forbidden`: authenticated user is known, the resource exists, but the
  user is not allowed to perform the action.
- `404 not_found`: resource does not exist, or the API intentionally hides
  private resource existence from unauthorized users.
- `409 conflict`: request is valid but conflicts with an existing state.
- `410 link_revoked`: public share link used to exist but has been revoked.
- `500 internal_error`: unexpected server failure. The message must not leak
  credentials, tokens, connection strings or internal stack traces.

## Auth

Start OAuth:

```http
POST /api/v1/auth/oauth/:provider/start
```

`:provider` is `google` or `apple`.

Body:

```json
{
  "redirectUri": "memo://oauth/callback"
}
```

Response:

```json
{
  "data": {
    "authorizationUrl": "https://...",
    "state": "oauth_..."
  },
  "requestId": "req_..."
}
```

Browser OAuth callback redirect:

```http
GET /api/v1/auth/oauth/:provider/callback?code=...&state=...
```

Providers that require `response_mode=form_post` may call the same callback
with a form-encoded POST:

```http
POST /api/v1/auth/oauth/:provider/callback
Content-Type: application/x-www-form-urlencoded
```

When the callback comes from the browser/provider, the backend redirects to the
mobile/web app callback route configured by `OAUTH_APP_REDIRECT_BASE_URL`,
preserving `code`, `state` and OAuth error query fields. The app then completes
the exchange with the JSON POST callback below.

Complete OAuth:

```http
POST /api/v1/auth/oauth/:provider/callback
```

Body:

```json
{
  "code": "provider-code",
  "state": "oauth_...",
  "redirectUri": "memo://oauth/callback"
}
```

Cancelled or failed provider callbacks return `401 oauth_failed` and no token.

Refresh session:

```http
POST /api/v1/auth/refresh
```

Body:

```json
{
  "refreshToken": "jwt"
}
```

Logout:

```http
POST /api/v1/auth/logout
Authorization: Bearer <accessToken>
```

Body may include the active refresh token so both token IDs are revoked:

```json
{
  "refreshToken": "jwt"
}
```

Response:

```json
{
  "data": {
    "revoked": true
  },
  "requestId": "req_..."
}
```

Expired or revoked tokens return `401 unauthorized` on protected routes.

Session DTO:

```json
{
  "accessToken": "jwt",
  "refreshToken": "jwt",
  "expiresIn": 3600,
  "user": {
    "id": "user_123",
    "email": "user@example.com",
    "displayName": "Memo User",
    "avatarUrl": "https://..."
  }
}
```

Protected mobile requests attach:

```http
Authorization: Bearer <accessToken>
```

Protected endpoints must reject unauthenticated requests before reaching feature
logic. Skeleton endpoints may still return `501 not_implemented` after a valid
token passes the guard.

## Authorization Model

- Personal maps are accessible only by the owner.
- Duo maps are readable by the owner and accepted map members.
- Only the map owner can modify map-level settings, invitations and members.
- The owner and accepted duo members can create pins on a readable map.
- Pin read/write access is resolved through the parent map.
- Media upload access is resolved through the parent pin.
- Account export/delete access is self-only.
- Public share-link access is resolved by a non-revoked share token.

## Maps and Duo

Map DTO:

```json
{
  "id": "map_duo_1",
  "type": "duo",
  "ownerId": "user_1",
  "name": null,
  "members": [
    {
      "mapId": "map_duo_1",
      "userId": "user_1",
      "role": "owner",
      "joinedAt": "2026-06-06T00:00:00.000Z"
    }
  ],
  "pendingInvitation": {
    "id": "inv_1",
    "mapId": "map_duo_1",
    "code": "INV-7QK2",
    "status": "pending",
    "expiresAt": "2026-06-13T00:00:00.000Z",
    "createdAt": "2026-06-06T00:00:00.000Z"
  }
}
```

Valid map types are `personal` and `duo`. Valid member roles are `owner` and
`member`. Valid invitation statuses are `pending`, `accepted`, `revoked` and
`expired`.

List maps for the authenticated user:

```http
GET /api/v1/maps
```

Response:

```json
{
  "data": {
    "maps": []
  },
  "requestId": "req_..."
}
```

Get the user's default personal map:

```http
GET /api/v1/maps/default
```

Response: `Map DTO`.

Create a Duo Map:

```http
POST /api/v1/maps/duo
```

Body:

```json
{
  "name": "Our memories"
}
```

`name` is optional. The backend creates the Duo Map and adds the authenticated
user as the `owner` member. Response: `Map DTO`.

Create a Duo invitation:

```http
POST /api/v1/maps/:mapId/invitations
```

Only the map owner may create invitations. A Duo Map may have at most one fresh
pending invitation, and a Duo Map may have at most two accepted members.

Response:

```json
{
  "data": {
    "id": "inv_1",
    "mapId": "map_duo_1",
    "code": "INV-7QK2",
    "status": "pending",
    "expiresAt": "2026-06-13T00:00:00.000Z",
    "createdAt": "2026-06-06T00:00:00.000Z"
  },
  "requestId": "req_..."
}
```

Invitation creation errors:

- `409 invitation_pending_exists`: a fresh pending invitation already exists.
- `409 map_full`: the Duo Map already has two members.
- `422 validation_error`: the map is not a Duo Map.

Revoke a pending invitation:

```http
DELETE /api/v1/maps/:mapId/invitations/:invitationId
```

Only the owner may revoke. Response:

```json
{
  "data": {
    "ok": true
  },
  "requestId": "req_..."
}
```

Accept an invitation:

```http
POST /api/v1/invitations/:code/accept
```

The backend normalizes invite codes to uppercase. Acceptance runs in a
transaction, locks the invitation row, rejects already-used membership, enforces
the two-member cap, creates the second `member`, then marks the invitation
`accepted`.

Response:

```json
{
  "data": {
    "map": {
      "id": "map_duo_1",
      "type": "duo",
      "ownerId": "user_1",
      "name": null,
      "members": []
    },
    "membershipRole": "member"
  },
  "requestId": "req_..."
}
```

Invitation acceptance errors:

- `410 invalid_invitation`: code is missing, expired, revoked, accepted, owned
  by an existing member, or otherwise invalid.
- `409 map_full`: another member accepted first and the map is now full.

Remove a Duo member:

```http
DELETE /api/v1/maps/:mapId/members/:userId
```

Only the owner may remove a non-owner Duo member. The owner cannot remove
themselves through this endpoint. Response:

```json
{
  "data": {
    "removed": true
  },
  "requestId": "req_..."
}
```

## Pins

Pin DTO:

```json
{
  "id": "pin_123",
  "mapId": "map_123",
  "title": "Da Lat trip",
  "note": "First day",
  "memoryDate": "2026-05-30T00:00:00.000Z",
  "lat": 11.9404,
  "lng": 108.4583,
  "media": [],
  "createdAt": "2026-05-30T10:00:00.000Z",
  "updatedAt": "2026-05-30T10:00:00.000Z"
}
```

List by bbox:

```http
GET /api/v1/maps/:mapId/pins?bbox=minLng,minLat,maxLng,maxLat
```

`bbox` is required and is parsed as four finite numbers:

- `minLng` and `maxLng` must be between `-180` and `180`.
- `minLat` and `maxLat` must be between `-90` and `90`.
- `minLng` must be less than `maxLng`.
- `minLat` must be less than `maxLat`.
- Invalid or missing bbox returns `422 validation_error`.

Response:

```json
{
  "data": {
    "pins": []
  },
  "requestId": "req_..."
}
```

Create pin:

```http
POST /api/v1/maps/:mapId/pins
```

Body:

```json
{
  "title": "Da Lat trip",
  "note": "First day",
  "memoryDate": "2026-05-30T00:00:00.000Z",
  "lat": 11.9404,
  "lng": 108.4583,
  "clientId": "local_pin_..."
}
```

Response: `Pin DTO`.

Get pin:

```http
GET /api/v1/pins/:pinId
```

Response: `Pin DTO`.

Update pin:

```http
PATCH /api/v1/pins/:pinId
```

Body:

```json
{
  "title": "Updated title",
  "note": "Updated note",
  "memoryDate": "2026-05-31T00:00:00.000Z",
  "lat": 11.9404,
  "lng": 108.4583
}
```

Fields are optional. If a request updates coordinates, it must send both `lat`
and `lng` so the backend can recompute the PostGIS point geometry.

Response: `Pin DTO`.

Delete pin:

```http
DELETE /api/v1/pins/:pinId
```

Response:

```json
{
  "data": {
    "deleted": true
  },
  "requestId": "req_..."
}
```

Coordinate validation:

- `lat` must be a finite number between `-90` and `90`.
- `lng` must be a finite number between `-180` and `180`.
- Invalid coordinates return `422 validation_error`.

Authorization:

- Creating a pin requires readable access to the parent map.
- Reading a pin resolves access through the parent map.
- Editing or deleting an existing pin without permission returns
  `403 forbidden`.

## Media

Presigned upload endpoint:

```http
POST /api/v1/pins/:pinId/media/presign
```

Body:

```json
{
  "mediaType": "image",
  "mimeType": "image/jpeg",
  "sizeBytes": 1048576,
  "fileName": "photo.jpg"
}
```

Response:

```json
{
  "data": {
    "uploadUrl": "https://...",
    "objectKey": "users/.../photo.jpg",
    "expiresAt": "2026-05-30T10:15:00.000Z"
  },
  "requestId": "req_..."
}
```

The backend validates `mediaType`, `mimeType` and `sizeBytes` before creating
the presigned URL. Files larger than `MEDIA_MAX_BYTES` return:

```json
{
  "error": "payload_too_large",
  "message": "Media file exceeds the maximum allowed size.",
  "details": {
    "maxBytes": 10485760,
    "sizeBytes": 10485761
  },
  "requestId": "req_..."
}
```

The backend does not receive or proxy binary file bytes. The mobile client uploads
the file directly to the returned `uploadUrl`, then registers the media metadata.

Register uploaded media:

```http
POST /api/v1/pins/:pinId/media
```

Body:

```json
{
  "mediaType": "image",
  "objectKey": "pins/pin_123/...-photo.jpg",
  "mimeType": "image/jpeg",
  "sizeBytes": 1048576
}
```

Response:

```json
{
  "data": {
    "id": "media_123",
    "pinId": "pin_123",
    "mediaType": "image",
    "objectKey": "pins/pin_123/...-photo.jpg",
    "mimeType": "image/jpeg",
    "sizeBytes": 1048576,
    "createdAt": "2026-05-30T10:16:00.000Z"
  },
  "requestId": "req_..."
}
```

Create authorized read URL:

```http
GET /api/v1/media/:mediaId/presign
```

Response:

```json
{
  "data": {
    "url": "https://...",
    "expiresAt": "2026-05-30T10:30:00.000Z"
  },
  "requestId": "req_..."
}
```

Media upload and read access are authorized through the parent pin. If the media
or parent pin exists but the authenticated user cannot access it, the API returns
`403 forbidden`.

## Timeline

```http
GET /api/v1/maps/:mapId/timeline?order=desc&cursor=&limit=50
```

Timeline pagination uses opaque keyset cursors. The backend orders by
`memoryDate` and then `id` as the stable tie-breaker. Pins without
`memoryDate` are returned last for both ascending and descending order.

Query parameters:

- `order`: `desc` by default. Accepted values are `asc` and `desc`.
- `limit`: `50` by default. Accepted range is `1` to `100`.
- `cursor`: opaque base64url cursor returned by the previous page.

Invalid `order`, `limit` or `cursor` returns `422 validation_error`.

Response:

```json
{
  "data": {
    "items": [],
    "nextCursor": null,
    "hasMore": false
  },
  "requestId": "req_..."
}
```

## Share Links

Share links expose exactly one pin and must not leak the parent map, sibling
pins, owner/member data or storage object keys.

Create share link:

```http
POST /api/v1/pins/:pinId/share-links
Authorization: Bearer <accessToken>
```

Body:

```json
{}
```

`expiresAt` is not supported in this slice. Sending it returns
`422 validation_error`.

Response:

```json
{
  "data": {
    "id": "share_123",
    "pinId": "pin_123",
    "token": "aB3dE5fG7hI9",
    "url": "https://memo.app/p/aB3dE5fG7hI9",
    "revoked": false,
    "createdAt": "2026-05-30T10:20:00.000Z",
    "expiresAt": null
  },
  "requestId": "req_..."
}
```

Create requires read access to the source pin. Tokens are 12-character
URL-safe random IDs using `[A-Za-z0-9_-]`; creation retries if a generated token
already exists.

Resolve public shared pin:

```http
GET /api/v1/share/:token
```

This endpoint is public and does not require a bearer token.

Response:

```json
{
  "data": {
    "shareLinkId": "share_123",
    "pin": {
      "id": "pin_123",
      "title": "Da Lat trip",
      "note": "First day",
      "memoryDate": "2026-05-30T00:00:00.000Z",
      "lat": 11.9404,
      "lng": 108.4583,
      "media": [
        {
          "id": "media_123",
          "pinId": "pin_123",
          "mediaType": "image",
          "mimeType": "image/jpeg",
          "sizeBytes": 1048576,
          "createdAt": "2026-05-30T10:16:00.000Z",
          "url": "https://..."
        }
      ],
      "createdAt": "2026-05-30T10:00:00.000Z",
      "updatedAt": "2026-05-30T10:00:00.000Z"
    }
  },
  "requestId": "req_..."
}
```

The public response intentionally omits `mapId`, `clientId`, media `objectKey`,
map metadata, owner/member data and all sibling pins. Unknown tokens return
`404 not_found`. Revoked links return:

```json
{
  "error": "link_revoked",
  "message": "Share link has been revoked.",
  "details": {},
  "requestId": "req_..."
}
```

Revoke share link:

```http
DELETE /api/v1/share-links/:shareLinkId
Authorization: Bearer <accessToken>
```

Only the link creator can revoke it. Repeated revoke is idempotent.

Response:

```json
{
  "data": {
    "revoked": true
  },
  "requestId": "req_..."
}
```

## Mobile Data Layer Rule

Feature code must not call HTTP directly. UI and use cases should depend on:

```text
ApiClient -> Repository -> UI
```

Real API repositories are enabled by default with:

```text
USE_MOCK_DATA=false
```

Run with the local real API:

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3000/api/v1
```

Switch to mock repositories with:

```bash
flutter run --dart-define=USE_MOCK_DATA=true --dart-define=USE_REAL_AUTH=false
```

## Token Storage

`TokenStorage` is the stable interface. The current Sprint 1 implementation uses
`shared_preferences` only to unblock integration. Before production release, replace
the implementation with `flutter_secure_storage` without changing repositories or UI.

## Local Client IDs

Offline-created pins should include `clientId`. Mobile generates this with the
local helper in `data/client_id.dart`; no external UUID package is required for
the Sprint 1 foundation.

## Contract Smoke Tests

Backend contract smoke tests live in:

```text
apps/api/test/integration/api-contract-smoke.spec.ts
```

Run them directly with:

```bash
pnpm api:test:contract
```

The CI `API` job runs these smoke tests as a required gate. They cover:

- Success envelope shape: `{ data, requestId }`.
- Error envelope shape: `{ error, message, details, requestId }`.
- Protected routes returning `401 unauthorized` before feature logic.
- Skeleton protected routes returning `501 not_implemented` only after a valid
  bearer token passes the guard.
- Server-generated `requestId` fallback when clients do not send
  `x-request-id`.
