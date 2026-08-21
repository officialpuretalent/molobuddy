import 'package:flutter/material.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';

abstract final class MoloTheme {
  static TextStyle _inputLabelStyle(Set<WidgetState> states) {
    return TextStyle(color: _inputStateColour(states));
  }

  static Color _inputStateColour(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return MoloColours.controlBorder;
    }
    if (states.contains(WidgetState.error)) {
      return MoloColours.error;
    }
    if (states.contains(WidgetState.focused)) {
      return MoloColours.pulseText;
    }
    return MoloColours.secondaryText;
  }

  static ThemeData light() {
    const colourScheme = ColorScheme.light(
      primary: MoloColours.moloPlum,
      onPrimary: MoloColours.surface,
      primaryContainer: MoloColours.pulseTint,
      onPrimaryContainer: MoloColours.moloPlum,
      secondary: MoloColours.moloPulse,
      onSecondary: MoloColours.moloPlum,
      surface: MoloColours.surface,
      onSurface: MoloColours.moloPlum,
      error: MoloColours.error,
      onError: MoloColours.surface,
      outline: MoloColours.controlBorder,
      outlineVariant: MoloColours.border,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colourScheme,
      scaffoldBackgroundColor: MoloColours.warmCanvas,
      visualDensity: VisualDensity.standard,
      fontFamily: 'Geist',
    );
    final textTheme = base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        color: MoloColours.moloPlum,
        fontSize: 42,
        height: 1.08,
        fontWeight: FontWeight.w500,
        letterSpacing: -1.2,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        color: MoloColours.moloPlum,
        fontSize: 32,
        height: 1.12,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.7,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        color: MoloColours.moloPlum,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.3,
      ),
      // Material 3 tracks its body and label roles; the design does not track
      // body, navigation or control text at all. Every role states zero
      // explicitly, because anything left unset inherits Material's spacing
      // and reads looser than the design at every size.
      titleMedium: base.textTheme.titleMedium?.copyWith(
        color: MoloColours.moloPlum,
        letterSpacing: 0,
      ),
      titleSmall: base.textTheme.titleSmall?.copyWith(
        color: MoloColours.moloPlum,
        letterSpacing: 0,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        color: MoloColours.moloPlum,
        height: 1.5,
        letterSpacing: 0,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        color: MoloColours.secondaryText,
        height: 1.45,
        letterSpacing: 0,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        color: MoloColours.secondaryText,
        letterSpacing: 0,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      labelMedium: base.textTheme.labelMedium?.copyWith(letterSpacing: 0),
      labelSmall: base.textTheme.labelSmall?.copyWith(letterSpacing: 0),
    );

    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(MoloSpacing.controlRadius),
    );
    return base.copyWith(
      textTheme: textTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MoloColours.surface,
        hoverColor: MoloColours.softBlush,
        // Pinned so state colour never falls back to the Material default,
        // which paints an invalid field's label and icon in onErrorContainer:
        // white on this palette, and invisible against the field.
        labelStyle: WidgetStateTextStyle.resolveWith(_inputLabelStyle),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith(_inputLabelStyle),
        hintStyle: const TextStyle(color: MoloColours.secondaryText),
        suffixIconColor: WidgetStateColor.resolveWith(_inputStateColour),
        prefixIconColor: WidgetStateColor.resolveWith(_inputStateColour),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MoloSpacing.md,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MoloSpacing.controlRadius),
          borderSide: const BorderSide(color: MoloColours.controlBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MoloSpacing.controlRadius),
          borderSide: const BorderSide(color: MoloColours.controlBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MoloSpacing.controlRadius),
          borderSide: const BorderSide(color: MoloColours.pulseText, width: 2),
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
          foregroundColor: MoloColours.moloPlum,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: MoloColours.controlBorder),
          shape: controlShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      // Text buttons read as links, so they stay quiet: hover underlines
      // rather than painting a filled pill, and a background appears only for
      // keyboard focus, which must stay distinguishable from hover.
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return MoloColours.secondaryText;
            }
            return MoloColours.pulseText;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.focused)) {
              return MoloColours.pulseTint;
            }
            return Colors.transparent;
          }),
          textStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return textTheme.labelLarge?.copyWith(
                decoration: TextDecoration.underline,
              );
            }
            return textTheme.labelLarge;
          }),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return MoloColours.border;
          }
          if (states.contains(WidgetState.selected)) {
            return MoloColours.moloPlum;
          }
          return MoloColours.surface;
        }),
        checkColor: const WidgetStatePropertyAll(MoloColours.surface),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.focused) ||
              states.contains(WidgetState.hovered)) {
            return MoloColours.moloPulse.withValues(alpha: 0.12);
          }
          return null;
        }),
        side: WidgetStateBorderSide.resolveWith((states) {
          if (states.contains(WidgetState.error)) {
            return const BorderSide(color: MoloColours.error, width: 1.5);
          }
          if (states.contains(WidgetState.disabled)) {
            return const BorderSide(color: MoloColours.border, width: 1.5);
          }
          if (states.contains(WidgetState.selected)) {
            return const BorderSide(color: MoloColours.moloPlum, width: 1.5);
          }
          if (states.contains(WidgetState.focused)) {
            return const BorderSide(color: MoloColours.pulseText, width: 2);
          }
          if (states.contains(WidgetState.hovered)) {
            return const BorderSide(color: MoloColours.pulseText, width: 1.5);
          }
          return const BorderSide(color: MoloColours.controlBorder, width: 1.5);
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: MoloColours.moloPlum,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: MoloColours.surface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: controlShape,
      ),
      dividerTheme: const DividerThemeData(color: MoloColours.border),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: MoloColours.pulseText,
      ),
    );
  }
}
