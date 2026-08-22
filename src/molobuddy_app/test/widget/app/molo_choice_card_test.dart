import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_choice_card.dart';
import 'package:molobuddy_app/app/design_system/icons/molo_glyphs.dart';
import 'package:molobuddy_app/app/design_system/molo_theme.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';

void main() {
  late int taps;

  Future<void> pump(
    WidgetTester tester, {
    bool selected = false,
    MoloChoiceKind kind = MoloChoiceKind.single,
  }) async {
    taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: MoloTheme.light(),
        home: Scaffold(
          backgroundColor: MoloColours.warmCanvas,
          body: Center(
            child: SizedBox(
              width: 452,
              child: MoloChoiceCard(
                glyph: MoloGlyphs.practiceSolo,
                title: 'Just me',
                description: 'A focused workspace for a solo practitioner.',
                selected: selected,
                kind: kind,
                onTap: () => taps++,
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration cardDecoration(WidgetTester tester) {
    return tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(MoloChoiceCard),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;
  }

  BoxDecoration markDecoration(WidgetTester tester) {
    return tester
            .widget<Container>(find.byKey(MoloChoiceCard.markKey))
            .decoration!
        as BoxDecoration;
  }

  testWidgets('resting, the card is white inside a quiet outline', (
    tester,
  ) async {
    await pump(tester);
    final decoration = cardDecoration(tester);
    expect(decoration.color, MoloColours.surface);
    expect(decoration.border?.top.color, MoloColours.border);
    expect(decoration.border?.top.width, 1);
    expect(
      decoration.borderRadius,
      BorderRadius.circular(MoloSpacing.choiceCardRadius),
    );
  });

  testWidgets('selected, it tints and takes the design two-pixel edge', (
    tester,
  ) async {
    await pump(tester, selected: true);
    final decoration = cardDecoration(tester);
    expect(decoration.color, MoloColours.pulseTint);
    expect(decoration.border?.top.color, MoloColours.pulseText);
    expect(decoration.border?.top.width, 2);
  });

  testWidgets('hovering firms the outline without tinting the card', (
    tester,
  ) async {
    await pump(tester);
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.byType(MoloChoiceCard)));
    await tester.pumpAndSettle();

    final decoration = cardDecoration(tester);
    expect(decoration.border?.top.color, MoloColours.controlBorder);
    expect(decoration.color, MoloColours.surface);
  });

  testWidgets('the glyph is 19px and follows the selection', (tester) async {
    await pump(tester);
    expect(
      tester.widget<MoloIcon>(find.byType(MoloIcon).first).color,
      MoloColours.controlBorder,
    );
    expect(tester.getSize(find.byType(MoloIcon).first), const Size(19, 19));

    await pump(tester, selected: true);
    expect(
      tester.widget<MoloIcon>(find.byType(MoloIcon).first).color,
      MoloColours.pulseText,
    );
  });

  testWidgets('the title and description take the design sizes', (
    tester,
  ) async {
    await pump(tester);
    final title = tester.widget<Text>(find.text('Just me'));
    expect(title.style?.fontSize, 15);
    expect(title.style?.fontWeight, FontWeight.w500);
    expect(title.style?.color, MoloColours.moloPlum);

    final description = tester.widget<Text>(
      find.text('A focused workspace for a solo practitioner.'),
    );
    expect(description.style?.fontSize, 13);
    expect(description.style?.height, 1.5);
    expect(description.style?.color, MoloColours.secondaryText);
  });

  group('the mark', () {
    testWidgets('a single choice is round, 21 across', (tester) async {
      await pump(tester);
      expect(
        tester.getSize(find.byKey(MoloChoiceCard.markKey)),
        const Size(21, 21),
      );
      expect(markDecoration(tester).shape, BoxShape.circle);
      expect(markDecoration(tester).color, MoloColours.surface);
      expect(
        markDecoration(tester).border?.top.color,
        MoloColours.controlBorder,
      );
    });

    testWidgets('a chosen single choice fills pulseText', (tester) async {
      await pump(tester, selected: true);
      expect(markDecoration(tester).color, MoloColours.pulseText);
    });

    testWidgets('a multiple choice is square at radius 7', (tester) async {
      await pump(tester, kind: MoloChoiceKind.multiple);
      expect(
        tester.getSize(find.byKey(MoloChoiceCard.markKey)),
        const Size(21, 21),
      );
      expect(markDecoration(tester).borderRadius, BorderRadius.circular(7));
    });

    testWidgets('a chosen multiple choice fills plum', (tester) async {
      await pump(tester, kind: MoloChoiceKind.multiple, selected: true);
      expect(markDecoration(tester).color, MoloColours.moloPlum);
    });

    testWidgets('the card carries one mark, never two', (tester) async {
      // The goals step used to hang a Material Checkbox beside this, so two
      // controls painted one state.
      await pump(tester, kind: MoloChoiceKind.multiple);
      expect(find.byKey(MoloChoiceCard.markKey), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
    });
  });

  testWidgets('the whole card is the control', (tester) async {
    await pump(tester);
    await tester.tap(find.text('A focused workspace for a solo practitioner.'));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('a single choice announces as one of a set', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, selected: true);
    expect(
      tester.getSemantics(find.byType(MoloChoiceCard)),
      isSemantics(
        hasCheckedState: true,
        isChecked: true,
        isInMutuallyExclusiveGroup: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('a multiple choice announces as an independent check', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, kind: MoloChoiceKind.multiple);
    expect(
      tester.getSemantics(find.byType(MoloChoiceCard)),
      isSemantics(
        hasCheckedState: true,
        isChecked: false,
        isInMutuallyExclusiveGroup: false,
      ),
    );
    semantics.dispose();
  });

  group('the card holds its box as it is chosen', () {
    // The shared harness centres the card in a loose box, where its Material
    // stretches to the viewport. These measure the box itself, so they give it
    // a column to shrink-wrap into instead.
    Future<void> pumpBox(WidgetTester tester, {required bool selected}) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: MoloTheme.light(),
          home: Scaffold(
            backgroundColor: MoloColours.warmCanvas,
            body: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 452,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MoloChoiceCard(
                      glyph: MoloGlyphs.goalDeadlines,
                      title: 'Stay ahead of deadlines',
                      description:
                          'See what is due and what needs attention now.',
                      selected: selected,
                      kind: MoloChoiceKind.multiple,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Rect contents(WidgetTester tester) => tester.getRect(
      find
          .descendant(
            of: find.byType(MoloChoiceCard),
            matching: find.byType(Row),
          )
          .first,
    );

    testWidgets('choosing it leaves its height alone', (tester) async {
      await pumpBox(tester, selected: false);
      final off = tester.getSize(find.byType(MoloChoiceCard));
      await pumpBox(tester, selected: true);
      final on = tester.getSize(find.byType(MoloChoiceCard));
      // The design keeps one padding and one 1px border in both states and
      // draws the chosen edge as an inset ring, which costs no layout. Trading
      // a pixel of padding for a wider border instead shrank the card by 2 as
      // it was chosen, and a column of them jumped as each was ticked.
      expect(on.height, off.height);
    });

    testWidgets('its contents sit where the design puts them, chosen or not', (
      tester,
    ) async {
      await pumpBox(tester, selected: false);
      var card = tester.getRect(find.byType(MoloChoiceCard));
      var row = contents(tester);
      // 16 and 18 of padding inside a 1 border, which border-box holds inside
      // the element, so the contents start 17 down and 19 across.
      expect(row.top - card.top, 17);
      expect(row.left - card.left, 19);

      await pumpBox(tester, selected: true);
      card = tester.getRect(find.byType(MoloChoiceCard));
      row = contents(tester);
      expect(row.top - card.top, 17);
      expect(row.left - card.left, 19);
    });
  });
}
