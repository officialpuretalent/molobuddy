import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:molobuddy_app/app/molo_app.dart';
import 'package:molobuddy_app/bootstrap/app_environment.dart';
import 'package:molobuddy_app/core/auth/auth_providers.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_provider_catalogue_service.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_service.dart';
import 'package:molobuddy_app/core/auth/data/services/firebase_auth_service.dart';
import 'package:molobuddy_app/core/auth/data/services/http_auth_provider_catalogue_service.dart';
import 'package:molobuddy_app/core/auth/data/services/preview_auth_service.dart';
import 'package:molobuddy_app/core/auth/data/services/unavailable_auth_service.dart';

Future<void> bootstrapMolo() async {
  WidgetsFlutterBinding.ensureInitialized();
  final environment = AppEnvironment.fromCompilation();
  final authService = await _createAuthService(environment);
  final providerCatalogue = _createProviderCatalogue(environment);

  runApp(
    ProviderScope(
      overrides: [
        appEnvironmentProvider.overrideWithValue(environment),
        authServiceProvider.overrideWithValue(authService),
        authProviderCatalogueProvider.overrideWithValue(providerCatalogue),
      ],
      child: const MoloApp(),
    ),
  );
}

Future<AuthService> _createAuthService(AppEnvironment environment) async {
  if (environment.authMode == AuthRuntimeMode.preview) {
    return PreviewAuthService();
  }
  final configuration = environment.firebaseConfiguration;
  if (environment.authMode != AuthRuntimeMode.firebase ||
      configuration == null) {
    return const UnavailableAuthService();
  }
  try {
    return await FirebaseAuthService.initialise(configuration);
  } on Object {
    return const UnavailableAuthService();
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
