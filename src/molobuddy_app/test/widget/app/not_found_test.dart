import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/molo_app.dart';
import 'package:molobuddy_app/app/router/app_router.dart';
import 'package:molobuddy_app/bootstrap/app_environment.dart';
import 'package:molobuddy_app/core/auth/auth_providers.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_provider_catalogue_service.dart';
import 'package:molobuddy_app/core/auth/data/services/preview_auth_service.dart';

void main() {
  testWidgets('an unknown location shows a Molo page, not a router exception', (
    tester,
  ) async {
    await _pumpSignedIn(tester);

    await _goTo(tester, '/nowhere');

    expect(find.byKey(const Key('not_found_view')), findsOneWidget);
    // What the router says to itself is not what the reader should be told.
    expect(find.textContaining('GoException'), findsNothing);
    expect(find.textContaining('no routes for location'), findsNothing);
  });

  testWidgets('the unknown location leads back to the workspace', (
    tester,
  ) async {
    await _pumpSignedIn(tester);
    await _goTo(tester, '/nowhere');

    await tester.tap(find.byKey(const Key('not_found_home_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('welcome_view')), findsOneWidget);
  });

  testWidgets('a signed-out visitor is sent to sign-in, not to an error', (
    tester,
  ) async {
    await _pumpPreviewApp(tester);

    await _goTo(tester, '/nowhere');

    expect(find.byKey(const Key('sign_in_form')), findsOneWidget);
    expect(find.byKey(const Key('not_found_view')), findsNothing);
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

Future<void> _pumpSignedIn(WidgetTester tester) async {
  await _pumpPreviewApp(tester);
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
  expect(find.byKey(const Key('welcome_view')), findsOneWidget);
}

Future<void> _pumpPreviewApp(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
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
      ],
      child: const MoloApp(),
    ),
  );
  await tester.pumpAndSettle();
}
