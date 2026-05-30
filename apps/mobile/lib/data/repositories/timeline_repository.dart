import '../api_client.dart';
import '../models/models.dart';

abstract interface class TimelineRepository {
  Future<TimelinePageDto> listTimeline({
    required String mapId,
    String? cursor,
    int limit = 50,
    String order = 'desc',
  });
}

class ApiTimelineRepository implements TimelineRepository {
  ApiTimelineRepository(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<TimelinePageDto> listTimeline({
    required String mapId,
    String? cursor,
    int limit = 50,
    String order = 'desc',
  }) {
    return apiClient.get<TimelinePageDto>(
      '/maps/$mapId/timeline',
      queryParameters: <String, Object?>{
        'cursor': cursor,
        'limit': limit,
        'order': order,
      },
      decoder: TimelinePageDto.fromJson,
    );
  }
}
