import 'package:flutter/material.dart';

abstract final class MoloColours {
  static const moloPlum = Color(0xFF241529);
  static const warmCanvas = Color(0xFFFFF9F7);
  static const surface = Color(0xFFFFFFFF);
  static const softBlush = Color(0xFFF8ECEE);
  static const moloPulse = Color(0xFFF25775);
  static const pulseTint = Color(0xFFFDECEF);
  static const pulseText = Color(0xFF9B263B);
  static const secondaryText = Color(0xFF685E68);
  static const controlBorder = Color(0xFF9A858D);
  static const border = Color(0xFFE4D5D8);

  /// Hover outline for a pill on a tinted surface.
  ///
  /// 1.72:1 on white, so it may only ever replace an outline that already
  /// exists: the resting [border] or [controlBorder] is what identifies the
  /// control, and this is the hover decoration over it.
  static const pulseBorder = Color(0xFFE9B9C4);

  /// Hover fill for a plum primary action.
  ///
  /// Fill only. A [warmCanvas] label on it measures 13.37:1, so the hover
  /// state never costs the label its contrast.
  static const moloPlumHover = Color(0xFF3A2440);

  /// The readiness figure in the signup wizard's rail.
  ///
  /// 7.82:1 on [moloPlum], against [moloPulse]'s 5.27:1. Both clear AA, so this
  /// is hierarchy rather than a gate: pulse is spent on the bar's fill, and a
  /// figure in the same pink would compete with the bar it describes instead of
  /// labelling it.
  static const pulseOnDark = Color(0xFFF98FA4);
  static const success = Color(0xFF087A55);
  static const warning = Color(0xFFA85D00);
  static const error = Color(0xFFC2382B);

  /// Quiet backdrop behind error copy. Pairs with [error] for the icon and
  /// with the default body colour for the text, which keeps the text contrast
  /// well above 4.5:1.
  static const errorTint = Color(0xFFFFF1F0);
  static const information = Color(0xFF3459D4);
}
