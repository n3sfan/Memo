// Feature: timeline-pin-detail-media-viewer, Property 1: Ordering preserves the pin set
//
// Property 1 (design.md "Correctness Properties"):
//   For any list of pins and any sort order, `orderPins` returns a list
//   containing exactly the same pins (same multiset of ids) as the input -
//   none added, none removed.
//
// Validates: Requirements 2.5, 3.1, 3.4
import 'package:glados/glados.dart';
import 'package:memory_map_mobile/app/timeline_ordering.dart';
import 'package:memory_map_mobile/data/models/models.dart';

/// Generators for [PinDto] values exercising both ordering partitions.
extension TimelineSetPreservationAny on Any {
  /// A `memoryDate` that is present roughly half the time and absent
  /// otherwise, so both the dated and undated partitions of [orderPins] are
  /// exercised.
  Generator<DateTime?> get optionalMemoryDate => combine2(
        any.bool,
        any.dateTime,
        (bool hasDate, DateTime date) => hasDate ? date : null,
      );

  /// A [PinDto] with a random id, title, and a mix of present/absent
  /// `memoryDate`.
  ///
  /// The id is drawn from a small alphabet so that duplicate ids occur with
  /// reasonable frequency. This makes the property a genuine *multiset* check:
  /// `orderPins` must preserve repeated ids, not just the set of distinct ids.
  Generator<PinDto> get pin => combine3(
        any.nonEmptyLetterOrDigits,
        any.optionalMemoryDate,
        any.letterOrDigits,
        (String id, DateTime? memoryDate, String titleSuffix) => PinDto(
          id: id,
          mapId: 'map_1',
          title: 'Pin $titleSuffix',
          note: null,
          memoryDate: memoryDate,
          lat: 0,
          lng: 0,
          media: const <PinMediaDto>[],
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      );

  /// A sort order (`newest` or `oldest`).
  Generator<TimelineSortOrder> get timelineSortOrder => any.choose(
        const <TimelineSortOrder>[
          TimelineSortOrder.newest,
          TimelineSortOrder.oldest,
        ],
      );
}

/// Returns the sorted multiset of ids, so two lists compare equal exactly when
/// they contain the same ids with the same multiplicities, regardless of order.
List<String> _sortedIds(List<PinDto> pins) =>
    pins.map((PinDto pin) => pin.id).toList(growable: true)..sort();

void main() {
  // Glados runs 100 generated cases by default.
  Glados2<List<PinDto>, TimelineSortOrder>(
    any.list(any.pin),
    any.timelineSortOrder,
  ).test(
    'orderPins preserves the exact multiset of pin ids for any sort order',
    (List<PinDto> pins, TimelineSortOrder order) {
      final List<PinDto> ordered = orderPins(pins, order);

      // No pins added or removed: same length.
      expect(ordered.length, pins.length);

      // Same multiset of ids: none added, none removed, duplicates preserved.
      expect(_sortedIds(ordered), _sortedIds(pins));

      // The output is composed of the exact same pin instances as the input
      // (a permutation), confirming nothing is fabricated or dropped.
      expect(ordered.toSet().length, pins.toSet().length);
      for (final PinDto pin in pins) {
        expect(ordered.contains(pin), isTrue);
      }
    },
  );
}
