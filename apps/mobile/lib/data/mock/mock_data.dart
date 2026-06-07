import '../models/models.dart';

const String mockUserId = 'user_mock_1';
const String mockPersonalMapId = 'map_personal_1';

final UserProfileDto mockUser = UserProfileDto(
  id: mockUserId,
  email: 'demo@memo.local',
  displayName: 'Memo Demo',
);

final SessionDto mockSession = SessionDto(
  accessToken: 'mock_access_token',
  refreshToken: 'mock_refresh_token',
  expiresIn: 3600,
  user: mockUser,
);

final MapDto mockPersonalMap = MapDto(
  id: mockPersonalMapId,
  type: MemoryMapType.personal,
  ownerId: mockUserId,
  name: 'Personal Map',
  members: <MapMemberDto>[
    MapMemberDto(
      mapId: mockPersonalMapId,
      userId: mockUserId,
      role: MapMemberRole.owner,
      joinedAt: DateTime.utc(2026, 5, 20),
    ),
  ],
);

final List<PinMediaDto> mockDaLatMedia = <PinMediaDto>[
  PinMediaDto(
    id: 'media_da_lat_photo',
    pinId: 'pin_da_lat_1',
    mediaType: PinMediaType.image,
    objectKey: 'mock/pin_da_lat_1/photo.jpg',
    mimeType: 'image/jpeg',
    sizeBytes: 245000,
    createdAt: DateTime.utc(2026, 5, 20, 8, 5),
  ),
  PinMediaDto(
    id: 'media_da_lat_audio',
    pinId: 'pin_da_lat_1',
    mediaType: PinMediaType.audio,
    objectKey: 'mock/pin_da_lat_1/audio.mp3',
    mimeType: 'audio/mpeg',
    sizeBytes: 580000,
    createdAt: DateTime.utc(2026, 5, 20, 8, 10),
  ),
];

final List<PinMediaDto> mockSaiGonMedia = <PinMediaDto>[
  PinMediaDto(
    id: 'media_sai_gon_photo',
    pinId: 'pin_sai_gon_1',
    mediaType: PinMediaType.image,
    objectKey: 'mock/pin_sai_gon_1/photo.jpg',
    mimeType: 'image/jpeg',
    sizeBytes: 238000,
    createdAt: DateTime.utc(2026, 5, 24, 18, 5),
  ),
];

final List<PinDto> mockPins = <PinDto>[
  PinDto(
    id: 'pin_da_lat_1',
    mapId: mockPersonalMapId,
    title: 'Da Lat morning',
    note: 'Coffee near the lake.',
    memoryDate: DateTime.utc(2026, 5, 20),
    lat: 11.9404,
    lng: 108.4583,
    media: mockDaLatMedia,
    createdAt: DateTime.utc(2026, 5, 20, 8),
    updatedAt: DateTime.utc(2026, 5, 20, 8),
  ),
  PinDto(
    id: 'pin_sai_gon_1',
    mapId: mockPersonalMapId,
    title: 'Sai Gon walk',
    note: 'A quick walk after work.',
    memoryDate: DateTime.utc(2026, 5, 24),
    lat: 10.7769,
    lng: 106.7009,
    media: mockSaiGonMedia,
    createdAt: DateTime.utc(2026, 5, 24, 18),
    updatedAt: DateTime.utc(2026, 5, 24, 18),
  ),
];

class MockBackendState {
  MockBackendState.seeded()
      : maps = <MapDto>[mockPersonalMap],
        pins = <PinDto>[...mockPins];

  final List<MapDto> maps;
  final List<PinDto> pins;
  int _sequence = 100;

  String nextId(String prefix) {
    _sequence += 1;

    return '${prefix}_$_sequence';
  }

  String nextInvitationCode() {
    _sequence += 1;

    return 'INV-${_sequence.toRadixString(36).toUpperCase().padLeft(4, '0')}';
  }
}
