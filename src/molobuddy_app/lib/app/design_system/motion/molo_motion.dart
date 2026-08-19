import 'package:flutter/material.dart';

abstract final class MoloMotion {
  static const Duration route = Duration(milliseconds: 180);
  static const Duration routeReverse = Duration(milliseconds: 140);
  static const Duration step = Duration(milliseconds: 170);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;

  static Duration duration(BuildContext context, Duration preferred) {
    return MediaQuery.disableAnimationsOf(context) ? Duration.zero : preferred;
  }
}
