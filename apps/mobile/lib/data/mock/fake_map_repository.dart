import '../models/models.dart';
import '../repositories/map_repository.dart';
import 'mock_data.dart';

const String mockExternalInvitationCode = 'INV-DEMO';
const String _mockExternalOwnerId = 'user_mock_partner';

class FakeMapRepository implements MapRepository {
  FakeMapRepository(this.state);

  final MockBackendState state;

  @override
  Future<MapDto> getDefaultMap() async {
    return state.maps.first;
  }

  @override
  Future<List<MapDto>> listMaps() async {
    return List<MapDto>.unmodifiable(state.maps);
  }

  @override
  Future<MapDto> createDuoMap({String? name}) async {
    final String mapId = state.nextId('map_duo');
    final DateTime now = DateTime.now().toUtc();
    final MapDto map = MapDto(
      id: mapId,
      type: MemoryMapType.duo,
      ownerId: mockUserId,
      name: name,
      members: <MapMemberDto>[
        MapMemberDto(
          mapId: mapId,
          userId: mockUserId,
          role: MapMemberRole.owner,
          joinedAt: now,
        ),
      ],
    );

    state.maps.add(map);

    return map;
  }

  @override
  Future<InvitationDto> createInvitation({required String mapId}) async {
    final int index = _mapIndex(mapId);
    final MapDto map = state.maps[index];

    if (map.type != MemoryMapType.duo) {
      throw _apiException(
        statusCode: 422,
        error: 'validation_error',
        message: 'Invitations are only supported for Duo Maps.',
      );
    }

    if (map.members.length >= 2) {
      throw _apiException(
        statusCode: 409,
        error: 'map_full',
        message: 'This Duo Map already has two members.',
      );
    }

    final InvitationDto? pendingInvitation = map.pendingInvitation;
    if (pendingInvitation != null &&
        pendingInvitation.status == InvitationStatus.pending &&
        pendingInvitation.expiresAt.isAfter(DateTime.now().toUtc())) {
      throw _apiException(
        statusCode: 409,
        error: 'invitation_pending_exists',
        message: 'A pending invitation already exists for this map.',
      );
    }

    final DateTime now = DateTime.now().toUtc();
    final InvitationDto invitation = InvitationDto(
      id: state.nextId('invitation'),
      mapId: mapId,
      code: state.nextInvitationCode(),
      status: InvitationStatus.pending,
      expiresAt: now.add(const Duration(days: 7)),
      createdAt: now,
    );
    state.maps[index] = map.copyWith(pendingInvitation: invitation);

    return invitation;
  }

  @override
  Future<void> revokeInvitation({
    required String mapId,
    required String invitationId,
  }) async {
    final int index = _mapIndex(mapId);
    final MapDto map = state.maps[index];
    final InvitationDto? invitation = map.pendingInvitation;

    if (invitation == null || invitation.id != invitationId) {
      throw _invalidInvitation();
    }

    state.maps[index] = map.copyWith(pendingInvitation: null);
  }

  @override
  Future<AcceptInvitationResponseDto> acceptInvitation({
    required String code,
  }) async {
    final String normalizedCode = normalizeInvitationCode(code);
    if (normalizedCode.isEmpty) {
      throw _invalidInvitation();
    }

    final int index = state.maps.indexWhere((MapDto map) {
      final InvitationDto? invitation = map.pendingInvitation;
      return invitation != null &&
          invitation.code == normalizedCode &&
          invitation.status == InvitationStatus.pending &&
          invitation.expiresAt.isAfter(DateTime.now().toUtc());
    });

    if (index < 0) {
      if (normalizedCode == mockExternalInvitationCode) {
        return _acceptExternalDemoInvitation();
      }

      throw _invalidInvitation();
    }

    final MapDto map = state.maps[index];
    if (map.members.any((MapMemberDto member) => member.userId == mockUserId)) {
      throw _invalidInvitation();
    }

    if (map.members.length >= 2) {
      throw _apiException(
        statusCode: 409,
        error: 'map_full',
        message: 'This Duo Map already has two members.',
      );
    }

    final MapDto acceptedMap = map.copyWith(
      members: <MapMemberDto>[
        ...map.members,
        MapMemberDto(
          mapId: map.id,
          userId: mockUserId,
          role: MapMemberRole.member,
          joinedAt: DateTime.now().toUtc(),
        ),
      ],
      pendingInvitation: null,
    );
    state.maps[index] = acceptedMap;

    return AcceptInvitationResponseDto(
      map: acceptedMap,
      membershipRole: MapMemberRole.member,
    );
  }

  @override
  Future<RemoveMapMemberResponseDto> removeMember({
    required String mapId,
    required String userId,
  }) async {
    final int index = _mapIndex(mapId);
    final MapDto map = state.maps[index];

    if (map.ownerId == userId) {
      throw _apiException(
        statusCode: 403,
        error: 'forbidden',
        message: 'The owner cannot remove themselves from a Duo Map.',
      );
    }

    final List<MapMemberDto> members = map.members
        .where((MapMemberDto member) => member.userId != userId)
        .toList(growable: false);
    if (members.length == map.members.length) {
      throw _apiException(
        statusCode: 404,
        error: 'not_found',
        message: 'Map member not found.',
      );
    }

    state.maps[index] = map.copyWith(members: members);

    return const RemoveMapMemberResponseDto(removed: true);
  }

  int _mapIndex(String mapId) {
    final int index = state.maps.indexWhere((MapDto map) => map.id == mapId);
    if (index < 0) {
      throw _apiException(
        statusCode: 404,
        error: 'not_found',
        message: 'Map not found.',
      );
    }

    return index;
  }

  AcceptInvitationResponseDto _acceptExternalDemoInvitation() {
    final String mapId = state.nextId('map_duo');
    final DateTime now = DateTime.now().toUtc();
    final MapDto map = MapDto(
      id: mapId,
      type: MemoryMapType.duo,
      ownerId: _mockExternalOwnerId,
      name: 'Duo Map Demo',
      members: <MapMemberDto>[
        MapMemberDto(
          mapId: mapId,
          userId: _mockExternalOwnerId,
          role: MapMemberRole.owner,
          joinedAt: now.subtract(const Duration(minutes: 5)),
        ),
        MapMemberDto(
          mapId: mapId,
          userId: mockUserId,
          role: MapMemberRole.member,
          joinedAt: now,
        ),
      ],
    );

    state.maps.add(map);

    return AcceptInvitationResponseDto(
      map: map,
      membershipRole: MapMemberRole.member,
    );
  }

  ApiException _invalidInvitation() {
    return _apiException(
      statusCode: 410,
      error: 'invalid_invitation',
      message: 'Invitation is invalid, expired, revoked or already used.',
    );
  }

  ApiException _apiException({
    required int statusCode,
    required String error,
    required String message,
  }) {
    return ApiException(
      statusCode: statusCode,
      apiError: ApiError(
        error: error,
        message: message,
        details: const <String, Object?>{},
        requestId: 'req_mock',
      ),
    );
  }
}
