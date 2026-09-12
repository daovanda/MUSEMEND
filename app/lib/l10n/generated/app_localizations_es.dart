// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'MuseMend';

  @override
  String get navSky => 'Cielo';

  @override
  String get navJournal => 'Diario';

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
      'Usa el idioma del dispositivo. Los idiomas no compatibles usarán inglés.';

  @override
  String get profileAndSettings => 'Perfil y ajustes';

  @override
  String get displayName => 'Nombre visible';

  @override
  String get cloudName => 'Nombre de la nube';

  @override
  String get appearance => 'Apariencia';

  @override
  String get themeSystem => 'Ajuste del dispositivo';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get sound => 'Sonido';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get settingsUpdated => 'Ajustes actualizados.';

  @override
  String get settingsUpdateFailed => 'No se pudieron actualizar los ajustes.';
}
