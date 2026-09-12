// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MuseMend';

  @override
  String get navSky => 'Sky';

  @override
  String get navJournal => 'Journal';

  @override
  String get navExplore => 'Explore';

  @override
  String get navProfile => 'Profile';

  @override
  String get language => 'Language';

  @override
  String get languageAutomatic => 'Automatic (device)';

  @override
  String get languageAutomaticDescription =>
      'Uses your device language. Unsupported languages use English.';

  @override
  String get profileAndSettings => 'Profile and settings';

  @override
  String get displayName => 'Display name';

  @override
  String get cloudName => 'Cloud name';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'Device setting';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get sound => 'Sound';

  @override
  String get notifications => 'Notifications';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get settingsUpdated => 'Settings updated.';

  @override
  String get settingsUpdateFailed => 'Could not update settings.';
}
