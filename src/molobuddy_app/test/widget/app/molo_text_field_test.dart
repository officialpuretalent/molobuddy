import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_text_field.dart';
import 'package:molobuddy_app/app/design_system/molo_theme.dart';

void main() {
  const fieldKey = Key('field');

  Future<void> pump(
    WidgetTester tester, {
    Widget? trailing,
    String? errorText,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MoloTheme.light(),
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: Center(
              child: SizedBox(
                width: 384,
                child: MoloTextField(
                  label: 'Work email',
                  fieldKey: fieldKey,
                  controller: TextEditingController(),
                  hintText: 'you@practice.co.za',
                  errorText: errorText,
                  trailing: trailing,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('the field is 50 high, the design height', (tester) async {
    await pump(tester);
    expect(tester.getSize(find.byKey(fieldKey)).height, 50);
  });

  testWidgets('the value text is 15px', (tester) async {
    await pump(tester);
    expect(tester.widget<TextField>(find.byKey(fieldKey)).style?.fontSize, 15);
  });

  testWidgets('the label sits above the field, 13px medium', (tester) async {
    await pump(tester);
    final label = tester.widget<Text>(find.text('Work email'));
    expect(label.style?.fontSize, 13);
    expect(label.style?.fontWeight, FontWeight.w500);
    expect(label.style?.color, MoloColours.moloPlum);

    final labelBottom = tester.getRect(find.text('Work email')).bottom;
    final fieldTop = tester.getRect(find.byKey(fieldKey)).top;
    expect(fieldTop - labelBottom, closeTo(7, 1));
  });

  testWidgets('a trailing action shares the label row', (tester) async {
    await pump(
      tester,
      trailing: TextButton(onPressed: () {}, child: const Text('Forgot?')),
    );
    final labelRow = tester.getRect(find.text('Work email'));
    final trailing = tester.getRect(find.text('Forgot?'));
    expect(trailing.center.dx, greaterThan(labelRow.center.dx));
    expect(trailing.center.dy, closeTo(labelRow.center.dy, 4));
  });

  testWidgets('the field carries exactly one accessible name', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    // Flutter folds the hint into the field's name, which is what a screen
    // reader should hear. What matters is that the label is on the control and
    // appears once, not twice from the visible text as well.
    expect(find.bySemanticsLabel(RegExp('^Work email')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('doubling the text size grows the field instead of clipping', (
    tester,
  ) async {
    await pump(tester, textScale: 2);
    expect(tester.getSize(find.byKey(fieldKey)).height, greaterThan(50));
    expect(tester.takeException(), isNull);
  });

  testWidgets('an error message appears below the field', (tester) async {
    await pump(tester, errorText: 'Enter a valid email address.');
    expect(
      tester.getRect(find.text('Enter a valid email address.')).top,
      greaterThan(tester.getRect(find.byKey(fieldKey)).top),
    );
  });
}
