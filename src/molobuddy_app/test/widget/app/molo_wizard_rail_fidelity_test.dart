import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/adaptive/molo_wizard_rail.dart';
import 'package:molobuddy_app/app/adaptive/molo_wizard_shell.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/icons/molo_glyphs.dart';
import 'package:molobuddy_app/app/design_system/molo_theme.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';
import 'package:molobuddy_app/app/localisation/generated/app_localizations.dart';

void main() {
  const steps = [
    WizardStepDescriptor(
      title: 'Your account',
      note: 'Name, email and a password',
    ),
    WizardStepDescriptor(
      title: 'Your practice',
      note: 'Practice, team size and region',
    ),
    WizardStepDescriptor(
      title: 'Your first win',
      note: 'What you want to fix first',
    ),
    WizardStepDescriptor(
      title: 'Your starting point',
      note: 'Real data or a sample',
    ),
  ];

  Future<void> pump(
    WidgetTester tester, {
    int step = 2,
    int readiness = 32,
    String practiceName = '',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MoloTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: 460,
                height: 900,
                child: MoloWizardRail(
                  progress: WizardProgress(
                    stepNumber: step,
                    readinessPercent: readiness,
                    steps: steps,
                    practiceName: practiceName,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  BoxDecoration chipDecoration(WidgetTester tester, int step) {
    return tester
            .widget<Container>(find.byKey(MoloWizardRail.chipKey(step)))
            .decoration!
        as BoxDecoration;
  }

  testWidgets('the rail is plum and says where you are', (tester) async {
    await pump(tester);
    expect(find.byKey(MoloWizardRail.railKey), findsOneWidget);
    expect(find.text('Step 2 of 4'), findsOneWidget);
    expect(find.text('molo'), findsOneWidget);
  });

  /// The step titles are 15px. "Your practice" is also the workspace card's
  /// placeholder for an unnamed practice, at 24px, so a bare text finder would
  /// match two different things — as the baseline's own copy does.
  Text stepTitle(WidgetTester tester, String title) {
    return tester
        .widgetList<Text>(find.text(title))
        .firstWhere((text) => text.style?.fontSize == 15);
  }

  testWidgets('all four steps are listed, with their notes', (tester) async {
    await pump(tester);
    for (final step in steps) {
      expect(stepTitle(tester, step.title).data, step.title);
      expect(find.text(step.note), findsOneWidget);
    }
  });

  testWidgets('every chip is 28 square and fully round', (tester) async {
    await pump(tester);
    for (var step = 1; step <= 4; step++) {
      expect(
        tester.getSize(find.byKey(MoloWizardRail.chipKey(step))),
        const Size(28, 28),
      );
      expect(chipDecoration(tester, step).shape, BoxShape.circle);
    }
  });

  testWidgets('a finished step fills pulse and shows a tick, not a number', (
    tester,
  ) async {
    await pump(tester, step: 3);
    expect(chipDecoration(tester, 1).color, MoloColours.moloPulse);
    expect(
      find.descendant(
        of: find.byKey(MoloWizardRail.chipKey(1)),
        matching: find.text('1'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(MoloWizardRail.chipKey(1)),
        matching: find.byType(MoloIcon),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the step on screen fills warm canvas and keeps its number', (
    tester,
  ) async {
    await pump(tester, step: 3);
    expect(chipDecoration(tester, 3).color, MoloColours.warmCanvas);
    expect(
      find.descendant(
        of: find.byKey(MoloWizardRail.chipKey(3)),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a step still ahead is quiet but numbered', (tester) async {
    await pump(tester, step: 3);
    expect(
      chipDecoration(tester, 4).color,
      MoloColours.surface.withValues(alpha: 0.1),
    );
    expect(
      find.descendant(
        of: find.byKey(MoloWizardRail.chipKey(4)),
        matching: find.text('4'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the current title is brighter than the others', (tester) async {
    await pump(tester, step: 2);
    expect(
      stepTitle(tester, 'Your practice').style?.color,
      MoloColours.warmCanvas,
    );
    expect(
      stepTitle(tester, 'Your first win').style?.color,
      MoloColours.warmCanvas.withValues(alpha: 0.72),
    );
  });

  group('workspace card', () {
    testWidgets('is padded 20 at the design radius', (tester) async {
      await pump(tester);
      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find
                        .ancestor(
                          of: find.text('YOUR WORKSPACE'),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(
        decoration.borderRadius,
        BorderRadius.circular(MoloSpacing.railCardRadius),
      );
      expect(decoration.color, MoloColours.surface.withValues(alpha: 0.06));
    });

    testWidgets('names the practice once it has a name', (tester) async {
      await pump(tester, practiceName: 'Mokoena Tax Studio');
      final name = tester.widget<Text>(
        find.byKey(MoloWizardRail.practiceNameKey),
      );
      expect(name.data, 'Mokoena Tax Studio');
      expect(name.style?.fontSize, 24);
    });

    testWidgets('stands in for it until then', (tester) async {
      await pump(tester);
      expect(
        tester.widget<Text>(find.byKey(MoloWizardRail.practiceNameKey)).data,
        'Your practice',
      );
    });
  });

  group('readiness', () {
    testWidgets('states the figure twice, in words and as a number', (
      tester,
    ) async {
      await pump(tester, readiness: 58);
      expect(find.text('Workspace 58% ready'), findsOneWidget);
      expect(find.text('58%'), findsOneWidget);
    });

    testWidgets('the figure takes the colour that separates it from the bar', (
      tester,
    ) async {
      await pump(tester, readiness: 58);
      expect(
        tester.widget<Text>(find.text('58%')).style?.color,
        MoloColours.pulseOnDark,
      );
    });

    testWidgets('the track is 4 high and the fill follows the figure', (
      tester,
    ) async {
      await pump(tester, readiness: 58);
      expect(
        tester.getSize(find.byKey(MoloWizardRail.readinessBarKey)).height,
        4,
      );
      final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(MoloWizardRail.readinessBarKey),
      );
      expect(bar.value, closeTo(0.58, 0.001));
      expect(bar.color, MoloColours.moloPulse);
    });
  });

  testWidgets('on a short window it scrolls rather than clipping', (
    tester,
  ) async {
    // Four step rows, a workspace card and a readiness bar are taller than a
    // laptop window once the step notes wrap, and the spacer that pushes the
    // card down cannot absorb a negative amount of slack.
    await tester.pumpWidget(
      MaterialApp(
        theme: MoloTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: 460,
                height: 420,
                child: MoloWizardRail(
                  progress: const WizardProgress(
                    stepNumber: 2,
                    readinessPercent: 32,
                    steps: steps,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('the rail is decoration, not a place to tab into', (
    tester,
  ) async {
    await pump(tester);
    // The form's own heading announces the step. A tab stop here would put four
    // unreachable-looking rows in front of the first field.
    expect(find.byType(InkWell), findsNothing);
    expect(find.byType(TextButton), findsNothing);
  });
}
