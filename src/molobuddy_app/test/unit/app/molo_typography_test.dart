import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/design_system/molo_theme.dart';
import 'package:molobuddy_app/app/design_system/typography/molo_typography.dart';

/// The design tracks type by two rules and leaves everything else alone.
///
/// Material 3 disagrees: it bakes letter spacing into its body and label
/// roles, so text inherits tracking the design never asked for. Measured
/// against the baseline, `bodyMedium` was painting at 0.25 where the design
/// uses none.
void main() {
  group('em tracking converts to logical pixels', () {
    test('the design states tracking in em, Flutter wants pixels', () {
      // 0.06em at 12px is the kicker's measured 0.72.
      expect(MoloTypography.trackingEm(0.06, 12), closeTo(0.72, 0.0001));
      // -0.02em at 34px is the greeting's measured -0.68.
      expect(MoloTypography.trackingEm(-0.02, 34), closeTo(-0.68, 0.0001));
    });
  });

  group('body and label roles carry no tracking', () {
    final textTheme = MoloTheme.light().textTheme;

    final untracked = <String, TextStyle?>{
      'bodyLarge': textTheme.bodyLarge,
      'bodyMedium': textTheme.bodyMedium,
      'bodySmall': textTheme.bodySmall,
      'labelLarge': textTheme.labelLarge,
      'labelMedium': textTheme.labelMedium,
      'labelSmall': textTheme.labelSmall,
    };

    for (final entry in untracked.entries) {
      test('${entry.key} is untracked', () {
        expect(
          entry.value?.letterSpacing,
          0,
          reason:
              '${entry.key} inherits Material tracking the design does not '
              'use. Set letterSpacing: 0 explicitly.',
        );
      });
    }
  });

  group('display roles keep the design negative tracking', () {
    final textTheme = MoloTheme.light().textTheme;

    test('displaySmall is tight, near -0.02em', () {
      final style = textTheme.displaySmall!;
      expect(style.letterSpacing! / style.fontSize!, lessThan(-0.015));
    });

    test('headlineMedium is tight, near -0.02em', () {
      final style = textTheme.headlineMedium!;
      expect(style.letterSpacing! / style.fontSize!, lessThan(-0.015));
    });
  });

  group('the uppercase micro-label follows the design', () {
    test('is 12px, 0.06em wide and regular weight', () {
      // Measured on the baseline's date kicker: 12px, 0.72 tracking, 400.
      // The app had it at 0.5 tracking and medium weight.
      expect(MoloTypography.kicker.fontSize, 12);
      expect(MoloTypography.kicker.letterSpacing, closeTo(0.72, 0.0001));
      expect(MoloTypography.kicker.fontWeight, FontWeight.w400);
    });
  });
}
