import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_brand_lockup.dart';

void main() {
  Widget host(Widget child) =>
      MaterialApp(home: Scaffold(body: Row(children: [child])));

  const markKey = Key('mark');

  testWidgets('the full lockup is 26 square beside a 21px wordmark', (
    tester,
  ) async {
    await tester.pumpWidget(host(const MoloBrandLockup(markKey: markKey)));
    expect(tester.getSize(find.byKey(markKey)), const Size(26, 26));
    expect(tester.widget<Text>(find.text('molo')).style?.fontSize, 21);
  });

  testWidgets('the compact lockup is 22 square beside an 18px wordmark', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const MoloBrandLockup(compact: true, markKey: markKey)),
    );
    expect(tester.getSize(find.byKey(markKey)), const Size(22, 22));
    expect(tester.widget<Text>(find.text('molo')).style?.fontSize, 18);
  });

  testWidgets('the wordmark tracks -0.02em at its own size', (tester) async {
    await tester.pumpWidget(host(const MoloBrandLockup()));
    expect(
      tester.widget<Text>(find.text('molo')).style?.letterSpacing,
      closeTo(-0.42, 0.001),
    );
  });

  testWidgets('unlabelled paints the mark alone', (tester) async {
    await tester.pumpWidget(
      host(const MoloBrandLockup(labelled: false, markKey: markKey)),
    );
    expect(find.byKey(markKey), findsOneWidget);
    expect(find.text('molo'), findsNothing);
  });

  testWidgets('on dark the wordmark takes the surface colour', (tester) async {
    await tester.pumpWidget(host(const MoloBrandLockup(onDark: true)));
    expect(
      tester.widget<Text>(find.text('molo')).style?.color,
      MoloColours.surface,
    );
  });

  testWidgets('the lockup announces once, as the brand', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(host(const MoloBrandLockup()));
    expect(find.bySemanticsLabel('Molo'), findsOneWidget);
    semantics.dispose();
  });
}
