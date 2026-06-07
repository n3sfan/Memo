import 'package:flutter/material.dart';

import '../app/theme.dart';

/// A shared visual stand-in shown when a media item cannot be displayed because
/// it is pending, uncached, offline, or failed to load.
///
/// The widget is localization-agnostic: the calling screen supplies the already
/// localized [message] and (optional) [retryLabel] strings. When those are not
/// provided, the widget falls back to English defaults so it remains safe to use
/// before the feature's localization keys are generated.
///
/// When an [onRetry] callback is provided, a retry control is rendered that
/// invokes the callback when activated.
///
/// _Requirements: 10.2, 10.3, 12.3_
class MediaPlaceholder extends StatelessWidget {
  const MediaPlaceholder({
    this.message,
    this.retryLabel,
    this.onRetry,
    this.icon = Icons.broken_image_outlined,
    super.key,
  });

  /// Default English message used when [message] is not supplied by the caller.
  static const String defaultMessage = 'Media unavailable';

  /// Default English retry label used when [retryLabel] is not supplied.
  static const String defaultRetryLabel = 'Retry';

  /// Localized "media unavailable" message supplied by the calling screen.
  ///
  /// Falls back to [defaultMessage] when null.
  final String? message;

  /// Localized label for the retry control supplied by the calling screen.
  ///
  /// Falls back to [defaultRetryLabel] when null. Only rendered when [onRetry]
  /// is non-null.
  final String? retryLabel;

  /// Optional retry callback. When non-null, a retry control is shown that
  /// invokes this callback.
  final VoidCallback? onRetry;

  /// Icon rendered above the message.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final String resolvedMessage = message ?? defaultMessage;
    final String resolvedRetryLabel = retryLabel ?? defaultRetryLabel;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact =
            constraints.maxWidth < 180 || constraints.maxHeight < 180;

        return Semantics(
          label: resolvedMessage,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(compact ? 12 : 24),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: compact ? 28 : 40,
                  color: MemoTheme.onBackground.withValues(alpha: 0.5),
                ),
                SizedBox(height: compact ? 8 : 12),
                Text(
                  resolvedMessage,
                  maxLines: compact ? 2 : null,
                  overflow:
                      compact ? TextOverflow.ellipsis : TextOverflow.visible,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: compact ? 12 : 14,
                    color: MemoTheme.onBackground.withValues(alpha: 0.7),
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(resolvedRetryLabel),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      foregroundColor: MemoTheme.primary,
                      side: const BorderSide(color: MemoTheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
