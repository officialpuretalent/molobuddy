abstract final class MoloAuthShellLayout {
  static double supportingPaneWidth(double availableWidth) {
    return availableWidth.clamp(300, 360).toDouble();
  }
}
