import 'package:flutter/widgets.dart';

import 'app_localizations.dart';
import 'app_localizations_en.dart';

/// Localization helpers that resolve feature strings with a safe English
/// fallback when the localized delegate is unavailable in the current
/// [BuildContext].
///
/// Requirements 3.3 and 5.4 mandate that the "date unknown" label falls back to
/// the English string if the localized value cannot be resolved (for example,
/// when [AppLocalizations] has not been injected into the widget tree). The
/// English source of truth is the generated [AppLocalizationsEn] so the
/// fallback never drifts from the `app_en.arb` value.
extension AppLocalizationsContext on BuildContext {
  /// English-source localizations, used as the fallback when no localized
  /// [AppLocalizations] instance is available for this context.
  static final AppLocalizations _englishFallback = AppLocalizationsEn();

  /// The localized "date unknown" label, falling back to the English string
  /// when the localized value is unavailable (Req 3.3, 5.4).
  String get dateUnknownLabel =>
      AppLocalizations.of(this)?.dateUnknown ?? _englishFallback.dateUnknown;
}
