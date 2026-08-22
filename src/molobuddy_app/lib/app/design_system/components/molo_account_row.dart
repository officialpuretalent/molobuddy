import 'package:flutter/material.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/typography/molo_typography.dart';

/// The practice and person identity row that closes the workspace sidebar.
///
/// Presentational: the caller wraps it in whatever opens the account menu, so
/// this widget carries no sign-out or navigation of its own.
class MoloAccountRow extends StatelessWidget {
  const MoloAccountRow({
    required this.initials,
    required this.name,
    this.detail,
    this.labelled = true,
    this.showCaret = true,
    super.key,
  });

  /// The initials tile, so tests and the rail can find the same element.
  static const avatarKey = Key('molo_account_row_avatar');

  /// The second line's colour: the warm white at 66 percent.
  static const detailForeground = Color(0xA8FFF9F7);

  /// The caret's ink, measured off the design's glyph at 12px.
  static const caretSize = Size(6.94, 3.47);

  final String initials;
  final String name;

  /// The signed-in person, under the practice name. Absent on the rail, where
  /// there is only room for the initials tile.
  final String? detail;

  /// Whether the text and caret show. False on the icon rail.
  final bool labelled;

  final bool showCaret;

  @override
  Widget build(BuildContext context) {
    final detailLine = detail;
    return Padding(
      // 12 on every side, inside a 15 radius, as the design draws it.
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: labelled
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          Container(
            key: avatarKey,
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: MoloColours.softBlush,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
                height: MoloTypography.normalLineHeight,
                color: MoloColours.moloPlum,
              ),
            ),
          ),
          if (labelled) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                      height: MoloTypography.normalLineHeight,
                      color: MoloColours.surface,
                    ),
                  ),
                  if (detailLine != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      detailLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        // Stated rather than inherited, like every other value
                        // here. It happens to match the ambient weight today,
                        // which is exactly how the leading went unnoticed.
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                        height: MoloTypography.normalLineHeight,
                        color: detailForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showCaret) const _Caret(),
          ],
        ],
      ),
    );
  }
}

/// The small solid triangle that closes the account row.
///
/// The design draws this with a text glyph, U+25BE at 12px. Flutter cannot rely
/// on that: Geist has no such glyph, so it resolves through font fallback and
/// comes out a different shape and size on every platform. Painting it keeps
/// the design's ink size, which was measured off the baseline's own rendering.
///
/// Centred in the row, where the design's sits about 2 lower: that offset is
/// where a text baseline put it, not a placement the design chose.
class _Caret extends StatelessWidget {
  const _Caret();

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: CustomPaint(
        size: MoloAccountRow.caretSize,
        painter: _CaretPainter(),
      ),
    );
  }
}

class _CaretPainter extends CustomPainter {
  const _CaretPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = MoloAccountRow.detailForeground
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_CaretPainter oldDelegate) => false;
}
