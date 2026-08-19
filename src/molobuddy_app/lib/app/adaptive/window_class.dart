enum MoloWindowClass { compact, medium, expanded, large, extraLarge }

abstract final class MoloBreakpoints {
  static const medium = 600.0;
  static const expanded = 840.0;
  static const large = 1200.0;
  static const extraLarge = 1600.0;
}

MoloWindowClass moloWindowClassFor(double width) {
  return switch (width) {
    < MoloBreakpoints.medium => MoloWindowClass.compact,
    < MoloBreakpoints.expanded => MoloWindowClass.medium,
    < MoloBreakpoints.large => MoloWindowClass.expanded,
    < MoloBreakpoints.extraLarge => MoloWindowClass.large,
    _ => MoloWindowClass.extraLarge,
  };
}
