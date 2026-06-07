import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A simple, vendor-neutral online/offline signal used for Offline_Mode
/// decisions across the app.
enum NetworkStatus {
  online,
  offline;

  bool get isOnline => this == NetworkStatus.online;

  bool get isOffline => this == NetworkStatus.offline;
}

/// Project-owned port for observing network reachability.
///
/// Feature code depends on this interface rather than on `connectivity_plus`
/// directly, keeping the vendor dependency behind an adapter (OCP/DIP).
abstract interface class NetworkMonitor {
  /// Resolves the current [NetworkStatus] once.
  Future<NetworkStatus> currentStatus();

  /// Emits a [NetworkStatus] whenever reachability changes.
  Stream<NetworkStatus> statusChanges();
}

/// `connectivity_plus`-backed adapter implementing [NetworkMonitor].
class ConnectivityNetworkMonitor implements NetworkMonitor {
  ConnectivityNetworkMonitor({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<NetworkStatus> currentStatus() async {
    final List<ConnectivityResult> results =
        await _connectivity.checkConnectivity();
    return _statusFromResults(results);
  }

  @override
  Stream<NetworkStatus> statusChanges() {
    return _connectivity.onConnectivityChanged.map(_statusFromResults);
  }

  /// The device is considered offline only when there is no connectivity at
  /// all (empty list or a sole `none` result).
  static NetworkStatus _statusFromResults(List<ConnectivityResult> results) {
    final bool hasConnection = results.any(
      (ConnectivityResult result) => result != ConnectivityResult.none,
    );
    return hasConnection ? NetworkStatus.online : NetworkStatus.offline;
  }
}

/// Provides the project-owned [NetworkMonitor] adapter.
final networkMonitorProvider = Provider<NetworkMonitor>((ref) {
  return ConnectivityNetworkMonitor();
});

/// Exposes the current online/offline signal as a reactive provider.
///
/// Resolves the current status immediately and then tracks connectivity
/// changes. Consumers (e.g. `MediaUrlController`, the Timeline and Pin Detail
/// views) watch this for Offline_Mode behavior. Defaults to
/// [NetworkStatus.online] until the first reading resolves so content is not
/// pessimistically degraded on startup.
final networkStatusProvider = StreamProvider<NetworkStatus>((ref) async* {
  final NetworkMonitor monitor = ref.watch(networkMonitorProvider);
  yield await monitor.currentStatus();
  yield* monitor.statusChanges();
});
