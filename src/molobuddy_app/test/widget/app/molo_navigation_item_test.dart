import 'dart:ui' show PointerDeviceKind, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_navigation_item.dart';
import 'package:molobuddy_app/app/design_system/icons/molo_glyphs.dart';

/// Every number here was measured from the design baseline's live sidebar
/// rather than estimated, because the previous implementation was close on
/// every value and identical on none.
void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(
      backgroundColor: MoloColours.moloPlum,
      body: Align(alignment: Alignment.topLeft, child: child),
    ),
  );

  MoloNavigationItem item({
    bool selected = false,
    bool labelled = true,
    String? badge,
    bool enabled = true,
    VoidCallback? onTap,
  }) => MoloNavigationItem(
    glyph: MoloGlyphs.work,
    label: 'Work',
    selected: selected,
    labelled: labelled,
    badgeLabel: badge,
    enabled: enabled,
    onTap: onTap ?? () {},
  );

  Size iconSize(WidgetTester tester) =>
      tester.getSize(find.byType(MoloIcon).first);

  TextStyle labelStyle(WidgetTester tester) =>
      tester.widget<Text>(find.text('Work')).style!;

  group('labelled sidebar', () {
    testWidgets('is 44 high, the design height', (tester) async {
      await tester.pumpWidget(host(item()));
      expect(tester.getSize(find.byType(MoloNavigationItem)).height, 44);
    });

    testWidgets('draws the glyph at 18px', (tester) async {
      await tester.pumpWidget(host(item()));
      expect(iconSize(tester), const Size(18, 18));
    });

    testWidgets('sets the label at 15px', (tester) async {
      await tester.pumpWidget(host(item()));
      expect(labelStyle(tester).fontSize, 15);
    });

    testWidgets('shows the badge', (tester) async {
      await tester.pumpWidget(host(item(badge: '3')));
      expect(find.text('3'), findsOneWidget);
    });
  });

  group('icon rail', () {
    testWidgets('is 48 high, taller than the labelled row', (tester) async {
      await tester.pumpWidget(host(item(labelled: false)));
      expect(tester.getSize(find.byType(MoloNavigationItem)).height, 48);
    });

    testWidgets('grows the glyph to 22px', (tester) async {
      await tester.pumpWidget(host(item(labelled: false)));
      expect(iconSize(tester), const Size(22, 22));
    });

    testWidgets('hides the badge, as the design does', (tester) async {
      await tester.pumpWidget(host(item(labelled: false, badge: '3')));
      expect(find.text('3'), findsNothing);
    });

    testWidgets('keeps the label reachable for assistive technology', (
      tester,
    ) async {
      await tester.pumpWidget(host(item(labelled: false)));
      expect(find.bySemanticsLabel('Work'), findsOneWidget);
    });
  });

  group('selection', () {
    testWidgets('selected fills a pill at ten percent white', (tester) async {
      await tester.pumpWidget(host(item(selected: true)));
      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(MoloNavigationItem),
          matching: find.byType(Material),
        ),
      );
      expect(material.color, MoloNavigationItem.selectedFill);
    });

    testWidgets('unselected has no fill', (tester) async {
      await tester.pumpWidget(host(item()));
      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(MoloNavigationItem),
          matching: find.byType(Material),
        ),
      );
      expect(material.color, Colors.transparent);
    });

    testWidgets('selected label is white and medium', (tester) async {
      await tester.pumpWidget(host(item(selected: true)));
      expect(labelStyle(tester).color, MoloColours.surface);
      expect(labelStyle(tester).fontWeight, FontWeight.w500);
    });

    testWidgets('unselected label is the design translucent warm white', (
      tester,
    ) async {
      await tester.pumpWidget(host(item()));
      expect(labelStyle(tester).color, MoloNavigationItem.idleForeground);
      expect(labelStyle(tester).fontWeight, FontWeight.w400);
    });

    testWidgets('the glyph takes the label colour, never an accent', (
      tester,
    ) async {
      // The baseline strokes every glyph in currentColor. An accent-coloured
      // icon was the most visible deviation in the previous implementation.
      await tester.pumpWidget(host(item(selected: true)));
      expect(
        tester.widget<MoloIcon>(find.byType(MoloIcon).first).color,
        MoloColours.surface,
      );
      await tester.pumpWidget(host(item()));
      expect(
        tester.widget<MoloIcon>(find.byType(MoloIcon).first).color,
        MoloNavigationItem.idleForeground,
      );
    });
  });

  group('destinations whose screen does not exist yet', () {
    testWidgets('a disabled item does not report a tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(item(enabled: false, onTap: () => taps++)));
      await tester.tap(find.byType(MoloNavigationItem));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('a disabled item says so to assistive technology', (
      tester,
    ) async {
      await tester.pumpWidget(host(item(enabled: false)));
      final node = tester.getSemantics(find.byType(MoloNavigationItem));
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
    });

    testWidgets('an enabled item does report a tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(item(onTap: () => taps++)));
      await tester.tap(find.byType(MoloNavigationItem));
      await tester.pump();
      expect(taps, 1);
      expect(
        tester
            .getSemantics(find.byType(MoloNavigationItem))
            .flagsCollection
            .isEnabled,
        Tristate.isTrue,
      );
    });
  });

  group('pointer feedback suits a dark surface', () {
    testWidgets('hovering lifts the row with white, not with onSurface', (
      tester,
    ) async {
      await tester.pumpWidget(host(item()));
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byType(MoloNavigationItem)));
      await tester.pumpAndSettle();

      // Material resolves its default hover from the light theme's dark
      // onSurface, which on plum reads as a smudge rather than a highlight.
      // The design states white at eight percent for a row on this surface.
      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(
        inkWell.overlayColor?.resolve({WidgetState.hovered}),
        MoloNavigationItem.hoverFill,
      );
      expect(MoloNavigationItem.hoverFill, const Color(0x14FFFFFF));
    });

    testWidgets('and an idle row is left unpainted', (tester) async {
      await tester.pumpWidget(host(item()));
      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.overlayColor?.resolve(<WidgetState>{}), isNull);
    });
  });
}
