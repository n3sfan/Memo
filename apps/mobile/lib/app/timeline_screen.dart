import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/models/models.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_extensions.dart';
import 'theme.dart';
import 'timeline_controller.dart';
import 'timeline_ordering.dart';

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  static const int _bottomNavIndex = 1;

  void _onBottomNavTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        return;
      case 1:
        return;
      case 2:
        context.go('/duo');
        return;
      case 3:
        context.go('/settings');
        return;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AsyncValue<TimelineState> timeline =
        ref.watch(timelineControllerProvider);
    final TimelineSortOrder activeOrder =
        timeline.value?.order ?? TimelineSortOrder.newest;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.timelineTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _SortToggle(
              activeOrder: activeOrder,
              onChanged: (TimelineSortOrder order) =>
                  ref.read(timelineControllerProvider.notifier).setOrder(order),
            ),
          ),
        ),
      ),
      body: timeline.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) => _TimelineError(
          onRetry: () => ref.invalidate(timelineControllerProvider),
        ),
        data: (TimelineState state) {
          if (state.orderedPins.isEmpty) {
            return const _TimelineEmpty();
          }
          return _TimelineList(pins: state.orderedPins);
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: (int index) => _onBottomNavTapped(context, index),
        selectedItemColor: MemoTheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.map_outlined),
            label: l10n.navMap,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.access_time),
            label: l10n.navTimeline,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_outline),
            label: l10n.navDuo,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}

/// Newest/oldest sort toggle bound to [TimelineController.setOrder] (Req 2.1).
class _SortToggle extends StatelessWidget {
  const _SortToggle({
    required this.activeOrder,
    required this.onChanged,
  });

  final TimelineSortOrder activeOrder;
  final ValueChanged<TimelineSortOrder> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool newestSelected = activeOrder == TimelineSortOrder.newest;
    return Row(
      children: [
        Expanded(
          child: newestSelected
              ? FilledButton(
                  onPressed: () => onChanged(TimelineSortOrder.newest),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.horizontal(left: Radius.circular(20)),
                    ),
                  ),
                  child: Text(l10n.sortNewest),
                )
              : OutlinedButton(
                  onPressed: () => onChanged(TimelineSortOrder.newest),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.horizontal(left: Radius.circular(20)),
                    ),
                    side: const BorderSide(color: Colors.black12),
                    backgroundColor: Colors.transparent,
                  ),
                  child: Text(
                    l10n.sortNewest,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
        ),
        Expanded(
          child: !newestSelected
              ? FilledButton(
                  onPressed: () => onChanged(TimelineSortOrder.oldest),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.horizontal(right: Radius.circular(20)),
                    ),
                  ),
                  child: Text(l10n.sortOldest),
                )
              : OutlinedButton(
                  onPressed: () => onChanged(TimelineSortOrder.oldest),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.horizontal(right: Radius.circular(20)),
                    ),
                    side: const BorderSide(color: Colors.black12),
                    backgroundColor: Colors.transparent,
                  ),
                  child: Text(
                    l10n.sortOldest,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Localized empty-state shown when zero pins are returned (Req 1.6).
class _TimelineEmpty extends StatelessWidget {
  const _TimelineEmpty();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          l10n.timelineEmpty,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ),
    );
  }
}

/// Localized error message with a retry control (Req 1.7).
class _TimelineError extends StatelessWidget {
  const _TimelineError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.timelineError,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
              ),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders one entry per pin (Req 1.3) with title (Req 1.5) and a localized
/// memory-date label or "date unknown" (Req 1.4, 3.3, 10.4).
class _TimelineList extends StatelessWidget {
  const _TimelineList({required this.pins});

  final List<PinDto> pins;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 24, left: 24, right: 16),
      itemCount: pins.length,
      itemBuilder: (BuildContext context, int index) {
        final PinDto pin = pins[index];
        return _TimelineEntry(pin: pin);
      },
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.pin});

  final PinDto pin;

  String _memoryDateLabel(BuildContext context) {
    final DateTime? memoryDate = pin.memoryDate;
    if (memoryDate == null) {
      // Localized "date unknown" with English fallback (Req 3.3).
      return context.dateUnknownLabel;
    }
    final String locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.yMMMd(locale).format(memoryDate.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 4,
          top: 0,
          bottom: 0,
          child: Container(width: 2, color: Colors.black12),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 24),
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: MemoTheme.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () =>
                        context.push('/pins/${Uri.encodeComponent(pin.id)}'),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 64),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _memoryDateLabel(context),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pin.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
