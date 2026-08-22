import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_account_menu.dart';
import 'package:molobuddy_app/app/design_system/components/molo_account_row.dart';
import 'package:molobuddy_app/app/design_system/icons/molo_glyphs.dart';
import 'package:molobuddy_app/app/design_system/molo_theme.dart';

/// The account panel, measured from the design baseline's own markup.
///
/// Every row the design draws is here, and only signing out does anything: the
/// rest are inert until their screens exist, the same bargain the sidebar makes
/// for Meetings and Practice view.
void main() {
  var signedOut = 0;
  var otherTaps = 0;

  setUp(() {
    signedOut = 0;
    otherTaps = 0;
  });

  MoloAccountMenu menu({bool signingOut = false}) => MoloAccountMenu(
    header: const MoloAccountMenuHeader(
      initials: 'SS',
      name: 'Stash Studio',
      caption: 'Practice account',
    ),
    sections: [
      [
        MoloAccountMenuEntry(
          glyph: MoloGlyphs.switchPractice,
          label: 'Switch practice',
        ),
        MoloAccountMenuEntry(
          glyph: MoloGlyphs.connectors,
          label: 'Connectors and intake',
        ),
        MoloAccountMenuEntry(glyph: MoloGlyphs.profile, label: 'Your profile'),
        MoloAccountMenuEntry(glyph: MoloGlyphs.settings, label: 'Settings'),
      ],
      [
        MoloAccountMenuEntry(
          glyph: MoloGlyphs.help,
          label: 'Help and support',
          showChevron: true,
        ),
        MoloAccountMenuEntry(
          key: const Key('sign_out_button'),
          glyph: MoloGlyphs.logOut,
          label: 'Log out',
          destructive: true,
          onTap: signingOut ? null : () => signedOut++,
        ),
      ],
    ],
  );

  Future<void> pumpPanel(WidgetTester tester, {bool signingOut = false}) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: MoloTheme.light(),
        home: Scaffold(
          backgroundColor: MoloColours.moloPlum,
          body: Align(
            alignment: Alignment.topLeft,
            child: menu(signingOut: signingOut),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  TextStyle styleOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style!;

  group('the panel is the design box', () {
    testWidgets('268 wide, at a 22 radius, inset 8', (tester) async {
      await pumpPanel(tester);
      expect(MoloAccountMenu.width, 268);
      expect(tester.getSize(find.byType(MoloAccountMenu)).width, 268);

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(MoloAccountMenu),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, MoloColours.surface);
      expect(decoration.borderRadius, BorderRadius.circular(22));
      expect(decoration.border, Border.all(color: MoloColours.border));
      expect(decoration.boxShadow, isNotNull);
      expect(container.padding, const EdgeInsets.all(8));
    });

    testWidgets('its shadow reaches as far as the design blur, not further', (
      tester,
    ) async {
      await pumpPanel(tester);
      // The design blurs 40 in CSS, which is a deviation of 20. Flutter takes a
      // radius and converts it, so passing 40 straight through would spread the
      // shadow half again as far.
      expect(MoloAccountMenu.shadow.blurSigma, closeTo(20, 0.5));
      expect(MoloAccountMenu.shadow.offset, const Offset(0, 18));
      expect(MoloAccountMenu.shadow.color.a, closeTo(0.22, 0.01));
    });

    testWidgets('groups are split by a hairline inset 10', (tester) async {
      await pumpPanel(tester);
      final rules = find.descendant(
        of: find.byType(MoloAccountMenu),
        matching: find.byType(ColoredBox),
      );
      // One above the four navigation rows, one above support and signing out.
      expect(rules, findsNWidgets(2));
      final panel = tester.getRect(find.byType(MoloAccountMenu));
      final rule = tester.getRect(rules.first);
      expect(rule.height, 1);
      // A 1 border, 8 of panel padding, then the design's own 10 of margin.
      // The border counts because CSS holds it outside the padding, and the
      // panel is a Container, which reserves room for it the same way.
      expect(rule.left - panel.left, 19);
      expect(panel.right - rule.right, 19);
    });
  });

  group('the header names the practice, not the person', () {
    testWidgets('initials, name and what the identity is', (tester) async {
      await pumpPanel(tester);
      expect(find.text('SS'), findsOneWidget);
      expect(find.text('Stash Studio'), findsOneWidget);
      // The sidebar row underneath carries the person; this line says what
      // kind of account it is, exactly as the design has it.
      expect(find.text('Practice account'), findsOneWidget);
    });

    testWidgets('at the design sizes, on the pulse tint', (tester) async {
      await pumpPanel(tester);
      expect(styleOf(tester, 'Stash Studio').fontSize, 14);
      expect(styleOf(tester, 'Stash Studio').fontWeight, FontWeight.w500);
      expect(styleOf(tester, 'Practice account').fontSize, 12);
      expect(styleOf(tester, 'SS').fontSize, 12);
      expect(styleOf(tester, 'SS').color, MoloColours.pulseText);
      expect(tester.getSize(find.text('SS').first).height, closeTo(15.6, 0.5));
    });
  });

  group('every row the design draws is present', () {
    testWidgets('in the design order', (tester) async {
      await pumpPanel(tester);
      const expected = [
        'Switch practice',
        'Connectors and intake',
        'Your profile',
        'Settings',
        'Help and support',
        'Log out',
      ];
      var previousBottom = 0.0;
      for (final label in expected) {
        expect(find.text(label), findsOneWidget, reason: '$label is missing');
        final top = tester.getRect(find.text(label)).top;
        expect(
          top,
          greaterThan(previousBottom),
          reason: '$label is out of order',
        );
        previousBottom = top;
      }
    });

    testWidgets('at 14, and signing out in the pulse text', (tester) async {
      await pumpPanel(tester);
      expect(styleOf(tester, 'Settings').fontSize, 14);
      expect(styleOf(tester, 'Log out').color, MoloColours.pulseText);
    });
  });

  group('only signing out does anything', () {
    testWidgets('signing out reports the tap', (tester) async {
      await pumpPanel(tester);
      await tester.tap(find.text('Log out'));
      await tester.pump();
      expect(signedOut, 1);
    });

    testWidgets('the rows whose screens do not exist stay quiet', (
      tester,
    ) async {
      await pumpPanel(tester);
      for (final label in const [
        'Switch practice',
        'Connectors and intake',
        'Your profile',
        'Settings',
        'Help and support',
      ]) {
        await tester.tap(find.text(label), warnIfMissed: false);
        await tester.pump();
      }
      expect(otherTaps, 0);
      expect(signedOut, 0);
    });

    testWidgets('and they are drawn as unavailable, not as live rows', (
      tester,
    ) async {
      await pumpPanel(tester);
      // Same 38 percent the sidebar uses for a destination without a screen.
      expect(
        styleOf(tester, 'Settings').color,
        MoloColours.moloPlum.withValues(alpha: 0.38),
      );
      expect(styleOf(tester, 'Log out').color!.a, 1);
    });

    testWidgets('signing out goes quiet once it is under way', (tester) async {
      await pumpPanel(tester, signingOut: true);
      await tester.tap(find.text('Log out'), warnIfMissed: false);
      await tester.pump();
      expect(signedOut, 0);
    });
  });

  group('the panel opens where the design puts it', () {
    testWidgets('above the account row, left aligned, 4 clear of it', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: MoloTheme.light(),
          home: Scaffold(
            body: Row(
              children: [
                SizedBox(
                  width: 240,
                  height: 900,
                  child: Column(
                    children: [
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: MenuAnchor(
                          style: const MenuStyle(
                            backgroundColor: WidgetStatePropertyAll(
                              Color(0x00000000),
                            ),
                            elevation: WidgetStatePropertyAll(0),
                            padding: WidgetStatePropertyAll(EdgeInsets.zero),
                          ),
                          alignmentOffset: const Offset(0, 4),
                          menuChildren: [menu()],
                          builder: (context, controller, _) => InkWell(
                            key: const Key('trigger'),
                            onTap: controller.open,
                            child: const MoloAccountRow(
                              initials: 'SQ',
                              name: 'Stash Studio',
                              detail: 'Siphumelelo Qwabe',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final row = tester.getRect(find.byKey(const Key('trigger')));
      await tester.tap(find.byKey(const Key('trigger')));
      await tester.pumpAndSettle();

      final panel = tester.getRect(find.byType(MoloAccountMenu));
      // The design pins it 12 from the sidebar's left and 76 up from its floor,
      // which against a 900 frame puts its foot 4 above the row it opens from.
      expect(panel.left, row.left);
      expect(panel.left, 12);
      expect(row.top - panel.bottom, 4);
      expect(panel.bottom, 824);
      // Wider than the sidebar, so it overhangs the content as the design does.
      expect(panel.width, 268);
      expect(panel.right, greaterThan(240));
    });
  });
}
