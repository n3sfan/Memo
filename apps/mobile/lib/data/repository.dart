import 'api_client.dart';
import 'repositories/repositories.dart';

class MemoryRepository {
  MemoryRepository({
    required this.apiClient,
    this.auth,
    this.maps,
    this.pins,
    this.media,
    this.timeline,
  });

  final ApiClient apiClient;
  final AuthRepository? auth;
  final MapRepository? maps;
  final PinRepository? pins;
  final MediaRepository? media;
  final TimelineRepository? timeline;
}
