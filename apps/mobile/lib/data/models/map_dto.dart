import 'json.dart';

enum MemoryMapType {
  personal,
  duo;

  static MemoryMapType fromWire(String value) {
    return switch (value) {
      'personal' => MemoryMapType.personal,
      'duo' => MemoryMapType.duo,
      _ => throw FormatException('Unknown map type: $value'),
    };
  }

  String toWire() {
    return switch (this) {
      MemoryMapType.personal => 'personal',
      MemoryMapType.duo => 'duo',
    };
  }
}

enum InvitationStatus {
  pending,
  accepted,
  revoked,
  expired;

  static InvitationStatus fromWire(String value) {
    return switch (value) {
      'pending' => InvitationStatus.pending,
      'accepted' => InvitationStatus.accepted,
      'revoked' => InvitationStatus.revoked,
      'expired' => InvitationStatus.expired,
      _ => throw FormatException('Unknown invitation status: $value'),
    };
  }

  String toWire() {
    return switch (this) {
      InvitationStatus.pending => 'pending',
      InvitationStatus.accepted => 'accepted',
      InvitationStatus.revoked => 'revoked',
      InvitationStatus.expired => 'expired',
    };
  }
}

enum MapMemberRole {
  owner,
  member;

  static MapMemberRole fromWire(String value) {
    return switch (value) {
      'owner' => MapMemberRole.owner,
      'member' => MapMemberRole.member,
      _ => throw FormatException('Unknown map member role: $value'),
    };
  }

  String toWire() {
    return switch (this) {
      MapMemberRole.owner => 'owner',
      MapMemberRole.member => 'member',
    };
  }
}

class InvitationDto {
  const InvitationDto({
    required this.id,
    required this.mapId,
    required this.code,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
  });

  factory InvitationDto.fromJson(Object? value) {
    final JsonMap json = asJsonMap(value, name: 'invitation');

    return InvitationDto(
      id: readString(json, 'id'),
      mapId: readString(json, 'mapId'),
      code: readString(json, 'code'),
      status: InvitationStatus.fromWire(readString(json, 'status')),
      expiresAt: readDateTime(json, 'expiresAt'),
      createdAt: readDateTime(json, 'createdAt'),
    );
  }

  final String id;
  final String mapId;
  final String code;
  final InvitationStatus status;
  final DateTime expiresAt;
  final DateTime createdAt;

  JsonMap toJson() {
    return <String, Object?>{
      'id': id,
      'mapId': mapId,
      'code': code,
      'status': status.toWire(),
      'expiresAt': writeDateTime(expiresAt),
      'createdAt': writeDateTime(createdAt),
    };
  }
}

class MapMemberDto {
  const MapMemberDto({
    required this.mapId,
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  factory MapMemberDto.fromJson(Object? value) {
    final JsonMap json = asJsonMap(value, name: 'map member');

    return MapMemberDto(
      mapId: readString(json, 'mapId'),
      userId: readString(json, 'userId'),
      role: MapMemberRole.fromWire(readString(json, 'role')),
      joinedAt: readDateTime(json, 'joinedAt'),
    );
  }

  final String mapId;
  final String userId;
  final MapMemberRole role;
  final DateTime joinedAt;

  JsonMap toJson() {
    return <String, Object?>{
      'mapId': mapId,
      'userId': userId,
      'role': role.toWire(),
      'joinedAt': writeDateTime(joinedAt),
    };
  }
}

class MapDto {
  const MapDto({
    required this.id,
    required this.type,
    required this.ownerId,
    this.name,
    this.members = const <MapMemberDto>[],
    this.pendingInvitation,
  });

  factory MapDto.fromJson(Object? value) {
    final JsonMap json = asJsonMap(value, name: 'map');
    final Object? members = json['members'];
    final Object? pendingInvitation = json['pendingInvitation'];

    return MapDto(
      id: readString(json, 'id'),
      type: MemoryMapType.fromWire(readString(json, 'type')),
      ownerId: readString(json, 'ownerId'),
      name: readOptionalString(json, 'name'),
      members: members == null
          ? const <MapMemberDto>[]
          : asJsonMapList(members, name: 'members')
              .map(MapMemberDto.fromJson)
              .toList(growable: false),
      pendingInvitation: pendingInvitation == null
          ? null
          : InvitationDto.fromJson(pendingInvitation),
    );
  }

  final String id;
  final MemoryMapType type;
  final String ownerId;
  final String? name;
  final List<MapMemberDto> members;
  final InvitationDto? pendingInvitation;

  MapDto copyWith({
    String? id,
    MemoryMapType? type,
    String? ownerId,
    Object? name = _unset,
    List<MapMemberDto>? members,
    Object? pendingInvitation = _unset,
  }) {
    return MapDto(
      id: id ?? this.id,
      type: type ?? this.type,
      ownerId: ownerId ?? this.ownerId,
      name: identical(name, _unset) ? this.name : name as String?,
      members: members ?? this.members,
      pendingInvitation: identical(pendingInvitation, _unset)
          ? this.pendingInvitation
          : pendingInvitation as InvitationDto?,
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'id': id,
      'type': type.toWire(),
      'ownerId': ownerId,
      'name': name,
      'members': members.map((MapMemberDto member) {
        return member.toJson();
      }).toList(growable: false),
      'pendingInvitation': pendingInvitation?.toJson(),
    };
  }
}

class AcceptInvitationResponseDto {
  const AcceptInvitationResponseDto({
    required this.map,
    required this.membershipRole,
  });

  factory AcceptInvitationResponseDto.fromJson(Object? value) {
    final JsonMap json = asJsonMap(value, name: 'accept invitation response');

    return AcceptInvitationResponseDto(
      map: MapDto.fromJson(json['map']),
      membershipRole: MapMemberRole.fromWire(
        readString(json, 'membershipRole'),
      ),
    );
  }

  final MapDto map;
  final MapMemberRole membershipRole;

  JsonMap toJson() {
    return <String, Object?>{
      'map': map.toJson(),
      'membershipRole': membershipRole.toWire(),
    };
  }
}

class RemoveMapMemberResponseDto {
  const RemoveMapMemberResponseDto({required this.removed});

  factory RemoveMapMemberResponseDto.fromJson(Object? value) {
    final JsonMap json = asJsonMap(value, name: 'remove member response');

    return RemoveMapMemberResponseDto(removed: readBool(json, 'removed'));
  }

  final bool removed;
}

const Object _unset = Object();
