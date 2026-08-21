import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/adaptive/molo_app_shell.dart';
import 'package:molobuddy_app/app/design_system/components/molo_account_row.dart';
import 'package:molobuddy_app/app/design_system/components/molo_navigation_item.dart';
import 'package:molobuddy_app/app/design_system/icons/molo_glyphs.dart';
import 'package:molobuddy_app/app/design_system/molo_theme.dart';
import 'package:molobuddy_app/app/design_system/typography/molo_typography.dart';

/// Where the sidebar's type sits, measured against the design baseline.
///
/// Material leads its body roles taller than Geist's own line box, and a
/// component that states size, weight and colour but not leading inherits that
/// taller line. Nothing here is about the glyphs: it is about the boxes around
/// them, which is what moved every row in the frame off the design.
///
/// These are real measurements, so they need the real font. Widget tests
/// otherwise draw in a stand-in whose advance widths are nothing like Geist's,
/// which is what let the create button ship in a fallback family unnoticed.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('Geist');
    for (final path in const [
      'assets/fonts/Geist-Regular.ttf',
      'assets/fonts/Geist-Medium.ttf',
    ]) {
      loader.addFont(
        Future.value(File(path).readAsBytesSync().buffer.asByteData()),
      );
    }
    await loader.load();
  });

  /// The design's own nine destinations, so the offsets below can be compared
  /// with the baseline row for row rather than approximately.
  final destinations = <MoloNavigationDestination>[
    MoloNavigationDestination(id: 'home', label: 'Home', glyph: MoloGlyphs.home),
    MoloNavigationDestination(
      id: 'work',
      label: 'Work',
      glyph: MoloGlyphs.work,
      badgeLabel: '3',
    ),
    MoloNavigationDestination(
      id: 'clients',
      label: 'Clients',
      glyph: MoloGlyphs.clients,
    ),
    MoloNavigationDestination(
      id: 'documents',
      label: 'Documents',
      glyph: MoloGlyphs.documents,
    ),
    MoloNavigationDestination(
      id: 'deadlines',
      label: 'Deadlines',
      glyph: MoloGlyphs.deadlines,
    ),
    MoloNavigationDestination(
      id: 'meetings',
      label: 'Meetings',
      glyph: MoloGlyphs.meetings,
    ),
    MoloNavigationDestination(
      id: 'ask',
      label: 'Ask Molo',
      glyph: MoloGlyphs.askMolo,
      section: MoloNavigationSection.secondary,
    ),
    MoloNavigationDestination(
      id: 'team',
      label: 'Team',
      glyph: MoloGlyphs.team,
      section: MoloNavigationSection.secondary,
    ),
    MoloNavigationDestination(
      id: 'practice',
      label: 'Practice view',
      glyph: MoloGlyphs.practiceView,
      section: MoloNavigationSection.secondary,
    ),
  ];

  /// The design renders at 1440x900, and the sidebar rests its account row on
  /// the floor, so the window height is part of the measurement.
  Future<void> pumpSidebar(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: MoloTheme.light(),
        home: Scaffold(
          body: Row(
            children: [
              MoloSidebar(
                destinations: destinations,
                selectedDestinationId: 'home',
                onDestinationSelected: (_) {},
                primaryActionLabel: 'Create work',
                primaryActionTooltip: 'Create work',
                onPrimaryAction: () {},
                accountMenu: const MoloAccountRow(
                  initials: 'SQ',
                  name: 'Stash Studio',
                  detail: 'Siphumelelo Qwabe',
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  TextStyle resolvedStyle(WidgetTester tester, Finder text) =>
      tester.renderObject<RenderParagraph>(text).text.style!;

  group('the design leads type at Geist own line box', () {
    test('which is 1.3, not the taller line Material uses for reading', () {
      expect(MoloTypography.normalLineHeight, 1.3);
    });

    testWidgets('the wordmark, so the mark stays centred beside it', (
      tester,
    ) async {
      await pumpSidebar(tester);
      expect(
        resolvedStyle(tester, find.text('molo')).height,
        MoloTypography.normalLineHeight,
      );
      // 21 at 1.3 is the design's 27. Inheriting Material's leading made it 30,
      // which sat the 26 mark 1.5 low and pushed the whole frame down with it.
      expect(tester.getSize(find.text('molo')).height, closeTo(27, 0.5));
      expect(
        tester.getRect(find.byKey(MoloSidebar.brandMarkKey)).top,
        closeTo(18.5, 0.4),
      );
    });

    testWidgets('a navigation label', (tester) async {
      await pumpSidebar(tester);
      expect(
        resolvedStyle(tester, find.text('Home')).height,
        MoloTypography.normalLineHeight,
      );
      expect(tester.getSize(find.text('Home')).height, closeTo(19.5, 0.5));
    });

    testWidgets('the attention badge, which has to fit a 44 row', (
      tester,
    ) async {
      await pumpSidebar(tester);
      expect(
        resolvedStyle(tester, find.text('3')).height,
        MoloTypography.normalLineHeight,
      );
      // The design's pill is 23.5 x 19.5. Material's leading grew it to 21.
      final pill = tester.getSize(
        find
            .ancestor(of: find.text('3'), matching: find.byType(DecoratedBox))
            .first,
      );
      expect(pill.width, closeTo(23.5, 0.6));
      expect(pill.height, closeTo(19.5, 0.6));
    });

    testWidgets('both account lines, which decide the row height', (
      tester,
    ) async {
      await pumpSidebar(tester);
      expect(
        resolvedStyle(tester, find.text('Stash Studio')).height,
        MoloTypography.normalLineHeight,
      );
      expect(
        resolvedStyle(tester, find.text('Siphumelelo Qwabe')).height,
        MoloTypography.normalLineHeight,
      );
      // 12 of padding, a 36 avatar, 12 of padding. The two lines have to stay
      // shorter than the avatar or they, not the avatar, set the height: with
      // Material's leading they totalled 39 and the row stood 63.
      expect(tester.getSize(find.byType(MoloAccountRow)).height, 60);
    });
  });

  group('the frame lands where the design puts it', () {
    testWidgets('the first row clears the lockup by the design 18', (
      tester,
    ) async {
      await pumpSidebar(tester);
      final firstRow = tester.getRect(
        find.ancestor(
          of: find.text('Home'),
          matching: find.byType(MoloNavigationItem),
        ),
      );
      // 18 of frame padding, a 27 lockup, 18 beneath it.
      expect(firstRow.top, closeTo(63, 0.5));
    });

    testWidgets('the account row rests on the floor of the frame', (
      tester,
    ) async {
      await pumpSidebar(tester);
      final row = tester.getRect(find.byType(MoloAccountRow));
      // 900 tall, 12 of padding under it.
      expect(row.bottom, closeTo(888, 0.5));
      expect(row.top, closeTo(828, 0.5));
    });
  });

  group('the create action keeps the design font', () {
    testWidgets('its label is Geist, not whatever the platform supplies', (
      tester,
    ) async {
      await pumpSidebar(tester);
      final style = resolvedStyle(tester, find.text('Create work'));
      // A button style's text style replaces the theme's button role rather
      // than merging with it, so a bare TextStyle here silently dropped the
      // family and the label rendered in the platform default.
      expect(style.fontFamily, 'Geist');
      expect(style.fontSize, 15);
      expect(style.height, MoloTypography.normalLineHeight);
    });

    testWidgets('so it measures what the design measures', (tester) async {
      await pumpSidebar(tester);
      // 85.84 in the baseline. In the fallback family it came out 165, which
      // is what pushed the plus out of the centre of the button.
      expect(tester.getSize(find.text('Create work')).width, closeTo(86, 1.5));
      expect(tester.getSize(find.text('+')).width, closeTo(10.1, 0.5));
    });
  });

  group('the account caret follows the design glyph', () {
    testWidgets('it is the design ink size, not a Material chevron', (
      tester,
    ) async {
      await pumpSidebar(tester);
      // The design draws U+25BE at 12, whose ink measures 6.94 x 3.47. The
      // Material chevron that stood here was a 16 square stroked outline.
      expect(MoloAccountRow.caretSize, const Size(6.94, 3.47));
      final caret = tester.getRect(
        find
            .descendant(
              of: find.byType(MoloAccountRow),
              matching: find.byType(CustomPaint),
            )
            .last,
      );
      expect(caret.width, closeTo(MoloAccountRow.caretSize.width, 0.01));
      expect(caret.height, closeTo(MoloAccountRow.caretSize.height, 0.01));
      // Flush with the inner edge of the row's 12 padding.
      expect(
        caret.right,
        closeTo(tester.getRect(find.byType(MoloAccountRow)).right - 12, 0.5),
      );
    });
  });

  group('the profile row sets each line at the design size', () {
    testWidgets('initials 13, practice 14, person 12', (tester) async {
      await pumpSidebar(tester);
      expect(resolvedStyle(tester, find.text('SQ')).fontSize, 13);
      expect(resolvedStyle(tester, find.text('Stash Studio')).fontSize, 14);
      expect(
        resolvedStyle(tester, find.text('Siphumelelo Qwabe')).fontSize,
        12,
      );
    });

    testWidgets('and each weight, none of them left to the ambient style', (
      tester,
    ) async {
      await pumpSidebar(tester);
      expect(
        resolvedStyle(tester, find.text('SQ')).fontWeight,
        FontWeight.w500,
      );
      expect(
        resolvedStyle(tester, find.text('Stash Studio')).fontWeight,
        FontWeight.w500,
      );
      // The design drops to regular for the person under the practice.
      expect(
        resolvedStyle(tester, find.text('Siphumelelo Qwabe')).fontWeight,
        FontWeight.w400,
      );
    });

    testWidgets('so the lines measure what the baseline measures', (
      tester,
    ) async {
      await pumpSidebar(tester);
      // Advance widths move with size and weight together, so they catch a
      // wrong or synthesised face that a style assertion cannot see.
      expect(tester.getSize(find.text('SQ')).width, closeTo(18.18, 0.4));
      expect(
        tester.getSize(find.text('Stash Studio')).width,
        closeTo(83.8, 0.6),
      );
      expect(
        tester.getSize(find.text('Siphumelelo Qwabe')).width,
        closeTo(109.85, 0.6),
      );
    });
  });

  group('the create action is medium, as the design draws it', () {
    testWidgets('both the label and the plus', (tester) async {
      await pumpSidebar(tester);
      expect(
        resolvedStyle(tester, find.text('Create work')).fontWeight,
        FontWeight.w500,
      );
      // The plus takes the button own style rather than stating a weight, so
      // this guards the button style as much as the glyph.
      expect(
        resolvedStyle(tester, find.text('+')).fontWeight,
        FontWeight.w500,
      );
      expect(resolvedStyle(tester, find.text('+')).fontSize, 18);
    });
  });
}
