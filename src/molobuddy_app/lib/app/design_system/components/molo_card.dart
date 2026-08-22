import 'package:flutter/material.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';

/// A quiet, bordered Molo content surface.
///
/// This is intentionally presentational: actions, navigation and data state
/// remain with the owning feature. Use [semanticLabel] only when the full card
/// needs a group label beyond its visible heading.
class MoloCard extends StatelessWidget {
  const MoloCard({
    required this.child,
    this.padding = const EdgeInsets.all(MoloSpacing.lg),
    this.backgroundColor = MoloColours.surface,
    this.radius = MoloSpacing.cardRadius,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final double radius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final surface = DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: MoloColours.border),
      ),
      child: Padding(padding: padding, child: child),
    );
    return semanticLabel == null
        ? surface
        : Semantics(container: true, label: semanticLabel, child: surface);
  }
}
