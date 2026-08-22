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

  /// The account menu's glyphs, transcribed from the same 18-unit paths.
  ///
  /// Arcs and curves are carried across command for command rather than
  /// approximated: `relativeArcToPoint` takes the same radius, large-arc and
  /// sweep that SVG's `a` does, and a smooth cubic's first control point is the
  /// reflection of the previous one, worked out here rather than eyeballed.

  static final switchPractice = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    buildPath: () => Path()
      ..moveTo(2.8, 6.8)
      ..relativeLineTo(9.6, 0)
      ..moveTo(9.8, 4)
      ..lineTo(12.6, 6.8)
      ..lineTo(9.8, 9.6)
      ..moveTo(15.2, 11.2)
      ..lineTo(5.6, 11.2)
      ..moveTo(8.4, 14)
      ..lineTo(5.6, 11.2)
      ..lineTo(8.4, 8.4),
  );

  static final connectors = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    buildPath: () => Path()
      ..moveTo(6.4, 2.8)
      ..relativeLineTo(0, 3.4)
      ..moveTo(11.6, 2.8)
      ..relativeLineTo(0, 3.4)
      ..moveTo(4.6, 6.2)
      ..relativeLineTo(8.8, 0)
      ..relativeLineTo(0, 2.4)
      ..relativeArcToPoint(
        const Offset(-8.8, 0),
        radius: const Radius.circular(4.4),
      )
      ..close()
      ..moveTo(9, 13)
      ..relativeLineTo(0, 2.2),
  );

  static final profile = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    buildPath: () => Path()
      // Two semicircles of diameter 5.6 about (9, 6.6), which is a circle.
      ..addOval(Rect.fromCircle(center: const Offset(9, 6.6), radius: 2.8))
      ..moveTo(3.8, 15.2)
      ..relativeCubicTo(0.6, -2.5, 2.5, -3.9, 5.2, -3.9)
      // The smooth cubic's first control is the reflection of (2.5, -3.9)
      // about the join, which is (2.7, 0).
      ..relativeCubicTo(2.7, 0, 4.6, 1.4, 5.2, 3.9),
  );

  static final settings = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    buildPath: () => Path()
      ..moveTo(3.2, 5.6)
      ..relativeLineTo(11.6, 0)
      ..moveTo(3.2, 12.4)
      ..relativeLineTo(11.6, 0)
      ..moveTo(6.6, 3.9)
      ..relativeLineTo(0, 3.4)
      ..moveTo(11.4, 10.7)
      ..relativeLineTo(0, 3.4),
  );

  static final help = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    buildPath: () => Path()
      ..addOval(Rect.fromCircle(center: const Offset(9, 9), radius: 6.4))
      ..moveTo(7.2, 7)
      ..relativeArcToPoint(
        const Offset(2.6, 1.8),
        radius: const Radius.circular(1.9),
        largeArc: true,
      )
      ..relativeCubicTo(-0.5, 0.2, -0.8, 0.7, -0.8, 1.2)
      ..relativeLineTo(0, 0.4)
      // The stop under the hook. A round cap turns this into the dot.
      ..moveTo(9, 12.7)
      ..relativeLineTo(0.01, 0),
  );

  static final logOut = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    buildPath: () => Path()
      ..moveTo(11, 5.6)
      ..lineTo(11, 4)
      ..relativeArcToPoint(
        const Offset(-1.4, -1.4),
        radius: const Radius.circular(1.4),
        clockwise: false,
      )
      ..lineTo(4.8, 2.6)
      ..arcToPoint(
        const Offset(3.4, 4),
        radius: const Radius.circular(1.4),
        clockwise: false,
      )
      ..relativeLineTo(0, 10)
      ..relativeArcToPoint(
        const Offset(1.4, 1.4),
        radius: const Radius.circular(1.4),
        clockwise: false,
      )
      ..relativeLineTo(4.8, 0)
      ..arcToPoint(
        const Offset(11, 14),
        radius: const Radius.circular(1.4),
        clockwise: false,
      )
      ..relativeLineTo(0, -1.6)
      ..moveTo(7.8, 9)
      ..relativeLineTo(6.8, 0)
      ..moveTo(12.2, 6.6)
      ..lineTo(14.6, 9)
      ..relativeLineTo(-2.4, 2.4),
  );

  // The signup wizard's ten option glyphs, traced from the baseline's own path
  // data. The `arcToPoint` calls are its `a` commands: SVG's arc parameters and
  // Flutter's are the same five, so these are the baseline's arcs rather than
  // circles fitted by eye.

  /// A solo practitioner.
  static final practiceSolo = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    buildPath: () => Path()
      ..moveTo(9, 9.4)
      ..arcToPoint(
        const Offset(9, 4.2),
        radius: const Radius.circular(2.6),
        largeArc: true,
        clockwise: false,
      )
      ..arcToPoint(
        const Offset(9, 9.4),
        radius: const Radius.circular(2.6),
        clockwise: false,
      )
      ..close()
      ..moveTo(3.6, 15)
      ..cubicTo(4.2, 12.6, 6.3, 11.3, 9, 11.3)
      ..cubicTo(11.7, 11.3, 13.8, 12.6, 14.4, 15),
  );

  /// A team of two to ten.
  static final practiceSmallTeam = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    buildPath: () => Path()
      ..moveTo(6.6, 8.6)
      ..arcToPoint(
        const Offset(6.6, 4),
        radius: const Radius.circular(2.3),
        largeArc: true,
        clockwise: false,
      )
      ..arcToPoint(
        const Offset(6.6, 8.6),
        radius: const Radius.circular(2.3),
        clockwise: false,
      )
      ..close()
      ..moveTo(12.4, 9)
      ..arcToPoint(
        const Offset(12.4, 5),
        radius: const Radius.circular(2),
        largeArc: true,
        clockwise: false,
      )
      ..arcToPoint(
        const Offset(12.4, 9),
        radius: const Radius.circular(2),
        clockwise: false,
      )
      ..close()
      ..moveTo(2.4, 14.6)
      ..cubicTo(2.9, 12.5, 4.5, 11.4, 6.6, 11.4)
      ..cubicTo(8.7, 11.4, 10.3, 12.5, 10.8, 14.6)
      ..moveTo(12, 11.6)
      ..cubicTo(13.9, 11.7, 15.1, 12.7, 15.6, 14.6),
  );

  /// A team of eleven or more.
  static final practiceGrowing = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    buildPath: () => Path()
      ..moveTo(3.4, 15)
      ..lineTo(3.4, 4.2)
      ..lineTo(8.8, 4.2)
      ..lineTo(8.8, 15)
      ..moveTo(8.8, 7.4)
      ..lineTo(14.6, 7.4)
      ..lineTo(14.6, 15)
      ..moveTo(2.2, 15)
      ..lineTo(15.8, 15)
      ..moveTo(5.4, 6.6)
      ..lineTo(6.8, 6.6)
      ..moveTo(5.4, 9.2)
      ..lineTo(6.8, 9.2)
      ..moveTo(5.4, 11.8)
      ..lineTo(6.8, 11.8)
      ..moveTo(11, 10)
      ..lineTo(12.6, 10)
      ..moveTo(11, 12.6)
      ..lineTo(12.6, 12.6),
  );

  /// Staying ahead of deadlines.
  static final goalDeadlines = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    buildPath: () => Path()
      ..moveTo(3, 5.4)
      ..lineTo(15, 5.4)
      ..lineTo(15, 15)
      ..lineTo(3, 15)
      ..close()
      ..moveTo(6, 3)
      ..lineTo(6, 5.6)
      ..moveTo(12, 3)
      ..lineTo(12, 5.6)
      ..moveTo(3, 8.4)
      ..lineTo(15, 8.4)
      ..moveTo(8.2, 11.6)
      ..lineTo(9.4, 12.8)
      ..lineTo(11.8, 10.4),
  );

  /// Keeping documents moving.
  static final goalDocuments = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    buildPath: () => Path()
      ..moveTo(2.6, 5.4)
      ..lineTo(6.8, 5.4)
      ..lineTo(8.2, 7.1)
      ..lineTo(15.4, 7.1)
      ..lineTo(15.4, 15)
      ..lineTo(2.6, 15)
      ..close(),
  );

  /// Running work with a team.
  static final goalTeamwork = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    buildPath: () => Path()
      ..moveTo(9, 5.2)
      ..arcToPoint(
        const Offset(9, 2.2),
        radius: const Radius.circular(1.5),
        largeArc: true,
        clockwise: false,
      )
      ..arcToPoint(
        const Offset(9, 5.2),
        radius: const Radius.circular(1.5),
        clockwise: false,
      )
      ..close()
      ..moveTo(4.4, 14.6)
      ..arcToPoint(
        const Offset(4.4, 11.6),
        radius: const Radius.circular(1.5),
        largeArc: true,
        clockwise: false,
      )
      ..arcToPoint(
        const Offset(4.4, 14.6),
        radius: const Radius.circular(1.5),
        clockwise: false,
      )
      ..close()
      ..moveTo(13.6, 14.6)
      ..arcToPoint(
        const Offset(13.6, 11.6),
        radius: const Radius.circular(1.5),
        largeArc: true,
        clockwise: false,
      )
      ..arcToPoint(
        const Offset(13.6, 14.6),
        radius: const Radius.circular(1.5),
        clockwise: false,
      )
      ..close()
      ..moveTo(8.2, 6.4)
      ..lineTo(5.2, 11.4)
      ..moveTo(9.8, 6.4)
      ..lineTo(12.8, 11.4),
  );

  /// Seeing the whole practice clearly.
  static final goalVisibility = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    buildPath: () => Path()
      ..moveTo(8.2, 2.6)
      ..lineTo(9.5, 6.1)
      ..lineTo(13, 7.4)
      ..lineTo(9.5, 8.7)
      ..lineTo(8.2, 12.2)
      ..lineTo(6.9, 8.7)
      ..lineTo(3.4, 7.4)
      ..lineTo(6.9, 6.1)
      ..close()
      ..moveTo(13, 11.4)
      ..lineTo(13.7, 13.2)
      ..lineTo(15.5, 13.9)
      ..lineTo(13.7, 14.6)
      ..lineTo(13, 16.4)
      ..lineTo(12.3, 14.6)
      ..lineTo(10.5, 13.9)
      ..lineTo(12.3, 13.2)
      ..close(),
  );

  /// Importing a client list.
  static final startImport = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    buildPath: () => Path()
      ..moveTo(4.4, 2.6)
      ..lineTo(9.6, 2.6)
      ..lineTo(13.4, 6.4)
      ..lineTo(13.4, 15.4)
      ..lineTo(4.4, 15.4)
      ..close()
      ..moveTo(9.4, 2.6)
      ..lineTo(9.4, 6.5)
      ..lineTo(13.3, 6.5)
      ..moveTo(9, 9)
      ..lineTo(9, 13)
      ..moveTo(7.4, 10.6)
      ..lineTo(9, 9)
      ..lineTo(10.6, 10.6),
  );

  /// Adding the first client.
  static final startFirstClient = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    buildPath: () => Path()
      ..moveTo(7.4, 9.2)
      ..arcToPoint(
        const Offset(7.4, 4),
        radius: const Radius.circular(2.6),
        largeArc: true,
        clockwise: false,
      )
      ..arcToPoint(
        const Offset(7.4, 9.2),
        radius: const Radius.circular(2.6),
        clockwise: false,
      )
      ..close()
      ..moveTo(2.6, 15)
      ..cubicTo(3.1, 12.7, 5, 11.4, 7.4, 11.4)
      ..moveTo(12.6, 8.6)
      ..lineTo(12.6, 12.8)
      ..moveTo(10.5, 10.7)
      ..lineTo(14.7, 10.7),
  );

  /// Exploring a sample workspace.
  static final startSample = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    buildPath: () => Path()
      ..moveTo(9, 15.4)
      ..arcToPoint(
        const Offset(9, 2.6),
        radius: const Radius.circular(6.4),
        largeArc: true,
        clockwise: false,
      )
      ..arcToPoint(
        const Offset(9, 15.4),
        radius: const Radius.circular(6.4),
        clockwise: false,
      )
      ..close()
      ..moveTo(11.6, 6.4)
      ..lineTo(7.9, 7.9)
      ..lineTo(6.4, 11.6)
      ..lineTo(10.1, 10.1)
      ..close(),
  );

  /// The wizard's back link, drawn in a 16-unit box like the search glyph.
  static final backArrow = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    viewBox: 16,
    buildPath: () => Path()
      ..moveTo(9.6, 3.6)
      ..lineTo(5.2, 8)
      ..lineTo(9.6, 12.4)
      ..moveTo(5.4, 8)
      ..lineTo(11.6, 8),
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

  /// The password field's reveal toggle.
  ///
  /// The baseline draws one eye for both states and changes only the control's
  /// title, so there is no crossed-out variant to trace: what the state is, is
  /// carried by the accessible name.
  static final eye = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    buildPath: () => Path()
      // The lid, as four cubics. The source writes it with smooth-curve
      // shorthand, whose first control point mirrors the previous segment's
      // second; these are those mirrors written out.
      ..moveTo(1.6, 9)
      ..cubicTo(1.6, 9, 4.4, 4.4, 9, 4.4)
      ..cubicTo(13.6, 4.4, 16.4, 9, 16.4, 9)
      ..cubicTo(16.4, 9, 13.6, 13.6, 9, 13.6)
      ..cubicTo(4.4, 13.6, 1.6, 9, 1.6, 9)
      ..close()
      ..addOval(Rect.fromCircle(center: const Offset(9, 9), radius: 2.1)),
  );

  /// The mark inside a checked box, drawn in the 14-unit box the baseline uses
  /// for it rather than the usual 18.
  static final tick = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    viewBox: 14,
    buildPath: () => Path()
      ..moveTo(3, 7.4)
      ..lineTo(5.6, 10)
      ..lineTo(11, 4.4),
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
