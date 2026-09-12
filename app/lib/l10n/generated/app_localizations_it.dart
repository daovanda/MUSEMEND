// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'MuseMend';

  @override
  String get navSky => 'Cielo';

  @override
  String get navJournal => 'Diario';

  @override
  String get navExplore => 'Esplora';

  @override
  String get navProfile => 'Profilo';

  @override
  String get language => 'Lingua';

  @override
  String get languageAutomatic => 'Automatica (dispositivo)';

  @override
  String get languageAutomaticDescription =>
      'Usa la lingua del dispositivo. Le lingue non supportate useranno l’inglese.';

  @override
  String get profileAndSettings => 'Profilo e impostazioni';

  @override
  String get displayName => 'Nome visualizzato';

  @override
  String get cloudName => 'Nome della nuvola';

  @override
  String get appearance => 'Aspetto';

  @override
  String get themeSystem => 'Impostazione dispositivo';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeDark => 'Scuro';

  @override
  String get sound => 'Suono';

  @override
  String get notifications => 'Notifiche';

  @override
  String get cancel => 'Annulla';

  @override
  String get save => 'Salva';

  @override
  String get settingsUpdated => 'Impostazioni aggiornate.';

  @override
  String get settingsUpdateFailed => 'Impossibile aggiornare le impostazioni.';
}
