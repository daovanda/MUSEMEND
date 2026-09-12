import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:musemend/core/localization/supported_locales.dart';

void main() {
  test('keeps a supported device language', () {
    expect(resolveDeviceLocale(const [Locale('vi', 'VN')]), const Locale('vi'));
  });

  test('falls back unsupported device languages to English', () {
    expect(resolveDeviceLocale(const [Locale('ru', 'RU')]), const Locale('en'));
    expect(resolveSupportedLanguageCode('zh'), 'en');
  });
}
