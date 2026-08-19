import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/molo_app.dart';
import 'package:molobuddy_app/bootstrap/app_environment.dart';
import 'package:molobuddy_app/core/auth/auth_providers.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_provider_catalogue_service.dart';
import 'package:molobuddy_app/core/auth/data/services/preview_auth_service.dart';

void main() {
  testWidgets('compact layout shows the form and disabled Google stub', (
    tester,
  ) async {
    await _setViewport(tester, const Size(390, 844));
    await _pumpPreviewApp(tester);

    expect(find.byKey(const Key('sign_in_form')), findsOneWidget);
    expect(find.byKey(const Key('auth_hero_panel')), findsNothing);
    expect(find.byKey(const Key('preview_banner')), findsOneWidget);

    final googleButton = tester.widget<OutlinedButton>(
      find.byKey(const Key('google_sign_in_button')),
    );
    expect(googleButton.onPressed, isNull);
    expect(find.text('Coming soon'), findsOneWidget);
  });

  testWidgets('expanded layout adds a bounded brand story panel', (
    tester,
  ) async {
    await _setViewport(tester, const Size(1280, 900));
    await _pumpPreviewApp(tester);

    expect(find.byKey(const Key('auth_hero_panel')), findsOneWidget);
    expect(find.byKey(const Key('sign_in_form')), findsOneWidget);
    expect(
      find.text('Everything your practice needs to keep work moving.'),
      findsOneWidget,
    );
  });

  testWidgets('preview email sign-in reaches welcome and can sign out', (
    tester,
  ) async {
    await _setViewport(tester, const Size(390, 844));
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
    expect(find.text('thando.mokoena@example.com'), findsOneWidget);
    expect(find.text('Welcome, Thando Mokoena'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sign_out_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sign_in_form')), findsOneWidget);
  });
}

Future<void> _setViewport(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<void> _pumpPreviewApp(WidgetTester tester) async {
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
