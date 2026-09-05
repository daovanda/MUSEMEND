import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/app/router/app_router.dart';
import 'package:musemend/app/theme/muse_theme.dart';

class MuseMendApp extends ConsumerWidget {
  const MuseMendApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'MuseMend',
      debugShowCheckedModeBanner: false,
      theme: buildMuseTheme(),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
