import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/design_system/icons/molo_glyphs.dart';

/// The navigation glyphs are traced from the design baseline's SVG paths.
///
/// Material's icons were close but never right: different stroke weight, glyph
/// shape and optical sizing. These tests guard the two things a hand-traced
/// path gets wrong most easily — geometry drifting outside the design's
/// coordinate space, and a stroke that does not scale with the icon.
void main() {
  final glyphs = <String, MoloGlyph>{
    'home': MoloGlyphs.home,
    'work': MoloGlyphs.work,
    'clients': MoloGlyphs.clients,
    'documents': MoloGlyphs.documents,
    'deadlines': MoloGlyphs.deadlines,
    'meetings': MoloGlyphs.meetings,
    'askMolo': MoloGlyphs.askMolo,
    'team': MoloGlyphs.team,
    'practiceView': MoloGlyphs.practiceView,
  };

  test('every navigation destination in the design has a glyph', () {
    expect(glyphs, hasLength(9));
  });

  group('geometry stays inside the design coordinate space', () {
    for (final entry in glyphs.entries) {
      test(entry.key, () {
        final bounds = entry.value.buildPath().getBounds();
        expect(bounds.isEmpty, isFalse, reason: 'path drew nothing');
        // The baseline draws every glyph in an 18-unit viewBox. A path outside
        // it would clip or shrink once scaled to the rendered size.
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.top, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(MoloGlyphs.viewBox));
        expect(bounds.bottom, lessThanOrEqualTo(MoloGlyphs.viewBox));
      });
    }
  });

  group('stroke scales with the rendered size, as SVG does', () {
    test('is the design stroke at the design size', () {
      expect(MoloGlyphs.strokeWidthFor(18), closeTo(1.5, 0.0001));
    });

    test('grows with the rail icon size', () {
      // The rail renders the same glyph at 22px. A stroke pinned to 1.5 would
      // read visibly thinner there than in the design.
      expect(MoloGlyphs.strokeWidthFor(22), closeTo(1.5 * 22 / 18, 0.0001));
    });
  });

  group('stroke joins and caps match the design per glyph', () {
    // Taken from the baseline markup: some glyphs set stroke-linecap="round",
    // others stroke-linejoin="round", a couple set both, and the default for
    // an unset attribute is butt/miter.
    const expected = <String, (StrokeCap, StrokeJoin)>{
      'home': (StrokeCap.butt, StrokeJoin.round),
      'work': (StrokeCap.round, StrokeJoin.miter),
      'clients': (StrokeCap.round, StrokeJoin.miter),
      'documents': (StrokeCap.butt, StrokeJoin.round),
      'deadlines': (StrokeCap.round, StrokeJoin.miter),
      'meetings': (StrokeCap.round, StrokeJoin.round),
      'askMolo': (StrokeCap.butt, StrokeJoin.round),
      'team': (StrokeCap.butt, StrokeJoin.round),
      'practiceView': (StrokeCap.round, StrokeJoin.miter),
    };

    for (final entry in expected.entries) {
      test(entry.key, () {
        final glyph = glyphs[entry.key]!;
        expect(glyph.cap, entry.value.$1);
        expect(glyph.join, entry.value.$2);
      });
    }
  });

  testWidgets('MoloIcon paints at the requested size and colour', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: MoloIcon(
            MoloGlyphs.home,
            size: 22,
            color: const Color(0xFFFFFFFF),
            semanticLabel: 'Home',
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(MoloIcon)), const Size(22, 22));
    expect(find.bySemanticsLabel('Home'), findsOneWidget);
  });
}
