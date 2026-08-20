// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'registration_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RegistrationViewModel)
final registrationViewModelProvider = RegistrationViewModelProvider._();

final class RegistrationViewModelProvider
    extends $NotifierProvider<RegistrationViewModel, RegistrationViewState> {
  RegistrationViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'registrationViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$registrationViewModelHash();

  @$internal
  @override
  RegistrationViewModel create() => RegistrationViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RegistrationViewState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RegistrationViewState>(value),
    );
  }
}

String _$registrationViewModelHash() =>
    r'd4a08cdeb187ab1f85a25797f3e4d9eb5636c00e';

abstract class _$RegistrationViewModel
    extends $Notifier<RegistrationViewState> {
  RegistrationViewState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RegistrationViewState, RegistrationViewState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RegistrationViewState, RegistrationViewState>,
              RegistrationViewState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
