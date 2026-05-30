# Architecture Guidelines

This project keeps business logic behind project-owned abstractions. Concrete
third-party providers are implementation details, not dependencies that feature
code should know about.

## Dependency Rule

Feature code may depend on:

- DTOs and domain models owned by this repository.
- Interfaces/ports owned by this repository.
- Framework primitives that are already part of the module boundary.

Feature code must not depend directly on:

- Map vendors such as Mapbox or OpenStreetMap tile implementations.
- Object storage vendors such as Cloudflare R2 or S3.
- OAuth vendors such as Google or Apple.
- Database clients such as Prisma, except inside repository adapters.
- Cache clients such as Redis, except inside cache adapters.

## Ports And Adapters

Use this shape for third-party integrations:

```text
Controller/UI -> Service/use case -> Port/interface -> Concrete adapter
```

Examples:

```text
MediaService -> ObjectStoragePort -> R2ObjectStorageAdapter
AuthService -> OAuthProviderClient -> GoogleOAuthProviderClient
AuthorizationService -> AccessControlRepository -> PrismaAccessControlRepository
Map View -> MapViewportController -> Mapbox/OpenStreetMap implementation
```

## Backend Database Rule

Prisma is the current database implementation. Services should not spread
Prisma queries across feature logic. Add repositories by domain need, not a
generic base repository.

Preferred examples:

```text
AccessControlRepository.findMapAccessRecord(mapId)
PinRepository.listPinsByBbox(mapId, bbox)
MediaRepository.createPendingMedia(...)
```

Avoid:

```text
BaseRepository<T>
service.prisma.someModel.findMany(...)
```

Repository methods should speak the language of the feature. The repository
adapter may use Prisma/PostGIS-specific query details internally.

## Mobile Map Rule

The mobile app can use Mapbox, OpenStreetMap, or another provider later. Feature
screens should depend on map-facing ports from `apps/mobile/lib/map`, not on a
vendor widget throughout the app.

Provider-specific widgets/controllers should stay in provider adapter files,
for example:

```text
apps/mobile/lib/map/adapters/mapbox/...
apps/mobile/lib/map/adapters/open_street_map/...
```

## When To Add An Abstraction

Add a port when:

- The code talks to an external provider.
- The implementation is expensive to initialize in tests.
- The implementation may be swapped by environment or product decision.
- The implementation has provider-specific SDK types that would leak upward.

Do not add broad generic abstractions just to hide normal language or framework
features. Keep ports narrow and feature-oriented.
