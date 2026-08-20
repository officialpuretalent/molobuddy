// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The one HTTP client that carries Molo's identity and attestation tokens.
///
/// Anything calling an authenticated Molo endpoint uses this, so tokens are
/// attached in exactly one place.

@ProviderFor(authenticatedDio)
final authenticatedDioProvider = AuthenticatedDioProvider._();

/// The one HTTP client that carries Molo's identity and attestation tokens.
///
/// Anything calling an authenticated Molo endpoint uses this, so tokens are
/// attached in exactly one place.

final class AuthenticatedDioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// The one HTTP client that carries Molo's identity and attestation tokens.
  ///
  /// Anything calling an authenticated Molo endpoint uses this, so tokens are
  /// attached in exactly one place.
  AuthenticatedDioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authenticatedDioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authenticatedDioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return authenticatedDio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$authenticatedDioHash() => r'd7588611fac4fe6956b709d6b371a105b5eb402c';
