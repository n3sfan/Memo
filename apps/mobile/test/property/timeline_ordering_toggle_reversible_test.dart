// Feature: timeline-pin-detail-media-viewer, Property 4: Sort toggle is order-reversible over the same set
//
// Property 4 (design.md "Correctness Properties"):
//   For any list of pins, ordering as `newest` and ordering as `oldest` yield
//   the same set of pins, and re-applying `newest` after `oldest` reproduces
//   the original `newest` ordering (reordering only, never adding or dropping
//   a pin).
//
// Validates: Requirements 2.5, 2.8, 3.4
import 'package:glados/glados.dart';
import 'package:memory_map_mobile/app/timeline_ordering.dart';
import 'package:memory_map_mobile/data/models/models.dart';

/// Builds a [PinDto] with only the fields that influence ordering populated.
///
/// [id] is the stable tie-breaker used by `orderPins`, and [memoryDate]
/// determines whether a pin is dated or undated.
PinDto _pin({required String id, required DateTime? memoryDate}) {
  return PinDto(
    id: id,
    mapId: 'map_1',
    title: 'Pin $id',
    note: null,
    memoryDate: memoryDate,
    lat: 0,
    lng: 0,
    media: const <PinMediaDto>[],
    createdAt: DateTime.utc(2020),
    updatedAt: DateTime.utc(2020),
  );
}

/// Generates a `List<PinDto>` with a mix of present/absent `memoryDate`.
///
/// Each pin is given a unique `id` (`pin_<index>`) so the ordering is fully
/// deterministic (the `id` tie-breaker never ties), which makes the
/// reversibility comparison meaningful. The integer seed decides both whether
/// a pin is dated (~75% dated) and its memory date.
final Generator<List<PinDto>> _anyPins = any.list(any.int).map(
  (List<int> seeds) {
    return List<PinDto>.generate(seeds.length, (int index) {
      final int seed = seeds[index];
      final bool isDated = seed % 4 != 0;
      final DateTime? memoryDate =
          isDated ? DateTime.utc(2020).add(Duration(days: seed % 1000)) : null;
      return _pin(id: 'pin_$index', memoryDate: memoryDate);
    });
  },
);

List<String> _ids(List<PinDto> pins) =>
    pins.map((PinDto pin) => pin.id).toList(growable: false);

void main() {
  // Glados runs 100 generated cases by default.
  Glados<List<PinDto>>(_anyPins).test(
    'sort toggle is order-reversible over the same set',
    (List<PinDto> pins) {
      final List<PinDto> newest = orderPins(pins, TimelineSortOrder.newest);
      final List<PinDto> oldest = orderPins(pins, TimelineSortOrder.oldest);

      // Same set of pins for both directions (reordering only, never adding or
      // dropping a pin).
      expect(_ids(newest)..sort(), _ids(oldest)..sort());
      expect(newest.length, pins.length);
      expect(oldest.length, pins.length);

      // Re-applying `newest` after `oldest` reproduces the original `newest`
      // ordering.
      final List<PinDto> reNewest = orderPins(oldest, TimelineSortOrder.newest);
      expect(_ids(reNewest), _ids(newest));

      // Symmetrically, re-applying `oldest` after `newest` reproduces `oldest`.
      final List<PinDto> reOldest = orderPins(newest, TimelineSortOrder.oldest);
      expect(_ids(reOldest), _ids(oldest));
    },
  );
}
