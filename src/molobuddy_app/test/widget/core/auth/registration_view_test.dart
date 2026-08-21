import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/adaptive/molo_wizard_shell.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_check_row.dart';
import 'package:molobuddy_app/app/design_system/components/molo_choice_card.dart';
import 'package:molobuddy_app/app/molo_app.dart';
import 'package:molobuddy_app/bootstrap/app_environment.dart';
import 'package:molobuddy_app/core/auth/auth_providers.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_user.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_provider_catalogue_service.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_service.dart';
import 'package:molobuddy_app/core/auth/data/services/preview_auth_service.dart';
import 'package:molobuddy_app/core/auth/ui/widgets/auth_legal_links_text.dart';

void main() {
  testWidgets('the account step creates an account and hands over', (
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

    await _tapWhenVisible(
      tester,
      find.byKey(const Key('registration_account_continue')),
    );
    expect(find.text('Enter your full name.'), findsOneWidget);
    expect(find.text('You need to agree before continuing.'), findsOneWidget);

    await _fillAccount(tester);
    await _tapWhenVisible(
      tester,
      find.byKey(const Key('registration_account_continue')),
    );

    // The account exists now, so signup continues on the route that survives a
    // closed tab.
    expect(find.byKey(const Key('registration_practice_step')), findsOneWidget);
  });

  testWidgets('an address that already has an account says so on the field', (
    tester,
  ) async {
    await _setViewport(tester, const Size(390, 844));
    await _pumpPreviewApp(tester, authService: _AlwaysTakenAuthService());
    await _openRegistration(tester);
    await _fillAccount(tester);

    await _tapWhenVisible(
      tester,
      find.byKey(const Key('registration_account_continue')),
    );

    expect(
      find.text('That address already has an account. Sign in instead.'),
      findsOneWidget,
    );
    // It is a fact about one field, so it belongs on that field rather than in
    // a banner above the form.
    expect(find.byKey(const Key('registration_failure_notice')), findsNothing);
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

    await _fillAccount(tester);
    await _tapWhenVisible(
      tester,
      find.byKey(const Key('registration_account_continue')),
    );
    await tester.enterText(
      find.byKey(const Key('practice_name_field')),
      'Mokoena Global Tax',
    );
    await tester.pumpAndSettle();

    // The panel previews what is being typed, before it is saved.
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

    // Selection is carried by the mark's fill and its tick, not by the card's
    // tint: the chosen mark fills and shows the tick, an unchosen one is white
    // with the tick at zero opacity.
    BoxDecoration markOf(Key card) {
      return tester
              .widget<Container>(
                find.descendant(
                  of: find.byKey(card),
                  matching: find.byKey(MoloChoiceCard.markKey),
                ),
              )
              .decoration!
          as BoxDecoration;
    }

    double tickOpacityOf(Key card) {
      return tester
          .widget<Opacity>(
            find.descendant(
              of: find.byKey(card),
              matching: find.byType(Opacity),
            ),
          )
          .opacity;
    }

    expect(
      markOf(const Key('starting_point_sample')).color,
      MoloColours.pulseText,
    );
    expect(tickOpacityOf(const Key('starting_point_sample')), 1);
    expect(
      markOf(const Key('starting_point_import')).color,
      MoloColours.surface,
    );
    expect(tickOpacityOf(const Key('starting_point_import')), 0);
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

  group('step one fidelity', () {
    testWidgets('the rail names all four steps and marks this one', (
      tester,
    ) async {
      await _setViewport(tester, const Size(1440, 950));
      await _pumpRegistration(tester);

      // "Your account" twice on purpose: it is both the rail's name for step
      // one and the form's own eyebrow, which is what the baseline writes.
      expect(find.text('Your account'), findsNWidgets(2));
      expect(find.text('Your practice'), findsWidgets);
      expect(find.text('Your first win'), findsOneWidget);
      expect(find.text('Your starting point'), findsOneWidget);
      expect(find.text('Step 1 of 4'), findsOneWidget);
    });

    testWidgets('there is no way back from the first step', (tester) async {
      await _setViewport(tester, const Size(1440, 950));
      await _pumpRegistration(tester);
      expect(find.byType(MoloWizardBackButton), findsNothing);
    });

    testWidgets('the password hint changes once it is long enough', (
      tester,
    ) async {
      await _setViewport(tester, const Size(1440, 950));
      await _pumpRegistration(tester);

      expect(find.text('Use at least 8 characters.'), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.text('Use at least 8 characters.'))
            .style
            ?.color,
        MoloColours.secondaryText,
      );

      await tester.enterText(
        find.byKey(const Key('registration_password_field')),
        'long-enough-password',
      );
      await tester.pumpAndSettle();

      expect(find.text('Use at least 8 characters.'), findsNothing);
      expect(find.text('Long enough.'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Long enough.')).style?.color,
        MoloColours.success,
      );
    });

    testWidgets('the terms row is the design box, not a Material checkbox', (
      tester,
    ) async {
      await _setViewport(tester, const Size(1440, 950));
      await _pumpRegistration(tester);
      expect(find.byType(Checkbox), findsNothing);
      expect(
        find.byKey(const Key('registration_terms_checkbox')),
        findsOneWidget,
      );
      expect(
        tester.getSize(find.byKey(MoloCheckRow.boxKey)),
        const Size(21, 21),
      );
    });

    testWidgets('the action is quiet until every answer is in', (tester) async {
      await _setViewport(tester, const Size(1440, 950));
      await _pumpRegistration(tester);
      final button = find.byKey(const Key('registration_account_continue'));

      expect(
        tester
            .widget<FilledButton>(button)
            .style
            ?.backgroundColor
            ?.resolve(const <WidgetState>{}),
        MoloColours.border,
      );

      await _fillAccount(tester);
      await tester.pumpAndSettle();

      expect(
        tester.widget<FilledButton>(button).style,
        isNull,
        reason: 'a complete step defers to the theme',
      );
    });

    testWidgets('the footnote says what Molo will not do', (tester) async {
      await _setViewport(tester, const Size(1440, 950));
      await _pumpRegistration(tester);
      expect(find.textContaining('never signs in to eFiling'), findsOneWidget);
    });
  });
}

final class _AlwaysTakenAuthService implements AuthService {
  @override
  Future<AuthResult<AuthUser>> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return const AuthError(AuthFailure(AuthFailureKind.emailAlreadyRegistered));
  }

  @override
  AuthUser? get currentUser => null;

  @override
  Future<AuthResult<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
    required bool persistSession,
  }) async => throw UnimplementedError('signInWithEmailAndPassword');

  @override
  Future<AuthResult<void>> signOut() async => const AuthSuccess(null);
}

Future<void> _fillAccount(
  WidgetTester tester, {
  String email = 'naledi@example.com',
}) async {
  await tester.enterText(
    find.byKey(const Key('registration_name_field')),
    'Naledi Mokoena',
  );
  await tester.enterText(
    find.byKey(const Key('registration_email_field')),
    email,
  );
  await tester.enterText(
    find.byKey(const Key('registration_password_field')),
    'safe-preview-password',
  );
  // A real click blurs the field first; without this the text-editing overlay
  // swallows the synthetic tap.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await _tapWhenVisible(
    tester,
    find.byKey(const Key('registration_terms_checkbox')),
  );
}

/// Sign-in, then through to the account step.
Future<void> _pumpRegistration(WidgetTester tester) async {
  await _pumpPreviewApp(tester);
  await _openRegistration(tester);
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

Future<void> _pumpPreviewApp(
  WidgetTester tester, {
  AuthService? authService,
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
          authService ?? PreviewAuthService.forTesting(debugAllowed: true),
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
