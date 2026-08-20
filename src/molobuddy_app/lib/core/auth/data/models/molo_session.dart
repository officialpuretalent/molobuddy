enum PracticeAccessStatus { active, invited, suspended }

final class PracticeRef {
  const PracticeRef({
    required this.practiceId,
    required this.displayLabel,
    required this.homeRegionKey,
    required this.routeVersion,
    required this.accessStatus,
  });

  final String practiceId;
  final String displayLabel;
  final String homeRegionKey;
  final int routeVersion;
  final PracticeAccessStatus accessStatus;
}

/// The server's answer to "who is this and what may they reach".
///
/// Authentication does not imply authorisation for a practice, so this is
/// reloaded even when a Firebase session is restored from persistence.
final class MoloSession {
  const MoloSession({
    required this.uid,
    required this.practiceRefs,
    this.displayName,
    this.emailMasked,
    this.preferredLocale,
    this.onboardingComplete = true,
  });

  final String uid;
  final List<PracticeRef> practiceRefs;
  final String? displayName;
  final String? emailMasked;
  final String? preferredLocale;

  /// Whether the server considers this account finished setting up.
  ///
  /// Defaults to true so an older server, or any response without the block,
  /// never traps a user in a wizard. The field only ever adds a redirect, so
  /// the safe default is the one that adds none.
  final bool onboardingComplete;

  bool get hasPractices => practiceRefs.isNotEmpty;

  Iterable<PracticeRef> get selectablePractices {
    return practiceRefs.where(
      (practice) => practice.accessStatus == PracticeAccessStatus.active,
    );
  }
}
