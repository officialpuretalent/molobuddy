import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/molo_app.dart';
import 'package:molobuddy_app/app/router/app_router.dart';
import 'package:molobuddy_app/bootstrap/app_environment.dart';
import 'package:molobuddy_app/core/auth/auth_providers.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_provider_catalogue_service.dart';
import 'package:molobuddy_app/core/auth/data/services/preview_auth_service.dart';

/// The whole of signup, in preview, with no backend.
///
/// Preview is a supported way to show the product, so it deserves a test that
/// fails when it breaks. It also exercises the same view models the real
/// build uses, against in-memory services rather than the control API.
void main() {
  testWidgets('preview signs up, answers every step and reaches a workspace', (
    tester,
  ) async {
    await _pumpPreviewApp(tester);

    await _tap(tester, const Key('create_account_link'));
    expect(find.byKey(const Key('registration_account_step')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('registration_name_field')),
      'Naledi Mokoena',
    );
    await tester.enterText(
      find.byKey(const Key('registration_email_field')),
      'naledi@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('registration_password_field')),
      'safe-preview-password',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await _tap(tester, const Key('registration_terms_checkbox'));
    await _tap(tester, const Key('registration_account_continue'));

    // The account exists, so signup continues on the resumable route.
    expect(find.byKey(const Key('registration_practice_step')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('practice_name_field')),
      'Mokoena Tax Studio',
    );
    await _tap(tester, const Key('practice_size_small'));
    await _tap(tester, const Key('registration_practice_continue'));

    expect(
      find.byKey(const Key('registration_priorities_step')),
      findsOneWidget,
    );
    await _tap(tester, const Key('priority_deadlines'));
    await _tap(tester, const Key('complete_registration_preview'));

    expect(
      find.byKey(const Key('registration_starting_point_step')),
      findsOneWidget,
    );
    await _tap(tester, const Key('starting_point_sample'));
    // Not pumpAndSettle: founding reloads the session, and that state renders
    // an indeterminate progress indicator which animates forever.
    final finish = find.byKey(const Key('finish_registration_preview'));
    await tester.ensureVisible(finish);
    await tester.pumpAndSettle();
    await tester.tap(finish);
    await _pumpFrames(tester);

    // The practice exists, so the gate lets them through and the welcome
    // screen never shows its no-practice state.
    expect(find.byKey(const Key('welcome_view')), findsOneWidget);
    expect(
      find.text(
        'You are signed in. No practice has been connected to this account yet.',
      ),
      findsNothing,
    );
  });

  testWidgets('an interrupted preview signup resumes where it stopped', (
    tester,
  ) async {
    await _pumpPreviewApp(tester);
    await _tap(tester, const Key('create_account_link'));
    await tester.enterText(
      find.byKey(const Key('registration_name_field')),
      'Naledi Mokoena',
    );
    await tester.enterText(
      find.byKey(const Key('registration_email_field')),
      'naledi@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('registration_password_field')),
      'safe-preview-password',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await _tap(tester, const Key('registration_terms_checkbox'));
    await _tap(tester, const Key('registration_account_continue'));

    await tester.enterText(
      find.byKey(const Key('practice_name_field')),
      'Mokoena Tax Studio',
    );
    await _tap(tester, const Key('practice_size_small'));
    await _tap(tester, const Key('registration_practice_continue'));

    // Walk away, then come back the way a deep link or a reload does.
    ProviderScope.containerOf(
      tester.element(find.byType(MoloApp)),
    ).read(appRouterProvider).go('/home');
    await _pumpFrames(tester);

    expect(
      find.byKey(const Key('registration_priorities_step')),
      findsOneWidget,
      reason: 'the answered practice step must not be asked again',
    );
  });
}

/// Advances a fixed number of frames.
///
/// Anything that reloads the session renders an indeterminate progress
/// indicator, so pumpAndSettle would wait for an animation that never ends.
Future<void> _pumpFrames(WidgetTester tester, {int frames = 80}) async {
  for (var frame = 0; frame < frames; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _tap(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _pumpPreviewApp(WidgetTester tester) async {
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
      ],
      child: const MoloApp(),
    ),
  );
  await tester.pumpAndSettle();
}
