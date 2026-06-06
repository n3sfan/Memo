import 'package:flutter_test/flutter_test.dart';
import 'package:memory_map_mobile/data/models/models.dart';

void main() {
  test('serializes and deserializes Duo Map fields', () {
    final MapDto map = MapDto(
      id: 'map_duo_1',
      type: MemoryMapType.duo,
      ownerId: 'user_owner',
      name: 'Our map',
      members: <MapMemberDto>[
        MapMemberDto(
          mapId: 'map_duo_1',
          userId: 'user_owner',
          role: MapMemberRole.owner,
          joinedAt: DateTime.utc(2026, 6, 6),
        ),
      ],
      pendingInvitation: InvitationDto(
        id: 'inv_1',
        mapId: 'map_duo_1',
        code: 'INV-1234',
        status: InvitationStatus.pending,
        expiresAt: DateTime.utc(2026, 6, 13),
        createdAt: DateTime.utc(2026, 6, 6),
      ),
    );

    final MapDto parsed = MapDto.fromJson(map.toJson());

    expect(parsed.id, map.id);
    expect(parsed.type, MemoryMapType.duo);
    expect(parsed.members.single.role, MapMemberRole.owner);
    expect(parsed.pendingInvitation?.code, 'INV-1234');
    expect(parsed.pendingInvitation?.status, InvitationStatus.pending);
  });

  test('parses accepted invitation responses', () {
    final AcceptInvitationResponseDto response =
        AcceptInvitationResponseDto.fromJson(<String, Object?>{
      'map': <String, Object?>{
        'id': 'map_duo_1',
        'type': 'duo',
        'ownerId': 'user_owner',
        'name': null,
        'members': <Object?>[],
        'pendingInvitation': null,
      },
      'membershipRole': 'member',
    });

    expect(response.map.id, 'map_duo_1');
    expect(response.membershipRole, MapMemberRole.member);
  });
}
