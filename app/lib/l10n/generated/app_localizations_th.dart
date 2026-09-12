// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'MuseMend';

  @override
  String get navSky => 'ท้องฟ้า';

  @override
  String get navJournal => 'บันทึก';

  @override
  String get navExplore => 'สำรวจ';

  @override
  String get navProfile => 'โปรไฟล์';

  @override
  String get language => 'ภาษา';

  @override
  String get languageAutomatic => 'อัตโนมัติ (อุปกรณ์)';

  @override
  String get languageAutomaticDescription =>
      'ใช้ภาษาของอุปกรณ์ ภาษาที่ยังไม่รองรับจะแสดงเป็นภาษาอังกฤษ';

  @override
  String get profileAndSettings => 'โปรไฟล์และการตั้งค่า';

  @override
  String get displayName => 'ชื่อที่แสดง';

  @override
  String get cloudName => 'ชื่อก้อนเมฆ';

  @override
  String get appearance => 'รูปแบบ';

  @override
  String get themeSystem => 'ตามอุปกรณ์';

  @override
  String get themeLight => 'สว่าง';

  @override
  String get themeDark => 'มืด';

  @override
  String get sound => 'เสียง';

  @override
  String get notifications => 'การแจ้งเตือน';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get save => 'บันทึก';

  @override
  String get settingsUpdated => 'อัปเดตการตั้งค่าแล้ว';

  @override
  String get settingsUpdateFailed => 'ไม่สามารถอัปเดตการตั้งค่าได้';
}
