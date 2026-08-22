import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/icons/molo_glyphs.dart';
import 'package:molobuddy_app/app/molo_app.dart';
import 'package:molobuddy_app/bootstrap/app_environment.dart';
import 'package:molobuddy_app/core/auth/auth_providers.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_provider_catalogue_service.dart';
import 'package:molobuddy_app/core/auth/data/services/preview_auth_service.dart';
import 'package:molobuddy_app/core/auth/data/services/session_service.dart';

void main() {
  testWidgets('compact layout shows the form and both disabled providers', (
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

    // The design has no room for a "Coming soon" pill in a 46-high grid cell,
    // so the reason lives in each button's accessible name instead. That is
    // asserted in sign_in_fidelity_test.
    for (final key in const [
      Key('microsoft_sign_in_button'),
      Key('google_sign_in_button'),
    ]) {
      expect(tester.widget<OutlinedButton>(find.byKey(key)).onPressed, isNull);
    }
  });

  testWidgets('expanded layout adds the hero pane at the design width', (
    tester,
  ) async {
    await _setViewport(tester, const Size(1280, 900));
    await _pumpPreviewApp(tester);

    expect(find.byKey(const Key('auth_hero_panel')), findsOneWidget);
    expect(find.byKey(const Key('sign_in_form')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('auth_hero_panel'))).width,
      closeTo(1280 * 0.44, 0.01),
    );
    expect(find.text('Make serious work feel light.'), findsOneWidget);
  });

  testWidgets('the two wizard routes keep a stable supporting pane edge', (
    tester,
  ) async {
    // The invariant lives between /sign-up and /onboarding, which fade into
    // each other through one shared shell. Sign-in's photographic hero is a
    // different pane, and the baseline deliberately draws it wider, so it is
    // not part of this comparison.
    await _setViewport(tester, const Size(1280, 900));
    await _pumpPreviewApp(tester);

    final createAccountLink = find.byKey(const Key('create_account_link'));
    await tester.ensureVisible(createAccountLink);
    await tester.tap(createAccountLink);
    await tester.pumpAndSettle();

    final signUpPaneWidth = tester
        .getSize(find.byKey(const Key('registration_progress_panel')))
        .width;

    // Back to sign-in, because signing in is what reaches the onboarding
    // steps, and they wear the same shell as the account step.
    await _tapWhenVisible(
      tester,
      find.byKey(const Key('registration_sign_in_link')),
    );
    await _signIn(tester);
    expect(find.byKey(const Key('registration_practice_step')), findsOneWidget);
    final onboardingPaneWidth = tester
        .getSize(find.byKey(const Key('registration_progress_panel')))
        .width;

    expect(onboardingPaneWidth, signUpPaneWidth);
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
    // The bug this guards cannot recur in the same shape: the label is no
    // longer Material's floating one, so it never takes an error colour and
    // can never be painted white on white. What has to hold now is that the
    // label stays plum, the message says what is wrong, and the reveal glyph
    // stays visible against the field.
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
    expect(labelColour, MoloColours.moloPlum);
    expect(find.text('Use at least 8 characters.'), findsOneWidget);

    final glyph = tester.widget<MoloIcon>(
      find.descendant(
        of: find.byKey(const Key('password_field')),
        matching: find.byType(MoloIcon),
      ),
    );
    expect(glyph.color, isNot(MoloColours.surface));
    expect(glyph.color, MoloColours.secondaryText);
  });

  testWidgets('each coming-soon provider control announces once', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _setViewport(tester, const Size(390, 844));
    await _pumpPreviewApp(tester);

    expect(_semanticsLabelsContaining(tester, 'Google'), hasLength(1));
    expect(_semanticsLabelsContaining(tester, 'Microsoft'), hasLength(1));
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

  testWidgets('signing in with setup unfinished lands in the wizard', (
    tester,
  ) async {
    // A preview account has founded no practice, so the gate correctly sends
    // it to finish setting up rather than to a workspace it does not have.
    await _setViewport(tester, const Size(390, 900));
    await _pumpPreviewApp(tester);

    await _signIn(tester);

    expect(find.byKey(const Key('registration_practice_step')), findsOneWidget);
  });

  testWidgets('preview email sign-in reaches welcome and can sign out', (
    tester,
  ) async {
    await _setViewport(tester, const Size(390, 844));
    await _pumpPreviewApp(tester, finishedSetup: true);

    await _signIn(tester);

    expect(find.byKey(const Key('welcome_view')), findsOneWidget);
    // Preview answers with a demo session in the shape the server returns, so
    // the identity on screen is the masked address, never the one typed into
    // the form.
    expect(find.text('t***@example.com'), findsOneWidget);
    expect(find.text('thando.mokoena@example.com'), findsNothing);
    expect(find.text('Good morning, Thando Mokoena.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sign_out_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sign_in_form')), findsOneWidget);
  });
}

/// A session for an account that has finished setting up, so the onboarding
/// gate lets it reach the workspace.
final class _FinishedSession implements SessionService {
  const _FinishedSession();

  @override
  Future<AuthResult<MoloSession>> loadSession() async {
    return const AuthSuccess(
      MoloSession(
        uid: 'user_preview',
        displayName: 'Thando Mokoena',
        emailMasked: 't***@example.com',
        practiceRefs: [],
      ),
    );
  }
}

Future<void> _signIn(WidgetTester tester) async {
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

Future<void> _pumpPreviewApp(
  WidgetTester tester, {
  bool finishedSetup = false,
}) async {
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
        if (finishedSetup)
          sessionServiceProvider.overrideWithValue(const _FinishedSession()),
      ],
      child: const MoloApp(),
    ),
  );
  await tester.pumpAndSettle();
}
