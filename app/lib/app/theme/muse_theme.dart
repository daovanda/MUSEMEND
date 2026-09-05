import 'package:flutter/material.dart';
import 'package:musemend/app/theme/muse_colors.dart';

ThemeData buildMuseTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: MuseColors.coral,
    brightness: Brightness.light,
    surface: MuseColors.cream,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: MuseColors.cream,
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        color: MuseColors.ink,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(color: MuseColors.ink, fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(color: MuseColors.ink, height: 1.45),
      bodyMedium: TextStyle(color: MuseColors.mutedInk, height: 1.4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.78),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      color: Colors.white.withValues(alpha: 0.82),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
  );
}
