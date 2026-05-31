import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../data/repository_providers.dart';

final mapViewControllerProvider =
    StateNotifierProvider.autoDispose<MapViewController, MapViewState>((ref) {
  return MapViewController(
    mapRepository: ref.watch(mapRepositoryProvider),
    pinRepository: ref.watch(pinRepositoryProvider),
  );
});

class MapViewState {
  const MapViewState({
    this.map,
    this.pins = const <PinDto>[],
    this.isLoading = false,
    this.errorMessage,
    this.lastBbox,
  });

  final MapDto? map;
  final List<PinDto> pins;
  final bool isLoading;
  final String? errorMessage;
  final BboxQuery? lastBbox;

  bool get isEmpty => !isLoading && errorMessage == null && pins.isEmpty;

  MapViewState copyWith({
    MapDto? map,
    List<PinDto>? pins,
    bool? isLoading,
    Object? errorMessage = _unset,
    BboxQuery? lastBbox,
  }) {
    return MapViewState(
      map: map ?? this.map,
      pins: pins ?? this.pins,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      lastBbox: lastBbox ?? this.lastBbox,
    );
  }
}

class MapViewController extends StateNotifier<MapViewState> {
  MapViewController({
    required MapRepository mapRepository,
    required PinRepository pinRepository,
    Duration debounceDuration = const Duration(milliseconds: 350),
  })  : _mapRepository = mapRepository,
        _pinRepository = pinRepository,
        _debounceDuration = debounceDuration,
        super(const MapViewState());

  final MapRepository _mapRepository;
  final PinRepository _pinRepository;
  final Duration _debounceDuration;
  Timer? _viewportDebounce;
  int _requestVersion = 0;

  void viewportChanged(BboxQuery bbox) {
    state = state.copyWith(lastBbox: bbox);
    _viewportDebounce?.cancel();

    if (_debounceDuration == Duration.zero) {
      unawaited(_loadViewport(bbox));
      return;
    }

    _viewportDebounce = Timer(_debounceDuration, () {
      unawaited(_loadViewport(bbox));
    });
  }

  Future<void> loadViewportNow(BboxQuery bbox) async {
    _viewportDebounce?.cancel();
    await _loadViewport(bbox);
  }

  Future<void> refresh() async {
    final BboxQuery? bbox = state.lastBbox;
    if (bbox == null) {
      return;
    }

    await loadViewportNow(bbox);
  }

  Future<void> _loadViewport(BboxQuery bbox) async {
    final int requestVersion = ++_requestVersion;

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      lastBbox: bbox,
    );

    try {
      final MapDto map = state.map ?? await _mapRepository.getDefaultMap();
      final List<PinDto> pins = await _pinRepository.listByBbox(
        mapId: map.id,
        bbox: bbox,
      );

      if (requestVersion != _requestVersion) {
        return;
      }

      state = state.copyWith(
        map: map,
        pins: pins,
        isLoading: false,
        errorMessage: null,
      );
    } catch (_) {
      if (requestVersion != _requestVersion) {
        return;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not load memories.',
      );
    }
  }

  @override
  void dispose() {
    _viewportDebounce?.cancel();
    super.dispose();
  }
}

const Object _unset = Object();
