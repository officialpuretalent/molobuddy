import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/adaptive/auth_shell_layout.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/molo_theme.dart';
import 'package:molobuddy_app/app/localisation/generated/app_localizations.dart';
import 'package:molobuddy_app/core/auth/ui/views/sign_in/sign_in_hero_pane.dart';

import 'sign_in_test_host.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    theme: MoloTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  group('hero pane', () {
    testWidgets('it carries the promise and the hero body', (tester) async {
      await tester.pumpWidget(host(const SignInHeroPane()));
      expect(find.text('Make serious work feel light.'), findsOneWidget);
      expect(
        find.textContaining('every deadline in one place'),
        findsOneWidget,
      );
    });

    testWidgets('the promise is 30px at the design tracking', (tester) async {
      await tester.pumpWidget(host(const SignInHeroPane()));
      final promise = tester.widget<Text>(
        find.text('Make serious work feel light.'),
      );
      expect(promise.style?.fontSize, 30);
      expect(promise.style?.height, 1.2);
      expect(promise.style?.letterSpacing, closeTo(-0.6, 0.001));
      expect(promise.style?.color, MoloColours.warmCanvas);
    });

    test('the pane is 44% of the window', () {
      expect(MoloAuthShellLayout.signInHeroWidth(1280), closeTo(563.2, 0.01));
      expect(MoloAuthShellLayout.signInHeroWidth(1440), closeTo(633.6, 0.01));
    });

    test('it is wider than the wizard rail, as the baseline draws it', () {
      // The two panes differ on purpose. Asserting it here means a later change
      // that quietly unifies them has to argue with a test.
      expect(
        MoloAuthShellLayout.signInHeroWidth(1440),
        greaterThan(MoloAuthShellLayout.supportingPaneWidth(1440)),
      );
    });
  });

  group('form pane', () {
    testWidgets('the form column is capped at 384', (tester) async {
      await setViewport(tester, const Size(1440, 950));
      await pumpPreviewSignIn(tester);
      expect(tester.getSize(find.byKey(const Key('sign_in_form'))).width, 384);
    });

    testWidgets('the heading is 34px at the design tracking', (tester) async {
      await setViewport(tester, const Size(1440, 950));
      await pumpPreviewSignIn(tester);
      final heading = tester.widget<Text>(find.text('Welcome back'));
      expect(heading.style?.fontSize, 34);
      expect(heading.style?.height, 1.12);
      expect(heading.style?.letterSpacing, closeTo(-0.85, 0.001));
    });

    testWidgets('a time-of-day kicker sits above it, in a readable colour', (
      tester,
    ) async {
      await setViewport(tester, const Size(1440, 950));
      await pumpPreviewSignIn(tester);
      final kicker = tester.widget<Text>(
        find.byKey(const Key('sign_in_kicker')),
      );
      expect(kicker.style?.fontSize, 12);
      expect(kicker.style?.color, MoloColours.secondaryText);
      expect(kicker.style?.letterSpacing, closeTo(0.96, 0.001));
      expect(
        kicker.data,
        isIn(<String>['GOOD MORNING', 'GOOD AFTERNOON', 'GOOD EVENING']),
      );
    });

    testWidgets('create an account moves to the top of the pane', (
      tester,
    ) async {
      await setViewport(tester, const Size(1440, 950));
      await pumpPreviewSignIn(tester);
      final pill = tester.getRect(find.byKey(const Key('create_account_link')));
      final heading = tester.getRect(find.text('Welcome back'));
      expect(pill.top, lessThan(heading.top));
      expect(find.text('New to Molo?'), findsOneWidget);
    });

    testWidgets('on compact the lockup takes the left and the label drops', (
      tester,
    ) async {
      await setViewport(tester, const Size(390, 900));
      await pumpPreviewSignIn(tester);
      expect(find.text('New to Molo?'), findsNothing);
      expect(find.byKey(const Key('create_account_link')), findsOneWidget);
      expect(find.text('molo'), findsOneWidget);
    });

    testWidgets('forgot password sits on the password label row', (
      tester,
    ) async {
      await setViewport(tester, const Size(1440, 950));
      await pumpPreviewSignIn(tester);
      final link = tester.getRect(find.text('Forgot password?'));
      final field = tester.getRect(find.byKey(const Key('password_field')));
      expect(link.bottom, lessThan(field.top));
      expect(link.center.dx, greaterThan(field.center.dx));
    });

    testWidgets('both providers are offered, 46 high and disabled', (
      tester,
    ) async {
      await setViewport(tester, const Size(1440, 950));
      await pumpPreviewSignIn(tester);
      for (final key in const [
        Key('microsoft_sign_in_button'),
        Key('google_sign_in_button'),
      ]) {
        expect(
          tester.widget<OutlinedButton>(find.byKey(key)).onPressed,
          isNull,
        );
        // The design's 46 is the height that is drawn. Material's padded tap
        // target keeps the reachable box at 48 around it, which is a floor
        // worth keeping rather than a discrepancy to remove.
        expect(
          tester
              .getSize(
                find.descendant(
                  of: find.byKey(key),
                  matching: find.byType(Material),
                ),
              )
              .height,
          46,
        );
        expect(
          tester.getSize(find.byKey(key)).height,
          greaterThanOrEqualTo(48),
        );
      }
      final microsoft = tester.getRect(
        find.byKey(const Key('microsoft_sign_in_button')),
      );
      final google = tester.getRect(
        find.byKey(const Key('google_sign_in_button')),
      );
      expect(google.left - microsoft.right, closeTo(10, 0.5));
      expect(microsoft.width, closeTo(google.width, 0.5));
    });

    testWidgets('each disabled provider names its reason once', (tester) async {
      final semantics = tester.ensureSemantics();
      await setViewport(tester, const Size(390, 900));
      await pumpPreviewSignIn(tester);
      expect(
        semanticsLabelsContaining(tester, 'Microsoft sign-in is coming soon'),
        hasLength(1),
      );
      expect(
        semanticsLabelsContaining(tester, 'Google sign-in is coming soon'),
        hasLength(1),
      );
      semantics.dispose();
    });

    testWidgets('the legal footer says Molo never signs in to eFiling', (
      tester,
    ) async {
      await setViewport(tester, const Size(1440, 950));
      await pumpPreviewSignIn(tester);
      expect(
        find.textContaining(
          'Molo never signs in to eFiling',
          findRichText: true,
        ),
        findsOneWidget,
      );
    });

    testWidgets('the reveal toggle keeps a 48 tap target', (tester) async {
      await setViewport(tester, const Size(1440, 950));
      await pumpPreviewSignIn(tester);
      expect(
        tester.getSize(find.byType(IconButton)).height,
        greaterThanOrEqualTo(48),
      );
    });
  });

  group('remember me', () {
    testWidgets('is offered where the platform can honour it', (tester) async {
      await setViewport(tester, const Size(1440, 950));
      await pumpPreviewSignIn(tester, persistenceChoosable: true);
      expect(find.byKey(const Key('remember_me_row')), findsOneWidget);
      expect(find.text('Keep me signed in on this device'), findsOneWidget);
    });

    testWidgets('is absent where it would be a promise nothing keeps', (
      tester,
    ) async {
      await setViewport(tester, const Size(1440, 950));
      await pumpPreviewSignIn(tester);
      expect(find.byKey(const Key('remember_me_row')), findsNothing);
    });

    testWidgets('starts checked, as the design draws it', (tester) async {
      final semantics = tester.ensureSemantics();
      await setViewport(tester, const Size(1440, 950));
      await pumpPreviewSignIn(tester, persistenceChoosable: true);
      expect(
        tester.getSemantics(find.byKey(const Key('remember_me_row'))),
        isSemantics(hasCheckedState: true, isChecked: true),
      );
      semantics.dispose();
    });

    testWidgets('unchecking it is what reaches the auth layer', (tester) async {
      final semantics = tester.ensureSemantics();
      await setViewport(tester, const Size(1440, 950));
      await pumpPreviewSignIn(tester, persistenceChoosable: true);
      await tester.tap(find.byKey(const Key('remember_me_row')));
      await tester.pump();
      expect(
        tester.getSemantics(find.byKey(const Key('remember_me_row'))),
        isSemantics(hasCheckedState: true, isChecked: false),
      );
      semantics.dispose();
    });
  });

  group('keyboard order', () {
    // Flutter's default traversal reads top to bottom, then left to right, so
    // asserting the geometry is asserting the tab order. The design moved the
    // offer to create an account to the top and recovery onto the label row,
    // both of which change where the caret goes next.
    testWidgets('every control is reached in the order it is drawn', (
      tester,
    ) async {
      await setViewport(tester, const Size(1440, 950));
      await pumpPreviewSignIn(tester, persistenceChoosable: true);

      final order = <String, Finder>{
        'create account': find.byKey(const Key('create_account_link')),
        'email': find.byKey(const Key('email_field')),
        'password': find.byKey(const Key('password_field')),
        'remember me': find.byKey(const Key('remember_me_row')),
        'sign in': find.byKey(const Key('sign_in_button')),
        'microsoft': find.byKey(const Key('microsoft_sign_in_button')),
      };
      final tops = <String, double>{
        for (final entry in order.entries)
          entry.key: tester.getRect(entry.value).top,
      };

      final names = tops.keys.toList();
      for (var i = 1; i < names.length; i++) {
        expect(
          tops[names[i]],
          greaterThan(tops[names[i - 1]]!),
          reason: '${names[i]} must come after ${names[i - 1]}',
        );
      }

      // Recovery belongs to the password's label row, so it is reached before
      // the field it recovers rather than after it.
      expect(
        tester.getRect(find.text('Forgot password?')).top,
        lessThan(tops['password']!),
      );
      // The two providers share a row, so left to right is what separates them.
      expect(
        tester.getRect(find.byKey(const Key('google_sign_in_button'))).left,
        greaterThan(
          tester
              .getRect(find.byKey(const Key('microsoft_sign_in_button')))
              .left,
        ),
      );
    });

    testWidgets('a focused field is not styled as a hovered one', (
      tester,
    ) async {
      await setViewport(tester, const Size(1440, 950));
      await pumpPreviewSignIn(tester);
      final theme = Theme.of(tester.element(find.byType(FilledButton)));
      final focused = theme.inputDecorationTheme.focusedBorder!;
      expect(focused.borderSide.width, 2);
      expect(focused.borderSide.color, MoloColours.pulseText);
    });
  });
}
