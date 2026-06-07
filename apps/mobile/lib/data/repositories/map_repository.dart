import '../api_client.dart';
import '../models/models.dart';

abstract interface class MapRepository {
  Future<List<MapDto>> listMaps();

  Future<MapDto> getDefaultMap();

  Future<MapDto> createDuoMap({String? name});

  Future<InvitationDto> createInvitation({required String mapId});

  Future<void> revokeInvitation({
    required String mapId,
    required String invitationId,
  });

  Future<AcceptInvitationResponseDto> acceptInvitation({
    required String code,
  });

  Future<RemoveMapMemberResponseDto> removeMember({
    required String mapId,
    required String userId,
  });
}

class ApiMapRepository implements MapRepository {
  ApiMapRepository(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<List<MapDto>> listMaps() {
    return apiClient.get<List<MapDto>>(
      '/maps',
      decoder: (Object? data) {
        final JsonMap json = asJsonMap(data, name: 'maps response');

        return asJsonMapList(json['maps'], name: 'maps')
            .map(MapDto.fromJson)
            .toList(growable: false);
      },
    );
  }

  @override
  Future<MapDto> getDefaultMap() {
    return apiClient.get<MapDto>(
      '/maps/default',
      decoder: MapDto.fromJson,
    );
  }

  @override
  Future<MapDto> createDuoMap({String? name}) {
    final String? trimmedName = name?.trim();

    return apiClient.post<MapDto>(
      '/maps/duo',
      body: <String, Object?>{
        if (trimmedName != null && trimmedName.isNotEmpty) 'name': trimmedName,
      },
      decoder: MapDto.fromJson,
    );
  }

  @override
  Future<InvitationDto> createInvitation({required String mapId}) {
    return apiClient.post<InvitationDto>(
      '/maps/$mapId/invitations',
      decoder: InvitationDto.fromJson,
    );
  }

  @override
  Future<void> revokeInvitation({
    required String mapId,
    required String invitationId,
  }) async {
    await apiClient.delete<Object?>(
      '/maps/$mapId/invitations/$invitationId',
      decoder: (Object? data) => data,
    );
  }

  @override
  Future<AcceptInvitationResponseDto> acceptInvitation({
    required String code,
  }) {
    final String normalizedCode = normalizeInvitationCode(code);

    return apiClient.post<AcceptInvitationResponseDto>(
      '/invitations/${Uri.encodeComponent(normalizedCode)}/accept',
      decoder: AcceptInvitationResponseDto.fromJson,
    );
  }

  @override
  Future<RemoveMapMemberResponseDto> removeMember({
    required String mapId,
    required String userId,
  }) {
    return apiClient.delete<RemoveMapMemberResponseDto>(
      '/maps/$mapId/members/$userId',
      decoder: RemoveMapMemberResponseDto.fromJson,
    );
  }
}

String normalizeInvitationCode(String value) {
  final String normalized = value.trim().toUpperCase();
  final RegExpMatch? match = RegExp(r'INV-[A-Z0-9]+').firstMatch(normalized);

  return match?.group(0) ?? normalized;
}
