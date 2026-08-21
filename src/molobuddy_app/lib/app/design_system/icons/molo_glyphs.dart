import 'package:flutter/widgets.dart';

/// One Molo line glyph, traced from the design baseline.
///
/// Glyphs are described in the design's 18-unit square and stroked, never
/// filled. That is why a selected destination changes only its colour: there
/// is no separate filled variant to swap to, exactly as in the baseline.
@immutable
class MoloGlyph {
  const MoloGlyph({
    required this.buildPath,
    this.cap = StrokeCap.butt,
    this.join = StrokeJoin.miter,
    this.viewBox = MoloGlyphs.viewBox,
  });

  /// Builds the glyph outline in the 18-unit design space.
  final Path Function() buildPath;

  /// Line ending, mirroring `stroke-linecap` on the source SVG.
  final StrokeCap cap;

  /// Corner treatment, mirroring `stroke-linejoin` on the source SVG.
  final StrokeJoin join;

  /// Side of the square the outline is drawn in. Most of the design's glyphs
  /// use 18, but the search field's uses 16, and scaling it as though it were
  /// 18 would render it small and thin-stroked.
  final double viewBox;
}

/// The navigation glyphs used by the workspace sidebar and rail.
abstract final class MoloGlyphs {
  /// The design draws every glyph in an 18x18 viewBox.
  static const viewBox = 18.0;

  /// Stroke width in design units, before scaling to the rendered size.
  static const designStrokeWidth = 1.5;

  /// The stroke width to paint when the glyph is rendered at [size].
  ///
  /// SVG scales the stroke with the viewBox unless `vector-effect` opts out,
  /// and the baseline does not. Pinning 1.5 would make the 22px rail icons
  /// read thinner than the 18px sidebar ones.
  static double strokeWidthFor(double size, {double inViewBox = viewBox}) =>
      designStrokeWidth * size / inViewBox;

  static final home = MoloGlyph(
    join: StrokeJoin.round,
    buildPath: () => Path()
      ..moveTo(3, 7.5)
      ..lineTo(9, 3)
      ..relativeLineTo(6, 4.5)
      ..lineTo(15, 15)
      ..lineTo(3, 15)
      ..close(),
  );

  static final work = MoloGlyph(
    cap: StrokeCap.round,
    buildPath: () => Path()
      ..addOval(Rect.fromCircle(center: const Offset(9, 9), radius: 6.2))
      ..moveTo(6.4, 9.2)
      ..relativeLineTo(1.8, 1.8)
      ..relativeLineTo(3.4, -3.6),
  );

  static final clients = MoloGlyph(
    cap: StrokeCap.round,
    buildPath: () => Path()
      ..addOval(Rect.fromCircle(center: const Offset(7, 6.5), radius: 2.6))
      ..addOval(Rect.fromCircle(center: const Offset(13.2, 7.6), radius: 2))
      ..moveTo(2.6, 14.4)
      ..relativeCubicTo(0.5, -2.2, 2.2, -3.4, 4.4, -3.4)
      // The source uses a smooth cubic (`s`), whose first control point is the
      // reflection of the previous one about the current point.
      ..relativeCubicTo(2.2, 0, 3.9, 1.2, 4.4, 3.4),
  );

  static final documents = MoloGlyph(
    join: StrokeJoin.round,
    buildPath: () => Path()
      ..moveTo(2.6, 5.6)
      ..relativeLineTo(4.2, 0)
      ..relativeLineTo(1.4, 1.7)
      ..relativeLineTo(7.2, 0)
      ..relativeLineTo(0, 7.1)
      ..lineTo(2.6, 14.4)
      ..close(),
  );

  static final deadlines = MoloGlyph(
    cap: StrokeCap.round,
    buildPath: () => Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(2.8, 4.2, 12.4, 11),
          const Radius.circular(2.5),
        ),
      )
      ..moveTo(6, 2.6)
      ..relativeLineTo(0, 2.6)
      ..moveTo(12, 2.6)
      ..relativeLineTo(0, 2.6)
      ..moveTo(2.8, 8)
      ..relativeLineTo(12.4, 0),
  );

  static final meetings = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    buildPath: () => Path()
      ..addOval(Rect.fromCircle(center: const Offset(9, 9), radius: 6.4))
      ..moveTo(9, 5.4)
      ..lineTo(9, 9)
      ..relativeLineTo(2.6, 1.6),
  );

  static final askMolo = MoloGlyph(
    join: StrokeJoin.round,
    buildPath: () => Path()
      ..moveTo(9, 2.6)
      ..lineTo(10.6, 7)
      ..relativeLineTo(4.4, 1.6)
      ..lineTo(10.6, 10.2)
      ..lineTo(9, 14.6)
      ..lineTo(7.4, 10.2)
      ..lineTo(3, 8.6)
      ..lineTo(7.4, 7)
      ..close(),
  );

  static final team = MoloGlyph(
    join: StrokeJoin.round,
    buildPath: () => Path()
      ..moveTo(10.2, 2.4)
      ..lineTo(5, 9.6)
      ..relativeLineTo(3.4, 0)
      ..lineTo(7.8, 15.6)
      ..lineTo(13, 8.4)
      ..lineTo(9.6, 8.4)
      ..close(),
  );

  /// The top bar's search glyph, drawn in a 16-unit box.
  static final search = MoloGlyph(
    cap: StrokeCap.round,
    viewBox: 16,
    buildPath: () => Path()
      ..addOval(Rect.fromCircle(center: const Offset(7, 7), radius: 4.4))
      ..moveTo(10.4, 10.4)
      ..lineTo(14, 14),
  );

  static final practiceView = MoloGlyph(
    cap: StrokeCap.round,
    buildPath: () => Path()
      ..moveTo(3, 15)
      ..lineTo(3, 8.6)
      ..moveTo(7.6, 15)
      ..lineTo(7.6, 4.4)
      ..moveTo(12.2, 15)
      ..relativeLineTo(0, -4.2)
      ..moveTo(16, 15)
      ..lineTo(2.4, 15),
  );
}

/// Paints a [MoloGlyph] at [size], stroked in [color].
///
/// Sized rather than font-driven: the design specifies 18px in the labelled
/// sidebar and 22px in the icon rail, which a text-scaled icon would not hold.
class MoloIcon extends StatelessWidget {
  const MoloIcon(
    this.glyph, {
    required this.size,
    required this.color,
    this.semanticLabel,
    super.key,
  });

  final MoloGlyph glyph;
  final double size;
  final Color color;

  /// Only set this where the glyph is the sole meaning. Beside a visible label
  /// it would be read twice.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: semanticLabel != null,
      excludeSemantics: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _MoloGlyphPainter(glyph: glyph, color: color),
      ),
    );
  }
}

class _MoloGlyphPainter extends CustomPainter {
  const _MoloGlyphPainter({required this.glyph, required this.color});

  final MoloGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / glyph.viewBox;
    canvas
      ..save()
      ..scale(scale);
    canvas.drawPath(
      glyph.buildPath(),
      Paint()
        ..style = PaintingStyle.stroke
        // Stated in design units; the canvas scale carries it to the rendered
        // width, which is what strokeWidthFor documents.
        ..strokeWidth = MoloGlyphs.designStrokeWidth
        ..strokeCap = glyph.cap
        ..strokeJoin = glyph.join
        ..color = color
        ..isAntiAlias = true,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MoloGlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph || oldDelegate.color != color;
}
