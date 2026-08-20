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
