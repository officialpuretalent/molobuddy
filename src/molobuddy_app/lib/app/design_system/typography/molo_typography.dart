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
  static const geist = 'Geist';
  static const geistMono = 'Geist Mono';

  /// Geist's own line box, which is what the design's `line-height: normal`
  /// resolves to.
  ///
  /// Measured in the baseline at 1000px to remove rounding: both weights
  /// report exactly 1.3, and the browser's own font metrics agree. Material
  /// bakes taller line heights into its body roles for reading text, so any
  /// chrome that merges with the ambient style inherits leading the design
  /// never asked for: the sidebar's account row stood 63 tall against the
  /// design's 60, and everything under the wordmark sat 3 low.
  static const normalLineHeight = 1.3;

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
    fontFamily: geistMono,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: microLabel(12),
  );

  /// The source workbench uses Geist Mono for metadata, references and
  /// uppercase eyebrow labels. This style keeps its mechanical character
  /// independent of Material's body roles.
  static TextStyle mono({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w400,
    double? letterSpacing,
    double height = normalLineHeight,
    Color? color,
  }) => TextStyle(
    fontFamily: geistMono,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing ?? 0,
    height: height,
    color: color,
  );
}
