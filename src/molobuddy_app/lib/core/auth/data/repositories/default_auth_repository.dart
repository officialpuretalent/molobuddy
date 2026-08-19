import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_method_descriptor.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_user.dart';
import 'package:molobuddy_app/core/auth/data/repositories/auth_repository.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_provider_catalogue_service.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_service.dart';

final class DefaultAuthRepository implements AuthRepository {
  const DefaultAuthRepository(this._authService, this._providerCatalogue);

  final AuthService _authService;
  final AuthProviderCatalogueService _providerCatalogue;

  @override
  AuthUser? get currentUser => _authService.currentUser;

  @override
  Future<AuthResult<List<AuthMethodDescriptor>>> loadMethods() {
    return _providerCatalogue.loadProviders();
  }

  @override
  Future<AuthResult<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<AuthResult<void>> signOut() => _authService.signOut();
}
