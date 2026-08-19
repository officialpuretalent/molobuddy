import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/molo_theme.dart';

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
}
