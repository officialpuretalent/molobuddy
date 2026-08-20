import 'package:molobuddy_app/bootstrap/app_environment.dart';
import 'package:molobuddy_app/core/auth/data/repositories/auth_repository.dart';
import 'package:molobuddy_app/core/auth/data/repositories/default_auth_repository.dart';
import 'package:molobuddy_app/core/auth/data/services/app_check_gateway.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_provider_catalogue_service.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_service.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_token_broker.dart';
import 'package:molobuddy_app/core/auth/data/services/http_session_service.dart';
import 'package:molobuddy_app/core/auth/data/services/session_service.dart';
import 'package:molobuddy_app/core/network/network_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthService authService(Ref ref) {
  throw StateError('AuthService must be provided during bootstrap.');
}

/// Raw identity tokens. Only the authenticated transport may read this.
@Riverpod(keepAlive: true)
AuthTokenBroker authTokenBroker(Ref ref) {
  throw StateError('AuthTokenBroker must be provided during bootstrap.');
}

/// Application attestation. Only the authenticated transport may read this.
@Riverpod(keepAlive: true)
AppCheckGateway appCheckGateway(Ref ref) {
  throw StateError('AppCheckGateway must be provided during bootstrap.');
}

@Riverpod(keepAlive: true)
AuthProviderCatalogueService authProviderCatalogue(Ref ref) {
  throw StateError(
    'AuthProviderCatalogueService must be provided during bootstrap.',
  );
}

/// Loads Molo's own session over the authenticated transport. Falls back to
/// [UnavailableSessionService] when no API base URL is configured, such as
/// preview builds.
@Riverpod(keepAlive: true)
SessionService sessionService(Ref ref) {
  final baseUrl = ref.watch(appEnvironmentProvider).apiBaseUrl;
  if (baseUrl == null) {
    return const UnavailableSessionService();
  }
  return HttpSessionService(
    dio: ref.watch(authenticatedDioProvider),
    baseUrl: baseUrl,
  );
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return DefaultAuthRepository(
    ref.watch(authServiceProvider),
    ref.watch(authProviderCatalogueProvider),
    ref.watch(sessionServiceProvider),
  );
}
