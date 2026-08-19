import 'package:flutter/material.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';

class MoloWordmark extends StatelessWidget {
  const MoloWordmark({this.onDark = false, this.compact = false, super.key});

  final bool onDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Molo',
      header: true,
      child: ExcludeSemantics(
        child: Text(
          'molo',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: onDark ? MoloColours.surface : MoloColours.deepInk,
            fontSize: compact ? 27 : 32,
            fontWeight: FontWeight.w500,
            letterSpacing: -1.4,
          ),
        ),
      ),
    );
  }
}
