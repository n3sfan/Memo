import '../data/models/models.dart';

/// The Timeline ordering selection.
///
/// `newest` maps to a descending memory-date order (`order=desc`) and `oldest`
/// maps to an ascending memory-date order (`order=asc`).
enum TimelineSortOrder { newest, oldest }

/// Orders [pins] for the Timeline according to [order].
///
/// This is a pure function: it never mutates [pins] and always returns a new
/// list. The ordering mirrors the backend timeline contract:
///
/// 1. Pins are partitioned into those that have a [PinDto.memoryDate] (dated)
///    and those that do not (undated).
/// 2. Dated pins are sorted by `memoryDate` - descending for
///    [TimelineSortOrder.newest] and ascending for [TimelineSortOrder.oldest] -
///    using `id` as a stable tie-breaker in the same direction as the date
///    (matching `ORDER BY memory_date {DESC|ASC} NULLS LAST, id {DESC|ASC}`).
/// 3. Undated pins are appended after all dated pins, preserving their original
///    relative order from [pins] (NULLS LAST for both directions).
List<PinDto> orderPins(List<PinDto> pins, TimelineSortOrder order) {
  final List<PinDto> dated = <PinDto>[];
  final List<PinDto> undated = <PinDto>[];

  for (final PinDto pin in pins) {
    if (pin.memoryDate == null) {
      undated.add(pin);
    } else {
      dated.add(pin);
    }
  }

  dated.sort((PinDto a, PinDto b) => _compareDated(a, b, order));

  return <PinDto>[...dated, ...undated];
}

int _compareDated(PinDto a, PinDto b, TimelineSortOrder order) {
  // Both pins are guaranteed to have a non-null memoryDate here.
  final DateTime aDate = a.memoryDate!;
  final DateTime bDate = b.memoryDate!;

  final int dateComparison = aDate.compareTo(bDate);
  final int idComparison = a.id.compareTo(b.id);

  return switch (order) {
    // Newest first: later dates and larger ids come first.
    TimelineSortOrder.newest =>
      dateComparison != 0 ? -dateComparison : -idComparison,
    // Oldest first: earlier dates and smaller ids come first.
    TimelineSortOrder.oldest =>
      dateComparison != 0 ? dateComparison : idComparison,
  };
}
