import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/adaptive/molo_app_shell.dart';
import 'package:molobuddy_app/app/design_system/components/molo_navigation_item.dart';
import 'package:molobuddy_app/app/design_system/icons/molo_glyphs.dart';

/// Container measurements traced from the design baseline's live sidebar.
///
/// The row itself is covered by molo_navigation_item_test; this file guards the
/// frame around it, where the old implementation used generic spacing tokens
/// instead of the design's numbers.
void main() {
  final destinations = <MoloNavigationDestination>[
    MoloNavigationDestination(
      id: 'home',
      label: 'Home',
      glyph: MoloGlyphs.home,
    ),
    MoloNavigationDestination(
      id: 'work',
      label: 'Work',
      glyph: MoloGlyphs.work,
      badgeLabel: '3',
    ),
    MoloNavigationDestination(
      id: 'meetings',
      label: 'Meetings',
      glyph: MoloGlyphs.meetings,
      enabled: false,
    ),
    MoloNavigationDestination(
      id: 'ask',
      label: 'Ask Molo',
      glyph: MoloGlyphs.askMolo,
      section: MoloNavigationSection.secondary,
    ),
  ];

  Widget host(Widget child) =>
      MaterialApp(home: Scaffold(body: Row(children: [child])));

  Widget sidebar() => MoloSidebar(
    destinations: destinations,
    selectedDestinationId: 'home',
    onDestinationSelected: (_) {},
    primaryActionLabel: 'Create work',
    primaryActionTooltip: 'Create work',
    onPrimaryAction: () {},
  );

  Widget rail() => MoloNavigationRail(
    destinations: destinations,
    selectedDestinationId: 'home',
    onDestinationSelected: (_) {},
    primaryActionLabel: 'Create work',
    primaryActionTooltip: 'Create work',
    onPrimaryAction: () {},
  );

  group('widths', () {
    testWidgets('the labelled sidebar is 240 wide', (tester) async {
      await tester.pumpWidget(host(sidebar()));
      expect(tester.getSize(find.byType(MoloSidebar)).width, 240);
    });

    testWidgets('the rail is 76 wide, not 72', (tester) async {
      await tester.pumpWidget(host(rail()));
      expect(tester.getSize(find.byType(MoloNavigationRail)).width, 76);
    });
  });

  group('horizontal padding places the rows', () {
    testWidgets('sidebar rows inset 12 and span the rest', (tester) async {
      await tester.pumpWidget(host(sidebar()));
      final row = tester.getRect(find.byType(MoloNavigationItem).first);
      expect(row.left, 12);
      expect(row.width, 240 - 24);
    });

    testWidgets('rail rows inset 10 and span the rest', (tester) async {
      await tester.pumpWidget(host(rail()));
      final row = tester.getRect(find.byType(MoloNavigationItem).first);
      expect(row.left, 10);
      expect(row.width, 76 - 20);
    });
  });

  testWidgets('rows sit 4 apart, not 8', (tester) async {
    await tester.pumpWidget(host(sidebar()));
    final first = tester.getRect(find.byType(MoloNavigationItem).at(0));
    final second = tester.getRect(find.byType(MoloNavigationItem).at(1));
    expect(second.top - first.bottom, 4);
  });

  testWidgets('the section divider is white at fourteen percent', (
    tester,
  ) async {
    await tester.pumpWidget(host(sidebar()));
    final divider = tester.widget<Divider>(find.byType(Divider));
    expect(divider.color, MoloSidebar.dividerColour);
    expect(divider.height, 1);
  });

  group('brand lockup', () {
    testWidgets('the mark is 26 square', (tester) async {
      await tester.pumpWidget(host(sidebar()));
      expect(
        tester.getSize(find.byKey(MoloSidebar.brandMarkKey)),
        const Size(26, 26),
      );
    });

    testWidgets('the wordmark is 21px, the sidebar size', (tester) async {
      await tester.pumpWidget(host(sidebar()));
      expect(tester.widget<Text>(find.text('molo')).style?.fontSize, 21);
    });

    testWidgets('the rail keeps the mark and drops the wordmark', (
      tester,
    ) async {
      await tester.pumpWidget(host(rail()));
      expect(find.byKey(MoloSidebar.brandMarkKey), findsOneWidget);
      expect(find.text('molo'), findsNothing);
    });
  });

  group('create action', () {
    testWidgets('is 48 high with the design 15 radius', (tester) async {
      await tester.pumpWidget(host(sidebar()));
      expect(tester.getSize(find.byKey(MoloSidebar.primaryActionKey)).height, 48);
    });

    testWidgets('shows its label in the sidebar', (tester) async {
      await tester.pumpWidget(host(sidebar()));
      expect(find.text('Create work'), findsOneWidget);
    });

    testWidgets('drops the label on the rail, keeping the tooltip', (
      tester,
    ) async {
      await tester.pumpWidget(host(rail()));
      expect(find.text('Create work'), findsNothing);
      expect(find.byKey(MoloSidebar.primaryActionKey), findsOneWidget);
    });
  });

  testWidgets('create sits under the last row, not down at the account', (
    tester,
  ) async {
    // The design puts 16 between the last destination and the create action,
    // then lets the remaining height fall below it so the account row rests on
    // the floor. Anchoring create to the bottom instead bunches the two.
    await tester.pumpWidget(host(sidebar()));
    final lastRow = tester.getRect(find.byType(MoloNavigationItem).last);
    final create = tester.getRect(find.byKey(MoloSidebar.primaryActionKey));
    expect(create.top - lastRow.bottom, 16);
  });

  testWidgets('a destination without a screen still appears', (tester) async {
    await tester.pumpWidget(host(sidebar()));
    expect(find.text('Meetings'), findsOneWidget);
  });
}
