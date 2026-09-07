import 'package:flutter/material.dart';
import 'package:musemend/app/theme/muse_colors.dart';

ThemeData buildMuseTheme([Brightness brightness = Brightness.light]) {
  final scheme = ColorScheme.fromSeed(
    seedColor: MuseColors.teal,
    brightness: brightness,
    surface: brightness == Brightness.light ? MuseColors.cream : null,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor:
        brightness == Brightness.light ? MuseColors.cream : scheme.surface,
    textTheme: TextTheme(
      headlineSmall: TextStyle(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(color: scheme.onSurface, height: 1.45),
      bodyMedium: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.78),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      color: scheme.surfaceContainerHigh.withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: MuseColors.teal,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: MuseColors.teal,
        side: BorderSide(color: MuseColors.teal.withValues(alpha: .38)),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  );
}
