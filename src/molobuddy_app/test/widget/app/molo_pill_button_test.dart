import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_pill_button.dart';
import 'package:molobuddy_app/app/design_system/molo_theme.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';

void main() {
  Future<void> pump(WidgetTester tester, {VoidCallback? onPressed}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MoloTheme.light(),
        home: Scaffold(
          backgroundColor: MoloColours.warmCanvas,
          body: Center(
            child: MoloPillButton(
              label: 'Create an account',
              onPressed: onPressed ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  Material materialOf(WidgetTester tester) {
    return tester.widget<Material>(
      find
          .descendant(
            of: find.byType(MoloPillButton),
            matching: find.byType(Material),
          )
          .first,
    );
  }

  testWidgets('the label is 13px medium plum', (tester) async {
    await pump(tester);
    final text = tester.widget<Text>(find.text('Create an account'));
    final style =
        text.style ??
        DefaultTextStyle.of(
          tester.element(find.text('Create an account')),
        ).style;
    expect(style.fontSize, 13);
    expect(style.fontWeight, FontWeight.w500);
    expect(style.color, MoloColours.moloPlum);
  });

  testWidgets('it is padded 9 by 16 at the design radius', (tester) async {
    await pump(tester);
    final labelHeight = tester.getSize(find.text('Create an account')).height;
    final pillHeight = tester.getSize(find.byType(MoloPillButton)).height;
    expect(pillHeight - labelHeight, closeTo(18, 1));

    final labelWidth = tester.getSize(find.text('Create an account')).width;
    final pillWidth = tester.getSize(find.byType(MoloPillButton)).width;
    expect(pillWidth - labelWidth, closeTo(32, 1));

    final shape = materialOf(tester).shape! as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(MoloSpacing.pillRadius));
  });

  testWidgets('the resting outline is the one that clears 3:1', (tester) async {
    await pump(tester);
    final material = materialOf(tester);
    final shape = material.shape! as RoundedRectangleBorder;
    expect(shape.side.color, MoloColours.controlBorder);
    expect(material.color, MoloColours.surface);
  });

  testWidgets('hover tints the fill and keeps the outline', (tester) async {
    await pump(tester);
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.byType(MoloPillButton)));
    await tester.pumpAndSettle();

    final material = materialOf(tester);
    expect(material.color, MoloColours.pulseTint);
    expect(
      (material.shape! as RoundedRectangleBorder).side.color,
      MoloColours.controlBorder,
    );
  });

  testWidgets('it is a button to a screen reader', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    final node = tester.getSemantics(find.text('Create an account'));
    expect(node.label, 'Create an account');
    expect(node.hasFlag(SemanticsFlag.isButton), isTrue);
    expect(node.hasFlag(SemanticsFlag.isEnabled), isTrue);
    semantics.dispose();
  });

  testWidgets('disabled, it drops to the quiet outline and cannot act', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MoloTheme.light(),
        home: const Scaffold(
          body: Center(
            child: MoloPillButton(label: 'Create an account', onPressed: null),
          ),
        ),
      ),
    );
    expect(
      (materialOf(tester).shape! as RoundedRectangleBorder).side.color,
      MoloColours.border,
    );
  });
}
