abstract final class MoloSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const display = 64.0;

  // The design draws six corner radii and no others. Naming them keeps a
  // literal from appearing at a call site, where it reads as a choice rather
  // than as the design's number.

  /// The small switch pill each authentication screen offers the other through.
  static const pillRadius = 12.0;

  /// Fields and secondary buttons.
  static const controlRadius = 14.0;

  /// A primary action, which the design draws one unit rounder than a field.
  static const primaryActionRadius = 15.0;

  /// A selectable option card in the signup wizard.
  static const choiceCardRadius = 16.0;

  /// The workspace card inside the wizard rail.
  static const railCardRadius = 18.0;

  /// A surface card in the workspace.
  static const cardRadius = 24.0;
}
