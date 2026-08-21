import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:molobuddy_app/app/molo_app.dart';
import 'package:molobuddy_app/bootstrap/app_environment.dart';
import 'package:molobuddy_app/core/auth/auth_providers.dart';
import 'package:molobuddy_app/core/auth/data/services/app_check_debug_token.dart';
import 'package:molobuddy_app/core/auth/data/services/app_check_gateway.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_provider_catalogue_service.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_service.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_token_broker.dart';
import 'package:molobuddy_app/core/auth/data/services/firebase_app_check_service.dart';
import 'package:molobuddy_app/core/auth/data/services/firebase_auth_service.dart';
import 'package:molobuddy_app/core/auth/data/services/http_auth_provider_catalogue_service.dart';
import 'package:molobuddy_app/core/auth/data/services/preview_auth_service.dart';
import 'package:molobuddy_app/core/auth/data/services/unavailable_auth_service.dart';

Future<void> bootstrapMolo() async {
  WidgetsFlutterBinding.ensureInitialized();
  final environment = AppEnvironment.fromCompilation();
  final identity = await _createIdentity(environment);
  final providerCatalogue = _createProviderCatalogue(environment);

  runApp(
    ProviderScope(
      overrides: [
        appEnvironmentProvider.overrideWithValue(environment),
        authServiceProvider.overrideWithValue(identity.authService),
        authTokenBrokerProvider.overrideWithValue(identity.tokenBroker),
        appCheckGatewayProvider.overrideWithValue(identity.appCheckGateway),
        authProviderCatalogueProvider.overrideWithValue(providerCatalogue),
      ],
      child: const MoloApp(),
    ),
  );
}

/// What one identity runtime resolves to: the sign-in service plus the two
/// token sources the authenticated transport needs.
typedef _Identity = ({
  AuthService authService,
  AuthTokenBroker tokenBroker,
  AppCheckGateway appCheckGateway,
});

const _unavailableIdentity = (
  authService: UnavailableAuthService(),
  tokenBroker: UnavailableAuthTokenBroker(),
  appCheckGateway: UnavailableAppCheckGateway(),
);

Future<_Identity> _createIdentity(AppEnvironment environment) async {
  if (environment.authMode == AuthRuntimeMode.preview) {
    return (
      authService: PreviewAuthService(),
      tokenBroker: const UnavailableAuthTokenBroker(),
      appCheckGateway: const UnavailableAppCheckGateway(),
    );
  }

  final configuration = environment.firebaseConfiguration;
  if (environment.authMode != AuthRuntimeMode.firebase ||
      configuration == null) {
    return _unavailableIdentity;
  }

  // The debug token must be published before Firebase initialises. The App
  // Check JavaScript module reads the global as it loads, which happens inside
  // Firebase.initializeApp; setting it after activation is too late, and the
  // SDK then falls back to reCAPTCHA with a placeholder site key and fails
  // every attestation with `appCheck/recaptcha-error`.
  if (environment.useAppCheckDebugProvider) {
    pinAppCheckDebugToken(environment.appCheckDebugToken);
  }

  try {
    final authService = await FirebaseAuthService.initialise(configuration);
    // Attestation is activated after Firebase initialisation and before any
    // protected service is used, and never blocks start-up when it fails.
    final appCheckGateway = environment.canAttestApplication
        ? await FirebaseAppCheckGateway.activate(
            app: authService.app,
            useDebugProvider: environment.useAppCheckDebugProvider,
            recaptchaSiteKey: environment.appCheckRecaptchaSiteKey,
          )
        : const UnavailableAppCheckGateway();

    return (
      authService: authService,
      tokenBroker: authService.tokenBroker,
      appCheckGateway: appCheckGateway,
    );
  } on Object {
    return _unavailableIdentity;
  }
}

AuthProviderCatalogueService _createProviderCatalogue(
  AppEnvironment environment,
) {
  final previewFallback = environment.isPreview
      ? const BundledPreviewAuthProviderCatalogueService()
      : null;
  final apiBaseUrl = environment.apiBaseUrl;
  if (apiBaseUrl == null) {
    return previewFallback ?? const UnavailableAuthProviderCatalogueService();
  }
  return HttpAuthProviderCatalogueService(
    dio: Dio(
      BaseOptions(
        headers: const {'accept': 'application/json'},
        connectTimeout: const Duration(seconds: 5),
      ),
    ),
    baseUrl: apiBaseUrl,
    offlineFallback: previewFallback,
  );
}
