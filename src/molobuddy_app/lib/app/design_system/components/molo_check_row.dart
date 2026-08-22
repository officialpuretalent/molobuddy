import 'package:flutter/material.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/icons/molo_glyphs.dart';
import 'package:molobuddy_app/app/design_system/typography/molo_typography.dart';

/// A square box and a label, the whole row being the control.
///
/// The design draws no Material checkbox anywhere: the box is 19 square at
/// radius 6, and pressing the words is the same as pressing the box. The
/// unchecked outline is [MoloColours.controlBorder] rather than the baseline's
/// quieter colour, because that outline is the only thing that says a checkbox
/// is there and WCAG 1.4.11 asks for 3:1 of it.
class MoloCheckRow extends StatelessWidget {
  const MoloCheckRow({
    required this.label,
    required this.semanticLabel,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.boxSize = 19,
    this.boxRadius = 6,
    super.key,
  });

  /// A widget rather than a string, so a row can carry links inside its words.
  final Widget label;

  /// The plain-text name of the whole row, spoken once.
  final String semanticLabel;

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  /// The design draws 19 at sign-in and 21 on the wizard's terms row.
  final double boxSize;

  /// 6 at sign-in, 7 on the terms row, where the box matches the shape of a
  /// multiple-choice mark.
  final double boxRadius;

  /// The box itself, so a measurement can find it.
  static const boxKey = Key('molo_check_row_box');

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      checked: value,
      enabled: enabled,
      label: semanticLabel,
      child: InkWell(
        onTap: enabled ? () => onChanged(!value) : null,
        borderRadius: BorderRadius.circular(boxRadius),
        child: Row(
          children: [
            Container(
              key: boxKey,
              width: boxSize,
              height: boxSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: value ? MoloColours.moloPlum : MoloColours.surface,
                borderRadius: BorderRadius.circular(boxRadius),
                border: value
                    ? null
                    : Border.all(color: MoloColours.controlBorder),
              ),
              // The tick stays in the tree and fades, as the baseline does, so
              // the box never reflows as it is toggled.
              child: Opacity(
                opacity: value ? 1 : 0,
                child: MoloIcon(
                  MoloGlyphs.tick,
                  size: 12,
                  color: MoloColours.warmCanvas,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: ExcludeSemantics(
                child: DefaultTextStyle.merge(
                  style: const TextStyle(
                    fontSize: 13,
                    letterSpacing: 0,
                    height: MoloTypography.normalLineHeight,
                    color: MoloColours.secondaryText,
                  ),
                  child: label,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
