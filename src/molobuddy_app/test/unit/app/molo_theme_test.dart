import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/molo_theme.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';

void main() {
  group('text buttons read as quiet links', () {
    final style = MoloTheme.light().textButtonTheme.style!;

    test('hover underlines instead of painting a background', () {
      expect(
        style.overlayColor!.resolve({WidgetState.hovered}),
        Colors.transparent,
      );
      expect(
        style.textStyle!.resolve({WidgetState.hovered})!.decoration,
        TextDecoration.underline,
      );
    });

    test('keyboard focus stays visible and distinct from hover', () {
      expect(
        style.overlayColor!.resolve({WidgetState.focused}),
        MoloColours.pulseTint,
      );
    });

    test('the resting state carries no underline', () {
      expect(
        style.textStyle!.resolve(<WidgetState>{})!.decoration,
        isNot(TextDecoration.underline),
      );
      expect(style.overlayColor!.resolve(<WidgetState>{}), Colors.transparent);
    });
  });

  group('input fields stay readable in every state', () {
    final inputTheme = MoloTheme.light().inputDecorationTheme;

    test('an invalid field keeps its label off the surface colour', () {
      final labelStyle = inputTheme.labelStyle! as WidgetStateTextStyle;
      final hoveredError = labelStyle.resolve({
        WidgetState.error,
        WidgetState.hovered,
      });
      expect(hoveredError.color, MoloColours.error);
      expect(hoveredError.color, isNot(MoloColours.surface));
    });

    test('the suffix icon follows the same state colours', () {
      final iconColour = inputTheme.suffixIconColor! as WidgetStateColor;
      expect(
        iconColour.resolve({WidgetState.error, WidgetState.hovered}),
        MoloColours.error,
      );
      expect(iconColour.resolve({WidgetState.focused}), MoloColours.pulseText);
    });
  });

  group('control geometry', () {
    test('a field is drawn at the design radius and height', () {
      final theme = MoloTheme.light();
      final border = theme.inputDecorationTheme.enabledBorder;
      expect(border, isA<OutlineInputBorder>());
      expect(
        (border! as OutlineInputBorder).borderRadius,
        BorderRadius.circular(MoloSpacing.controlRadius),
      );
      expect(theme.inputDecorationTheme.constraints?.minHeight, 50);
      expect(
        theme.inputDecorationTheme.contentPadding,
        const EdgeInsets.symmetric(horizontal: MoloSpacing.md, vertical: 15),
      );
    });

    test('a primary action is 52 high at the design radius', () {
      final style = MoloTheme.light().filledButtonTheme.style!;
      expect(
        style.minimumSize?.resolve(const <WidgetState>{}),
        const Size.fromHeight(52),
      );
      expect(
        style.shape?.resolve(const <WidgetState>{}),
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MoloSpacing.primaryActionRadius),
        ),
      );
    });

    test('hovering a primary action darkens the fill, not the label', () {
      final style = MoloTheme.light().filledButtonTheme.style!;
      expect(
        style.backgroundColor?.resolve(const <WidgetState>{}),
        MoloColours.moloPlum,
      );
      expect(
        style.backgroundColor?.resolve({WidgetState.hovered}),
        MoloColours.moloPlumHover,
      );
      expect(
        style.foregroundColor?.resolve({WidgetState.hovered}),
        MoloColours.warmCanvas,
      );
    });
  });

}
