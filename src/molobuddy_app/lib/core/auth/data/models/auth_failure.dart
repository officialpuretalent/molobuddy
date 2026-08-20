enum AuthFailureKind {
  invalidCredentials,
  networkUnavailable,
  providerUnavailable,
  configurationMissing,
  attestationRequired,
  sessionExpired,

  /// The address already has an account. Only reported when the provider says
  /// so; email-enumeration protection may answer generically instead, which
  /// falls through to [unexpected] and neutral copy.
  emailAlreadyRegistered,

  /// The provider refused the password. Molo's own minimum is checked before
  /// this, so reaching it means the provider asked for more.
  passwordRejected,
  unexpected,
}

final class AuthFailure {
  const AuthFailure(this.kind);

  final AuthFailureKind kind;
}

sealed class AuthResult<T> {
  const AuthResult();
}

final class AuthSuccess<T> extends AuthResult<T> {
  const AuthSuccess(this.value);

  final T value;
}

final class AuthError<T> extends AuthResult<T> {
  const AuthError(this.failure);

  final AuthFailure failure;
}
