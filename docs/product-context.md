# Product Context

This file summarizes the product intent from the original Kiro spec/design:

- `.kiro/specs/ban-do-ky-niem/requirements.md`
- `.kiro/specs/ban-do-ky-niem/design.md`
- `.kiro/specs/ban-do-ky-niem/tasks.md`
- `docs/YtuongWeb_extracted.txt`

Use this file for product direction. Use `contract/api-contract.md` for the
current implemented API contract when endpoint details differ from early design
examples.

## Product Intent

Memo, originally "Ban Do Ky Niem" or "Memory Map", is a mobile-first private
memory map app. Users pin memories to real-world coordinates and attach media
such as photos, text notes and audio.

The product is intentionally anti-social-media:

- Private by default.
- No ads.
- No behavioral tracking.
- No noisy public feed.
- Focused on revisiting personal journeys and shared memories.

Every pin is a location-based memory. The map is not just a utility view; it is
the primary emotional surface of the product.

## MVP Scope

MVP is Phase 1 and targets a mobile app with a backend API.

In scope:

- Google/Apple OAuth login.
- Personal memory map.
- Duo Map for exactly two people.
- Pin creation and management with coordinates, title, note and memory date.
- Media attachments: image, text and audio.
- Map View with bounding-box loading.
- Timeline View sorted by memory date.
- Share Link for a single pin.
- Offline local cache for text/coordinates.
- Upload queue and retry for media.
- Privacy controls, account export and account deletion.

Out of scope for MVP:

- Group Map with 3-10 people.
- Real-time collaboration.
- Marker clustering at large zoom levels.
- Video attachments.
- AI summaries/reminders.
- Monetization and print-on-demand.

## Product Rules

- A Personal Map is private to its owner.
- A Duo Map has exactly two members at most: owner plus one invited member.
- A pending Duo invitation should be unique per map.
- Share Links expose exactly one pin and must not leak the rest of the map.
- Media files must not be stored as binary data in the server or database.
- The backend stores media references and signs direct object-storage URLs.
- Mobile must not render all pins at once; it loads the current viewport bbox.
- Offline mode should preserve text/coordinate access and queue changes.
- Account deletion must remove personal data and related media references.

## Core User Flows

Auth:

1. User starts OAuth with Google or Apple.
2. Backend creates or links the user account.
3. Backend issues access and refresh tokens.
4. Protected requests require `Authorization: Bearer <accessToken>`.
5. Logout/revocation should make the current session unusable.

Pin creation:

1. User selects a location or drops a pin.
2. User adds title, note, memory date and optional media.
3. Mobile stores local data immediately when offline.
4. Backend validates coordinates and map access.
5. Backend persists pin in Postgres/PostGIS.

Media:

1. Mobile compresses images client-side before upload.
2. Backend creates presigned upload URL.
3. Mobile uploads media directly to object storage.
4. Backend stores object key and metadata only.
5. Read access also goes through permission checks and presigned read URLs.

Map View:

1. Mobile observes viewport bounds.
2. Mobile requests pins for `bbox=minLng,minLat,maxLng,maxLat`.
3. Backend queries PostGIS using spatial indexes.
4. Redis may cache active map/bbox responses.
5. Pin changes invalidate related cache entries.

Timeline:

1. User opens timeline for an accessible map.
2. Backend returns pins sorted by memory date.
3. Missing memory dates should not break the view.
4. Selecting a timeline item should reveal pin details and location.

Duo Map:

1. Owner creates a Duo Map.
2. Owner creates one invitation link/code.
3. One invited authenticated user accepts it.
4. Both members can view and contribute pins.
5. Owner can remove the second member.

Share Link:

1. Authorized user creates a public link for one pin.
2. Public access returns only that pin's content and location.
3. Revoking the link blocks future access.

Privacy:

1. Export returns only the requesting user's data scope.
2. Delete account must remove personal maps, pins and media references.
3. If cleanup fails, keep retry state instead of reporting complete deletion.

## Technical Direction

Backend:

- NestJS with module boundaries.
- PostgreSQL + PostGIS for spatial data.
- Prisma for schema/migrations and normal DB access.
- Raw SQL is acceptable for PostGIS-specific spatial queries.
- Redis for cache and token/session denylist.
- Cloudflare R2/S3-compatible object storage for media.
- Docker Compose for local infrastructure.
- PM2 + Nginx TLS for VPS deployment direction.

Mobile:

- Flutter.
- Riverpod for providers.
- Dio for API client.
- Repository interfaces between UI and HTTP.
- Local cache with SQLite/sqflite or drift direction.
- `workmanager` for background retry.
- `flutter_image_compress`, `image_picker` and `record` for media.
- Map provider is not locked: concrete Mapbox, OpenStreetMap-style or other
  implementations must stay behind project-owned map ports.

Testing:

- Backend: Jest.
- Backend property testing direction: fast-check.
- Mobile: flutter test.
- Mobile property testing direction: glados.
- Contract smoke tests protect API envelope/auth behavior in CI.

## Current Implementation Notes

Already established in repo:

- Monorepo with `apps/api` and `apps/mobile`.
- Docker/PM2/Nginx deployment skeleton.
- Prisma/PostGIS schema and migrations.
- Mobile DTO/API/repository/mock/local-cache foundation.
- Backend route/module skeleton.
- JWT guard, standard API errors and authorization foundation.
- API contract smoke tests and CI gates.
- Conventional Commit and PR title checks.
- Provider abstraction rule for third-party integrations.

Important current contract decisions:

- Success responses use `{ data, requestId }`.
- Error responses use `{ error, message, details, requestId }`.
- Current media presign endpoint follows `contract/api-contract.md`.
- Backend routes are under `/api/v1`.
- Mobile should use repositories/providers instead of direct HTTP calls.

## Future Phases

Phase 2:

- Group Map for 3-10 members.
- Real-time updates via WebSockets and Redis Pub/Sub.
- Marker clustering.
- Short video attachments.

Phase 3:

- AI journey summaries, preferably local-first when feasible.
- "On this day" memory reminders.
- Music attachments.

Phase 4:

- Print-on-demand photobook/poster.
- Freemium storage/features.
- Themes and custom icons.

## Decision Guidance For Agents

When implementing a feature:

1. Preserve the anti-social-media and privacy-first product direction.
2. Prefer mobile-first UX decisions.
3. Keep third-party providers behind ports/adapters.
4. Keep map queries bbox-based.
5. Keep media binary out of backend/database storage.
6. Update contract docs and smoke tests when behavior changes.
7. Avoid expanding into Phase 2-4 unless the ticket explicitly asks for it.

