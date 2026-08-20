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

/// Raw identity tokens. Only the authenticated transport may read this.

@ProviderFor(authTokenBroker)
final authTokenBrokerProvider = AuthTokenBrokerProvider._();

/// Raw identity tokens. Only the authenticated transport may read this.

final class AuthTokenBrokerProvider
    extends
        $FunctionalProvider<AuthTokenBroker, AuthTokenBroker, AuthTokenBroker>
    with $Provider<AuthTokenBroker> {
  /// Raw identity tokens. Only the authenticated transport may read this.
  AuthTokenBrokerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authTokenBrokerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authTokenBrokerHash();

  @$internal
  @override
  $ProviderElement<AuthTokenBroker> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthTokenBroker create(Ref ref) {
    return authTokenBroker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthTokenBroker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthTokenBroker>(value),
    );
  }
}

String _$authTokenBrokerHash() => r'cbe19122a1441f8c0cadec93164d97f09570dcfa';

/// Application attestation. Only the authenticated transport may read this.

@ProviderFor(appCheckGateway)
final appCheckGatewayProvider = AppCheckGatewayProvider._();

/// Application attestation. Only the authenticated transport may read this.

final class AppCheckGatewayProvider
    extends
        $FunctionalProvider<AppCheckGateway, AppCheckGateway, AppCheckGateway>
    with $Provider<AppCheckGateway> {
  /// Application attestation. Only the authenticated transport may read this.
  AppCheckGatewayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appCheckGatewayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appCheckGatewayHash();

  @$internal
  @override
  $ProviderElement<AppCheckGateway> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppCheckGateway create(Ref ref) {
    return appCheckGateway(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppCheckGateway value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppCheckGateway>(value),
    );
  }
}

String _$appCheckGatewayHash() => r'b26c2e9d942f141f50806614e11108845537cf2a';

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

/// Loads Molo's own session over the authenticated transport.
///
/// Only a build that runs a real Firebase identity and knows an API base URL
/// calls the control API. A preview build has no token broker and no
/// attestation, so calling could only ever return `authentication_required`,
/// which the user cannot recover from by signing in again. Preview describes
/// its own demo session instead, because preview is a supported way to show
/// the product without a backend. Everything else has no session to describe
/// and says so.

@ProviderFor(sessionService)
final sessionServiceProvider = SessionServiceProvider._();

/// Loads Molo's own session over the authenticated transport.
///
/// Only a build that runs a real Firebase identity and knows an API base URL
/// calls the control API. A preview build has no token broker and no
/// attestation, so calling could only ever return `authentication_required`,
/// which the user cannot recover from by signing in again. Preview describes
/// its own demo session instead, because preview is a supported way to show
/// the product without a backend. Everything else has no session to describe
/// and says so.

final class SessionServiceProvider
    extends $FunctionalProvider<SessionService, SessionService, SessionService>
    with $Provider<SessionService> {
  /// Loads Molo's own session over the authenticated transport.
  ///
  /// Only a build that runs a real Firebase identity and knows an API base URL
  /// calls the control API. A preview build has no token broker and no
  /// attestation, so calling could only ever return `authentication_required`,
  /// which the user cannot recover from by signing in again. Preview describes
  /// its own demo session instead, because preview is a supported way to show
  /// the product without a backend. Everything else has no session to describe
  /// and says so.
  SessionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionServiceHash();

  @$internal
  @override
  $ProviderElement<SessionService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SessionService create(Ref ref) {
    return sessionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionService>(value),
    );
  }
}

String _$sessionServiceHash() => r'748d33ee2ca74ccef5d6573deaf465742510d221';

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

String _$authRepositoryHash() => r'c193a887a6733b3ccd63668cf412c3662d911369';
