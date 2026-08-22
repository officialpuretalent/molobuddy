import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_status_pill.dart';
import 'package:molobuddy_app/app/design_system/molo_theme.dart';
import 'package:molobuddy_app/app/design_system/typography/molo_typography.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader(MoloTypography.geistMono);
    for (final path in const [
      'assets/fonts/GeistMono-Regular.ttf',
      'assets/fonts/GeistMono-Medium.ttf',
    ]) {
      loader.addFont(
        Future.value(File(path).readAsBytesSync().buffer.asByteData()),
      );
    }
    await loader.load();
  });

  Future<void> pumpPill(WidgetTester tester, MoloStatusPill pill) =>
      tester.pumpWidget(
        MaterialApp(
          theme: MoloTheme.light(),
          home: Scaffold(body: Center(child: pill)),
        ),
      );

  testWidgets('holds the baseline 28px status height', (tester) async {
    await pumpPill(tester, const MoloStatusPill(label: 'In review'));
    expect(tester.getSize(find.byType(MoloStatusPill)).height, 28);
  });

  testWidgets('uses Geist Mono for workbench state metadata', (tester) async {
    await pumpPill(tester, const MoloStatusPill(label: 'In review'));
    final text = tester.widget<Text>(find.text('In review'));
    expect(text.style?.fontFamily, MoloTypography.geistMono);
    expect(text.style?.fontSize, 11);
  });

  testWidgets('maps warning states to the baseline warning tint', (
    tester,
  ) async {
    await pumpPill(
      tester,
      const MoloStatusPill(label: 'Overdue', tone: MoloStatusTone.warning),
    );
    final surface = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(MoloStatusPill),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect(
      (surface.decoration as BoxDecoration).color,
      MoloColours.warningTint,
    );
  });
}
