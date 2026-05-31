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
- `500 internal_error`: unexpected server failure. The message must not leak
  credentials, tokens, connection strings or internal stack traces.

## Auth

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

## Timeline

```http
GET /api/v1/maps/:mapId/timeline?order=desc&cursor=&limit=50
```

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

## Mobile Data Layer Rule

Feature code must not call HTTP directly. UI and use cases should depend on:

```text
ApiClient -> Repository -> UI
```

Mock repositories are enabled by default with:

```text
USE_MOCK_DATA=true
```

Switch to real API with:

```bash
flutter run --dart-define=USE_MOCK_DATA=false --dart-define=API_BASE_URL=http://127.0.0.1:3000/api/v1
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
