import 'package:flutter/material.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/typography/molo_typography.dart';

/// The label above a field, and anything the design puts at the right of that
/// same row.
///
/// One definition because several controls need it — a text field, the region
/// select, a group of choice cards — and a label that drifted between them
/// would be visible on the one step that shows all three.
///
/// Excluded from semantics: the control below re-states it as its own accessible
/// name, so leaving this visible to a screen reader would say it twice.
class MoloFieldLabel extends StatelessWidget {
  const MoloFieldLabel({required this.label, this.trailing, super.key});

  final String label;

  /// An action at the right of the row, such as "Forgot password?". Outside this
  /// widget's exclusion, because it is a separate control.
  final Widget? trailing;

  /// The design's distance from this label to the control below it.
  static const gap = 7.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: ExcludeSemantics(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
                height: MoloTypography.normalLineHeight,
                color: MoloColours.moloPlum,
              ),
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
