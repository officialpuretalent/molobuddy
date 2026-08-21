import 'package:molobuddy_app/core/auth/data/services/app_check_debug_token_stub.dart'
    if (dart.library.js_interop) 'package:molobuddy_app/core/auth/data/services/app_check_debug_token_web.dart';

/// What to publish as the Firebase App Check debug token.
///
/// A configured token is pinned, so it can be safelisted once and then attest
/// from any browser profile. With nothing configured the Firebase SDK is asked
/// to mint a token per profile and print it, which is the behaviour this
/// repository had when the value lived in `web/index.html`.
///
/// The fallback matters: web debug attestation activates with a placeholder
/// site key that only works because the SDK is in debug mode. Leaving the
/// global unset would activate that placeholder for real and fail every
/// attestation.
Object appCheckDebugTokenGlobal(String? configuredToken) {
  final token = configuredToken?.trim() ?? '';
  return token.isEmpty ? true : token;
}

/// Publishes the debug token for the platforms that read one from the page.
///
/// Safe to call anywhere: off the web it does nothing.
void pinAppCheckDebugToken(String? configuredToken) {
  assignAppCheckDebugToken(appCheckDebugTokenGlobal(configuredToken));
}
