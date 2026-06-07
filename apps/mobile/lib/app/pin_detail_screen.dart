import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/models/models.dart';
import '../data/repository_providers.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_extensions.dart';
import '../media/audio_player.dart';
import '../media/image_viewer.dart';
import '../media/media_placeholder.dart';
import '../media/media_url_controller.dart';
import 'pin_detail_controller.dart';
import 'theme.dart';

/// Returns true when the pin's latitude/longitude are within valid ranges and
/// are finite numbers (Req 5.5/5.6).
bool _hasValidCoordinates(PinDto pin) {
  final double lat = pin.lat;
  final double lng = pin.lng;
  if (lat.isNaN || lng.isNaN || lat.isInfinite || lng.isInfinite) {
    return false;
  }
  return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
}

/// Controller-driven Pin Detail view.
///
/// Watches [pinDetailControllerProvider] and renders loading / error / data
/// branches (Req 4.4). The loaded pin's text and saved map-location status stay
/// visible regardless of media state (Req 10.1); media items load independently
/// through [mediaUrlControllerProvider] and degrade to [MediaPlaceholder] when
/// they cannot be loaded (Req 7.4, 10.2, 10.3).
class PinDetailScreen extends ConsumerWidget {
  const PinDetailScreen({required this.pinId, super.key});

  final String pinId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AsyncValue<PinDto> pinState =
        ref.watch(pinDetailControllerProvider(pinId));

    return pinState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      // Localized error message on load failure (Req 4.4).
      error: (Object error, StackTrace stackTrace) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.pinLoadError,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
        ),
      ),
      data: (PinDto pin) => _PinDetailView(pin: pin, pinId: pinId),
    );
  }
}

/// Renders the loaded [PinDto]. Content is derived only from the pin returned
/// by the repository (Req 5.7).
class _PinDetailView extends ConsumerWidget {
  const _PinDetailView({required this.pin, required this.pinId});

  final PinDto pin;
  final String pinId;

  String _memoryDateLabel(BuildContext context) {
    final DateTime? memoryDate = pin.memoryDate;
    if (memoryDate == null) {
      // Localized "date unknown" with English fallback (Req 5.4).
      return context.dateUnknownLabel;
    }
    final String locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.yMMMd(locale).format(memoryDate.toLocal());
  }

  /// Builds the map-route location for the "view on map" action (Req 6.1).
  ///
  /// When the pin has valid coordinates, the `lat`/`lng` query parameters are
  /// included so the map route can focus on this memory. The parameter names
  /// match those parsed by the router's `_coordinatesFromQuery` helper and used
  /// by the map screen's pin-editor navigation. When the coordinates are
  /// invalid, the bare map route (`/`) is used, which is acceptable per the
  /// task spec.
  String _viewOnMapLocation() {
    if (!_hasValidCoordinates(pin)) {
      return '/';
    }
    final Uri location = Uri(
      path: '/',
      queryParameters: <String, String>{
        'lat': pin.lat.toStringAsFixed(6),
        'lng': pin.lng.toStringAsFixed(6),
      },
    );
    return location.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final List<PinMediaDto> imageMedia = pin.media
        .where((PinMediaDto m) => m.mediaType == PinMediaType.image)
        .toList(growable: false);
    final List<PinMediaDto> audioMedia = pin.media
        .where((PinMediaDto m) => m.mediaType == PinMediaType.audio)
        .toList(growable: false);

    final bool hasNote = pin.note != null && pin.note!.isNotEmpty;
    final bool hasCoordinates = _hasValidCoordinates(pin);

    return Scaffold(
      appBar: AppBar(),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton.icon(
          // "View on map" navigates to the map route with the pin's
          // coordinates so the map can focus on this memory (Req 6.1). Uses
          // `context.go` so the map becomes the active shell destination.
          onPressed: () => context.go(_viewOnMapLocation()),
          icon: const Icon(Icons.map_outlined),
          label: Text(l10n.viewOnMap),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Icon(Icons.location_on, size: 48, color: MemoTheme.accent),
            ),
            const SizedBox(height: 16),
            // Pin title (Req 5.1).
            Text(
              pin.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: MemoTheme.onBackground,
                  ),
            ),
            const SizedBox(height: 8),
            // Memory-date label or "date unknown" (Req 5.3, 5.4).
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.black54,
                ),
                const SizedBox(width: 4),
                Text(
                  _memoryDateLabel(context),
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Image media: one selectable thumbnail per image item (Req 8.1),
            // each backed by its own mediaUrlControllerProvider.
            if (imageMedia.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final PinMediaDto media in imageMedia)
                    SizedBox(
                      width: 150,
                      child: _ImageThumbnail(media: media),
                    ),
                ],
              ),
              const SizedBox(height: 24),
            ],
            // Note when non-empty (Req 5.2).
            if (hasNote) ...[
              Row(
                children: [
                  const Icon(Icons.eco, size: 18, color: MemoTheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    l10n.note,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(pin.note!, style: const TextStyle(height: 1.5)),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
            ],
            _LocationCard(hasCoordinates: hasCoordinates),
            // Audio media: an AudioPlayer per audio item (Req 9.1), each backed
            // by its own mediaUrlControllerProvider.
            if (audioMedia.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              for (final PinMediaDto media in audioMedia) ...[
                AudioPlayer(
                  mediaId: media.id,
                  unavailableMessage: l10n.audioUnavailable,
                  playLabel: l10n.play,
                  pauseLabel: l10n.pause,
                ),
                const SizedBox(height: 12),
              ],
            ],
            const SizedBox(height: 32),
            // Action entry points (refined in task 9.4).
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionItem(
                  icon: Icons.edit_outlined,
                  label: l10n.edit,
                  onTap: () {
                    context.push(
                      '/pins/${Uri.encodeComponent(pinId)}/edit',
                    );
                  },
                ),
                _ActionItem(
                  icon: Icons.share_outlined,
                  label: l10n.share,
                  onTap: () => _showShareSheet(context),
                ),
                _ActionItem(
                  icon: Icons.delete_outline,
                  label: l10n.delete,
                  color: MemoTheme.danger,
                  onTap: () => _showDeleteSheet(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _shareText(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final StringBuffer buffer = StringBuffer(pin.title);
    if (pin.note != null && pin.note!.isNotEmpty) {
      buffer
        ..writeln()
        ..write(pin.note);
    }
    buffer
      ..writeln()
      ..write(_memoryDateLabel(context));
    if (_hasValidCoordinates(pin)) {
      buffer
        ..writeln()
        ..write(l10n.savedMapLocation);
    }
    return buffer.toString();
  }

  void _showShareSheet(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String shareText = _shareText(context);
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.share,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SelectableText(
                shareText,
                style: const TextStyle(height: 1.4),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: shareText));
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.copiedToClipboard)),
                  );
                },
                icon: const Icon(Icons.copy),
                label: Text(l10n.copy),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteSheet(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: MemoTheme.danger,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.deletePinTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.deletePinMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              const SizedBox(height: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: MemoTheme.danger,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await ref.read(pinRepositoryProvider).deletePin(pinId);
                    if (!context.mounted) {
                      return;
                    }
                    context.go('/timeline');
                  } catch (_) {
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.deleteFailed)),
                    );
                  }
                },
                child: Text(l10n.delete),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.hasCoordinates});

  final bool hasCoordinates;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_outlined, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.location,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  hasCoordinates
                      ? l10n.savedMapLocation
                      : l10n.locationUnavailable,
                  style: const TextStyle(color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A selectable image thumbnail backed by [mediaUrlControllerProvider]
/// (Req 8.1). Shows a small [Image.network] when the read URL is ready, a
/// loading indicator while it resolves, and a [MediaPlaceholder] when the media
/// is offline/pending/uncached/failed (Req 7.4, 10.2, 10.3). Tapping a ready
/// thumbnail opens the full-screen [ImageViewer] for the media id (Req 8.2).
class _ImageThumbnail extends ConsumerWidget {
  const _ImageThumbnail({required this.media});

  final PinMediaDto media;

  void _openViewer(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (BuildContext context) => ImageViewer(
          mediaId: media.id,
          unavailableMessage: l10n.mediaUnavailable,
          retryLabel: l10n.retry,
          closeLabel: l10n.close,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AsyncValue<MediaLoadState> urlState =
        ref.watch(mediaUrlControllerProvider(media.id));

    return urlState.when(
      loading: _buildLoading,
      error: (_, __) => _buildPlaceholder(l10n),
      data: (MediaLoadState loadState) {
        if (loadState is! MediaReady) {
          return _buildPlaceholder(l10n);
        }
        return _buildThumbnail(context, loadState.url, l10n);
      },
    );
  }

  Widget _buildLoading() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(AppLocalizations l10n) {
    return AspectRatio(
      aspectRatio: 1,
      child: MediaPlaceholder(
        message: l10n.mediaUnavailable,
        icon: Icons.broken_image_outlined,
      ),
    );
  }

  Widget _buildThumbnail(
    BuildContext context,
    String url,
    AppLocalizations l10n,
  ) {
    return GestureDetector(
      key: ValueKey<String>('image-thumbnail-${media.id}'),
      onTap: () => _openViewer(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 1,
          child: Image.network(
            url,
            fit: BoxFit.cover,
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
            errorBuilder:
                (BuildContext context, Object error, StackTrace? stack) {
              return MediaPlaceholder(
                message: l10n.mediaUnavailable,
                icon: Icons.broken_image_outlined,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 72, minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
