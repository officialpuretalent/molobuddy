enum PracticeSize { solo, smallTeam, growingTeam }

enum OnboardingPriority { deadlines, documents, teamwork, visibility }

enum WorkspaceStartingPoint { importClients, addFirstClient, sampleWorkspace }

/// Where a returning user picks up, as the server derived it.
///
/// Sent by the server on every read; never computed here. Two implementations
/// of one rule is how a resumed wizard opens on a question already answered.
enum OnboardingStep { practice, priorities, startingPoint, readyToComplete }

final class OnboardingAnswers {
  const OnboardingAnswers({
    this.practiceName,
    this.practiceSize,
    this.priorities = const {},
    this.startingPoint,
  });

  final String? practiceName;
  final PracticeSize? practiceSize;
  final Set<OnboardingPriority> priorities;
  final WorkspaceStartingPoint? startingPoint;

  OnboardingAnswers copyWith({
    String? practiceName,
    PracticeSize? practiceSize,
    Set<OnboardingPriority>? priorities,
    WorkspaceStartingPoint? startingPoint,
  }) {
    return OnboardingAnswers(
      practiceName: practiceName ?? this.practiceName,
      practiceSize: practiceSize ?? this.practiceSize,
      priorities: priorities ?? this.priorities,
      startingPoint: startingPoint ?? this.startingPoint,
    );
  }
}

String practiceSizeWireValue(PracticeSize value) => switch (value) {
  PracticeSize.solo => 'solo',
  PracticeSize.smallTeam => 'small_team',
  PracticeSize.growingTeam => 'growing_team',
};

PracticeSize? practiceSizeFromWire(Object? value) => switch (value) {
  'solo' => PracticeSize.solo,
  'small_team' => PracticeSize.smallTeam,
  'growing_team' => PracticeSize.growingTeam,
  _ => null,
};

String priorityWireValue(OnboardingPriority value) => switch (value) {
  OnboardingPriority.deadlines => 'deadlines',
  OnboardingPriority.documents => 'documents',
  OnboardingPriority.teamwork => 'teamwork',
  OnboardingPriority.visibility => 'visibility',
};

OnboardingPriority? priorityFromWire(Object? value) => switch (value) {
  'deadlines' => OnboardingPriority.deadlines,
  'documents' => OnboardingPriority.documents,
  'teamwork' => OnboardingPriority.teamwork,
  'visibility' => OnboardingPriority.visibility,
  _ => null,
};

String startingPointWireValue(WorkspaceStartingPoint value) => switch (value) {
  WorkspaceStartingPoint.importClients => 'import_clients',
  WorkspaceStartingPoint.addFirstClient => 'add_first_client',
  WorkspaceStartingPoint.sampleWorkspace => 'sample_workspace',
};

WorkspaceStartingPoint? startingPointFromWire(Object? value) => switch (value) {
  'import_clients' => WorkspaceStartingPoint.importClients,
  'add_first_client' => WorkspaceStartingPoint.addFirstClient,
  'sample_workspace' => WorkspaceStartingPoint.sampleWorkspace,
  _ => null,
};

OnboardingStep? onboardingStepFromWire(Object? value) => switch (value) {
  'practice' => OnboardingStep.practice,
  'priorities' => OnboardingStep.priorities,
  'starting_point' => OnboardingStep.startingPoint,
  'ready_to_complete' => OnboardingStep.readyToComplete,
  _ => null,
};
