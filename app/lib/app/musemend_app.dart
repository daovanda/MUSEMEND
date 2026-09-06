import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/app/router/app_router.dart';
import 'package:musemend/app/theme/muse_theme.dart';
import 'package:musemend/features/profile/application/profile_providers.dart';

class MuseMendApp extends ConsumerWidget {
  const MuseMendApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeModeProvider).value ?? ThemeMode.system;
    return MaterialApp.router(
      title: 'MuseMend',
      debugShowCheckedModeBanner: false,
      theme: buildMuseTheme(),
      darkTheme: buildMuseTheme(Brightness.dark),
      themeMode: themeMode,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
