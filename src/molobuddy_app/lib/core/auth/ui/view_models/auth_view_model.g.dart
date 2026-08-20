// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AuthViewModel)
final authViewModelProvider = AuthViewModelProvider._();

final class AuthViewModelProvider
    extends $AsyncNotifierProvider<AuthViewModel, AuthViewState> {
  AuthViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authViewModelHash();

  @$internal
  @override
  AuthViewModel create() => AuthViewModel();
}

String _$authViewModelHash() => r'3e7def7f148bf06e98f5187998175114b4232735';

abstract class _$AuthViewModel extends $AsyncNotifier<AuthViewState> {
  FutureOr<AuthViewState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AuthViewState>, AuthViewState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AuthViewState>, AuthViewState>,
              AsyncValue<AuthViewState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
