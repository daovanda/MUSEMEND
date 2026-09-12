// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'MuseMend';

  @override
  String get navSky => 'Céu';

  @override
  String get navJournal => 'Diário';

  @override
  String get navExplore => 'Explorar';

  @override
  String get navProfile => 'Perfil';

  @override
  String get language => 'Idioma';

  @override
  String get languageAutomatic => 'Automático (dispositivo)';

  @override
  String get languageAutomaticDescription =>
      'Usa o idioma do dispositivo. Idiomas não suportados usarão inglês.';

  @override
  String get profileAndSettings => 'Perfil e definições';

  @override
  String get displayName => 'Nome de exibição';

  @override
  String get cloudName => 'Nome da nuvem';

  @override
  String get appearance => 'Aparência';

  @override
  String get themeSystem => 'Definição do dispositivo';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get sound => 'Som';

  @override
  String get notifications => 'Notificações';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get settingsUpdated => 'Definições atualizadas.';

  @override
  String get settingsUpdateFailed =>
      'Não foi possível atualizar as definições.';
}
