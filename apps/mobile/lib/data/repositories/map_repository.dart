import '../api_client.dart';
import '../models/models.dart';

abstract interface class MapRepository {
  Future<List<MapDto>> listMaps();

  Future<MapDto> getDefaultMap();
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
}
