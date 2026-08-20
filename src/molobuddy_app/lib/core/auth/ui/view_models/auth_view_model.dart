import 'package:molobuddy_app/core/auth/auth_providers.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_user.dart';
import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';
import 'package:molobuddy_app/core/auth/data/repositories/auth_repository.dart';
import 'package:molobuddy_app/core/auth/ui/view_models/auth_view_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_view_model.g.dart';

@Riverpod(keepAlive: true)
class AuthViewModel extends _$AuthViewModel {
  /// Identifies the newest session load. Every guarded load takes the next
  /// number before it awaits, so a load that finishes can tell whether it is
  /// still the one whose answer the app is waiting for.
  int _sessionLoadGeneration = 0;

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
        final generation = ++_sessionLoadGeneration;
        final sessionResult = await _loadSessionSafely(repository);
        if (!ref.mounted) {
          return;
        }
        final afterSignIn = _sessionLoadStillOwnsState(generation);
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

  /// Adopts an account that has just been created.
  ///
  /// Creating an account signs that person in at the provider, so this model
  /// has to learn about it the same way it learns about a sign-in. Without
  /// this the app holds a signed-out session for a signed-in user, and every
  /// screen that reads the session waits forever for one that never loads.
  ///
  /// Settling is identical to an interactive sign-in, generation guard
  /// included, because it is the same thing happening for a different reason.
  Future<AuthResult<AuthUser>> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    // Registration can be reached before the first session load has settled,
    // so this waits rather than demanding a value that is not there yet.
    final current = switch (state) {
      AsyncData(:final value) => value,
      _ => await future,
    };
    state = AsyncData(
      current.copyWith(
        status: AuthViewStatus.authenticating,
        clearFailure: true,
      ),
    );

    final repository = ref.read(authRepositoryProvider);
    final result = await repository.createAccount(
      email: email,
      password: password,
      displayName: displayName,
    );
    if (!ref.mounted) {
      return result;
    }

    switch (result) {
      case AuthSuccess(:final value):
        state = AsyncData(
          current.copyWith(
            status: AuthViewStatus.loadingSession,
            user: value,
            clearFailure: true,
          ),
        );
        final generation = ++_sessionLoadGeneration;
        final sessionResult = await _loadSessionSafely(repository);
        if (!ref.mounted) {
          return result;
        }
        final afterCreate = _sessionLoadStillOwnsState(generation);
        if (afterCreate != null) {
          state = AsyncData(_settledWithSession(afterCreate, sessionResult));
        }
      case AuthError():
        state = AsyncData(current.copyWith(status: AuthViewStatus.signedOut));
    }
    return result;
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
    final generation = ++_sessionLoadGeneration;
    final sessionResult = await _loadSessionSafely(
      ref.read(authRepositoryProvider),
    );
    if (!ref.mounted) {
      return;
    }
    final loading = _sessionLoadStillOwnsState(generation);
    if (loading == null) {
      return;
    }
    state = AsyncData(_settledWithSession(loading, sessionResult));
  }

  /// The state the load numbered [generation] may settle onto, or `null` when
  /// it must abandon its answer.
  ///
  /// A load resolves into whatever the app has become in the meantime, so it
  /// re-reads rather than settling onto the snapshot it captured before the
  /// await. Two separate things can have moved on, and both are checked:
  ///
  /// * A newer load has started. Sign out stays enabled while a session
  ///   loads, so one user's load can still be hanging when the next user
  ///   signs in and begins their own. Status alone cannot tell those apart,
  ///   and letting the older one through wrote the first user's uid, masked
  ///   address and practice refs onto the second user's state, then discarded
  ///   the second user's own answer. Only the newest load may settle.
  /// * The app is no longer loading a session for a present user at all,
  ///   which is what a sign-out during a load leaves behind. Settling then
  ///   put the signed-out user back, signed in, after the router had already
  ///   navigated away.
  AuthViewState? _sessionLoadStillOwnsState(int generation) {
    if (generation != _sessionLoadGeneration) {
      return null;
    }
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
