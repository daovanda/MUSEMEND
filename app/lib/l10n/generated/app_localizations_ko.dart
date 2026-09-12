// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'MuseMend';

  @override
  String get navSky => '하늘';

  @override
  String get navJournal => '일기';

  @override
  String get navExplore => '탐색';

  @override
  String get navProfile => '프로필';

  @override
  String get language => '언어';

  @override
  String get languageAutomatic => '자동(기기)';

  @override
  String get languageAutomaticDescription =>
      '기기 언어를 사용합니다. 지원하지 않는 언어는 영어로 표시됩니다.';

  @override
  String get profileAndSettings => '프로필 및 설정';

  @override
  String get displayName => '표시 이름';

  @override
  String get cloudName => '구름 이름';

  @override
  String get appearance => '화면 모드';

  @override
  String get themeSystem => '기기 설정';

  @override
  String get themeLight => '라이트';

  @override
  String get themeDark => '다크';

  @override
  String get sound => '소리';

  @override
  String get notifications => '알림';

  @override
  String get cancel => '취소';

  @override
  String get save => '저장';

  @override
  String get settingsUpdated => '설정을 업데이트했습니다.';

  @override
  String get settingsUpdateFailed => '설정을 업데이트할 수 없습니다.';
}
