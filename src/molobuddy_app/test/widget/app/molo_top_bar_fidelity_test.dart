import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/adaptive/molo_app_shell.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_account_row.dart';
import 'package:molobuddy_app/app/design_system/components/molo_search_field.dart';
import 'package:molobuddy_app/app/design_system/icons/molo_glyphs.dart';
import 'package:molobuddy_app/app/design_system/molo_theme.dart';

/// Desktop top bar and the sidebar's account row, measured from the baseline.
void main() {
  Widget host(Widget child) => MaterialApp(
    theme: MoloTheme.light(),
    home: Scaffold(appBar: child as PreferredSizeWidget, body: const SizedBox()),
  );

  group('top bar', () {
    testWidgets('is 65 high, not 72', (tester) async {
      await tester.pumpWidget(
        host(const MoloTopBar(title: 'Home', searchHint: 'Search')),
      );
      expect(MoloTopBar.height, 65);
      expect(tester.getSize(find.byType(MoloTopBar)).height, 65);
    });

    testWidgets('sets the title at 15px medium', (tester) async {
      await tester.pumpWidget(
        host(const MoloTopBar(title: 'Home', searchHint: 'Search')),
      );
      final style = tester.widget<Text>(find.text('Home')).style!;
      expect(style.fontSize, 15);
      expect(style.fontWeight, FontWeight.w500);
    });

    testWidgets('sits on the translucent canvas the design blurs', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const MoloTopBar(title: 'Home', searchHint: 'Search')),
      );
      // 0.72 alpha over the warm canvas, blurred rather than opaque, so
      // content scrolling under the bar stays faintly visible.
      expect(MoloTopBar.background.a, closeTo(0.72, 0.01));
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('carries the search field on desktop', (tester) async {
      await tester.pumpWidget(
        host(const MoloTopBar(title: 'Home', searchHint: 'Search')),
      );
      expect(find.byType(MoloSearchField), findsOneWidget);
    });

    testWidgets('drops the search field when compact', (tester) async {
      await tester.pumpWidget(
        host(const MoloTopBar(title: 'Home', searchHint: 'Search', compact: true)),
      );
      expect(find.byType(MoloSearchField), findsNothing);
    });
  });

  group('search field', () {
    testWidgets('is 260 by 40, the design size', (tester) async {
      await tester.pumpWidget(
        host(const MoloTopBar(title: 'Home', searchHint: 'Search')),
      );
      expect(
        tester.getSize(find.byType(MoloSearchField)),
        const Size(260, 40),
      );
    });

    testWidgets('shows the hint the practice reads', (tester) async {
      await tester.pumpWidget(
        host(
          const MoloTopBar(
            title: 'Home',
            searchHint: 'Search clients, work, documents',
          ),
        ),
      );
      expect(find.text('Search clients, work, documents'), findsOneWidget);
    });
  });

  group('the right group holds the search field alone', () {
    testWidgets('search sits flush to the 40 inset the design uses', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const MoloTopBar(title: 'Home', searchHint: 'Search')),
      );
      final bar = tester.getRect(find.byType(MoloTopBar));
      final field = tester.getRect(find.byType(MoloSearchField));
      expect(bar.right - field.right, 40);
    });

    testWidgets('trailing status sits before search, not right of it', (
      tester,
    ) async {
      // The design's right group is search only. Anything the app adds is a
      // status, so it belongs inside that group ahead of the field rather
      // than pushing the field away from the edge.
      await tester.pumpWidget(
        host(
          const MoloTopBar(
            title: 'Home',
            searchHint: 'Search',
            trailing: [Text('Preview')],
          ),
        ),
      );
      final status = tester.getRect(find.text('Preview'));
      final field = tester.getRect(find.byType(MoloSearchField));
      final bar = tester.getRect(find.byType(MoloTopBar));
      expect(status.right, lessThan(field.left));
      expect(bar.right - field.right, 40);
    });
  });

  group('content scrolls under the bar', () {
    testWidgets('the shell hands the body a top inset of the bar height', (
      tester,
    ) async {
      // The design makes the header sticky inside the scroll container, so
      // content passes under a translucent bar. That only works if the body
      // fills the full height and insets its own first item instead.
      EdgeInsets? seen;
      await tester.pumpWidget(
        MaterialApp(
          theme: MoloTheme.light(),
          home: MoloAppShell(
            title: 'Home',
            searchHint: 'Search',
            destinations: [
              MoloNavigationDestination(
                id: 'home',
                label: 'Home',
                glyph: MoloGlyphs.home,
              ),
            ],
            selectedDestinationId: 'home',
            onDestinationSelected: (_) {},
            primaryActionLabel: 'Create work',
            primaryActionTooltip: 'Create work',
            brandSemanticLabel: 'Molo',
            onPrimaryAction: () {},
            child: Builder(
              builder: (context) {
                seen = MediaQuery.paddingOf(context);
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );
      expect(seen?.top, MoloTopBar.height);
    });

    testWidgets('the body reaches the top edge, behind the bar', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MoloTheme.light(),
          home: MoloAppShell(
            title: 'Home',
            searchHint: 'Search',
            destinations: [
              MoloNavigationDestination(
                id: 'home',
                label: 'Home',
                glyph: MoloGlyphs.home,
              ),
            ],
            selectedDestinationId: 'home',
            onDestinationSelected: (_) {},
            primaryActionLabel: 'Create work',
            primaryActionTooltip: 'Create work',
            brandSemanticLabel: 'Molo',
            onPrimaryAction: () {},
            child: const ColoredBox(
              key: Key('body'),
              color: Color(0xFF00FF00),
              child: SizedBox.expand(),
            ),
          ),
        ),
      );
      final body = tester.getRect(find.byKey(const Key('body')));
      final bar = tester.getRect(find.byType(MoloTopBar));
      expect(body.top, bar.top);
    });
  });

  group('account row', () {
    Widget accountHost() => MaterialApp(
      theme: MoloTheme.light(),
      home: const Scaffold(
        backgroundColor: MoloColours.moloPlum,
        body: SizedBox(
          width: 216,
          child: MoloAccountRow(
            initials: 'SQ',
            name: 'Stash Studio',
            detail: 'Siphumelelo Qwabe',
          ),
        ),
      ),
    );

    testWidgets('the avatar is 36 square', (tester) async {
      await tester.pumpWidget(accountHost());
      expect(
        tester.getSize(find.byKey(MoloAccountRow.avatarKey)),
        const Size(36, 36),
      );
    });

    testWidgets('names the practice at 14 and the person at 12', (
      tester,
    ) async {
      await tester.pumpWidget(accountHost());
      expect(
        tester.widget<Text>(find.text('Stash Studio')).style?.fontSize,
        14,
      );
      expect(
        tester.widget<Text>(find.text('Siphumelelo Qwabe')).style?.fontSize,
        12,
      );
    });

    testWidgets('the detail line is the design translucent warm white', (
      tester,
    ) async {
      await tester.pumpWidget(accountHost());
      expect(
        tester.widget<Text>(find.text('Siphumelelo Qwabe')).style?.color,
        MoloAccountRow.detailForeground,
      );
    });

    testWidgets('shows initials, not an avatar image', (tester) async {
      await tester.pumpWidget(accountHost());
      expect(find.text('SQ'), findsOneWidget);
    });
  });
}
