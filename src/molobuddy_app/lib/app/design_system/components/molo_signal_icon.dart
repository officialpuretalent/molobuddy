import 'package:flutter/material.dart';
import 'package:molobuddy_app/app/design_system/icons/molo_glyphs.dart';

/// A 36px tinted workbench signal tile.
///
/// It keeps attention, warning and neutral signal treatments from becoming
/// slightly different anonymous containers in every feature.
class MoloSignalIcon extends StatelessWidget {
  const MoloSignalIcon({
    required this.glyph,
    required this.foreground,
    required this.background,
    super.key,
  });

  final MoloGlyph glyph;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: SizedBox(
      width: 36,
      height: 36,
      child: Center(child: MoloIcon(glyph, size: 15, color: foreground)),
    ),
  );
}
