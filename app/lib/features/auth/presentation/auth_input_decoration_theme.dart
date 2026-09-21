import 'package:flutter/material.dart';
import 'package:musemend/app/theme/muse_colors.dart';

/// Shared field styling for every authentication form.
///
/// An outlined border reserves a notch for a floating label. This keeps a
/// pre-filled email address or a focused OTP field from visually colliding
/// with its label while retaining the sign-in and sign-up appearance.
InputDecorationTheme buildAuthInputDecorationTheme() {
  return InputDecorationTheme(
    filled: true,
    fillColor: Colors.white.withValues(alpha: .68),
    labelStyle: const TextStyle(color: MuseColors.mutedInk),
    floatingLabelStyle: const TextStyle(
      color: MuseColors.teal,
      fontWeight: FontWeight.w600,
    ),
    prefixIconColor: MuseColors.teal,
    suffixIconColor: MuseColors.mutedInk,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: Colors.white.withValues(alpha: .86),
        width: 1.2,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: MuseColors.leaf, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: MuseColors.coral),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: MuseColors.coral, width: 1.5),
    ),
  );
}

ThemeData buildAuthFormTheme(ThemeData baseTheme) {
  return baseTheme.copyWith(
    brightness: Brightness.light,
    inputDecorationTheme: buildAuthInputDecorationTheme(),
  );
}
