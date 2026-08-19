import 'package:flutter/material.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';

abstract final class MoloTheme {
  static ThemeData light() {
    const colourScheme = ColorScheme.light(
      primary: MoloColours.moloBlue,
      onPrimary: MoloColours.surface,
      primaryContainer: MoloColours.moloBlueTint,
      onPrimaryContainer: MoloColours.deepInk,
      secondary: MoloColours.helloCoral,
      onSecondary: MoloColours.deepInk,
      surface: MoloColours.surface,
      onSurface: MoloColours.deepInk,
      error: MoloColours.error,
      onError: MoloColours.surface,
      outline: MoloColours.border,
      outlineVariant: MoloColours.softCloud,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colourScheme,
      scaffoldBackgroundColor: MoloColours.canvas,
      visualDensity: VisualDensity.standard,
      fontFamily: 'Geist',
    );
    final textTheme = base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        color: MoloColours.deepInk,
        fontSize: 42,
        height: 1.08,
        fontWeight: FontWeight.w500,
        letterSpacing: -1.2,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        color: MoloColours.deepInk,
        fontSize: 32,
        height: 1.12,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.7,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        color: MoloColours.deepInk,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.3,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        color: MoloColours.deepInk,
        height: 1.5,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        color: MoloColours.secondaryText,
        height: 1.45,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
    );

    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(MoloSpacing.controlRadius),
    );
    return base.copyWith(
      textTheme: textTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MoloColours.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MoloSpacing.md,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MoloSpacing.controlRadius),
          borderSide: const BorderSide(color: MoloColours.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MoloSpacing.controlRadius),
          borderSide: const BorderSide(color: MoloColours.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MoloSpacing.controlRadius),
          borderSide: const BorderSide(color: MoloColours.moloBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MoloSpacing.controlRadius),
          borderSide: const BorderSide(color: MoloColours.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MoloSpacing.controlRadius),
          borderSide: const BorderSide(color: MoloColours.error, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: controlShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MoloColours.deepInk,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: MoloColours.border),
          shape: controlShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: MoloColours.moloBlue,
          textStyle: textTheme.labelLarge,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: MoloColours.deepInk,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: MoloColours.surface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: controlShape,
      ),
      dividerTheme: const DividerThemeData(color: MoloColours.border),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: MoloColours.moloBlue,
      ),
    );
  }
}
