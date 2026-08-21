import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_card.dart';
import 'package:molobuddy_app/app/design_system/molo_theme.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';

void main() {
  testWidgets('uses the shared surface, border, radius and padding tokens', (
    tester,
  ) async {
    await _pumpCard(tester);

    final surface = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(MoloCard),
        matching: find.byType(DecoratedBox),
      ),
    );
    final decoration = surface.decoration as BoxDecoration;
    final padding = tester.widget<Padding>(
      find.descendant(
        of: find.byType(MoloCard),
        matching: find.byType(Padding),
      ),
    );

    expect(decoration.color, MoloColours.surface);
    expect(decoration.border, Border.all(color: MoloColours.border));
    expect(
      decoration.borderRadius,
      BorderRadius.circular(MoloSpacing.cardRadius),
    );
    expect(padding.padding, const EdgeInsets.all(MoloSpacing.lg));
  });

  testWidgets('can add a semantic group label when its owner needs one', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpCard(tester, semanticLabel: 'Daily brief');

    expect(
      tester.getSemantics(find.byType(MoloCard)),
      matchesSemantics(label: 'Daily brief\nCard content'),
    );
    semantics.dispose();
  });
}

Future<void> _pumpCard(WidgetTester tester, {String? semanticLabel}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: MoloTheme.light(),
      home: Scaffold(
        body: MoloCard(
          semanticLabel: semanticLabel,
          child: const Text('Card content'),
        ),
      ),
    ),
  );
}
