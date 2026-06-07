import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi')
  ];

  /// Application title shown in the app shell.
  ///
  /// In vi, this message translates to:
  /// **'Bản Đồ Kỷ Niệm'**
  String get appTitle;

  /// Bottom navigation label for the map.
  ///
  /// In vi, this message translates to:
  /// **'Bản đồ'**
  String get navMap;

  /// Bottom navigation label for the timeline.
  ///
  /// In vi, this message translates to:
  /// **'Dòng thời gian'**
  String get navTimeline;

  /// Bottom navigation label for Duo.
  ///
  /// In vi, this message translates to:
  /// **'Duo'**
  String get navDuo;

  /// Bottom navigation label for settings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get navSettings;

  /// Title of the Timeline screen.
  ///
  /// In vi, this message translates to:
  /// **'Dòng thời gian'**
  String get timelineTitle;

  /// Sort order option that lists memories newest first.
  ///
  /// In vi, this message translates to:
  /// **'Mới nhất'**
  String get sortNewest;

  /// Sort order option that lists memories oldest first.
  ///
  /// In vi, this message translates to:
  /// **'Cũ nhất'**
  String get sortOldest;

  /// Empty-state message shown when the timeline has no pins.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có kỷ niệm nào'**
  String get timelineEmpty;

  /// Error message shown when the timeline fails to load.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải dòng thời gian của bạn'**
  String get timelineError;

  /// Label for the retry control.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get retry;

  /// Label shown for a memory that has no recorded date.
  ///
  /// In vi, this message translates to:
  /// **'Không rõ ngày'**
  String get dateUnknown;

  /// Label shown when a pin has no valid coordinates.
  ///
  /// In vi, this message translates to:
  /// **'Không có tọa độ'**
  String get coordinatesUnavailable;

  /// Section label for a pin's note text.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú'**
  String get note;

  /// Section label for a pin's coordinates.
  ///
  /// In vi, this message translates to:
  /// **'Tọa độ'**
  String get coordinates;

  /// Action label that opens the map focused on the pin.
  ///
  /// In vi, this message translates to:
  /// **'Xem trên bản đồ'**
  String get viewOnMap;

  /// Action label that opens the pin editor.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh sửa'**
  String get edit;

  /// Action label that opens the share entry point.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ'**
  String get share;

  /// Action label that opens the delete entry point.
  ///
  /// In vi, this message translates to:
  /// **'Xóa'**
  String get delete;

  /// Placeholder text shown when image media cannot be loaded.
  ///
  /// In vi, this message translates to:
  /// **'Không có phương tiện'**
  String get mediaUnavailable;

  /// Placeholder text shown when audio media cannot be loaded.
  ///
  /// In vi, this message translates to:
  /// **'Không có âm thanh'**
  String get audioUnavailable;

  /// Error message shown when a pin fails to load.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải kỷ niệm này'**
  String get pinLoadError;

  /// Accessible label for starting audio playback.
  ///
  /// In vi, this message translates to:
  /// **'Phát'**
  String get play;

  /// Accessible label for pausing audio playback.
  ///
  /// In vi, this message translates to:
  /// **'Tạm dừng'**
  String get pause;

  /// Accessible label for closing the media viewer.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get close;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
