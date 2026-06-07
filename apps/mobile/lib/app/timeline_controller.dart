import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/models.dart';
import '../data/repository_providers.dart';
import 'timeline_ordering.dart';

/// Immutable state rendered by the Timeline screen.
///
/// [orderedPins] is always the loaded pin set already projected through
/// [orderPins] for the active [order], so the widget can render it directly
/// without re-sorting.
class TimelineState {
  const TimelineState({
    required this.orderedPins,
    required this.order,
  });

  /// The loaded pins, already ordered for [order].
  final List<PinDto> orderedPins;

  /// The active sort order.
  final TimelineSortOrder order;

  TimelineState copyWith({
    List<PinDto>? orderedPins,
    TimelineSortOrder? order,
  }) {
    return TimelineState(
      orderedPins: orderedPins ?? this.orderedPins,
      order: order ?? this.order,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TimelineState &&
      other.order == order &&
      _listEquals(other.orderedPins, orderedPins);

  @override
  int get hashCode => Object.hash(order, Object.hashAll(orderedPins));
}

bool _listEquals(List<PinDto> a, List<PinDto> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

/// Maps a [TimelineSortOrder] to the repository `order` query parameter.
String _orderParam(TimelineSortOrder order) => switch (order) {
      TimelineSortOrder.newest => 'desc',
      TimelineSortOrder.oldest => 'asc',
    };

/// Owns Timeline loading, the active sort order, and the ordered projection of
/// pins for the Active Map.
///
/// Responsibilities (Requirements 1.1, 2.2-2.5, 2.8, 11.1):
/// - On first build: resolves the Active Map via
///   [MapRepository.getDefaultMap], then loads the timeline with the default
///   `newest` order (`order=desc`).
/// - [setOrder] reorders the already-loaded pins in memory via [orderPins],
///   retaining the same pin set without a network round-trip.
/// - Loading and error state are surfaced through the [AsyncNotifier] state so
///   the screen can render loading/error/retry branches.
///
/// The controller depends only on project-owned repository providers and never
/// calls Dio or HTTP directly.
class TimelineController extends AsyncNotifier<TimelineState> {
  @override
  Future<TimelineState> build() async {
    return _load(TimelineSortOrder.newest);
  }

  /// Loads the timeline for [order] from the Active Map.
  Future<TimelineState> _load(TimelineSortOrder order) async {
    final MapDto activeMap =
        await ref.read(mapRepositoryProvider).getDefaultMap();

    final TimelinePageDto page =
        await ref.read(timelineRepositoryProvider).listTimeline(
              mapId: activeMap.id,
              order: _orderParam(order),
            );

    return TimelineState(
      orderedPins: orderPins(page.items, order),
      order: order,
    );
  }

  /// Reorders the already-loaded pins in memory according to [order].
  ///
  /// The same pin set is retained (none added or removed) - only the order
  /// changes (Requirements 2.3, 2.4, 2.5, 2.8). No network request is made.
  void setOrder(TimelineSortOrder order) {
    final TimelineState? current = state.value;
    if (current == null || current.order == order) {
      return;
    }

    state = AsyncValue<TimelineState>.data(
      current.copyWith(
        orderedPins: orderPins(current.orderedPins, order),
        order: order,
      ),
    );
  }
}

/// Provides the [TimelineController] and its [TimelineState].
final timelineControllerProvider =
    AsyncNotifierProvider.autoDispose<TimelineController, TimelineState>(
  TimelineController.new,
);
