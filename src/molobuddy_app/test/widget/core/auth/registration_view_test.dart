import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/molo_app.dart';
import 'package:molobuddy_app/bootstrap/app_environment.dart';
import 'package:molobuddy_app/core/auth/auth_providers.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_provider_catalogue_service.dart';
import 'package:molobuddy_app/core/auth/data/services/preview_auth_service.dart';
import 'package:molobuddy_app/core/auth/ui/widgets/auth_legal_links_text.dart';

void main() {
  testWidgets('compact registration completes the full preview journey', (
    tester,
  ) async {
    await _setViewport(tester, const Size(390, 844));
    await _pumpPreviewApp(tester);
    await _openRegistration(tester);

    expect(find.byKey(const Key('registration_account_step')), findsOneWidget);
    expect(
      find.byKey(const Key('registration_compact_progress')),
      findsOneWidget,
    );
    final checkboxContext = tester.element(find.byType(Checkbox));
    final checkboxShape = CheckboxTheme.of(checkboxContext).shape;
    expect(checkboxShape, isA<RoundedRectangleBorder>());
    expect(
      (checkboxShape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(6),
    );
    expect(find.byType(CheckboxListTile), findsNothing);

    await tester.tapOnText(find.textRange.ofSubstring('I agree to the'));
    expect(
      tester
          .widget<Checkbox>(
            find.byKey(const Key('registration_terms_checkbox')),
          )
          .value,
      isFalse,
    );

    await tester.tapOnText(find.textRange.ofSubstring('Terms of Service'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'This document will be available before account creation is enabled.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await _tapWhenVisible(
      tester,
      find.byKey(const Key('registration_account_continue')),
    );
    expect(find.text('Enter your full name.'), findsOneWidget);
    expect(find.text('You need to agree before continuing.'), findsOneWidget);

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
    // A real click blurs the field first; without this the text-editing
    // overlay swallows the synthetic tap.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await _tapWhenVisible(
      tester,
      find.byKey(const Key('registration_terms_checkbox')),
    );
    await _tapWhenVisible(
      tester,
      find.byKey(const Key('registration_account_continue')),
    );

    expect(find.byKey(const Key('registration_practice_step')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('practice_name_field')),
      'Mokoena Tax Studio',
    );
    await _tapWhenVisible(tester, find.byKey(const Key('practice_size_small')));
    await _tapWhenVisible(
      tester,
      find.byKey(const Key('registration_practice_continue')),
    );

    expect(
      find.byKey(const Key('registration_priorities_step')),
      findsOneWidget,
    );
    await _tapWhenVisible(tester, find.byKey(const Key('priority_deadlines')));
    await _tapWhenVisible(
      tester,
      find.byKey(const Key('complete_registration_preview')),
    );

    expect(
      find.byKey(const Key('registration_starting_point_step')),
      findsOneWidget,
    );
    await _tapWhenVisible(
      tester,
      find.byKey(const Key('starting_point_sample')),
    );
    await _tapWhenVisible(
      tester,
      find.byKey(const Key('finish_registration_preview')),
    );

    expect(find.byKey(const Key('registration_complete_step')), findsOneWidget);
    expect(
      find.text('Your workspace is ready, Naledi Mokoena'),
      findsOneWidget,
    );
    expect(find.text('Mokoena Tax Studio'), findsOneWidget);
    expect(
      find.text('Preview complete. No account or practice data was saved.'),
      findsOneWidget,
    );
  });

  testWidgets('expanded registration shows the workspace context panel', (
    tester,
  ) async {
    await _setViewport(tester, const Size(1280, 900));
    await _pumpPreviewApp(tester);
    await _openRegistration(tester);

    expect(
      find.byKey(const Key('registration_progress_panel')),
      findsOneWidget,
    );
    expect(
      find.text(
        'A clear place for clients, documents, deadlines and your team.',
      ),
      findsOneWidget,
    );
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
    await _tapWhenVisible(
      tester,
      find.byKey(const Key('registration_terms_checkbox')),
    );
    await _tapWhenVisible(
      tester,
      find.byKey(const Key('registration_account_continue')),
    );
    await tester.enterText(
      find.byKey(const Key('practice_name_field')),
      'Mokoena Global Tax',
    );
    await tester.pump();

    final previewName = tester.widget<Text>(
      find.byKey(const Key('workspace_preview_practice_name')),
    );
    expect(previewName.data, 'Mokoena Global Tax');
  });

  testWidgets('the terms sentence is centred against its checkbox', (
    tester,
  ) async {
    await _setViewport(tester, const Size(390, 844));
    await _pumpPreviewApp(tester);
    await _openRegistration(tester);
    await _tapWhenVisible(
      tester,
      find.byKey(const Key('registration_account_continue')),
    );
    expect(find.text('You need to agree before continuing.'), findsOneWidget);

    final checkboxCentre = tester
        .getCenter(find.byKey(const Key('registration_terms_checkbox')))
        .dy;
    final sentenceCentre = tester.getCenter(find.byType(AuthLegalLinksText)).dy;
    expect(sentenceCentre, moreOrLessEquals(checkboxCentre, epsilon: 0.5));
  });

  testWidgets('step eyebrows keep sentence case', (tester) async {
    await _setViewport(tester, const Size(390, 844));
    await _pumpPreviewApp(tester);
    await _openRegistration(tester);

    expect(find.text('Your account'), findsOneWidget);
    expect(find.text('YOUR ACCOUNT'), findsNothing);
  });

  testWidgets('the registration heading is exposed as a heading', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _setViewport(tester, const Size(390, 844));
    await _pumpPreviewApp(tester);
    await _openRegistration(tester);

    expect(
      tester.getSemantics(find.text("Let's get you started")),
      isSemantics(label: "Let's get you started", isHeader: true),
    );
    semantics.dispose();
  });

  testWidgets('single-select cards show selection without relying on colour', (
    tester,
  ) async {
    await _setViewport(tester, const Size(390, 844));
    await _pumpPreviewApp(tester);
    await _openRegistration(tester);
    await _completeAccountStep(tester);

    await _tapWhenVisible(tester, find.byKey(const Key('practice_size_small')));
    await _tapWhenVisible(
      tester,
      find.byKey(const Key('registration_practice_continue')),
    );
    await _tapWhenVisible(tester, find.byKey(const Key('priority_deadlines')));
    await _tapWhenVisible(
      tester,
      find.byKey(const Key('complete_registration_preview')),
    );

    await _tapWhenVisible(
      tester,
      find.byKey(const Key('starting_point_sample')),
    );

    expect(
      find.descendant(
        of: find.byKey(const Key('starting_point_sample')),
        matching: find.byIcon(Icons.check_circle_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('starting_point_import')),
        matching: find.byIcon(Icons.circle_outlined),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('starting_point_import')),
        matching: find.byIcon(Icons.check_circle_rounded),
      ),
      findsNothing,
    );
  });

  testWidgets('registration can return to sign in', (tester) async {
    await _setViewport(tester, const Size(390, 844));
    await _pumpPreviewApp(tester);
    await _openRegistration(tester);

    await _tapWhenVisible(
      tester,
      find.byKey(const Key('registration_sign_in_link')),
    );

    expect(find.byKey(const Key('sign_in_form')), findsOneWidget);
  });
}

Future<void> _openRegistration(WidgetTester tester) async {
  final link = find.byKey(const Key('create_account_link'));
  await tester.ensureVisible(link);
  await tester.tap(link);
  await tester.pumpAndSettle();
}

Future<void> _completeAccountStep(WidgetTester tester) async {
  await _tapWhenVisible(
    tester,
    find.byKey(const Key('registration_terms_checkbox')),
  );
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
  await _tapWhenVisible(
    tester,
    find.byKey(const Key('registration_account_continue')),
  );
  await tester.enterText(
    find.byKey(const Key('practice_name_field')),
    'Mokoena Tax Studio',
  );
  await tester.pump();
}

Future<void> _tapWhenVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
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
