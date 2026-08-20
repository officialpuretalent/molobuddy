import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
  OnboardingFailure? saveFailure;
  OnboardingFailure? completeFailure;

  @override
  Future<OnboardingResult<OnboardingSnapshot>> load() async =>
      OnboardingSuccess(_snapshot);

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

Future<void> _pump(WidgetTester tester, _FakeOnboarding service) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 900);
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
Future<void> _tapWhenVisible(WidgetTester tester, Finder finder) async {
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
}
