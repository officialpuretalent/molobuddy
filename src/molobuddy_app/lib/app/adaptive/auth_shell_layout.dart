abstract final class MoloAuthShellLayout {
  /// The width at which sign-in shows its photograph and the wizard its rail.
  ///
  /// The design's own number, and not one of [MoloBreakpoints]: the baseline
  /// switches these two screens on 900 while the app's window classes turn at
  /// 840. Following the classes drew a rail between 840 and 900 that the
  /// design does not draw, so these screens keep the design's threshold and
  /// the rest of the app keeps the classes.
  static const supportingPaneMinimumWidth = 900.0;

  /// Whether [availableWidth] has room for the supporting pane beside the form.
  static bool showsSupportingPane(double availableWidth) {
    return availableWidth >= supportingPaneMinimumWidth;
  }

  /// The dark supporting pane the signup wizard shares across its routes.
  ///
  /// Fixed rather than proportional, because `/sign-up` and `/onboarding` fade
  /// into each other and a proportional edge would be the same number twice
  /// only by accident.
  static double supportingPaneWidth(double availableWidth) {
    return availableWidth.clamp(300, 360).toDouble();
  }

  /// The sign-in hero, which the design draws at 44% of the window.
  ///
  /// Wider than the wizard's rail on purpose: the baseline gives the photograph
  /// 44% and the rail 38%. Sign-in does not fade into the wizard through a
  /// shared pane, so the two are free to differ.
  static double signInHeroWidth(double availableWidth) {
    return availableWidth * 0.44;
  }

  /// The signup wizard's rail, which the design draws at 38% of the window and
  /// stops at 460.
  ///
  /// Narrower than [signInHeroWidth] on purpose: a photograph earns width that
  /// a list of four steps does not.
  static double wizardRailWidth(double availableWidth) {
    return (availableWidth * 0.38).clamp(0, 460).toDouble();
  }
}
