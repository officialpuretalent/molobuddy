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

  group('wizard option glyphs', () {
    final options = <String, MoloGlyph>{
      'practiceSolo': MoloGlyphs.practiceSolo,
      'practiceSmallTeam': MoloGlyphs.practiceSmallTeam,
      'practiceGrowing': MoloGlyphs.practiceGrowing,
      'goalDeadlines': MoloGlyphs.goalDeadlines,
      'goalDocuments': MoloGlyphs.goalDocuments,
      'goalTeamwork': MoloGlyphs.goalTeamwork,
      'goalVisibility': MoloGlyphs.goalVisibility,
      'startImport': MoloGlyphs.startImport,
      'startFirstClient': MoloGlyphs.startFirstClient,
      'startSample': MoloGlyphs.startSample,
    };

    test('all ten are drawn in the design 18-unit box, round-capped', () {
      expect(options, hasLength(10));
      for (final entry in options.entries) {
        expect(entry.value.viewBox, 18.0, reason: entry.key);
        expect(entry.value.cap, StrokeCap.round, reason: entry.key);
        expect(entry.value.join, StrokeJoin.round, reason: entry.key);
      }
    });

    test('every glyph stays inside its box', () {
      for (final entry in options.entries) {
        final bounds = entry.value.buildPath().getBounds();
        expect(bounds.left, greaterThanOrEqualTo(0), reason: entry.key);
        expect(bounds.top, greaterThanOrEqualTo(0), reason: entry.key);
        expect(bounds.right, lessThanOrEqualTo(18), reason: entry.key);
        expect(bounds.bottom, lessThanOrEqualTo(18), reason: entry.key);
      }
    });

    test('every glyph fills enough of its box to read at 19px', () {
      // A dropped subpath or a mis-parsed arc shows up as a glyph that occupies
      // a fraction of its box, which is invisible in a screenshot beside nine
      // that look right.
      for (final entry in options.entries) {
        final bounds = entry.value.buildPath().getBounds();
        expect(bounds.width, greaterThan(8), reason: entry.key);
        expect(bounds.height, greaterThan(8), reason: entry.key);
      }
    });

    test('no two option glyphs are the same shape', () {
      // Copy-paste between ten similar entries is the likely error, and it
      // would ship two cards wearing one icon.
      final seen = <String, String>{};
      for (final entry in options.entries) {
        final key = entry.value.buildPath().getBounds().toString();
        expect(
          seen.containsKey(key),
          isFalse,
          reason: '${entry.key} has the same bounds as ${seen[key]}',
        );
        seen[key] = entry.key;
      }
    });
  });

  test('the back arrow is drawn in the 16-unit box the baseline uses', () {
    expect(MoloGlyphs.backArrow.viewBox, 16.0);
    expect(MoloGlyphs.backArrow.cap, StrokeCap.round);
    final bounds = MoloGlyphs.backArrow.buildPath().getBounds();
    expect(bounds.left, closeTo(5.2, 0.1));
    expect(bounds.right, closeTo(11.6, 0.1));
  });
}
