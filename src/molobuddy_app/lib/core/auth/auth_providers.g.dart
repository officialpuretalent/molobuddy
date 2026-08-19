// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authService)
final authServiceProvider = AuthServiceProvider._();

final class AuthServiceProvider
    extends $FunctionalProvider<AuthService, AuthService, AuthService>
    with $Provider<AuthService> {
  AuthServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authServiceHash();

  @$internal
  @override
  $ProviderElement<AuthService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthService create(Ref ref) {
    return authService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthService>(value),
    );
  }
}

String _$authServiceHash() => r'0573df2b9db12b5d0809ec13b91b8e3e1359408e';

@ProviderFor(authProviderCatalogue)
final authProviderCatalogueProvider = AuthProviderCatalogueProvider._();

final class AuthProviderCatalogueProvider
    extends
        $FunctionalProvider<
          AuthProviderCatalogueService,
          AuthProviderCatalogueService,
          AuthProviderCatalogueService
        >
    with $Provider<AuthProviderCatalogueService> {
  AuthProviderCatalogueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authProviderCatalogueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authProviderCatalogueHash();

  @$internal
  @override
  $ProviderElement<AuthProviderCatalogueService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AuthProviderCatalogueService create(Ref ref) {
    return authProviderCatalogue(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthProviderCatalogueService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthProviderCatalogueService>(value),
    );
  }
}

String _$authProviderCatalogueHash() =>
    r'24b56fd680ca0ce6500db9920eae1b897c93d3fd';

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'bdc5106097e8b4b1a508e45b674731724a35dd90';
