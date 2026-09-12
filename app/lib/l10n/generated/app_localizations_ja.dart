// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'MuseMend';

  @override
  String get navSky => '空';

  @override
  String get navJournal => '日記';

  @override
  String get navExplore => '探索';

  @override
  String get navProfile => 'プロフィール';

  @override
  String get language => '言語';

  @override
  String get languageAutomatic => '自動（端末）';

  @override
  String get languageAutomaticDescription => '端末の言語を使用します。未対応の言語では英語を使用します。';

  @override
  String get profileAndSettings => 'プロフィールと設定';

  @override
  String get displayName => '表示名';

  @override
  String get cloudName => '雲の名前';

  @override
  String get appearance => '外観';

  @override
  String get themeSystem => '端末の設定';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get sound => 'サウンド';

  @override
  String get notifications => '通知';

  @override
  String get cancel => 'キャンセル';

  @override
  String get save => '保存';

  @override
  String get settingsUpdated => '設定を更新しました。';

  @override
  String get settingsUpdateFailed => '設定を更新できませんでした。';
}
