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

final List<PinDto> mockPins = <PinDto>[
  PinDto(
    id: 'pin_da_lat_1',
    mapId: mockPersonalMapId,
    title: 'Da Lat morning',
    note: 'Coffee near the lake.',
    memoryDate: DateTime.utc(2026, 5, 20),
    lat: 11.9404,
    lng: 108.4583,
    media: const <PinMediaDto>[],
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
    media: const <PinMediaDto>[],
    createdAt: DateTime.utc(2026, 5, 24, 18),
    updatedAt: DateTime.utc(2026, 5, 24, 18),
  ),
];

class MockBackendState {
  MockBackendState.seeded()
      : maps = <MapDto>[mockPersonalMap],
        pins = <PinDto>[...mockPins],
        shareLinks = <MockShareLink>[];

  final List<MapDto> maps;
  final List<PinDto> pins;
  final List<MockShareLink> shareLinks;
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

class MockShareLink {
  const MockShareLink({
    required this.id,
    required this.pinId,
    required this.token,
    required this.url,
    required this.createdAt,
    required this.revoked,
  });

  final String id;
  final String pinId;
  final String token;
  final String url;
  final DateTime createdAt;
  final bool revoked;

  MockShareLink copyWith({
    bool? revoked,
  }) {
    return MockShareLink(
      id: id,
      pinId: pinId,
      token: token,
      url: url,
      createdAt: createdAt,
      revoked: revoked ?? this.revoked,
    );
  }
}
