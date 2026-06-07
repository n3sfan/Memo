# Mobile Data Layer Usage

Import repositories through Riverpod providers:

```dart
final pins = await ref.read(pinRepositoryProvider).listByBbox(
  mapId: 'map_personal_1',
  bbox: const BboxQuery(
    minLng: 106.0,
    minLat: 10.0,
    maxLng: 109.0,
    maxLat: 12.5,
  ),
);
```

Create a pin:

```dart
final pin = await ref.read(pinRepositoryProvider).createPin(
  mapId: 'map_personal_1',
  request: CreatePinRequestDto(
    title: 'Da Lat trip',
    note: 'First day',
    memoryDate: DateTime.utc(2026, 5, 30),
    lat: 11.9404,
    lng: 108.4583,
    clientId: 'local_pin_001',
  ),
);
```

Create a presigned upload:

```dart
final upload = await ref.read(mediaRepositoryProvider).createPresignedUpload(
  pinId: pin.id,
  request: const PresignRequestDto(
    mediaType: PinMediaType.image,
    mimeType: 'image/jpeg',
    sizeBytes: 1048576,
    fileName: 'photo.jpg',
  ),
);
```

Upload bytes directly to object storage, then register the media reference:

```dart
await ref.read(objectUploadClientProvider).uploadFile(
  uploadUrl: upload.uploadUrl,
  localPath: localFilePath,
  mimeType: 'image/jpeg',
  sizeBytes: 1048576,
);

final media = await ref.read(mediaRepositoryProvider).registerMedia(
  pinId: pin.id,
  request: RegisterMediaRequestDto(
    mediaType: PinMediaType.image,
    objectKey: upload.objectKey,
    mimeType: 'image/jpeg',
    sizeBytes: 1048576,
  ),
);
```

The object upload client uses a separate Dio client and must not use the API
auth interceptor, because presigned URLs are already authorized by the backend.
The backend stores only the registered metadata and object key.

## Timeline, Pin Detail And Media Reads

Timeline and Pin Detail UI must continue to use repository providers:

```dart
final page = await ref.read(timelineRepositoryProvider).listTimeline(
  mapId: mapId,
  order: 'desc',
);

final pin = await ref.read(pinRepositoryProvider).getPin(pinId);
```

Media viewers obtain a short-lived Authorized Read URL from the backend through
`MediaRepository`. UI code must not construct object-storage URLs or import
`ApiClient`/Dio:

```dart
final readUrl = await ref
    .read(mediaRepositoryProvider)
    .createReadUrl(mediaId);
```

The read URL is ephemeral and scoped to the authorized media item. Mobile may
keep it in per-item Riverpod state while the viewer is alive, but should request
a fresh URL after retry, provider disposal or connectivity recovery instead of
persisting it in the local database.

Images may load the Authorized Read URL with `Image.network`. Audio playback
must go through the project-owned `AudioPlaybackPort`; the concrete
`just_audio` dependency belongs only in the adapter. Each media id owns an
independent playback port and Riverpod disposes it with the corresponding
widget/provider lifecycle.

When media cannot be resolved, Pin Detail keeps title, note, memory date and
coordinates visible and renders a localized placeholder for that media item.
Connectivity recovery causes the media URL provider to resolve again.

Pin Detail opens a map location with `/?lat=<latitude>&lng=<longitude>`. The
router validates both coordinate ranges before passing them to `MapScreen` as
its initial focus camera.

The default provider mode is the real API. Feature owners can still build Map
View, Pin Editor and Timeline without backend dependencies by running with
`--dart-define=USE_MOCK_DATA=true --dart-define=USE_REAL_AUTH=false`.

Map View should depend on `mapViewControllerProvider` and the project-owned map
port in `apps/mobile/lib/map`. UI code must not import concrete map SDK
packages directly; provider-specific code belongs in an adapter such as
`flutter_map_adapter.dart`.

## Duo Map

Duo UI should depend on `duoControllerProvider`, which in turn depends on
`mapRepositoryProvider`. UI code must not call `ApiClient`, Dio or endpoint
paths directly.

Create a Duo Map and owner invitation:

```dart
await ref.read(duoControllerProvider.notifier).createDuoMap();
```

For lower-level flows, use the repository:

```dart
final map = await ref.read(mapRepositoryProvider).createDuoMap();
final invitation = await ref.read(mapRepositoryProvider).createInvitation(
  mapId: map.id,
);
```

Accept a code or pasted link:

```dart
ref
    .read(duoControllerProvider.notifier)
    .openJoinForm('https://memo.app/inv/INV-7QK2');
await ref.read(duoControllerProvider.notifier).acceptInvitation();
```

The repository normalizes pasted links to `INV-...` before calling:

```http
POST /api/v1/invitations/:code/accept
```

Duo-specific API errors should stay inline on the Duo screen:

- `409 invitation_pending_exists`: owner already has one pending invite.
- `409 map_full`: the Duo Map already has two accepted members.
- `410 invalid_invitation`: the code is expired, revoked, accepted or invalid.
