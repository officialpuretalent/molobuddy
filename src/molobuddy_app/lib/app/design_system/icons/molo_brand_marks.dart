import 'package:flutter/widgets.dart';

/// One filled shape of a third-party brand mark, in the colour its owner
/// specifies.
@immutable
class MoloBrandMarkLayer {
  const MoloBrandMarkLayer(this.buildPath, this.colour);

  final Path Function() buildPath;
  final Color colour;
}

/// A third-party brand mark, such as Google's or Microsoft's.
///
/// Deliberately not a [MoloGlyph]. Molo's own glyphs are one stroked outline in
/// a single colour, which is what makes a selected destination change only its
/// colour. A brand mark is the opposite on both counts: several filled shapes,
/// each in a colour its owner fixes and nobody else may change. Keeping them in
/// a separate type stops one from being handed to [MoloIcon] and quietly
/// re-coloured.
///
/// The path data is the marks' owners' own, reproduced at the sizes and
/// proportions their brand guidelines set for a sign-in control.
@immutable
class MoloBrandMark {
  const MoloBrandMark({required this.layers, required this.viewBox});

  /// Painted in order, first to last.
  final List<MoloBrandMarkLayer> layers;

  /// Side of the square the mark is drawn in. Each mark keeps its owner's own
  /// box rather than being redrawn in Molo's 18, because rescaling the data by
  /// hand is how a mark stops being the mark.
  final double viewBox;
}

abstract final class MoloBrandMarks {
  /// Google's four-colour G, in its published 48-unit box.
  static final google = MoloBrandMark(
    viewBox: 48,
    layers: [
      MoloBrandMarkLayer(
        () => Path()
          ..moveTo(45.12, 24.5)
          ..cubicTo(45.12, 22.94, 44.98, 21.44, 44.72, 20)
          ..lineTo(24, 20)
          ..lineTo(24, 28.51)
          ..lineTo(35.84, 28.51)
          ..cubicTo(35.33, 31.26, 33.78, 33.59, 31.45, 35.15)
          ..lineTo(31.45, 40.67)
          ..lineTo(38.56, 40.67)
          ..cubicTo(42.72, 36.84, 45.12, 31.2, 45.12, 24.5)
          ..close(),
        const Color(0xFF4285F4),
      ),
      MoloBrandMarkLayer(
        () => Path()
          ..moveTo(24, 46)
          ..cubicTo(29.94, 46, 34.92, 44.03, 38.56, 40.67)
          ..lineTo(31.45, 35.15)
          ..cubicTo(29.48, 36.47, 26.96, 37.25, 24, 37.25)
          ..cubicTo(18.27, 37.25, 13.42, 33.38, 11.69, 28.18)
          ..lineTo(4.34, 28.18)
          ..lineTo(4.34, 33.88)
          ..cubicTo(7.96, 41.07, 15.4, 46, 24, 46)
          ..close(),
        const Color(0xFF34A853),
      ),
      MoloBrandMarkLayer(
        () => Path()
          ..moveTo(11.69, 28.18)
          ..cubicTo(11.25, 26.86, 11, 25.45, 11, 24)
          ..cubicTo(11, 22.55, 11.25, 21.14, 11.69, 19.82)
          ..lineTo(11.69, 14.12)
          ..lineTo(4.34, 14.12)
          ..cubicTo(2.85, 17.09, 2, 20.45, 2, 24)
          ..cubicTo(2, 27.55, 2.85, 30.91, 4.34, 33.88)
          ..lineTo(11.69, 28.18)
          ..close(),
        const Color(0xFFFBBC05),
      ),
      MoloBrandMarkLayer(
        () => Path()
          ..moveTo(24, 10.75)
          ..cubicTo(27.23, 10.75, 30.13, 11.86, 32.41, 14.04)
          ..lineTo(38.72, 7.73)
          ..cubicTo(34.91, 4.18, 29.93, 2, 24, 2)
          ..cubicTo(15.4, 2, 7.96, 6.93, 4.34, 14.12)
          ..lineTo(11.69, 19.82)
          ..cubicTo(13.42, 14.62, 18.27, 10.75, 24, 10.75)
          ..close(),
        const Color(0xFFEA4335),
      ),
    ],
  );

  /// Microsoft's four squares, in its published 23-unit box: sides of 10, one
  /// unit of gap, one unit of padding.
  static final microsoft = MoloBrandMark(
    viewBox: 23,
    layers: [
      MoloBrandMarkLayer(
        () => Path()..addRect(const Rect.fromLTWH(1, 1, 10, 10)),
        const Color(0xFFF25022),
      ),
      MoloBrandMarkLayer(
        () => Path()..addRect(const Rect.fromLTWH(12, 1, 10, 10)),
        const Color(0xFF7FBA00),
      ),
      MoloBrandMarkLayer(
        () => Path()..addRect(const Rect.fromLTWH(1, 12, 10, 10)),
        const Color(0xFF00A4EF),
      ),
      MoloBrandMarkLayer(
        () => Path()..addRect(const Rect.fromLTWH(12, 12, 10, 10)),
        const Color(0xFFFFB900),
      ),
    ],
  );
}

/// Paints a [MoloBrandMark] at [size].
///
/// Never takes a colour. A brand mark's colours belong to its owner, and a
/// parameter to override them would be an invitation to break their guidelines.
class MoloBrandIcon extends StatelessWidget {
  const MoloBrandIcon(this.mark, {required this.size, super.key});

  final MoloBrandMark mark;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _MoloBrandMarkPainter(mark),
      ),
    );
  }
}

class _MoloBrandMarkPainter extends CustomPainter {
  const _MoloBrandMarkPainter(this.mark);

  final MoloBrandMark mark;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.shortestSide / mark.viewBox);
    for (final layer in mark.layers) {
      canvas.drawPath(
        layer.buildPath(),
        Paint()
          ..style = PaintingStyle.fill
          ..color = layer.colour
          ..isAntiAlias = true,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MoloBrandMarkPainter oldDelegate) =>
      oldDelegate.mark != mark;
}
