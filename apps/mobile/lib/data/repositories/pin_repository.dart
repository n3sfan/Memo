import '../api_client.dart';
import '../models/models.dart';

abstract interface class PinRepository {
  Future<List<PinDto>> listByBbox({
    required String mapId,
    required BboxQuery bbox,
  });

  Future<PinDto> getPin(String pinId);

  Future<PinDto> createPin({
    required String mapId,
    required CreatePinRequestDto request,
  });

  Future<PinDto> updatePin({
    required String pinId,
    required CreatePinRequestDto request,
  });

  Future<void> deletePin(String pinId);
}

class ApiPinRepository implements PinRepository {
  ApiPinRepository(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<List<PinDto>> listByBbox({
    required String mapId,
    required BboxQuery bbox,
  }) {
    return apiClient.get<List<PinDto>>(
      '/maps/$mapId/pins',
      queryParameters: <String, Object?>{
        'bbox': bbox.serialize(),
      },
      decoder: (Object? data) {
        final JsonMap json = asJsonMap(data, name: 'pins response');

        return asJsonMapList(json['pins'], name: 'pins')
            .map(PinDto.fromJson)
            .toList(growable: false);
      },
    );
  }

  @override
  Future<PinDto> getPin(String pinId) {
    return apiClient.get<PinDto>(
      '/pins/$pinId',
      decoder: PinDto.fromJson,
    );
  }

  @override
  Future<PinDto> createPin({
    required String mapId,
    required CreatePinRequestDto request,
  }) {
    return apiClient.post<PinDto>(
      '/maps/$mapId/pins',
      body: request.toJson(),
      decoder: PinDto.fromJson,
    );
  }

  @override
  Future<PinDto> updatePin({
    required String pinId,
    required CreatePinRequestDto request,
  }) {
    return apiClient.patch<PinDto>(
      '/pins/$pinId',
      body: request.toJson(),
      decoder: PinDto.fromJson,
    );
  }

  @override
  Future<void> deletePin(String pinId) async {
    await apiClient.delete<JsonMap>(
      '/pins/$pinId',
      decoder: (Object? data) => data == null
          ? const <String, Object?>{}
          : asJsonMap(data, name: 'delete pin response'),
    );
  }
}
