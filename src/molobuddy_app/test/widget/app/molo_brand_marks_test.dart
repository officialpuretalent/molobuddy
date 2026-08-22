import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/design_system/icons/molo_brand_marks.dart';

void main() {
  group('Google', () {
    test('is drawn in its published 48-unit box', () {
      expect(MoloBrandMarks.google.viewBox, 48);
    });

    test('carries its four colours, in its own order', () {
      expect(
        MoloBrandMarks.google.layers.map((layer) => layer.colour).toList(),
        const [
          Color(0xFF4285F4),
          Color(0xFF34A853),
          Color(0xFFFBBC05),
          Color(0xFFEA4335),
        ],
      );
    });

    test('every layer stays inside the box', () {
      for (final layer in MoloBrandMarks.google.layers) {
        final bounds = layer.buildPath().getBounds();
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.top, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(48));
        expect(bounds.bottom, lessThanOrEqualTo(48));
      }
    });

    test('the G fills the box it is given', () {
      // The four arcs together span the full mark, so a translation error that
      // dropped or shrank one would show up here rather than on screen.
      var left = 48.0;
      var right = 0.0;
      var top = 48.0;
      var bottom = 0.0;
      for (final layer in MoloBrandMarks.google.layers) {
        final bounds = layer.buildPath().getBounds();
        left = bounds.left < left ? bounds.left : left;
        right = bounds.right > right ? bounds.right : right;
        top = bounds.top < top ? bounds.top : top;
        bottom = bounds.bottom > bottom ? bounds.bottom : bottom;
      }
      expect(left, closeTo(2, 0.5));
      expect(right, closeTo(45.12, 0.5));
      expect(top, closeTo(2, 0.5));
      expect(bottom, closeTo(46, 0.5));
    });
  });

  group('Microsoft', () {
    test('is four equal squares in its published 23-unit box', () {
      final mark = MoloBrandMarks.microsoft;
      expect(mark.viewBox, 23);
      expect(mark.layers, hasLength(4));
      for (final layer in mark.layers) {
        expect(layer.buildPath().getBounds().size, const Size(10, 10));
      }
    });

    test('carries its four colours clockwise from the top left', () {
      expect(
        MoloBrandMarks.microsoft.layers.map((layer) => layer.colour).toList(),
        const [
          Color(0xFFF25022),
          Color(0xFF7FBA00),
          Color(0xFF00A4EF),
          Color(0xFFFFB900),
        ],
      );
    });

    test('the squares sit in a two-by-two grid with one unit between them', () {
      final bounds = MoloBrandMarks.microsoft.layers
          .map((layer) => layer.buildPath().getBounds())
          .toList();
      expect(bounds[1].left - bounds[0].right, 1);
      expect(bounds[2].top - bounds[0].bottom, 1);
      expect(bounds[0].topLeft, const Offset(1, 1));
      expect(bounds[3].bottomRight, const Offset(22, 22));
    });
  });

  testWidgets('a mark paints at the size it is given and says nothing', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MoloBrandIcon(MoloBrandMarks.google, size: 18)),
      ),
    );
    expect(tester.getSize(find.byType(MoloBrandIcon)), const Size(18, 18));
    // The button around it owns the accessible name, so the mark adds nothing.
    expect(tester.getSemantics(find.byType(MoloBrandIcon)).label, isEmpty);
    semantics.dispose();
  });
}
