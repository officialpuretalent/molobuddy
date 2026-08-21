import 'package:flutter/material.dart';

/// How Molo tracks type.
///
/// The design applies exactly two tracking rules and leaves everything else
/// untracked:
///
/// * display and heading text is tightened to about `-0.02em`
///   (`-0.01em` around 20px);
/// * small uppercase micro-labels are opened to `0.04em`–`0.06em`;
/// * body, navigation and control text carries none.
///
/// Material 3 does not agree with the third rule. It bakes tracking into its
/// body and label roles, so any text that inherits the ambient style picks up
/// spacing the design never asked for. Every Molo style therefore states its
/// tracking, including when the answer is zero.
abstract final class MoloTypography {
  /// Converts the design's em tracking to the logical pixels Flutter wants.
  ///
  /// CSS `letter-spacing` in `em` scales with the font size; Flutter's
  /// `letterSpacing` is absolute, so the same design value is a different
  /// number at every size and cannot be shared as a constant.
  static double trackingEm(double em, double fontSize) => em * fontSize;

  /// Tracking for display and heading text.
  static double display(double fontSize) => trackingEm(-0.02, fontSize);

  /// Tracking for a small uppercase micro-label.
  static double microLabel(double fontSize) => trackingEm(0.06, fontSize);

  /// The uppercase micro-label above a heading, such as the date over the
  /// morning greeting.
  ///
  /// Regular weight, not medium: the tracking does the work of separating it
  /// from the heading, and the extra weight made it compete.
  static final kicker = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: microLabel(12),
  );
}
