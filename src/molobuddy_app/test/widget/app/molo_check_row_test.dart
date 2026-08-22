import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_check_row.dart';
import 'package:molobuddy_app/app/design_system/molo_theme.dart';

void main() {
  /// Records every toggle, so a tap is observed rather than guessed at.
  late List<bool> changes;

  Future<void> pump(
    WidgetTester tester, {
    required bool value,
    bool enabled = true,
  }) async {
    changes = <bool>[];
    var current = value;
    await tester.pumpWidget(
      MaterialApp(
        theme: MoloTheme.light(),
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (context, setState) => MoloCheckRow(
                label: const Text('Keep me signed in on this device'),
                semanticLabel: 'Keep me signed in on this device',
                value: current,
                enabled: enabled,
                onChanged: (next) {
                  changes.add(next);
                  setState(() => current = next);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration boxOf(WidgetTester tester) {
    return tester.widget<Container>(find.byKey(MoloCheckRow.boxKey)).decoration!
        as BoxDecoration;
  }

  testWidgets('the box is 19 square at radius 6', (tester) async {
    await pump(tester, value: false);
    expect(tester.getSize(find.byKey(MoloCheckRow.boxKey)), const Size(19, 19));
    expect(boxOf(tester).borderRadius, BorderRadius.circular(6));
  });

  testWidgets('unchecked, the outline is the one that clears 3:1', (
    tester,
  ) async {
    await pump(tester, value: false);
    final decoration = boxOf(tester);
    expect(decoration.color, MoloColours.surface);
    expect(decoration.border?.top.color, MoloColours.controlBorder);
  });

  testWidgets('checked, the box fills plum', (tester) async {
    await pump(tester, value: true);
    expect(boxOf(tester).color, MoloColours.moloPlum);
  });

  testWidgets('the label sits 10 from the box', (tester) async {
    await pump(tester, value: false);
    final boxRight = tester.getRect(find.byKey(MoloCheckRow.boxKey)).right;
    final labelLeft = tester
        .getRect(find.text('Keep me signed in on this device'))
        .left;
    expect(labelLeft - boxRight, closeTo(10, 1));
  });

  testWidgets('tapping the words toggles, not only the box', (tester) async {
    await pump(tester, value: true);
    await tester.tap(find.text('Keep me signed in on this device'));
    await tester.pump();
    expect(changes, [false]);
    expect(boxOf(tester).color, MoloColours.surface);
  });

  testWidgets('tapping the box toggles too', (tester) async {
    await pump(tester, value: false);
    await tester.tap(find.byKey(MoloCheckRow.boxKey));
    await tester.pump();
    expect(changes, [true]);
    expect(boxOf(tester).color, MoloColours.moloPlum);
  });

  testWidgets('it announces as a checked control, once', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, value: true);
    expect(
      tester.getSemantics(find.byType(MoloCheckRow)),
      isSemantics(
        label: 'Keep me signed in on this device',
        hasCheckedState: true,
        isChecked: true,
        isEnabled: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('disabled, it does not call back', (tester) async {
    await pump(tester, value: false, enabled: false);
    await tester.tap(
      find.text('Keep me signed in on this device'),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(changes, isEmpty);
  });
}
