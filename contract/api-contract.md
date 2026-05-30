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
- `validation_error`
- `payload_too_large`
- `invitation_pending_exists`
- `invalid_invitation`
- `map_full`
- `link_revoked`

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
