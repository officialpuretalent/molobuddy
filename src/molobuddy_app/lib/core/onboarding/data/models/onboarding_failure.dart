enum OnboardingFailureKind {
  /// Somebody else saved first. The client must reload before writing again.
  versionConflict,

  /// An answer was refused. The pointer says which.
  answerRejected,

  /// Completion was asked for before every question was answered.
  incomplete,

  /// The session is not usable. Signing in again is the only recovery.
  sessionExpired,

  /// This device could not be verified.
  attestationRequired,

  networkUnavailable,

  /// This build has no API to call.
  configurationMissing,

  unexpected,
}

final class OnboardingFailure {
  const OnboardingFailure(this.kind, {this.pointer});

  final OnboardingFailureKind kind;

  /// The JSON pointer the server named, when it named one.
  final String? pointer;
}

sealed class OnboardingResult<T> {
  const OnboardingResult();
}

final class OnboardingSuccess<T> extends OnboardingResult<T> {
  const OnboardingSuccess(this.value);
  final T value;
}

final class OnboardingError<T> extends OnboardingResult<T> {
  const OnboardingError(this.failure);
  final OnboardingFailure failure;
}
