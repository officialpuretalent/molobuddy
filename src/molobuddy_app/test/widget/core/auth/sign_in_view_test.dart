import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
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

    final legalNotice = find.textContaining(
      'By signing in',
      findRichText: true,
    );
    await tester.ensureVisible(legalNotice);
    await tester.pumpAndSettle();
    await tester.tapOnText(find.textRange.ofSubstring('By signing in'));
    expect(find.byType(AlertDialog), findsNothing);

    await tester.tapOnText(find.textRange.ofSubstring('Privacy Policy'));
    await tester.pumpAndSettle();
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(
      find.text(
        'This document will be available before account creation is enabled.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

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
    expect(tester.getSize(find.byKey(const Key('auth_hero_panel'))).width, 360);
    expect(
      find.text('Everything your practice needs to keep work moving.'),
      findsOneWidget,
    );
  });

  testWidgets('authentication pages keep a stable supporting pane edge', (
    tester,
  ) async {
    await _setViewport(tester, const Size(1280, 900));
    await _pumpPreviewApp(tester);

    final signInPaneWidth = tester
        .getSize(find.byKey(const Key('auth_hero_panel')))
        .width;
    final createAccountLink = find.byKey(const Key('create_account_link'));
    await tester.ensureVisible(createAccountLink);
    await tester.tap(createAccountLink);
    await tester.pumpAndSettle();

    final signUpPaneWidth = tester
        .getSize(find.byKey(const Key('registration_progress_panel')))
        .width;
    expect(signUpPaneWidth, signInPaneWidth);
  });

  testWidgets('page changes fade without sliding', (tester) async {
    await _setViewport(tester, const Size(390, 844));
    await _pumpPreviewApp(tester);

    final createAccountLink = find.byKey(const Key('create_account_link'));
    await tester.ensureVisible(createAccountLink);
    await tester.tap(createAccountLink);
    await tester.pump();

    expect(find.byType(FadeTransition), findsWidgets);
    expect(find.byType(SlideTransition), findsNothing);

    await tester.pumpAndSettle();
    expect(find.byKey(const Key('registration_account_step')), findsOneWidget);
  });

  testWidgets('returning to sign-in clears stale validation errors', (
    tester,
  ) async {
    await _setViewport(tester, const Size(390, 844));
    await _pumpPreviewApp(tester);

    await _tapWhenVisible(tester, find.byKey(const Key('sign_in_button')));
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Use at least 8 characters.'), findsOneWidget);

    await _tapWhenVisible(tester, find.byKey(const Key('create_account_link')));
    await _tapWhenVisible(
      tester,
      find.byKey(const Key('registration_sign_in_link')),
    );

    expect(find.byKey(const Key('sign_in_form')), findsOneWidget);
    expect(find.text('Enter a valid email address.'), findsNothing);
    expect(find.text('Use at least 8 characters.'), findsNothing);
  });

  testWidgets('hovering an invalid field keeps its label and icon readable', (
    tester,
  ) async {
    await _setViewport(tester, const Size(1280, 900));
    await _pumpPreviewApp(tester);
    await _tapWhenVisible(tester, find.byKey(const Key('sign_in_button')));

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(
      tester.getCenter(find.byKey(const Key('password_field'))),
    );
    await tester.pumpAndSettle();

    final labelColour = tester
        .renderObject<RenderParagraph>(find.text('Password'))
        .text
        .style
        ?.color;
    expect(labelColour, MoloColours.error);

    final icon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const Key('password_field')),
        matching: find.byIcon(Icons.visibility_outlined),
      ),
    );
    final iconColour =
        icon.color ??
        IconTheme.of(
          tester.element(find.byIcon(Icons.visibility_outlined)),
        ).color;
    expect(iconColour, isNot(MoloColours.surface));
  });

  testWidgets('the coming-soon Google control announces once', (tester) async {
    final semantics = tester.ensureSemantics();
    await _setViewport(tester, const Size(390, 844));
    await _pumpPreviewApp(tester);

    expect(_semanticsLabelsContaining(tester, 'Google'), hasLength(1));
    semantics.dispose();
  });

  testWidgets('the sign-in heading is exposed as a heading', (tester) async {
    final semantics = tester.ensureSemantics();
    await _setViewport(tester, const Size(390, 844));
    await _pumpPreviewApp(tester);

    expect(
      tester.getSemantics(find.text('Welcome back')),
      isSemantics(label: 'Welcome back', isHeader: true),
    );
    semantics.dispose();
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

List<String> _semanticsLabelsContaining(WidgetTester tester, String needle) {
  final labels = <String>[];
  void visit(SemanticsNode node) {
    if (node.label.contains(needle)) {
      labels.add(node.label);
    }
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(tester.getSemantics(find.byType(MaterialApp)));
  return labels;
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
