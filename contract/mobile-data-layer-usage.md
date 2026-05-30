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

The default provider mode is mock data. Feature owners can build Map View, Pin
Editor and Timeline before backend APIs are ready. To use the real backend, run
with `--dart-define=USE_MOCK_DATA=false`.
