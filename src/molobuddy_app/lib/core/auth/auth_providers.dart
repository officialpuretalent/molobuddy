import 'package:molobuddy_app/core/auth/data/repositories/auth_repository.dart';
import 'package:molobuddy_app/core/auth/data/repositories/default_auth_repository.dart';
import 'package:molobuddy_app/core/auth/data/services/app_check_gateway.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_provider_catalogue_service.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_service.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_token_broker.dart';
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

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return DefaultAuthRepository(
    ref.watch(authServiceProvider),
    ref.watch(authProviderCatalogueProvider),
  );
}
