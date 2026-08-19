import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'registration_view_model.g.dart';

enum RegistrationStep { account, practice, priorities, startingPoint, complete }

enum PracticeSize { solo, smallTeam, growingTeam }

enum RegistrationPriority { deadlines, documents, teamwork, visibility }

enum WorkspaceStartingPoint { importClients, addFirstClient, sampleWorkspace }

final class RegistrationViewState {
  const RegistrationViewState({
    this.step = RegistrationStep.account,
    this.displayName = '',
    this.email = '',
    this.practiceName = '',
    this.practiceSize = PracticeSize.solo,
    this.priorities = const {},
    this.startingPoint,
    this.nameInvalid = false,
    this.emailInvalid = false,
    this.passwordTooShort = false,
    this.termsNotAccepted = false,
    this.practiceNameInvalid = false,
    this.prioritiesInvalid = false,
    this.startingPointInvalid = false,
  });

  final RegistrationStep step;
  final String displayName;
  final String email;
  final String practiceName;
  final PracticeSize practiceSize;
  final Set<RegistrationPriority> priorities;
  final WorkspaceStartingPoint? startingPoint;
  final bool nameInvalid;
  final bool emailInvalid;
  final bool passwordTooShort;
  final bool termsNotAccepted;
  final bool practiceNameInvalid;
  final bool prioritiesInvalid;
  final bool startingPointInvalid;

  int get progressIndex => step.index.clamp(0, 3);

  int get readinessPercent => switch (step) {
    RegistrationStep.account => 12,
    RegistrationStep.practice => 32,
    RegistrationStep.priorities => 58,
    RegistrationStep.startingPoint => 82,
    RegistrationStep.complete => 100,
  };

  RegistrationViewState copyWith({
    RegistrationStep? step,
    String? displayName,
    String? email,
    String? practiceName,
    PracticeSize? practiceSize,
    Set<RegistrationPriority>? priorities,
    WorkspaceStartingPoint? startingPoint,
    bool clearStartingPoint = false,
    bool? nameInvalid,
    bool? emailInvalid,
    bool? passwordTooShort,
    bool? termsNotAccepted,
    bool? practiceNameInvalid,
    bool? prioritiesInvalid,
    bool? startingPointInvalid,
  }) {
    return RegistrationViewState(
      step: step ?? this.step,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      practiceName: practiceName ?? this.practiceName,
      practiceSize: practiceSize ?? this.practiceSize,
      priorities: priorities ?? this.priorities,
      startingPoint: clearStartingPoint
          ? null
          : startingPoint ?? this.startingPoint,
      nameInvalid: nameInvalid ?? this.nameInvalid,
      emailInvalid: emailInvalid ?? this.emailInvalid,
      passwordTooShort: passwordTooShort ?? this.passwordTooShort,
      termsNotAccepted: termsNotAccepted ?? this.termsNotAccepted,
      practiceNameInvalid: practiceNameInvalid ?? this.practiceNameInvalid,
      prioritiesInvalid: prioritiesInvalid ?? this.prioritiesInvalid,
      startingPointInvalid: startingPointInvalid ?? this.startingPointInvalid,
    );
  }
}

@riverpod
class RegistrationViewModel extends _$RegistrationViewModel {
  @override
  RegistrationViewState build() => const RegistrationViewState();

  bool continueFromAccount({
    required String displayName,
    required String email,
    required String password,
    required bool acceptedTerms,
  }) {
    final cleanName = displayName.trim();
    final cleanEmail = email.trim().toLowerCase();
    final nameInvalid = cleanName.length < 2;
    final emailInvalid = !_looksLikeEmail(cleanEmail);
    final passwordTooShort = password.length < 8;
    final termsNotAccepted = !acceptedTerms;
    state = state.copyWith(
      displayName: cleanName,
      email: cleanEmail,
      nameInvalid: nameInvalid,
      emailInvalid: emailInvalid,
      passwordTooShort: passwordTooShort,
      termsNotAccepted: termsNotAccepted,
      step: nameInvalid || emailInvalid || passwordTooShort || termsNotAccepted
          ? RegistrationStep.account
          : RegistrationStep.practice,
    );
    return !(nameInvalid ||
        emailInvalid ||
        passwordTooShort ||
        termsNotAccepted);
  }

  bool continueFromPractice({required String practiceName}) {
    final cleanName = practiceName.trim();
    final invalid = cleanName.length < 2;
    state = state.copyWith(
      practiceName: cleanName,
      practiceNameInvalid: invalid,
      step: invalid ? RegistrationStep.practice : RegistrationStep.priorities,
    );
    return !invalid;
  }

  void selectPracticeSize(PracticeSize size) {
    state = state.copyWith(practiceSize: size);
  }

  void updatePracticeNamePreview(String value) {
    state = state.copyWith(
      practiceName: value.trim(),
      practiceNameInvalid: false,
    );
  }

  void togglePriority(RegistrationPriority priority) {
    final priorities = {...state.priorities};
    if (!priorities.add(priority)) {
      priorities.remove(priority);
    }
    state = state.copyWith(
      priorities: Set.unmodifiable(priorities),
      prioritiesInvalid: false,
    );
  }

  bool continueFromPriorities() {
    if (state.priorities.isEmpty) {
      state = state.copyWith(prioritiesInvalid: true);
      return false;
    }
    state = state.copyWith(
      step: RegistrationStep.startingPoint,
      prioritiesInvalid: false,
    );
    return true;
  }

  void selectStartingPoint(WorkspaceStartingPoint startingPoint) {
    state = state.copyWith(
      startingPoint: startingPoint,
      startingPointInvalid: false,
    );
  }

  bool completePreview() {
    if (state.startingPoint == null) {
      state = state.copyWith(startingPointInvalid: true);
      return false;
    }
    state = state.copyWith(
      step: RegistrationStep.complete,
      startingPointInvalid: false,
    );
    return true;
  }

  void goBack() {
    final previous = switch (state.step) {
      RegistrationStep.account => RegistrationStep.account,
      RegistrationStep.practice => RegistrationStep.account,
      RegistrationStep.priorities => RegistrationStep.practice,
      RegistrationStep.startingPoint => RegistrationStep.priorities,
      RegistrationStep.complete => RegistrationStep.startingPoint,
    };
    state = state.copyWith(step: previous);
  }

  static bool _looksLikeEmail(String value) {
    final separator = value.indexOf('@');
    return separator > 0 &&
        separator < value.length - 3 &&
        value.indexOf('.', separator) > separator + 1;
  }
}
