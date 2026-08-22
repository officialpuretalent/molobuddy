import 'package:flutter/material.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';
import 'package:molobuddy_app/app/design_system/typography/molo_typography.dart';

/// A workbench state, with the source design's semantic colour mapping.
enum MoloStatusTone { attention, warning, success, neutral, error, info }

class MoloStatusPill extends StatelessWidget {
  const MoloStatusPill({
    required this.label,
    this.icon,
    this.tone = MoloStatusTone.attention,
    super.key,
  });

  final String label;
  final IconData? icon;
  final MoloStatusTone tone;

  (Color foreground, Color background) get _colours => switch (tone) {
    MoloStatusTone.attention => (MoloColours.pulseText, MoloColours.pulseTint),
    MoloStatusTone.warning => (MoloColours.warning, MoloColours.warningTint),
    MoloStatusTone.success => (MoloColours.success, MoloColours.successTint),
    MoloStatusTone.neutral => (
      MoloColours.secondaryText,
      MoloColours.softBlush,
    ),
    MoloStatusTone.error => (MoloColours.error, MoloColours.errorTint),
    MoloStatusTone.info => (
      MoloColours.information,
      MoloColours.informationTint,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (foreground, background) = _colours;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: SizedBox(
        height: 28,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: MoloSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: foreground),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: MoloTypography.mono(
                  fontSize: 11,
                  color: foreground,
                  fontWeight: FontWeight.w500,
                  letterSpacing: MoloTypography.trackingEm(0.04, 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
