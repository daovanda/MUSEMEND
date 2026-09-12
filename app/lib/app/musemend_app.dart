import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/app/router/app_router.dart';
import 'package:musemend/app/theme/muse_theme.dart';
import 'package:musemend/features/profile/application/profile_providers.dart';
import 'package:musemend/core/localization/supported_locales.dart';
import 'package:musemend/l10n/generated/app_localizations.dart';

class MuseMendApp extends ConsumerWidget {
  const MuseMendApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeModeProvider).value ?? ThemeMode.light;
    final languageCode = ref.watch(appLanguageCodeProvider).value;
    return MaterialApp.router(
      title: 'MuseMend',
      debugShowCheckedModeBanner: false,
      theme: buildMuseTheme(),
      darkTheme: buildMuseTheme(Brightness.dark),
      themeMode: themeMode,
      locale: languageCode == null ? null : Locale(languageCode),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeListResolutionCallback: (locales, supportedLocales) {
        return resolveDeviceLocale(locales);
      },
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
