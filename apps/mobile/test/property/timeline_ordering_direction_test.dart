// Feature: timeline-pin-detail-media-viewer, Property 3: Dated pins follow the selected direction
//
// Property 3: For any list of pins, the dated pins in the output are ordered by
// `memoryDate` descending when the order is `newest` and ascending when the
// order is `oldest`.
//
// Validates: Requirements 2.6, 2.7

import 'package:glados/glados.dart';
import 'package:memory_map_mobile/app/timeline_ordering.dart';
import 'package:memory_map_mobile/data/models/models.dart';

/// Generators for [PinDto] values with a mix of present/absent `memoryDate`.
extension TimelineAny on Any {
  /// Generates a `memoryDate` that is present roughly half the time and absent
  /// otherwise, exercising both the dated and undated partitions of
  /// [orderPins].
  Generator<DateTime?> get optionalMemoryDate => combine2(
        any.bool,
        any.dateTime,
        (bool hasDate, DateTime date) => hasDate ? date : null,
      );

  /// Generates a [PinDto] with a random id, a mix of present/absent
  /// `memoryDate`, and otherwise fixed, irrelevant fields. The id is drawn from
  /// a small alphabet so that ties (equal ids) and a wide spread of values both
  /// occur, exercising the `id` tie-breaker.
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
}

void main() {
  Glados(any.list(any.pin)).test(
    'dated pins are ordered descending by memoryDate when order is newest',
    (List<PinDto> pins) {
      final List<PinDto> ordered = orderPins(pins, TimelineSortOrder.newest);

      final List<DateTime> datedTimes = ordered
          .where((PinDto pin) => pin.memoryDate != null)
          .map((PinDto pin) => pin.memoryDate!)
          .toList(growable: false);

      for (int i = 0; i + 1 < datedTimes.length; i++) {
        // Descending: each date is the same as or after the next one.
        expect(
          datedTimes[i].isBefore(datedTimes[i + 1]),
          isFalse,
          reason: 'newest order must not have an earlier date before a later '
              'date at index $i: $datedTimes',
        );
      }
    },
  );

  Glados(any.list(any.pin)).test(
    'dated pins are ordered ascending by memoryDate when order is oldest',
    (List<PinDto> pins) {
      final List<PinDto> ordered = orderPins(pins, TimelineSortOrder.oldest);

      final List<DateTime> datedTimes = ordered
          .where((PinDto pin) => pin.memoryDate != null)
          .map((PinDto pin) => pin.memoryDate!)
          .toList(growable: false);

      for (int i = 0; i + 1 < datedTimes.length; i++) {
        // Ascending: each date is the same as or before the next one.
        expect(
          datedTimes[i].isAfter(datedTimes[i + 1]),
          isFalse,
          reason: 'oldest order must not have a later date before an earlier '
              'date at index $i: $datedTimes',
        );
      }
    },
  );
}
