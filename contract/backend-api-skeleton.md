# Backend API Skeleton

All routes are under the global prefix `/api/v1`.

Most controllers and services are scaffolded only. Scaffolded service methods
return `501 not_implemented` through the common error envelope until feature
owners add real logic. See each module note for implemented exceptions.

## Common

- Success envelope: `{ data, requestId }`
- Error envelope: `{ error, message, details, requestId }`
- `JwtAuthGuard` exists as a placeholder and must be replaced with real JWT
  verification before protected APIs are considered secure.
- `AuthorizationService` exists as the shared access resolver placeholder for
  owner, Duo member and public share-link access.

## Auth

- `POST /auth/oauth/:provider/start`
- `POST /auth/oauth/:provider/callback`
- `POST /auth/refresh`
- `POST /auth/logout`

Files:

- `apps/api/src/modules/auth/auth.controller.ts`
- `apps/api/src/modules/auth/auth.service.ts`

## Maps and Duo

- `GET /maps`
- `GET /maps/default`
- `POST /maps/duo`
- `POST /maps/:mapId/invitations`
- `DELETE /maps/:mapId/invitations/:invitationId`
- `POST /invitations/:code/accept`
- `DELETE /maps/:mapId/members/:userId`

Files:

- `apps/api/src/modules/maps/maps.controller.ts`
- `apps/api/src/modules/maps/maps.service.ts`

## Pins

- `GET /maps/:mapId/pins?bbox=minLng,minLat,maxLng,maxLat`
- `POST /maps/:mapId/pins`
- `GET /pins/:pinId`
- `PATCH /pins/:pinId`
- `DELETE /pins/:pinId`

Status:

- `POST /maps/:mapId/pins`, `GET /pins/:pinId`, `PATCH /pins/:pinId` and
  `DELETE /pins/:pinId` are implemented.
- `GET /maps/:mapId/pins` remains scaffolded until bbox map loading is
  implemented as its own slice.

Files:

- `apps/api/src/modules/pins/pins.controller.ts`
- `apps/api/src/modules/pins/pins.service.ts`

## Timeline

- `GET /maps/:mapId/timeline?order=desc&cursor=&limit=50`

Files:

- `apps/api/src/modules/timeline/timeline.controller.ts`
- `apps/api/src/modules/timeline/timeline.service.ts`

## Media

- `POST /pins/:pinId/media/presign`
- `POST /pins/:pinId/media`
- `GET /media/:mediaId/presign`

Implemented behavior:

- Presigned PUT URLs are created through the R2/S3-compatible storage adapter.
- Media bytes are uploaded directly by the client and never pass through the API.
- Registered media rows store only metadata plus the object key.
- Oversized media requests return `413 payload_too_large`.
- Media access is authorized through the parent pin and unauthorized access
  returns `403 forbidden`.

Files:

- `apps/api/src/modules/media/media.controller.ts`
- `apps/api/src/modules/media/media.service.ts`
- `apps/api/src/modules/media/repositories`
- `apps/api/src/infra/r2`

## Share Links

- `POST /pins/:pinId/share-links`
- `GET /share/:token`
- `DELETE /share-links/:shareLinkId`

Files:

- `apps/api/src/modules/share-links/share-links.controller.ts`
- `apps/api/src/modules/share-links/share-links.service.ts`

## Account

- `GET /account/export`
- `DELETE /account`

Files:

- `apps/api/src/modules/account/account.controller.ts`
- `apps/api/src/modules/account/account.service.ts`
