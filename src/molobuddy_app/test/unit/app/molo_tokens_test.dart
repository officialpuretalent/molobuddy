import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';

/// Contrast ratio as WCAG defines it, so a colour's evidence is checked rather
/// than asserted in a comment.
double _contrast(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('radii', () {
    test('the design draws six, each named', () {
      expect(MoloSpacing.pillRadius, 12.0);
      expect(MoloSpacing.controlRadius, 14.0);
      expect(MoloSpacing.primaryActionRadius, 15.0);
      expect(MoloSpacing.choiceCardRadius, 16.0);
      expect(MoloSpacing.railCardRadius, 18.0);
      expect(MoloSpacing.cardRadius, 24.0);
    });
  });

  group('new colours', () {
    test('a hovered plum action still carries its label', () {
      expect(
        _contrast(MoloColours.moloPlumHover, MoloColours.warmCanvas),
        greaterThan(4.5),
      );
    });

    test('the hover outline never has to carry identity on its own', () {
      // pulseBorder is 1.72:1 on white, which is why it may only replace an
      // outline that already exists in the resting state. Its resting partner
      // is what has to clear 3:1.
      expect(
        _contrast(MoloColours.controlBorder, MoloColours.surface),
        greaterThan(3.0),
      );
      expect(
        _contrast(MoloColours.pulseBorder, MoloColours.surface),
        lessThan(3.0),
      );
    });

    test('the values are the traced ones', () {
      expect(MoloColours.pulseBorder, const Color(0xFFE9B9C4));
      expect(MoloColours.moloPlumHover, const Color(0xFF3A2440));
    });
  });
}
