import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/models.dart';
import '../data/repository_providers.dart';

/// Loads and owns the [PinDto] for a single Pin Detail view, keyed by `pinId`.
///
/// Responsibilities (Requirements 4.2, 4.3, 5.7, 11.2):
/// - On build: requests the pin via [PinRepository.getPin] through the
///   [pinRepositoryProvider] (the fake repository under `USE_MOCK_DATA`).
/// - Exposes the loaded [PinDto] as the [AsyncNotifier] data state so the
///   screen renders content derived only from the repository result.
/// - Surfaces repository failures as an [AsyncValue] error state so the screen
///   can render a localized error message.
///
/// The controller depends only on the project-owned [pinRepositoryProvider] and
/// never calls Dio or HTTP directly.
class PinDetailController extends AsyncNotifier<PinDto> {
  PinDetailController(this.pinId);

  final String pinId;

  @override
  Future<PinDto> build() async {
    return ref.read(pinRepositoryProvider).getPin(pinId);
  }

  /// Re-requests the pin, surfacing a fresh loading state followed by the
  /// loaded pin or an error.
  Future<void> reload() async {
    state = const AsyncValue<PinDto>.loading();
    state = await AsyncValue.guard<PinDto>(
      () => ref.read(pinRepositoryProvider).getPin(pinId),
    );
  }
}

/// Family controller keyed by `pinId`, exposing the loaded [PinDto] (or an
/// error state) for the Pin Detail view.
final pinDetailControllerProvider = AsyncNotifierProvider.autoDispose
    .family<PinDetailController, PinDto, String>(
  PinDetailController.new,
);
