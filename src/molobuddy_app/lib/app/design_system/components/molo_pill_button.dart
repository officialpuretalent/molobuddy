import 'package:flutter/material.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';
import 'package:molobuddy_app/app/design_system/typography/molo_typography.dart';

/// The small outlined pill each authentication screen offers the other one
/// through.
///
/// The design draws a button here, not a link, which is why this replaced a
/// `TextButton`: the outline is what tells someone it is pressable. That
/// outline is [MoloColours.controlBorder] rather than the baseline's quieter
/// colour in both the resting and hovered states, because the pill's fill is
/// invisible against the warm canvas and the outline is therefore the only
/// thing identifying the control. Hover changes the fill alone.
class MoloPillButton extends StatelessWidget {
  const MoloPillButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;

  /// A null callback disables the pill.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size.zero),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: MoloSpacing.md, vertical: 9),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return MoloColours.surface;
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed)) {
            return MoloColours.pulseTint;
          }
          return MoloColours.surface;
        }),
        // Keyboard focus has to stay distinguishable from hover, so it takes
        // the focus ring rather than a second fill.
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return MoloColours.secondaryText;
          }
          return MoloColours.moloPlum;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return const BorderSide(color: MoloColours.border);
          }
          return const BorderSide(color: MoloColours.controlBorder);
        }),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MoloSpacing.pillRadius),
          ),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
            height: MoloTypography.normalLineHeight,
          ),
        ),
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
