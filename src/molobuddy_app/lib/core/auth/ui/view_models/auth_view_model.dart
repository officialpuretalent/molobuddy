import 'package:molobuddy_app/core/auth/auth_providers.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';
import 'package:molobuddy_app/core/auth/data/repositories/auth_repository.dart';
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

    final restored = switch (methodsResult) {
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

    if (currentUser == null) {
      return restored;
    }

    // Authentication does not imply authorisation, so a Firebase session
    // restored from persistence still asks the server who this is. Starting
    // the app must not depend on that answer, so a failure settles into state
    // instead of propagating, and it never displaces an earlier failure.
    return switch (await _loadSessionSafely(repository)) {
      AuthSuccess(:final value) => restored.copyWith(session: value),
      // The session slot always records what the session did. The general
      // slot still yields to an earlier catalogue failure, so the first thing
      // that went wrong is the one the rest of the app reports.
      AuthError(:final failure) => restored.copyWith(
        sessionFailure: failure,
        failure: restored.failure == null ? failure : null,
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
        final sessionResult = await _loadSessionSafely(repository);
        if (!ref.mounted) {
          return;
        }
        final afterSignIn = _sessionLoadStillOwnsState();
        if (afterSignIn == null) {
          return;
        }
        state = AsyncData(_settledWithSession(afterSignIn, sessionResult));
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
        clearSessionFailure: true,
      ),
      AuthError(:final failure) => current.copyWith(
        status: AuthViewStatus.signedIn,
        failure: failure,
      ),
    });
  }

  /// Asks the server for the Molo session again, for a user who is already
  /// signed in. This is the recovery path for a session that failed to load,
  /// and it settles exactly as an interactive sign-in does.
  Future<void> reloadSession() async {
    final current = switch (state) {
      AsyncData(:final value) => value,
      _ => null,
    };
    if (current == null ||
        current.user == null ||
        current.status == AuthViewStatus.loadingSession) {
      return;
    }

    state = AsyncData(
      current.copyWith(
        status: AuthViewStatus.loadingSession,
        clearFailure: true,
        clearSessionFailure: true,
      ),
    );
    final sessionResult = await _loadSessionSafely(
      ref.read(authRepositoryProvider),
    );
    if (!ref.mounted) {
      return;
    }
    final loading = _sessionLoadStillOwnsState();
    if (loading == null) {
      return;
    }
    state = AsyncData(_settledWithSession(loading, sessionResult));
  }

  /// The state a finished session load is allowed to settle onto, or `null`
  /// when it no longer owns the state and must abandon its answer.
  ///
  /// A load resolves into whatever the app has become in the meantime, so it
  /// must re-read rather than settle onto the snapshot it captured before the
  /// await. Sign out stays enabled while a session loads, and settling onto
  /// the old snapshot rewrote state to signed in with the signed-out user
  /// restored, after the router had already navigated away. Anything that is
  /// no longer a session load for a present user, including a sign-out or a
  /// newer load, means this answer is stale.
  AuthViewState? _sessionLoadStillOwnsState() {
    final current = switch (state) {
      AsyncData(:final value) => value,
      _ => null,
    };
    if (current == null ||
        current.status != AuthViewStatus.loadingSession ||
        current.user == null) {
      return null;
    }
    return current;
  }

  void clearFailure() {
    state = AsyncData(state.requireValue.copyWith(clearFailure: true));
  }

  /// A session load must never throw into the view. An adapter that breaks its
  /// contract becomes an ordinary unexpected failure.
  static Future<AuthResult<MoloSession>> _loadSessionSafely(
    AuthRepository repository,
  ) async {
    try {
      return await repository.loadSession();
    } on Object {
      return const AuthError(AuthFailure(AuthFailureKind.unexpected));
    }
  }

  static AuthViewState _settledWithSession(
    AuthViewState base,
    AuthResult<MoloSession> result,
  ) {
    return switch (result) {
      AuthSuccess(:final value) => base.copyWith(
        status: AuthViewStatus.signedIn,
        session: value,
        clearFailure: true,
        clearSessionFailure: true,
      ),
      AuthError(:final failure) => base.copyWith(
        status: AuthViewStatus.signedIn,
        clearSession: true,
        failure: failure,
        sessionFailure: failure,
      ),
    };
  }

  static bool _looksLikeEmail(String value) {
    final separator = value.indexOf('@');
    return separator > 0 &&
        separator < value.length - 3 &&
        value.indexOf('.', separator) > separator + 1;
  }
}
