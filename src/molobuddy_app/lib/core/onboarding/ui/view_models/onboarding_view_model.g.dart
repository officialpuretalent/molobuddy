// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives the part of signup that happens after the account exists.
///
/// Deliberately `keepAlive`. The idempotency key must outlive a widget
/// rebuild: an auto-disposed model would mint a new one when the tree
/// rebuilt, and a retry would then found a second practice.

@ProviderFor(OnboardingViewModel)
final onboardingViewModelProvider = OnboardingViewModelProvider._();

/// Drives the part of signup that happens after the account exists.
///
/// Deliberately `keepAlive`. The idempotency key must outlive a widget
/// rebuild: an auto-disposed model would mint a new one when the tree
/// rebuilt, and a retry would then found a second practice.
final class OnboardingViewModelProvider
    extends $AsyncNotifierProvider<OnboardingViewModel, OnboardingViewState> {
  /// Drives the part of signup that happens after the account exists.
  ///
  /// Deliberately `keepAlive`. The idempotency key must outlive a widget
  /// rebuild: an auto-disposed model would mint a new one when the tree
  /// rebuilt, and a retry would then found a second practice.
  OnboardingViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingViewModelHash();

  @$internal
  @override
  OnboardingViewModel create() => OnboardingViewModel();
}

String _$onboardingViewModelHash() =>
    r'3f9979c563fab2451a23ee575f80140c5ec35fdf';

/// Drives the part of signup that happens after the account exists.
///
/// Deliberately `keepAlive`. The idempotency key must outlive a widget
/// rebuild: an auto-disposed model would mint a new one when the tree
/// rebuilt, and a retry would then found a second practice.

abstract class _$OnboardingViewModel
    extends $AsyncNotifier<OnboardingViewState> {
  FutureOr<OnboardingViewState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<OnboardingViewState>, OnboardingViewState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<OnboardingViewState>, OnboardingViewState>,
              AsyncValue<OnboardingViewState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
