// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Preview's onboarding, kept as its own provider.
///
/// The preview session service reads the practice this founded, so both need
/// the same instance. Reaching it through the general
/// [onboardingServiceProvider] would mean a cast, and would break the moment
/// preview stopped being the mode in use.

@ProviderFor(previewOnboardingService)
final previewOnboardingServiceProvider = PreviewOnboardingServiceProvider._();

/// Preview's onboarding, kept as its own provider.
///
/// The preview session service reads the practice this founded, so both need
/// the same instance. Reaching it through the general
/// [onboardingServiceProvider] would mean a cast, and would break the moment
/// preview stopped being the mode in use.

final class PreviewOnboardingServiceProvider
    extends
        $FunctionalProvider<
          PreviewOnboardingService,
          PreviewOnboardingService,
          PreviewOnboardingService
        >
    with $Provider<PreviewOnboardingService> {
  /// Preview's onboarding, kept as its own provider.
  ///
  /// The preview session service reads the practice this founded, so both need
  /// the same instance. Reaching it through the general
  /// [onboardingServiceProvider] would mean a cast, and would break the moment
  /// preview stopped being the mode in use.
  PreviewOnboardingServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'previewOnboardingServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$previewOnboardingServiceHash();

  @$internal
  @override
  $ProviderElement<PreviewOnboardingService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PreviewOnboardingService create(Ref ref) {
    return previewOnboardingService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PreviewOnboardingService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PreviewOnboardingService>(value),
    );
  }
}

String _$previewOnboardingServiceHash() =>
    r'3f5065c5bfb84cfe80ff17af039857bd0f3d5acc';

/// Reads and writes onboarding over the authenticated transport.
///
/// Mirrors `sessionServiceProvider`: preview answers from memory because
/// preview is a supported way to show the product with no backend, a Firebase
/// build with an API base URL calls the control API, and anything else has no
/// onboarding to read and says so.

@ProviderFor(onboardingService)
final onboardingServiceProvider = OnboardingServiceProvider._();

/// Reads and writes onboarding over the authenticated transport.
///
/// Mirrors `sessionServiceProvider`: preview answers from memory because
/// preview is a supported way to show the product with no backend, a Firebase
/// build with an API base URL calls the control API, and anything else has no
/// onboarding to read and says so.

final class OnboardingServiceProvider
    extends
        $FunctionalProvider<
          OnboardingService,
          OnboardingService,
          OnboardingService
        >
    with $Provider<OnboardingService> {
  /// Reads and writes onboarding over the authenticated transport.
  ///
  /// Mirrors `sessionServiceProvider`: preview answers from memory because
  /// preview is a supported way to show the product with no backend, a Firebase
  /// build with an API base URL calls the control API, and anything else has no
  /// onboarding to read and says so.
  OnboardingServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingServiceHash();

  @$internal
  @override
  $ProviderElement<OnboardingService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OnboardingService create(Ref ref) {
    return onboardingService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OnboardingService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OnboardingService>(value),
    );
  }
}

String _$onboardingServiceHash() => r'3c74cce73fc91664826f3e50e8e6e82d9c652ac3';
