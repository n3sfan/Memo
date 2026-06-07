import 'package:flutter_test/flutter_test.dart';
import 'package:memory_map_mobile/l10n/app_localizations.dart';
import 'package:memory_map_mobile/l10n/app_localizations_en.dart';
import 'package:memory_map_mobile/l10n/app_localizations_vi.dart';

/// Localization smoke test (Task 11.2).
///
/// Verifies that every new key introduced for the timeline / pin detail /
/// media viewer feature resolves to a non-empty string in BOTH the `en` and
/// `vi` locales.
///
/// _Requirements: 12.4_
void main() {
  // Each entry maps a human-readable key name to the getter on AppLocalizations.
  final Map<String, String Function(AppLocalizations)> newKeys =
      <String, String Function(AppLocalizations)>{
    'navMap': (l) => l.navMap,
    'navTimeline': (l) => l.navTimeline,
    'navDuo': (l) => l.navDuo,
    'navSettings': (l) => l.navSettings,
    'timelineTitle': (l) => l.timelineTitle,
    'sortNewest': (l) => l.sortNewest,
    'sortOldest': (l) => l.sortOldest,
    'timelineEmpty': (l) => l.timelineEmpty,
    'timelineError': (l) => l.timelineError,
    'retry': (l) => l.retry,
    'dateUnknown': (l) => l.dateUnknown,
    'coordinatesUnavailable': (l) => l.coordinatesUnavailable,
    'note': (l) => l.note,
    'coordinates': (l) => l.coordinates,
    'viewOnMap': (l) => l.viewOnMap,
    'edit': (l) => l.edit,
    'share': (l) => l.share,
    'delete': (l) => l.delete,
    'mediaUnavailable': (l) => l.mediaUnavailable,
    'audioUnavailable': (l) => l.audioUnavailable,
    'pinLoadError': (l) => l.pinLoadError,
    'play': (l) => l.play,
    'pause': (l) => l.pause,
    'close': (l) => l.close,
  };

  final Map<String, AppLocalizations> locales = <String, AppLocalizations>{
    'en': AppLocalizationsEn(),
    'vi': AppLocalizationsVi(),
  };

  test('all 24 new keys are covered by the smoke test', () {
    expect(newKeys.length, 24);
  });

  for (final localeEntry in locales.entries) {
    final String localeName = localeEntry.key;
    final AppLocalizations l10n = localeEntry.value;

    group('locale "$localeName"', () {
      for (final keyEntry in newKeys.entries) {
        test('key "${keyEntry.key}" resolves to a non-empty string', () {
          final String value = keyEntry.value(l10n);
          expect(
            value,
            isNotEmpty,
            reason:
                'Key "${keyEntry.key}" should resolve to a non-empty string '
                'in locale "$localeName".',
          );
        });
      }
    });
  }
}
