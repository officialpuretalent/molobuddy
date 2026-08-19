/// Molo-owned access to the raw identity token.
///
/// This is the only supported way to obtain an ID token, and only the
/// authenticated transport may use it. Features consume session models
/// instead, so a raw token cannot reach feature state, logs or a URL.
abstract interface class AuthTokenBroker {
  /// The current ID token, or `null` when nobody is signed in.
  ///
  /// The Firebase SDK owns refresh and persistence. Pass [forceRefresh] only
  /// after a token-expiry response, never on every request.
  Future<String?> idToken({bool forceRefresh = false});
}

/// Used wherever identity is not configured, such as preview builds.
final class UnavailableAuthTokenBroker implements AuthTokenBroker {
  const UnavailableAuthTokenBroker();

  @override
  Future<String?> idToken({bool forceRefresh = false}) async => null;
}
