abstract final class MoloAuthShellLayout {
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
}
