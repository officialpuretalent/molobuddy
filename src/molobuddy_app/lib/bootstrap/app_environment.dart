import 'package:flutter/foundation.dart';
import 'package:molobuddy_app/core/auth/data/models/firebase_public_configuration.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_environment.g.dart';

enum AuthRuntimeMode { preview, firebase, unavailable }

final class AppEnvironment {
  const AppEnvironment({
    required this.authMode,
    required this.apiBaseUrl,
    required this.firebaseConfiguration,
    this.appCheckRecaptchaSiteKey,
    this.useAppCheckDebugProvider = false,
  });

  factory AppEnvironment.fromCompilation() {
    const requestedMode = String.fromEnvironment(
      'MOLO_AUTH_MODE',
      defaultValue: 'preview',
    );
    const configuredApiBaseUrl = String.fromEnvironment('MOLO_API_BASE_URL');

    final authMode = switch (requestedMode) {
      'firebase' => AuthRuntimeMode.firebase,
      'preview' when kDebugMode => AuthRuntimeMode.preview,
      _ => AuthRuntimeMode.unavailable,
    };

    final apiBaseUrl = configuredApiBaseUrl.trim().isEmpty
        ? (authMode == AuthRuntimeMode.preview ? 'http://localhost:8080' : null)
        : configuredApiBaseUrl.trim();

    const recaptchaSiteKey = String.fromEnvironment(
      'MOLO_APP_CHECK_RECAPTCHA_SITE_KEY',
    );
    const debugAttestation = bool.fromEnvironment('MOLO_APP_CHECK_DEBUG');

    return AppEnvironment(
      authMode: authMode,
      apiBaseUrl: apiBaseUrl,
      firebaseConfiguration: _firebaseConfigurationFromCompilation(),
      appCheckRecaptchaSiteKey: recaptchaSiteKey.trim().isEmpty
          ? null
          : recaptchaSiteKey.trim(),
      // A debug attestation must never ship in a release build, whatever the
      // define says.
      useAppCheckDebugProvider: debugAttestation && kDebugMode,
    );
  }

  final AuthRuntimeMode authMode;
  final String? apiBaseUrl;
  final FirebasePublicConfiguration? firebaseConfiguration;

  /// reCAPTCHA site key for web attestation. Absent until App Check is
  /// configured, which leaves the app unattested rather than guessing a key.
  final String? appCheckRecaptchaSiteKey;

  /// Debug attestation, for local development only. Never true in release.
  final bool useAppCheckDebugProvider;

  bool get isPreview => authMode == AuthRuntimeMode.preview;

  /// Whether this build can attest at all. Without either a site key or the
  /// debug provider there is nothing to activate.
  bool get canAttestApplication {
    return authMode == AuthRuntimeMode.firebase &&
        firebaseConfiguration != null &&
        (useAppCheckDebugProvider ||
            (appCheckRecaptchaSiteKey?.isNotEmpty ?? false));
  }

  bool get canAttemptAuthentication {
    return isPreview ||
        (authMode == AuthRuntimeMode.firebase && firebaseConfiguration != null);
  }

  static FirebasePublicConfiguration? _firebaseConfigurationFromCompilation() {
    const apiKey = String.fromEnvironment('MOLO_FIREBASE_API_KEY');
    const appId = String.fromEnvironment('MOLO_FIREBASE_APP_ID');
    const senderId = String.fromEnvironment('MOLO_FIREBASE_SENDER_ID');
    const projectId = String.fromEnvironment('MOLO_FIREBASE_PROJECT_ID');
    const authDomain = String.fromEnvironment('MOLO_FIREBASE_AUTH_DOMAIN');

    if ([apiKey, appId, senderId, projectId].any((value) => value.isEmpty)) {
      return null;
    }
    return FirebasePublicConfiguration(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: senderId,
      projectId: projectId,
      authDomain: authDomain.isEmpty ? null : authDomain,
    );
  }
}

@Riverpod(keepAlive: true)
AppEnvironment appEnvironment(Ref ref) {
  throw StateError('AppEnvironment must be provided during bootstrap.');
}
