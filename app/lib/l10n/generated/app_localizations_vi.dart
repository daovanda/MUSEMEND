// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'MuseMend';

  @override
  String get navSky => 'Bầu trời';

  @override
  String get navJournal => 'Nhật ký';

  @override
  String get navExplore => 'Khám phá';

  @override
  String get navProfile => 'Cá nhân';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get languageAutomatic => 'Tự động (thiết bị)';

  @override
  String get languageAutomaticDescription =>
      'Dùng ngôn ngữ thiết bị. Ngôn ngữ chưa hỗ trợ sẽ dùng tiếng Anh.';

  @override
  String get profileAndSettings => 'Hồ sơ và cài đặt';

  @override
  String get displayName => 'Tên hiển thị';

  @override
  String get cloudName => 'Tên của Mây';

  @override
  String get appearance => 'Giao diện';

  @override
  String get themeSystem => 'Theo thiết bị';

  @override
  String get themeLight => 'Sáng';

  @override
  String get themeDark => 'Tối';

  @override
  String get sound => 'Âm thanh';

  @override
  String get notifications => 'Thông báo';

  @override
  String get cancel => 'Hủy';

  @override
  String get save => 'Lưu';

  @override
  String get settingsUpdated => 'Đã cập nhật cài đặt.';

  @override
  String get settingsUpdateFailed => 'Chưa thể cập nhật cài đặt.';
}
