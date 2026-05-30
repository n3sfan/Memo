import '../models/models.dart';
import '../repositories/timeline_repository.dart';
import 'mock_data.dart';

class FakeTimelineRepository implements TimelineRepository {
  FakeTimelineRepository(this.state);

  final MockBackendState state;

  @override
  Future<TimelinePageDto> listTimeline({
    required String mapId,
    String? cursor,
    int limit = 50,
    String order = 'desc',
  }) async {
    final List<PinDto> pins = state.pins
        .where((PinDto pin) => pin.mapId == mapId)
        .toList(growable: false)
      ..sort((PinDto left, PinDto right) {
        final DateTime leftDate = left.memoryDate ?? left.createdAt;
        final DateTime rightDate = right.memoryDate ?? right.createdAt;
        final int result = leftDate.compareTo(rightDate);

        return order == 'asc' ? result : -result;
      });

    return TimelinePageDto(
      items: pins.take(limit).toList(growable: false),
      nextCursor: null,
      hasMore: false,
    );
  }
}
