import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/adaptive/molo_wizard_shell.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_pill_button.dart';
import 'package:molobuddy_app/app/design_system/molo_theme.dart';
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
    WidgetTester tester,
    Size size, {
    bool withBack = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        theme: MoloTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MoloWizardShell(
          pageTitle: 'Create your account | Molo',
          progress: const WizardProgress(
            stepNumber: 2,
            readinessPercent: 32,
            steps: steps,
          ),
          showSignInLink: true,
          child: Column(
            key: const Key('a_step'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MoloWizardHeadingGroup(
                eyebrow: 'Shape your workspace',
                title: 'Tell us about your practice',
                blurb: 'These details shape your workspace.',
                onBack: withBack ? () {} : null,
              ),
              const SizedBox(height: 28),
              const MoloStepFootnote(
                label: 'You can change these settings later.',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the content column is capped at 452', (tester) async {
    await pump(tester, const Size(1440, 950));
    expect(tester.getSize(find.byKey(const Key('a_step'))).width, 452);
  });

  testWidgets('the column is top aligned, well below the header', (
    tester,
  ) async {
    await pump(tester, const Size(1440, 950));
    final header = tester.getRect(find.text('Already have an account?'));
    final firstElement = tester.getRect(find.text('Shape your workspace'));
    expect(firstElement.top - header.bottom, greaterThan(50));
    // Top aligned rather than centred: on a tall window the heading stays put.
    expect(firstElement.top, lessThan(300));
  });

  testWidgets('the offer to sign in is a pill, not a link', (tester) async {
    await pump(tester, const Size(1440, 950));
    expect(find.byType(MoloPillButton), findsOneWidget);
    expect(find.text('Already have an account?'), findsOneWidget);
    expect(find.byKey(const Key('registration_sign_in_link')), findsOneWidget);
  });

  testWidgets('on compact the lockup appears and the label drops', (
    tester,
  ) async {
    await pump(tester, const Size(390, 900));
    expect(find.text('molo'), findsOneWidget);
    expect(find.text('Already have an account?'), findsNothing);
    expect(find.byKey(const Key('registration_sign_in_link')), findsOneWidget);
  });

  group('the heading group', () {
    testWidgets('the eyebrow is 13px medium pulseText', (tester) async {
      await pump(tester, const Size(1440, 950));
      final eyebrow = tester.widget<Text>(find.text('Shape your workspace'));
      expect(eyebrow.style?.fontSize, 13);
      expect(eyebrow.style?.fontWeight, FontWeight.w500);
      expect(eyebrow.style?.color, MoloColours.pulseText);
    });

    testWidgets('the title is 34px at the design tracking', (tester) async {
      await pump(tester, const Size(1440, 950));
      final title = tester.widget<Text>(
        find.text('Tell us about your practice'),
      );
      expect(title.style?.fontSize, 34);
      expect(title.style?.height, 1.12);
      expect(title.style?.letterSpacing, closeTo(-0.85, 0.001));
    });

    testWidgets('the blurb is 15px secondaryText', (tester) async {
      await pump(tester, const Size(1440, 950));
      final blurb = tester.widget<Text>(
        find.text('These details shape your workspace.'),
      );
      expect(blurb.style?.fontSize, 15);
      expect(blurb.style?.height, 1.6);
      expect(blurb.style?.color, MoloColours.secondaryText);
    });

    testWidgets('the title is announced as a heading', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, const Size(1440, 950));
      expect(
        tester.getSemantics(find.text('Tell us about your practice')),
        isSemantics(label: 'Tell us about your practice', isHeader: true),
      );
      semantics.dispose();
    });

    testWidgets('the group is 12 apart throughout', (tester) async {
      await pump(tester, const Size(1440, 950));
      final eyebrow = tester.getRect(find.text('Shape your workspace'));
      final title = tester.getRect(find.text('Tell us about your practice'));
      expect(title.top - eyebrow.bottom, closeTo(12, 2));
    });

    testWidgets('back appears only where there is somewhere to go', (
      tester,
    ) async {
      await pump(tester, const Size(1440, 950));
      expect(find.byType(MoloWizardBackButton), findsNothing);

      await pump(tester, const Size(1440, 950), withBack: true);
      expect(find.byType(MoloWizardBackButton), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      // Above the eyebrow, so it reads before the step it leaves.
      expect(
        tester.getRect(find.text('Back')).top,
        lessThan(tester.getRect(find.text('Shape your workspace')).top),
      );
    });
  });

  testWidgets('the footnote is 12px in a colour that clears 4.5:1', (
    tester,
  ) async {
    await pump(tester, const Size(1440, 950));
    final footnote = tester.widget<Text>(
      find.text('You can change these settings later.'),
    );
    expect(footnote.style?.fontSize, 12);
    expect(footnote.style?.height, 1.6);
    // Not the spec's controlBorder: 3.30:1 on the warm canvas, and this is
    // ordinary text at 12px.
    expect(footnote.style?.color, MoloColours.secondaryText);
  });

  group('the primary action', () {
    late int presses;

    Future<void> pumpAction(
      WidgetTester tester, {
      required bool complete,
      bool busy = false,
    }) async {
      presses = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: MoloTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 452,
                child: MoloWizardPrimaryAction(
                  buttonKey: const Key('primary'),
                  label: 'Continue',
                  complete: complete,
                  outstanding: 'Enter your practice name.',
                  busy: busy,
                  onPressed: () => presses++,
                ),
              ),
            ),
          ),
        ),
      );
    }

    ButtonStyle? styleOf(WidgetTester tester) =>
        tester.widget<FilledButton>(find.byKey(const Key('primary'))).style;

    testWidgets('complete, it is the plum primary at 52 high', (tester) async {
      await pumpAction(tester, complete: true);
      expect(tester.getSize(find.byKey(const Key('primary'))).height, 52);
      expect(
        styleOf(tester),
        isNull,
        reason: 'a complete step defers to the theme',
      );
    });

    testWidgets('incomplete, it takes the design quiet fill and label', (
      tester,
    ) async {
      await pumpAction(tester, complete: false);
      expect(
        styleOf(tester)?.backgroundColor?.resolve(const <WidgetState>{}),
        MoloColours.border,
      );
      expect(
        styleOf(tester)?.foregroundColor?.resolve(const <WidgetState>{}),
        MoloColours.controlBorder,
      );
    });

    testWidgets('incomplete, it still presses, which is what shows errors', (
      tester,
    ) async {
      await pumpAction(tester, complete: false);
      await tester.tap(find.byKey(const Key('primary')));
      await tester.pump();
      expect(presses, 1);
    });

    testWidgets('incomplete, it says what is outstanding', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpAction(tester, complete: false);
      expect(
        tester.getSemantics(find.byKey(const Key('primary'))),
        isSemantics(
          label: 'Continue',
          hint: 'Enter your practice name.',
          isButton: true,
          isEnabled: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('complete, it has nothing left to explain', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpAction(tester, complete: true);
      expect(
        tester.getSemantics(find.byKey(const Key('primary'))),
        isSemantics(label: 'Continue', hint: '', isButton: true),
      );
      semantics.dispose();
    });

    testWidgets('busy, it shows a spinner and refuses a second press', (
      tester,
    ) async {
      await pumpAction(tester, complete: true, busy: true);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byKey(const Key('primary')), warnIfMissed: false);
      await tester.pump();
      expect(presses, 0);
    });
  });
}
