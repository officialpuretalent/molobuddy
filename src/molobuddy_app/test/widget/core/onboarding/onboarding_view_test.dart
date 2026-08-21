import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:molobuddy_app/app/adaptive/molo_wizard_rail.dart';
import 'package:molobuddy_app/app/adaptive/molo_wizard_shell.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_choice_card.dart';
import 'package:molobuddy_app/app/design_system/icons/molo_glyphs.dart';
import 'package:molobuddy_app/app/design_system/molo_theme.dart';
import 'package:molobuddy_app/app/localisation/generated/app_localizations.dart';
import 'package:molobuddy_app/bootstrap/app_environment.dart';
import 'package:molobuddy_app/core/auth/auth_providers.dart';
import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_provider_catalogue_service.dart';
import 'package:molobuddy_app/core/auth/data/services/preview_auth_service.dart';
import 'package:molobuddy_app/core/onboarding/data/models/onboarding_answers.dart';
import 'package:molobuddy_app/core/onboarding/data/models/onboarding_failure.dart';
import 'package:molobuddy_app/core/onboarding/data/models/onboarding_snapshot.dart';
import 'package:molobuddy_app/core/onboarding/data/services/onboarding_service.dart';
import 'package:molobuddy_app/core/onboarding/onboarding_providers.dart';
import 'package:molobuddy_app/core/onboarding/ui/views/onboarding_view.dart';

final class _FakeOnboarding implements OnboardingService {
  _FakeOnboarding(this._snapshot);

  OnboardingSnapshot _snapshot;
  final List<OnboardingAnswers> saved = [];
  int completions = 0;
  OnboardingFailure? loadFailure;
  OnboardingFailure? saveFailure;
  OnboardingFailure? completeFailure;

  @override
  Future<OnboardingResult<OnboardingSnapshot>> load() async {
    final failure = loadFailure;
    return failure == null
        ? OnboardingSuccess(_snapshot)
        : OnboardingError(failure);
  }

  @override
  Future<OnboardingResult<OnboardingSnapshot>> save({
    required OnboardingAnswers answers,
    required String? expectedVersion,
  }) async {
    saved.add(answers);
    final failure = saveFailure;
    if (failure != null) {
      return OnboardingError(failure);
    }
    final merged = _snapshot.answers.copyWith(
      practiceName: answers.practiceName,
      practiceSize: answers.practiceSize,
      priorities: answers.priorities.isEmpty ? null : answers.priorities,
      startingPoint: answers.startingPoint,
    );
    _snapshot = OnboardingSnapshot(
      complete: false,
      // Derived the way the server derives it. A fake that always answered
      // with the same step would let the view advance somewhere the real
      // server never sends it.
      nextStep: _resume(merged),
      version: 'v-next',
      answers: merged,
    );
    return OnboardingSuccess(_snapshot);
  }

  static OnboardingStep _resume(OnboardingAnswers answers) {
    if (answers.practiceName == null || answers.practiceSize == null) {
      return OnboardingStep.practice;
    }
    if (answers.priorities.isEmpty) {
      return OnboardingStep.priorities;
    }
    if (answers.startingPoint == null) {
      return OnboardingStep.startingPoint;
    }
    return OnboardingStep.readyToComplete;
  }

  @override
  Future<OnboardingResult<PracticeRef>> complete({
    required String idempotencyKey,
  }) async {
    completions += 1;
    final failure = completeFailure;
    if (failure != null) {
      return OnboardingError(failure);
    }
    return const OnboardingSuccess(
      PracticeRef(
        practiceId: 'prc_1',
        displayLabel: 'Mokoena Media Tax',
        homeRegionKey: 'za1',
        routeVersion: 1,
        accessStatus: PracticeAccessStatus.active,
      ),
    );
  }
}

const _atPractice = OnboardingSnapshot(
  complete: false,
  nextStep: OnboardingStep.practice,
  answers: OnboardingAnswers(),
);

const _atStartingPoint = OnboardingSnapshot(
  complete: false,
  nextStep: OnboardingStep.startingPoint,
  version: 'v-3',
  answers: OnboardingAnswers(
    practiceName: 'Mokoena Media Tax',
    practiceSize: PracticeSize.smallTeam,
    priorities: {OnboardingPriority.deadlines},
  ),
);

/// A router with somewhere to land, because founding a practice navigates.
GoRouter _testRouter() {
  return GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingView()),
      GoRoute(
        path: '/home',
        builder: (_, _) =>
            const Scaffold(key: Key('landed_in_workspace'), body: SizedBox()),
      ),
    ],
  );
}

const _atPriorities = OnboardingSnapshot(
  complete: false,
  nextStep: OnboardingStep.priorities,
  version: 'v-2',
  answers: OnboardingAnswers(
    practiceName: 'Mokoena Tax Studio',
    practiceSize: PracticeSize.smallTeam,
  ),
);

Future<void> _pumpPracticeStep(WidgetTester tester, Size size) =>
    _pump(tester, _FakeOnboarding(_atPractice), size: size);

Future<void> _pumpPrioritiesStep(WidgetTester tester, Size size) =>
    _pump(tester, _FakeOnboarding(_atPriorities), size: size);

Future<void> _pumpStartingPointStep(WidgetTester tester, Size size) =>
    _pump(tester, _FakeOnboarding(_atStartingPoint), size: size);

Future<void> _pump(
  WidgetTester tester,
  _FakeOnboarding service, {
  Size size = const Size(390, 900),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        onboardingServiceProvider.overrideWithValue(service),
        appEnvironmentProvider.overrideWithValue(
          const AppEnvironment(
            authMode: AuthRuntimeMode.preview,
            apiBaseUrl: null,
            firebaseConfiguration: null,
          ),
        ),
        authServiceProvider.overrideWithValue(
          PreviewAuthService.forTesting(debugAllowed: true),
        ),
        authProviderCatalogueProvider.overrideWithValue(
          const BundledPreviewAuthProviderCatalogueService(),
        ),
      ],
      child: MaterialApp.router(
        theme: MoloTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: _testRouter(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The steps are taller than the viewport, so a bare tap can land on nothing.
///
/// Settles before scrolling, not only after: typing into a field leaves a
/// rebuild pending, and scrolling against the stale layout lands the target
/// somewhere the rebuild then moves it away from.
Future<void> _tapWhenVisible(WidgetTester tester, Finder finder) async {
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens at the step the server derived', (tester) async {
    await _pump(tester, _FakeOnboarding(_atPractice));

    expect(find.byKey(const Key('registration_practice_step')), findsOneWidget);
  });

  testWidgets('a resumed wizard opens past the questions already answered', (
    tester,
  ) async {
    await _pump(tester, _FakeOnboarding(_atStartingPoint));

    expect(
      find.byKey(const Key('registration_starting_point_step')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('registration_practice_step')), findsNothing);
  });

  testWidgets('a wizard that could not load asks nothing', (tester) async {
    final service = _FakeOnboarding(_atStartingPoint)
      ..loadFailure = const OnboardingFailure(
        OnboardingFailureKind.attestationRequired,
      );
    await _pump(tester, service);

    expect(find.byKey(const Key('onboarding_load_failure')), findsOneWidget);
    expect(
      find.byKey(const Key('registration_starting_point_step')),
      findsNothing,
    );
    expect(find.byKey(const Key('registration_practice_step')), findsNothing);
  });

  testWidgets('a wizard that could not load says which failure it was', (
    tester,
  ) async {
    final service = _FakeOnboarding(_atPractice)
      ..loadFailure = const OnboardingFailure(
        OnboardingFailureKind.attestationRequired,
      );
    await _pump(tester, service);

    expect(find.text('This device could not be verified.'), findsOneWidget);
    expect(find.text('Something went wrong. Try again.'), findsNothing);
  });

  testWidgets('a wizard that could not load offers to try again', (
    tester,
  ) async {
    final service = _FakeOnboarding(_atStartingPoint)
      ..loadFailure = const OnboardingFailure(
        OnboardingFailureKind.networkUnavailable,
      );
    await _pump(tester, service);
    service.loadFailure = null;

    await _tapWhenVisible(
      tester,
      find.byKey(const Key('onboarding_load_retry')),
    );

    expect(
      find.byKey(const Key('registration_starting_point_step')),
      findsOneWidget,
    );
  });

  testWidgets('a step saves before it advances', (tester) async {
    final service = _FakeOnboarding(_atPractice);
    await _pump(tester, service);

    await tester.enterText(
      find.byKey(const Key('practice_name_field')),
      'Mokoena Media Tax',
    );
    await _tapWhenVisible(tester, find.byKey(const Key('practice_size_small')));
    await _tapWhenVisible(
      tester,
      find.byKey(const Key('registration_practice_continue')),
    );

    expect(service.saved, hasLength(1));
    expect(service.saved.single.practiceName, 'Mokoena Media Tax');
    expect(service.saved.single.practiceSize, PracticeSize.smallTeam);
    expect(
      find.byKey(const Key('registration_priorities_step')),
      findsOneWidget,
    );
  });

  testWidgets('a failed save keeps the user on the step and says why', (
    tester,
  ) async {
    final service = _FakeOnboarding(_atPractice)
      ..saveFailure = const OnboardingFailure(
        OnboardingFailureKind.networkUnavailable,
      );
    await _pump(tester, service);

    await tester.enterText(
      find.byKey(const Key('practice_name_field')),
      'Mokoena Media Tax',
    );
    await _tapWhenVisible(
      tester,
      find.byKey(const Key('registration_practice_continue')),
    );

    expect(find.byKey(const Key('registration_practice_step')), findsOneWidget);
    expect(find.byKey(const Key('onboarding_failure_notice')), findsOneWidget);
    expect(
      find.text(
        'Molo cannot connect right now. Check your connection and try again.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('the last step founds the practice', (tester) async {
    final service = _FakeOnboarding(_atStartingPoint);
    await _pump(tester, service);

    await _tapWhenVisible(
      tester,
      find.byKey(const Key('starting_point_sample')),
    );
    await _tapWhenVisible(
      tester,
      find.byKey(const Key('finish_registration_preview')),
    );

    expect(
      service.saved.single.startingPoint,
      WorkspaceStartingPoint.sampleWorkspace,
    );
    expect(service.completions, 1);
  });

  testWidgets('a failed founding says why and leaves the button usable', (
    tester,
  ) async {
    final service = _FakeOnboarding(_atStartingPoint)
      ..completeFailure = const OnboardingFailure(
        OnboardingFailureKind.networkUnavailable,
      );
    await _pump(tester, service);

    await _tapWhenVisible(
      tester,
      find.byKey(const Key('starting_point_sample')),
    );
    await _tapWhenVisible(
      tester,
      find.byKey(const Key('finish_registration_preview')),
    );

    expect(find.byKey(const Key('onboarding_failure_notice')), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('finish_registration_preview')),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('nothing offers a return to sign-in any more', (tester) async {
    // The old completion screen claimed the workspace was ready and then sent
    // the user to sign in. Both halves of that are gone.
    await _pump(tester, _FakeOnboarding(_atStartingPoint));

    expect(find.text('Continue to sign in'), findsNothing);
    expect(
      find.byKey(const Key('registration_return_to_sign_in')),
      findsNothing,
    );
    expect(find.byKey(const Key('registration_complete_step')), findsNothing);
  });

  group('wizard fidelity', () {
    testWidgets('the practice step wears the rail at step two', (tester) async {
      await _pumpPracticeStep(tester, const Size(1440, 950));
      expect(find.text('Step 2 of 4'), findsOneWidget);
      // Step one is behind us, so its chip carries a tick, not a number.
      expect(
        find.descendant(
          of: find.byKey(MoloWizardRail.chipKey(1)),
          matching: find.text('1'),
        ),
        findsNothing,
      );
    });

    testWidgets('the practice step offers no way back to account creation', (
      tester,
    ) async {
      // Going back would mean un-creating a Firebase account that already
      // exists, so this step deliberately has no back link.
      await _pumpPracticeStep(tester, const Size(1440, 950));
      expect(find.byType(MoloWizardBackButton), findsNothing);
    });

    testWidgets('the size cards are single-choice, with traced glyphs', (
      tester,
    ) async {
      await _pumpPracticeStep(tester, const Size(1440, 950));
      for (final key in const [
        Key('practice_size_solo'),
        Key('practice_size_small'),
        Key('practice_size_growing'),
      ]) {
        expect(
          tester.widget<MoloChoiceCard>(find.byKey(key)).kind,
          MoloChoiceKind.single,
        );
        expect(
          find.descendant(of: find.byKey(key), matching: find.byType(MoloIcon)),
          findsWidgets,
        );
      }
      expect(find.byIcon(Icons.person_outline_rounded), findsNothing);
    });

    testWidgets('choosing one size unchooses the others', (tester) async {
      await _pumpPracticeStep(tester, const Size(1440, 950));
      await _tapWhenVisible(
        tester,
        find.byKey(const Key('practice_size_small')),
      );
      expect(
        tester
            .widget<MoloChoiceCard>(
              find.byKey(const Key('practice_size_small')),
            )
            .selected,
        isTrue,
      );
      await _tapWhenVisible(
        tester,
        find.byKey(const Key('practice_size_growing')),
      );
      expect(
        tester
            .widget<MoloChoiceCard>(
              find.byKey(const Key('practice_size_small')),
            )
            .selected,
        isFalse,
      );
    });

    testWidgets('the region select keeps its label above and its note below', (
      tester,
    ) async {
      await _pumpPracticeStep(tester, const Size(1440, 950));
      final label = tester.getRect(find.text('Primary tax region'));
      final field = tester.getRect(
        find.byKey(const Key('practice_region_field')),
      );
      final note = tester.getRect(
        find.text('South Africa is available first. More regions will follow.'),
      );
      expect(label.bottom, lessThan(field.top));
      expect(note.top, greaterThan(field.top));
    });

    testWidgets('the goals are multiple-choice and carry no extra checkbox', (
      tester,
    ) async {
      await _pumpPrioritiesStep(tester, const Size(1440, 950));
      expect(find.byType(Checkbox), findsNothing);
      for (final name in const [
        'deadlines',
        'documents',
        'teamwork',
        'visibility',
      ]) {
        expect(
          tester.widget<MoloChoiceCard>(find.byKey(Key('priority_$name'))).kind,
          MoloChoiceKind.multiple,
        );
      }
    });

    testWidgets('more than one goal can be chosen at once', (tester) async {
      await _pumpPrioritiesStep(tester, const Size(1440, 950));
      await _tapWhenVisible(
        tester,
        find.byKey(const Key('priority_deadlines')),
      );
      await _tapWhenVisible(
        tester,
        find.byKey(const Key('priority_documents')),
      );
      expect(
        tester
            .widget<MoloChoiceCard>(find.byKey(const Key('priority_deadlines')))
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<MoloChoiceCard>(find.byKey(const Key('priority_documents')))
            .selected,
        isTrue,
      );
    });

    testWidgets('the goals step can go back, and says so first', (
      tester,
    ) async {
      await _pumpPrioritiesStep(tester, const Size(1440, 950));
      expect(find.byType(MoloWizardBackButton), findsOneWidget);
      expect(
        tester.getRect(find.text('Back')).top,
        lessThan(tester.getRect(find.text('Choose your first win')).top),
      );
    });

    testWidgets('the starting points are single-choice', (tester) async {
      await _pumpStartingPointStep(tester, const Size(1440, 950));
      for (final key in const [
        Key('starting_point_import'),
        Key('starting_point_client'),
        Key('starting_point_sample'),
      ]) {
        expect(
          tester.widget<MoloChoiceCard>(find.byKey(key)).kind,
          MoloChoiceKind.single,
        );
      }
    });

    testWidgets('the last step asks to build the workspace', (tester) async {
      await _pumpStartingPointStep(tester, const Size(1440, 950));
      expect(find.text('Build my workspace'), findsOneWidget);
      expect(find.text('Step 4 of 4'), findsOneWidget);
      expect(
        find.textContaining('Sample data is clearly marked'),
        findsOneWidget,
      );
    });

    testWidgets('each step is quiet until it has its answer', (tester) async {
      await _pumpPrioritiesStep(tester, const Size(1440, 950));
      final button = find.byKey(const Key('complete_registration_preview'));
      expect(
        tester
            .widget<FilledButton>(button)
            .style
            ?.backgroundColor
            ?.resolve(const <WidgetState>{}),
        MoloColours.border,
      );

      await _tapWhenVisible(
        tester,
        find.byKey(const Key('priority_deadlines')),
      );
      expect(tester.widget<FilledButton>(button).style, isNull);
    });

    testWidgets('the tab order follows the order the step is drawn in', (
      tester,
    ) async {
      // Flutter's default traversal reads top to bottom, so asserting the
      // geometry asserts the order. The back link moved above the eyebrow and
      // the footnote below the action.
      await _pumpPrioritiesStep(tester, const Size(1440, 1400));
      final tops = <String, double>{
        'back': tester.getRect(find.text('Back')).top,
        'first goal': tester
            .getRect(find.byKey(const Key('priority_deadlines')))
            .top,
        'last goal': tester
            .getRect(find.byKey(const Key('priority_visibility')))
            .top,
        'continue': tester
            .getRect(find.byKey(const Key('complete_registration_preview')))
            .top,
      };
      final names = tops.keys.toList();
      for (var i = 1; i < names.length; i++) {
        expect(
          tops[names[i]],
          greaterThan(tops[names[i - 1]]!),
          reason: '${names[i]} must come after ${names[i - 1]}',
        );
      }
    });

    testWidgets('pressing it while incomplete still says what is missing', (
      tester,
    ) async {
      // The button looks quiet but is not dead: pressing is how a pointer user
      // finds out, and the inline message is the answer.
      await _pumpPrioritiesStep(tester, const Size(1440, 950));
      await _tapWhenVisible(
        tester,
        find.byKey(const Key('complete_registration_preview')),
      );
      expect(find.text('Choose at least one priority.'), findsOneWidget);
    });
  });
}
