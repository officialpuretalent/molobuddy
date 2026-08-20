import 'package:molobuddy_app/core/auth/auth_providers.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/ui/view_models/auth_view_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_view_model.g.dart';

@Riverpod(keepAlive: true)
class AuthViewModel extends _$AuthViewModel {
  @override
  Future<AuthViewState> build() async {
    final repository = ref.watch(authRepositoryProvider);
    final methodsResult = await repository.loadMethods();
    final currentUser = repository.currentUser;

    return switch (methodsResult) {
      AuthSuccess(:final value) => AuthViewState(
        status: currentUser == null
            ? AuthViewStatus.signedOut
            : AuthViewStatus.signedIn,
        methods: value,
        user: currentUser,
      ),
      AuthError(:final failure) => AuthViewState(
        status: currentUser == null
            ? AuthViewStatus.signedOut
            : AuthViewStatus.signedIn,
        methods: const [],
        user: currentUser,
        failure: failure,
      ),
    };
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final current = state.requireValue;
    final normalisedEmail = email.trim();
    final emailInvalid = !_looksLikeEmail(normalisedEmail);
    final passwordTooShort = password.length < 8;
    if (emailInvalid || passwordTooShort) {
      state = AsyncData(
        current.copyWith(
          clearFailure: true,
          emailInvalid: emailInvalid,
          passwordTooShort: passwordTooShort,
        ),
      );
      return;
    }

    state = AsyncData(
      current.copyWith(
        status: AuthViewStatus.authenticating,
        clearFailure: true,
        emailInvalid: false,
        passwordTooShort: false,
      ),
    );

    final repository = ref.read(authRepositoryProvider);
    final result = await repository.signInWithEmailAndPassword(
      email: normalisedEmail,
      password: password,
    );
    if (!ref.mounted) {
      return;
    }
    switch (result) {
      case AuthSuccess(:final value):
        state = AsyncData(
          current.copyWith(
            status: AuthViewStatus.loadingSession,
            user: value,
            clearFailure: true,
            emailInvalid: false,
            passwordTooShort: false,
          ),
        );
        final afterSignIn = state.requireValue;
        final sessionResult = await repository.loadSession();
        if (!ref.mounted) {
          return;
        }
        state = AsyncData(switch (sessionResult) {
          AuthSuccess(:final value) => afterSignIn.copyWith(
            status: AuthViewStatus.signedIn,
            session: value,
            clearFailure: true,
          ),
          AuthError(:final failure) => afterSignIn.copyWith(
            status: AuthViewStatus.signedIn,
            clearSession: true,
            failure: failure,
          ),
        });
      case AuthError(:final failure):
        state = AsyncData(
          current.copyWith(status: AuthViewStatus.signedOut, failure: failure),
        );
    }
  }

  Future<void> signOut() async {
    final current = state.requireValue;
    state = AsyncData(
      current.copyWith(status: AuthViewStatus.signingOut, clearFailure: true),
    );
    final result = await ref.read(authRepositoryProvider).signOut();
    if (!ref.mounted) {
      return;
    }
    state = AsyncData(switch (result) {
      AuthSuccess() => current.copyWith(
        status: AuthViewStatus.signedOut,
        clearUser: true,
        clearSession: true,
        clearFailure: true,
      ),
      AuthError(:final failure) => current.copyWith(
        status: AuthViewStatus.signedIn,
        failure: failure,
      ),
    });
  }

  void clearFailure() {
    state = AsyncData(state.requireValue.copyWith(clearFailure: true));
  }

  static bool _looksLikeEmail(String value) {
    final separator = value.indexOf('@');
    return separator > 0 &&
        separator < value.length - 3 &&
        value.indexOf('.', separator) > separator + 1;
  }
}
