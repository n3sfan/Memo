import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_map_mobile/sync/network_monitor.dart';

void main() {
  group('NetworkStatus', () {
    test('online reports isOnline and not isOffline', () {
      expect(NetworkStatus.online.isOnline, isTrue);
      expect(NetworkStatus.online.isOffline, isFalse);
    });

    test('offline reports isOffline and not isOnline', () {
      expect(NetworkStatus.offline.isOffline, isTrue);
      expect(NetworkStatus.offline.isOnline, isFalse);
    });
  });

  group('networkStatusProvider', () {
    test('emits the current status first, then tracks changes', () async {
      final StreamController<NetworkStatus> changes =
          StreamController<NetworkStatus>.broadcast();
      final _FakeNetworkMonitor monitor = _FakeNetworkMonitor(
        current: NetworkStatus.online,
        changes: changes.stream,
      );
      final ProviderContainer container = ProviderContainer(
        overrides: [
          networkMonitorProvider.overrideWithValue(monitor),
        ],
      );

      final List<NetworkStatus> seen = <NetworkStatus>[];
      final ProviderSubscription<AsyncValue<NetworkStatus>> sub =
          container.listen<AsyncValue<NetworkStatus>>(
        networkStatusProvider,
        (AsyncValue<NetworkStatus>? previous, AsyncValue<NetworkStatus> next) {
          final NetworkStatus? value = next.asData?.value;
          if (value != null) {
            seen.add(value);
          }
        },
        fireImmediately: true,
      );

      // Allow the initial currentStatus() reading to resolve.
      await _pump();
      expect(seen, <NetworkStatus>[NetworkStatus.online]);

      changes
        ..add(NetworkStatus.offline)
        ..add(NetworkStatus.online);
      await _pump();

      expect(
        seen,
        <NetworkStatus>[
          NetworkStatus.online,
          NetworkStatus.offline,
          NetworkStatus.online,
        ],
      );

      sub.close();
      container.dispose();
      await changes.close();
    });

    test('defaults to online when offline is reported by the monitor',
        () async {
      final StreamController<NetworkStatus> changes =
          StreamController<NetworkStatus>.broadcast();
      final _FakeNetworkMonitor monitor = _FakeNetworkMonitor(
        current: NetworkStatus.offline,
        changes: changes.stream,
      );
      final ProviderContainer container = ProviderContainer(
        overrides: [
          networkMonitorProvider.overrideWithValue(monitor),
        ],
      );

      AsyncValue<NetworkStatus> latest = const AsyncLoading();
      final ProviderSubscription<AsyncValue<NetworkStatus>> sub =
          container.listen<AsyncValue<NetworkStatus>>(
        networkStatusProvider,
        (AsyncValue<NetworkStatus>? previous, AsyncValue<NetworkStatus> next) {
          latest = next;
        },
        fireImmediately: true,
      );

      await _pump();
      expect(latest.asData?.value, NetworkStatus.offline);

      sub.close();
      container.dispose();
      await changes.close();
    });
  });
}

/// Lets pending microtasks and stream events settle.
Future<void> _pump() => Future<void>.delayed(const Duration(milliseconds: 20));

class _FakeNetworkMonitor implements NetworkMonitor {
  _FakeNetworkMonitor({required this.current, required this.changes});

  final NetworkStatus current;
  final Stream<NetworkStatus> changes;

  @override
  Future<NetworkStatus> currentStatus() async => current;

  @override
  Stream<NetworkStatus> statusChanges() => changes;
}
