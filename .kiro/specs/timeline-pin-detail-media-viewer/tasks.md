# Implementation Plan: Timeline, Pin Detail and Media Viewer

## Overview

Convert the design into incremental, repository-driven Flutter (`apps/mobile`) work. Each task
builds on the previous: first the data-layer additions (`MediaReadUrlDto`, `MediaRepository`
extension, fakes), then the pure ordering logic, then the Riverpod controllers, then the
screens and media-viewer widgets, then localization and wiring. Property-based tests (via
`glados`) cover the pure `orderPins` logic and media load-state resolution; widget/unit tests
(via `ProviderScope` overrides) cover rendering, navigation, and placeholder behavior.

All UI depends on Riverpod providers only (never Dio/HTTP directly), media bytes load from
Authorized Read URLs, text and friendly saved-location status stay visible offline, and every
new user-facing string is localized in English and Vietnamese.

## Tasks

- [x] 1. Add the media read-URL data model and repository operation
  - [x] 1.1 Add `MediaReadUrlDto` and export it
    - Create `apps/mobile/lib/data/models/media_read_url_dto.dart` with `url` and `expiresAt`
      fields and a `fromJson` factory using the existing `asJsonMap`/`readString`/`readDateTime`
      helpers
    - Add the new DTO to the `models.dart` barrel export
    - _Requirements: 7.1_

  - [x] 1.2 Extend `MediaRepository` with `createReadUrl` and implement the API repository
    - Add `Future<MediaReadUrlDto> createReadUrl(String mediaId)` to the `MediaRepository`
      interface in `apps/mobile/lib/data/repositories/media_repository.dart`
    - Implement `ApiMediaRepository.createReadUrl` calling
      `apiClient.get('/media/$mediaId/presign', decoder: MediaReadUrlDto.fromJson)`
    - _Requirements: 7.1, 7.2_

  - [x] 1.3 Implement `createReadUrl` on the fake media repository
    - Add `createReadUrl` to `FakeMediaRepository` returning a deterministic local URL plus an
      expiry so mock mode mirrors the real read-URL flow
    - _Requirements: 11.3, 11.4_

  - [x] 1.4 Write unit tests for `MediaReadUrlDto` and the fake `createReadUrl`
    - Test `fromJson` parsing of `url`/`expiresAt` and the fake's deterministic output
    - _Requirements: 7.1, 11.3, 11.4_

- [x] 2. Implement the pure Timeline ordering logic
  - [x] 2.1 Implement `orderPins` and `TimelineSortOrder`
    - Create `apps/mobile/lib/app/timeline_ordering.dart` defining
      `enum TimelineSortOrder { newest, oldest }` and a pure `orderPins(pins, order)` that
      partitions dated vs undated pins, sorts dated pins by `memoryDate` (desc for newest, asc
      for oldest) with `id` as a stable tie-breaker, and appends undated pins last in a stable
      order
    - _Requirements: 2.6, 2.7, 3.1, 3.2_

  - [x] 2.2 Write property test: ordering preserves the pin set
    - **Property 1: Ordering preserves the pin set**
    - **Validates: Requirements 2.5, 3.1, 3.4**

  - [x] 2.3 Write property test: undated pins placed after dated pins
    - **Property 2: Undated pins are placed after dated pins**
    - **Validates: Requirements 3.2**

  - [x] 2.4 Write property test: dated pins follow the selected direction
    - **Property 3: Dated pins follow the selected direction**
    - **Validates: Requirements 2.6, 2.7**

  - [x] 2.5 Write property test: sort toggle is order-reversible over the same set
    - **Property 4: Sort toggle is order-reversible over the same set**
    - **Validates: Requirements 2.5, 2.8, 3.4**

- [x] 3. Implement the network status provider
  - [x] 3.1 Flesh out `networkStatusProvider`
    - Implement `network_monitor.dart` to wrap `connectivity_plus` and expose a simple
      online/offline signal as a Riverpod provider for Offline_Mode decisions
    - _Requirements: 10.1, 10.2_

- [x] 4. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Implement the Timeline controller and screen
  - [x] 5.1 Implement `TimelineController` and `TimelineState`
    - Create the `AutoDisposeAsyncNotifier` that resolves the active map via
      `mapRepositoryProvider.getDefaultMap()`, loads the timeline with `order='desc'` (newest)
      on first build, exposes `setOrder` that reorders the loaded pins in memory via `orderPins`
      retaining the same pin set, and surfaces loading/error state
    - _Requirements: 1.1, 2.2, 2.3, 2.4, 2.5, 2.8, 11.1_

  - [x] 5.2 Write unit tests for `TimelineController`
    - Test first-load uses newest order, `setOrder` reorders without changing the pin set, and
      error state surfaces on repository failure
    - _Requirements: 2.2, 2.5, 2.8, 1.7_

  - [x] 5.3 Rewrite `TimelineScreen` to be controller-driven
    - Watch `timelineControllerProvider`; render loading indicator, one entry per pin showing
      title and localized memory-date label (or "date unknown"), localized empty-state on zero
      items, and localized error message + retry on failure; bind the newest/oldest sort toggle
      to `setOrder`; tapping an entry calls `context.push('/pins/{id}')`; remove the hard-coded
      mock fallback and static placeholder images
    - _Requirements: 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 2.1, 3.3, 4.1, 10.4, 12.1_

  - [x] 5.4 Write widget tests for `TimelineScreen`
    - Verify all pins render including undated pins; sort toggle reorders without removing pins;
      tapping an entry navigates to Pin Detail for the matching pin id; empty-state and
      error+retry render
    - _Requirements: 13.1, 13.2, 13.3, 1.6, 1.7_

- [x] 6. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 7. Implement the media URL controller
  - [x] 7.1 Implement `MediaLoadState` and `MediaUrlController`
    - Define the sealed `MediaLoadState` (`MediaLoading`, `MediaReady(url)`, `MediaUnavailable`)
      and the `family` controller keyed by `mediaId`: offline -> `MediaUnavailable`; online ->
      call `mediaRepositoryProvider.createReadUrl`; success -> `MediaReady(url)`, failure ->
      `MediaUnavailable`; provide `retry()` and connectivity-recovery re-resolution
    - _Requirements: 7.2, 7.3, 7.4, 8.5, 10.2, 10.5, 11.3_

  - [x] 7.2 Write property test: media load resolves to ready only with a non-empty URL
    - **Property 5: Media load resolves to ready only with a non-empty URL**
    - **Validates: Requirements 7.3, 7.4, 10.2**

- [x] 8. Implement the media viewer widgets
  - [x] 8.1 Implement `MediaPlaceholder`
    - Create `apps/mobile/lib/media/media_placeholder.dart` rendering a localized stand-in for
      pending/uncached/offline/failed media with an optional retry callback
    - _Requirements: 10.2, 10.3, 12.3_

  - [x] 8.2 Implement `ImageViewer`
    - Create `apps/mobile/lib/media/image_viewer.dart` that watches
      `mediaUrlControllerProvider(mediaId)`: loading indicator while resolving/decoding, load
      via `Image.network` on ready, `MediaPlaceholder` + localized retry on failure (retry calls
      controller `retry()`), and dismiss returns to Pin Detail
    - _Requirements: 8.2, 8.3, 8.4, 8.5, 8.6_

  - [x] 8.3 Implement the audio playback port, adapter, and `AudioPlayer` widget
    - Define a project-owned `AudioPlaybackPort` with a vendor adapter (no direct vendor
      coupling in feature code), then create `apps/mobile/lib/media/audio_player.dart` that
      plays from the Authorized Read URL, shows play/pause controls per playback state, and on
      load failure hides controls and shows an unavailable `MediaPlaceholder`
    - _Requirements: 9.2, 9.3, 9.4, 9.5_

  - [x] 8.4 Write widget tests for the media viewer widgets
    - Test `ImageViewer` placeholder + retry on failure and `AudioPlayer` hiding controls with
      unavailable placeholder on failure
    - _Requirements: 8.4, 9.5_

- [x] 9. Implement the Pin Detail controller and screen
  - [x] 9.1 Implement `PinDetailController`
    - Create the `AutoDisposeAsyncNotifierProvider.family` keyed by `pinId` that loads the pin
      via `pinRepositoryProvider.getPin(pinId)` and exposes the loaded `PinDto` or an error state
    - _Requirements: 4.2, 4.3, 5.7, 11.2_

  - [x] 9.2 Write unit tests for `PinDetailController`
    - Test successful load exposes the matching pin and repository failure surfaces error state
    - _Requirements: 4.3, 4.4_

  - [x] 9.3 Rewrite `PinDetailScreen` to be controller-driven
    - Watch `pinDetailControllerProvider(pinId)`; display title, note when non-empty,
      memory-date label or "date unknown", friendly saved-location or unavailable-location label,
      and a localized error on load failure; render a selectable thumbnail per image media item
      and an `AudioPlayer` per audio media item each backed by `mediaUrlControllerProvider`;
      show `MediaPlaceholder` for offline/pending/uncached/failed media while keeping
      title/note/date/saved-location status visible
    - _Requirements: 4.4, 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 8.1, 9.1, 10.1, 10.2, 10.3, 7.4, 12.2_

  - [x] 9.4 Wire Pin Detail navigation and action entry points
    - Add "view on map" -> `context.go('/?lat=..&lng=..')`, edit -> `context.push('/pins/{id}/edit')`,
      and delete/share action entry points; ensure back returns to the Timeline via the
      navigation stack
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

  - [x] 9.5 Write widget tests for `PinDetailScreen`
    - Verify `MediaPlaceholder` shows when a read URL cannot be retrieved or media fails to
      load; verify title, note, and friendly saved-location status render when media is
      unavailable; verify "date unknown" and friendly unavailable-location labels render for
      missing data
    - _Requirements: 13.4, 13.5, 3.3, 5.4, 5.6_

- [x] 10. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 11. Add localization strings and finalize wiring
  - [x] 11.1 Add localization keys for en and vi
    - Add all new keys (`timelineTitle`, `sortNewest`, `sortOldest`, `timelineEmpty`,
      `timelineError`, `retry`, `dateUnknown`, `locationUnavailable`, `note`,
      `viewOnMap`, `edit`, `share`, `delete`, `mediaUnavailable`, `audioUnavailable`,
      `pinLoadError`) to `app_en.arb` and `app_vi.arb`, run `flutter gen-l10n`, and implement the
      English fallback for the "date unknown" label
    - _Requirements: 3.3, 5.4, 12.1, 12.2, 12.3, 12.4_

  - [x] 11.2 Write localization smoke test
    - Verify every new key resolves in both `en` and `vi`
    - _Requirements: 12.4_

  - [x] 11.3 Verify mock-mode behavior end-to-end
    - Confirm the providers resolve to fake repositories under `USE_MOCK_DATA=true` for timeline,
      pin detail, and media read URLs, and that a fake failure surfaces a localized error without
      falling back to real repositories
    - _Requirements: 11.1, 11.2, 11.3, 11.5_

- [x] 12. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP.
- Each task references specific requirements for traceability.
- Checkpoints ensure incremental validation.
- Property tests (via `glados`) validate the universal correctness properties for the pure
  `orderPins` logic and media load-state resolution.
- Widget/unit tests validate rendering, navigation, and placeholder behavior via
  `ProviderScope` overrides.
- The UI layer must depend on Riverpod providers only and never call Dio/HTTP directly.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "2.1", "3.1"] },
    { "id": 1, "tasks": ["1.2", "2.2", "2.3", "2.4", "2.5"] },
    { "id": 2, "tasks": ["1.3", "5.1", "7.1", "8.1"] },
    { "id": 3, "tasks": ["1.4", "5.2", "7.2", "8.2", "8.3", "9.1"] },
    { "id": 4, "tasks": ["5.3", "9.2", "9.3"] },
    { "id": 5, "tasks": ["5.4", "8.4", "9.4", "11.1"] },
    { "id": 6, "tasks": ["9.5", "11.2", "11.3"] }
  ]
}
```
