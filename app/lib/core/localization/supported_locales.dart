import 'dart:ui';

const supportedLanguageCodes = <String>{
  'en',
  'vi',
  'ja',
  'fr',
  'es',
  'it',
  'de',
  'ko',
  'pt',
  'ms',
  'id',
  'th',
};

const fallbackLanguageCode = 'en';

String resolveSupportedLanguageCode(String? languageCode) {
  final normalized = languageCode?.trim().toLowerCase();
  return supportedLanguageCodes.contains(normalized)
      ? normalized!
      : fallbackLanguageCode;
}

Locale resolveDeviceLocale(Iterable<Locale>? deviceLocales) {
  for (final locale in deviceLocales ?? const <Locale>[]) {
    if (supportedLanguageCodes.contains(locale.languageCode.toLowerCase())) {
      return Locale(locale.languageCode.toLowerCase());
    }
  }
  return const Locale(fallbackLanguageCode);
}
