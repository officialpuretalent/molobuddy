import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/icons/molo_glyphs.dart';

void main() {
  test('the eye is drawn in the design 18-unit box', () {
    expect(MoloGlyphs.eye.viewBox, 18.0);
    expect(MoloGlyphs.eye.cap, StrokeCap.round);
    expect(MoloGlyphs.eye.join, StrokeJoin.round);
  });

  test('the eye closes around its own centre', () {
    final bounds = MoloGlyphs.eye.buildPath().getBounds();
    // The lid spans 1.6 to 16.4 and the pupil sits on the centre line, so the
    // path has to reach both edges and stay inside the box.
    expect(bounds.left, closeTo(1.6, 0.2));
    expect(bounds.right, closeTo(16.4, 0.2));
    expect(bounds.center.dy, closeTo(9, 0.2));
  });

  test('the tick is drawn in the 14-unit box the baseline uses for it', () {
    expect(MoloGlyphs.tick.viewBox, 14.0);
    expect(MoloGlyphs.tick.cap, StrokeCap.round);
    final bounds = MoloGlyphs.tick.buildPath().getBounds();
    expect(bounds.left, closeTo(3, 0.1));
    expect(bounds.right, closeTo(11, 0.1));
  });

  testWidgets('a glyph paints at the size it is given', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MoloIcon(
            MoloGlyphs.eye,
            size: 18,
            color: MoloColours.secondaryText,
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(MoloIcon)), const Size(18, 18));
  });
}
