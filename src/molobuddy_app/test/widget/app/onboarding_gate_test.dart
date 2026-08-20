import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/molo_app.dart';
import 'package:molobuddy_app/app/router/app_router.dart';
import 'package:molobuddy_app/bootstrap/app_environment.dart';
import 'package:molobuddy_app/core/auth/auth_providers.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_provider_catalogue_service.dart';
import 'package:molobuddy_app/core/auth/data/services/preview_auth_service.dart';
import 'package:molobuddy_app/core/auth/data/services/session_service.dart';

/// A session that says what the gate needs to decide, without going through
/// preview's practice directory.
final class _SessionSaying implements SessionService {
  const _SessionSaying({required this.onboardingComplete});

  final bool onboardingComplete;

  @override
  Future<AuthResult<MoloSession>> loadSession() async {
    return AuthSuccess(
      MoloSession(
        uid: 'user_preview',
        emailMasked: 't***@example.com',
        practiceRefs: const [],
        onboardingComplete: onboardingComplete,
      ),
    );
  }
}

/// A session load that fails the way a lapsed App Check token does.
final class _SessionThatFails implements SessionService {
  const _SessionThatFails();

  @override
  Future<AuthResult<MoloSession>> loadSession() async {
    return const AuthError(AuthFailure(AuthFailureKind.attestationRequired));
  }
}

void main() {
  testWidgets('a signed-out visitor at /onboarding is sent to sign-in', (
    tester,
  ) async {
    await _pumpPreviewApp(tester);

    await _goTo(tester, '/onboarding');

    expect(find.byKey(const Key('sign_in_form')), findsOneWidget);
  });

  testWidgets('an unfinished account is routed to onboarding from anywhere', (
    tester,
  ) async {
    await _pumpSignedIn(tester);

    for (final location in ['/home', '/sign-in', '/nowhere']) {
      await _goTo(tester, location);

      expect(
        find.byKey(const Key('registration_practice_step')),
        findsOneWidget,
        reason: '$location should have led back to onboarding',
      );
    }
  });

  testWidgets('an unknown route does not show the not-found page mid-setup', (
    tester,
  ) async {
    await _pumpSignedIn(tester);

    await _goTo(tester, '/nowhere');

    expect(find.byKey(const Key('not_found_view')), findsNothing);
  });

  testWidgets('a failed session is not left sitting on the sign-in form', (
    tester,
  ) async {
    // Nothing about the session is known, so the gate cannot say whether
    // setup is finished. Leaving the user on a form they have already
    // completed says nothing at all; the welcome screen names the failure
    // and offers to try again.
    await _pumpSignedIn(tester, session: const _SessionThatFails());

    await _goTo(tester, '/sign-in');

    expect(find.byKey(const Key('sign_in_form')), findsNothing);
    expect(find.byKey(const Key('welcome_view')), findsOneWidget);
  });

  testWidgets('a session still loading does not move anybody', (tester) async {
    // The gate must keep declining to guess while an answer is on its way,
    // or a slow connection flashes the user through three screens. Pumped a
    // fixed number of frames rather than settled: the loading state spins
    // forever by design, so there is nothing to settle into.
    await _pumpPreviewApp(tester, session: const _SessionThatNeverAnswers());
    await tester.enterText(
      find.byKey(const Key('email_field')),
      'thando.mokoena@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('password_field')),
      'safe-preview-password',
    );
    await tester.tap(find.byKey(const Key('sign_in_button')));
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.byKey(const Key('welcome_view')), findsNothing);
  });

  testWidgets('a finished account at /onboarding is sent to the workspace', (
    tester,
  ) async {
    await _pumpSignedIn(
      tester,
      session: const _SessionSaying(onboardingComplete: true),
    );

    await _goTo(tester, '/onboarding');

    expect(find.byKey(const Key('welcome_view')), findsOneWidget);
  });
}

/// Navigates the way a deep link or a typed URL does, through the app's own
/// router rather than a test-only one.
Future<void> _goTo(WidgetTester tester, String location) async {
  ProviderScope.containerOf(
    tester.element(find.byType(MoloApp)),
  ).read(appRouterProvider).go(location);
  await tester.pumpAndSettle();
}

/// Never settles, which is what a slow network looks like to the gate.
final class _SessionThatNeverAnswers implements SessionService {
  const _SessionThatNeverAnswers();

  @override
  Future<AuthResult<MoloSession>> loadSession() {
    return Completer<AuthResult<MoloSession>>().future;
  }
}

Future<void> _pumpSignedIn(
  WidgetTester tester, {
  SessionService? session,
}) async {
  await _pumpPreviewApp(tester, session: session);
  await tester.enterText(
    find.byKey(const Key('email_field')),
    'thando.mokoena@example.com',
  );
  await tester.enterText(
    find.byKey(const Key('password_field')),
    'safe-preview-password',
  );
  await tester.tap(find.byKey(const Key('sign_in_button')));
  await tester.pumpAndSettle();
}

Future<void> _pumpPreviewApp(
  WidgetTester tester, {
  SessionService? session,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 900);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
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
        if (session != null) sessionServiceProvider.overrideWithValue(session),
      ],
      child: const MoloApp(),
    ),
  );
  await tester.pumpAndSettle();
}
