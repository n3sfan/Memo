import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'media_placeholder.dart';
import 'media_url_controller.dart';

/// Full-screen viewer for a single image-type media item attached to a pin.
///
/// Opened when an image thumbnail is selected in Pin Detail (Requirement 8.2).
/// The widget watches [mediaUrlControllerProvider] for the media's Authorized
/// Read URL and never constructs a URL or calls Dio directly (UI depends only
/// on providers - AGENTS.md).
///
/// Behavior (Requirements 8.3-8.6):
/// - While the read URL is being resolved ([MediaLoading]/`AsyncLoading`) or
///   while [Image.network] is still decoding, a loading indicator is shown
///   (8.3).
/// - On [MediaReady], the image is loaded via `Image.network(url)`.
/// - On [MediaUnavailable] or an image load error, a [MediaPlaceholder] with a
///   localized retry control is shown (8.4); activating retry calls the
///   controller's [MediaUrlController.retry] (8.5).
/// - Dismissing (via the close button / system back) returns to Pin Detail
///   (8.6).
///
/// Localized strings are supplied by the calling screen; English fallbacks are
/// used until the feature's localization keys are generated (task 11.1).
class ImageViewer extends ConsumerWidget {
  const ImageViewer({
    required this.mediaId,
    this.unavailableMessage,
    this.retryLabel,
    this.closeLabel,
    super.key,
  });

  /// Default English message used when [unavailableMessage] is not supplied.
  static const String defaultUnavailableMessage = 'Image unavailable';

  /// Default English label used when [retryLabel] is not supplied.
  static const String defaultRetryLabel = 'Retry';

  /// Default English label used when [closeLabel] is not supplied.
  static const String defaultCloseLabel = 'Close';

  /// The id of the image media item to display.
  final String mediaId;

  /// Localized "image unavailable" message; falls back to English when null.
  final String? unavailableMessage;

  /// Localized retry control label; falls back to English when null.
  final String? retryLabel;

  /// Localized close control label; falls back to English when null.
  final String? closeLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<MediaLoadState> urlState =
        ref.watch(mediaUrlControllerProvider(mediaId));

    final String resolvedClose = closeLabel ?? defaultCloseLabel;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          key: const ValueKey<String>('image-viewer-close-button'),
          icon: const Icon(Icons.close),
          tooltip: resolvedClose,
          // Dismiss returns to Pin Detail (Req 8.6).
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: urlState.when(
          // The read URL is still being resolved (Req 8.3).
          loading: _buildLoading,
          // Resolution errors degrade to the unavailable placeholder (Req 8.4).
          error: (_, __) => _buildUnavailable(ref),
          data: (MediaLoadState loadState) {
            // Offline, pending, or failed to resolve -> placeholder + retry.
            if (loadState is! MediaReady) {
              return _buildUnavailable(ref);
            }
            return _buildImage(ref, loadState.url);
          },
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const SizedBox(
      width: 36,
      height: 36,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }

  Widget _buildImage(WidgetRef ref, String url) {
    return Image.network(
      url,
      fit: BoxFit.contain,
      // Show a loading indicator while the image is decoding (Req 8.3).
      loadingBuilder: (
        BuildContext context,
        Widget child,
        ImageChunkEvent? progress,
      ) {
        if (progress == null) {
          return child;
        }
        return _buildLoading();
      },
      // Image failed to load from the URL -> placeholder + retry (Req 8.4).
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
        return _buildUnavailable(ref);
      },
    );
  }

  Widget _buildUnavailable(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: MediaPlaceholder(
        message: unavailableMessage ?? defaultUnavailableMessage,
        retryLabel: retryLabel ?? defaultRetryLabel,
        icon: Icons.broken_image_outlined,
        // Retry re-requests the read URL and re-attempts the load (Req 8.5).
        onRetry: () =>
            ref.read(mediaUrlControllerProvider(mediaId).notifier).retry(),
      ),
    );
  }
}
