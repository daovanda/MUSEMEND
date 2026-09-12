// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'MuseMend';

  @override
  String get navSky => 'Ciel';

  @override
  String get navJournal => 'Journal';

  @override
  String get navExplore => 'Explorer';

  @override
  String get navProfile => 'Profil';

  @override
  String get language => 'Langue';

  @override
  String get languageAutomatic => 'Automatique (appareil)';

  @override
  String get languageAutomaticDescription =>
      'Utilise la langue de l’appareil. Les langues non prises en charge utilisent l’anglais.';

  @override
  String get profileAndSettings => 'Profil et paramètres';

  @override
  String get displayName => 'Nom affiché';

  @override
  String get cloudName => 'Nom du nuage';

  @override
  String get appearance => 'Apparence';

  @override
  String get themeSystem => 'Réglage de l’appareil';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get sound => 'Son';

  @override
  String get notifications => 'Notifications';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get settingsUpdated => 'Paramètres mis à jour.';

  @override
  String get settingsUpdateFailed =>
      'Impossible de mettre à jour les paramètres.';
}
