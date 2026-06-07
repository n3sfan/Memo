// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Memory Map';

  @override
  String get navMap => 'Map';

  @override
  String get navTimeline => 'Timeline';

  @override
  String get navDuo => 'Duo';

  @override
  String get navSettings => 'Settings';

  @override
  String get timelineTitle => 'Timeline';

  @override
  String get sortNewest => 'Newest';

  @override
  String get sortOldest => 'Oldest';

  @override
  String get timelineEmpty => 'No memories yet';

  @override
  String get timelineError => 'Could not load your timeline';

  @override
  String get retry => 'Retry';

  @override
  String get dateUnknown => 'Date unknown';

  @override
  String get coordinatesUnavailable => 'Coordinates unavailable';

  @override
  String get note => 'Note';

  @override
  String get coordinates => 'Coordinates';

  @override
  String get viewOnMap => 'View on map';

  @override
  String get edit => 'Edit';

  @override
  String get share => 'Share';

  @override
  String get delete => 'Delete';

  @override
  String get mediaUnavailable => 'Media unavailable';

  @override
  String get audioUnavailable => 'Audio unavailable';

  @override
  String get pinLoadError => 'Could not load this memory';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get close => 'Close';
}
