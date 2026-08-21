import 'package:flutter/material.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/icons/molo_glyphs.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';
import 'package:molobuddy_app/app/design_system/typography/molo_typography.dart';

/// One row of workspace navigation, on the plum sidebar or icon rail.
///
/// Presentational only: it reports taps and knows nothing about routes. Every
/// measurement is traced from the design baseline, so prefer changing the
/// design over changing these numbers.
class MoloNavigationItem extends StatelessWidget {
  const MoloNavigationItem({
    required this.glyph,
    required this.label,
    required this.selected,
    required this.labelled,
    required this.onTap,
    this.badgeLabel,
    this.enabled = true,
    super.key,
  });

  /// Row height with the label showing.
  static const labelledHeight = 44.0;

  /// Row height on the icon rail, where the taller target replaces the label.
  static const railHeight = 48.0;

  /// Glyph size beside a label.
  static const labelledIconSize = 18.0;

  /// Glyph size on the rail, which the design enlarges to hold the row.
  static const railIconSize = 22.0;

  /// The selected row's fill: white at ten percent over plum.
  static const selectedFill = Color(0x1AFFFFFF);

  /// Unselected label and glyph colour: the warm white at 72 percent.
  static const idleForeground = Color(0xB8FFF9F7);

  static const _fontSize = 15.0;
  static const _gap = 12.0;
  static const _radius = 14.0;

  final MoloGlyph glyph;
  final String label;
  final bool selected;

  /// Whether the label is visible. False on the icon rail, where the label
  /// stays available to assistive technology and as a tooltip.
  final bool labelled;

  final VoidCallback onTap;

  /// A localised count supplied by the feature. Hidden on the rail, as in the
  /// design, because there is no room to place it without crowding the glyph.
  final String? badgeLabel;

  /// False for a destination whose screen is not built yet. It stays visible so
  /// the navigation matches the design, but it does not pretend to work.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? MoloColours.surface : idleForeground;
    final effective = enabled ? foreground : idleForeground.withValues(alpha: 0.38);
    final badge = badgeLabel;

    final row = Row(
      mainAxisAlignment: labelled
          ? MainAxisAlignment.start
          : MainAxisAlignment.center,
      children: [
        MoloIcon(
          glyph,
          size: labelled ? labelledIconSize : railIconSize,
          color: effective,
        ),
        if (labelled) ...[
          const SizedBox(width: _gap),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: _fontSize,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                // Stated, not inherited: the ambient Material style tracks
                // body text and the design tracks navigation not at all, and
                // it leads body text taller than Geist's own line box.
                letterSpacing: 0,
                height: MoloTypography.normalLineHeight,
                color: effective,
              ),
            ),
          ),
          if (badge != null) _Badge(badge),
        ],
      ],
    );

    final surface = Material(
      color: selected ? selectedFill : Colors.transparent,
      borderRadius: BorderRadius.circular(_radius),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(_radius),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: labelled ? _gap : 0),
          child: row,
        ),
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      // The rail has no visible label, so name the row here. With a label
      // showing, the Text already carries it and naming it again repeats it.
      label: labelled ? null : label,
      child: SizedBox(
        height: labelled ? labelledHeight : railHeight,
        child: labelled ? surface : Tooltip(message: label, child: surface),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: MoloColours.moloPulse,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          // The design uses a tight 2px vertically against 8px horizontally,
          // which keeps the pill short enough to sit inside a 44px row.
          padding: const EdgeInsets.symmetric(
            horizontal: MoloSpacing.xs,
            vertical: 2,
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
              // Inheriting Material's leading grew the pill to 21 against the
              // design's 19.5, which crowded the 44 row.
              height: MoloTypography.normalLineHeight,
              color: MoloColours.moloPlum,
            ),
          ),
        ),
      ),
    );
  }
}
