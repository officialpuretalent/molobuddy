import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:molobuddy_app/core/auth/data/services/app_check_gateway.dart';

/// Firebase-backed application attestation.
///
/// The vendor SDK is contained here. Everything else in the app depends on
/// [AppCheckGateway], so App Check can be replaced or disabled without
/// touching a feature.
final class FirebaseAppCheckGateway implements AppCheckGateway {
  FirebaseAppCheckGateway._(this._appCheck);

  final FirebaseAppCheck _appCheck;

  /// Activates attestation and returns a gateway, or [UnavailableAppCheckGateway]
  /// when activation fails.
  ///
  /// Activation must happen after Firebase initialisation and before any
  /// protected service is used. Failing to attest is never fatal: the request
  /// still carries identity and the server decides.
  static Future<AppCheckGateway> activate({
    required FirebaseApp app,
    required bool useDebugProvider,
    String? recaptchaSiteKey,
  }) async {
    if (!useDebugProvider &&
        (recaptchaSiteKey == null || recaptchaSiteKey.isEmpty)) {
      return const UnavailableAppCheckGateway();
    }

    final appCheck = FirebaseAppCheck.instanceFor(app: app);
    try {
      await appCheck.activate(
        providerWeb: useDebugProvider
            ? ReCaptchaV3Provider('app-check-debug-token')
            : ReCaptchaV3Provider(recaptchaSiteKey!),
        providerAndroid: useDebugProvider
            ? AndroidDebugProvider()
            : AndroidPlayIntegrityProvider(),
        providerApple: useDebugProvider
            ? AppleDebugProvider()
            : AppleAppAttestProvider(),
      );
    } on Object catch (error) {
      // Swallowing this silently turned a configuration mistake into an
      // unexplained "This device could not be verified." on every request.
      // The reason belongs in the log even though the failure is not fatal.
      if (kDebugMode) {
        debugPrint('Molo: App Check activation failed. $error');
      }
      return const UnavailableAppCheckGateway();
    }
    return FirebaseAppCheckGateway._(appCheck);
  }

  @override
  Future<String?> token({bool forceRefresh = false}) async {
    try {
      return await _appCheck.getToken(forceRefresh);
    } on Object {
      // Attestation is best effort. Surfacing the provider error here would
      // leak vendor detail and turn a recoverable state into a hard failure.
      return null;
    }
  }
}
