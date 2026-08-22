/// The three workspace layouts expressed by the Molo workbench.
///
/// The source design does not have a device breakpoint system. It has one
/// compact layout below 900px, an icon rail from 900px up to 1180px, and a
/// labelled sidebar from 1180px. Keeping the names below preserves the
/// app-shell API while making the design boundaries explicit.
enum MoloWindowClass { compact, medium, expanded, large, extraLarge }

abstract final class MoloBreakpoints {
  /// The compact workbench becomes the wide workbench at this exact width.
  static const compactMaximum = 900.0;

  /// The icon rail becomes a labelled sidebar at this exact width.
  static const labelledSidebarMinimum = 1180.0;
}

MoloWindowClass moloWindowClassFor(double width) {
  return switch (width) {
    < MoloBreakpoints.compactMaximum => MoloWindowClass.compact,
    < MoloBreakpoints.labelledSidebarMinimum => MoloWindowClass.medium,
    _ => MoloWindowClass.large,
  };
}
