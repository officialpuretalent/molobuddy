/// Molo-owned view of application attestation.
///
/// Features never see this type. Only the authenticated transport reads the
/// token, so no feature state, log or URL can carry it.
abstract interface class AppCheckGateway {
  /// The current attestation token, or `null` when this build cannot attest.
  ///
  /// Tokens are cached and outlive many requests, so a token that lapses
  /// mid-session keeps being handed out until somebody insists otherwise.
  /// Pass [forceRefresh] only after the server has refused one, never on
  /// every request: minting is a network round trip to the attestation
  /// provider.
  Future<String?> token({bool forceRefresh = false});
}

/// Used wherever attestation is not configured, such as preview builds.
///
/// Returning `null` keeps App Check failure distinct from authentication
/// failure: the request still carries identity, and the server decides.
final class UnavailableAppCheckGateway implements AppCheckGateway {
  const UnavailableAppCheckGateway();

  @override
  Future<String?> token({bool forceRefresh = false}) async => null;
}
