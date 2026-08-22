import 'package:flutter/material.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/typography/molo_typography.dart';

/// The Molo mark, and the wordmark beside it where there is room.
///
/// The design draws this lockup at exactly two sizes: 26/21 in the sidebar and
/// the sign-in hero, 20/17 in a compact header. It is one component because
/// the mark's radius, the gap and the wordmark's size move together, and a
/// caller that only knew one of the three would drift.
class MoloBrandLockup extends StatelessWidget {
  const MoloBrandLockup({
    this.onDark = false,
    this.compact = false,
    this.labelled = true,
    this.markKey,
    super.key,
  });

  /// Paints the wordmark on a dark ground. The mark is pulse either way.
  final bool onDark;

  /// The smaller of the design's two sizes.
  final bool compact;

  /// Whether the wordmark appears. The navigation rail paints the mark alone.
  final bool labelled;

  /// Lets a caller keep a measurement key on the mark itself.
  final Key? markKey;

  double get _markSize => compact ? 20 : 26;
  double get _markRadius => compact ? 7 : 9;
  double get _gap => compact ? 8 : 10;
  double get _wordmarkSize => compact ? 17 : 21;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Molo',
      header: true,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              key: markKey,
              width: _markSize,
              height: _markSize,
              decoration: BoxDecoration(
                color: MoloColours.moloPulse,
                borderRadius: BorderRadius.circular(_markRadius),
              ),
            ),
            if (labelled) ...[
              SizedBox(width: _gap),
              // Flexible so a lockup sharing a row with an action gives ground
              // rather than painting over it once text is scaled up.
              Flexible(
                child: Text(
                  'molo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: _wordmarkSize,
                    fontWeight: FontWeight.w500,
                    letterSpacing: MoloTypography.display(_wordmarkSize),
                    // Material's body leading makes this line box taller than
                    // the design's, which pushes the mark off centre and
                    // shifts everything beneath the lockup down.
                    height: MoloTypography.normalLineHeight,
                    color: onDark ? MoloColours.surface : MoloColours.moloPlum,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
