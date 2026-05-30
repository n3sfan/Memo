import '../models/models.dart';
import '../repositories/map_repository.dart';
import 'mock_data.dart';

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
}
