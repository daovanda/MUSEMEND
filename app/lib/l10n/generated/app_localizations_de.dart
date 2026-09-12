// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'MuseMend';

  @override
  String get navSky => 'Himmel';

  @override
  String get navJournal => 'Tagebuch';

  @override
  String get navExplore => 'Entdecken';

  @override
  String get navProfile => 'Profil';

  @override
  String get language => 'Sprache';

  @override
  String get languageAutomatic => 'Automatisch (Gerät)';

  @override
  String get languageAutomaticDescription =>
      'Verwendet die Gerätesprache. Nicht unterstützte Sprachen verwenden Englisch.';

  @override
  String get profileAndSettings => 'Profil und Einstellungen';

  @override
  String get displayName => 'Anzeigename';

  @override
  String get cloudName => 'Wolkenname';

  @override
  String get appearance => 'Darstellung';

  @override
  String get themeSystem => 'Geräteeinstellung';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get sound => 'Ton';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get settingsUpdated => 'Einstellungen aktualisiert.';

  @override
  String get settingsUpdateFailed =>
      'Einstellungen konnten nicht aktualisiert werden.';
}
