import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_method_descriptor.dart';

abstract interface class AuthProviderCatalogueService {
  Future<AuthResult<List<AuthMethodDescriptor>>> loadProviders();
}

final class BundledPreviewAuthProviderCatalogueService
    implements AuthProviderCatalogueService {
  const BundledPreviewAuthProviderCatalogueService();

  @override
  Future<AuthResult<List<AuthMethodDescriptor>>> loadProviders() async {
    return const AuthSuccess([
      AuthMethodDescriptor.emailPassword,
      AuthMethodDescriptor.googleComingSoon,
    ]);
  }
}

final class UnavailableAuthProviderCatalogueService
    implements AuthProviderCatalogueService {
  const UnavailableAuthProviderCatalogueService();

  @override
  Future<AuthResult<List<AuthMethodDescriptor>>> loadProviders() async {
    return const AuthError(AuthFailure(AuthFailureKind.configurationMissing));
  }
}
