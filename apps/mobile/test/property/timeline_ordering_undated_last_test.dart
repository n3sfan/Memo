// Feature: timeline-pin-detail-media-viewer, Property 2: Undated pins are placed after dated pins
//
// Property 2 (design.md "Correctness Properties"):
//   For any list of pins and any sort order, in the output every pin that has a
//   `memoryDate` appears before every pin that has no `memoryDate`.
//
// Validates: Requirements 3.2

import 'package:glados/glados.dart';
import 'package:memory_map_mobile/app/timeline_ordering.dart';
import 'package:memory_map_mobile/data/models/models.dart';

/// Generators for [PinDto] values exercising both ordering partitions.
extension TimelineUndatedLastAny on Any {
  /// A `memoryDate` that is present roughly half the time and absent otherwise,
  /// so both the dated and undated partitions of [orderPins] are exercised.
  Generator<DateTime?> get optionalMemoryDate => combine2(
        any.bool,
        any.dateTime,
        (bool hasDate, DateTime date) => hasDate ? date : null,
      );

  /// A [PinDto] with a random id, title, and a mix of present/absent
  /// `memoryDate`. The id is drawn from a small alphabet so ties and a wide
  /// spread of values both occur.
  Generator<PinDto> get pin => combine2(
        any.nonEmptyLetterOrDigits,
        any.optionalMemoryDate,
        (String id, DateTime? memoryDate) => PinDto(
          id: id,
          mapId: 'map_1',
          title: 'Pin $id',
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

void main() {
  // Glados runs 100 generated cases by default.
  Glados2<List<PinDto>, TimelineSortOrder>(
    any.list(any.pin),
    any.timelineSortOrder,
  ).test(
    'orderPins places every dated pin before every undated pin for any order',
    (List<PinDto> pins, TimelineSortOrder order) {
      final List<PinDto> ordered = orderPins(pins, order);

      // The index of the first undated pin (no memoryDate). Once an undated pin
      // appears, no dated pin may follow it.
      bool seenUndated = false;
      for (int i = 0; i < ordered.length; i++) {
        final bool isUndated = ordered[i].memoryDate == null;
        if (isUndated) {
          seenUndated = true;
        } else {
          // A dated pin must never appear after an undated pin.
          expect(
            seenUndated,
            isFalse,
            reason: 'dated pin at index $i appears after an undated pin: '
                '${ordered.map((PinDto p) => p.memoryDate).toList()}',
          );
        }
      }
    },
  );
}
