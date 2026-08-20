enum AuthFailureKind {
  invalidCredentials,
  networkUnavailable,
  providerUnavailable,
  configurationMissing,
  attestationRequired,
  sessionExpired,
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
