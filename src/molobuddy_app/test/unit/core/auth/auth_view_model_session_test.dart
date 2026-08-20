import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/core/auth/auth_providers.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_method_descriptor.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_user.dart';
import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';
import 'package:molobuddy_app/core/auth/data/repositories/auth_repository.dart';
import 'package:molobuddy_app/core/auth/ui/view_models/auth_view_model.dart';
import 'package:molobuddy_app/core/auth/ui/view_models/auth_view_state.dart';

void main() {
  test(
    'a successful sign-in loads the session before becoming ready',
    () async {
      final repository = _FakeSessionRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await container.read(authViewModelProvider.future);

      final seen = <AuthViewStatus>[];
      container.listen(authViewModelProvider, (previous, next) {
        final value = next.value;
        if (value != null) {
          seen.add(value.status);
        }
      });

      await container
          .read(authViewModelProvider.notifier)
          .signInWithEmailAndPassword(
            email: 'person@example.com',
            password: 'safe-password',
          );

      final state = container.read(authViewModelProvider).requireValue;
      expect(seen, contains(AuthViewStatus.loadingSession));
      expect(state.status, AuthViewStatus.signedIn);
      expect(state.session?.uid, 'user_1');
      expect(repository.loadSessionCalls, 1);
    },
  );

  test(
    'an attestation failure surfaces without signing the user out',
    () async {
      final repository = _FakeSessionRepository(
        sessionResult: const AuthError(
          AuthFailure(AuthFailureKind.attestationRequired),
        ),
      );
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await container.read(authViewModelProvider.future);

      await container
          .read(authViewModelProvider.notifier)
          .signInWithEmailAndPassword(
            email: 'person@example.com',
            password: 'safe-password',
          );

      final state = container.read(authViewModelProvider).requireValue;
      expect(state.status, AuthViewStatus.signedIn);
      expect(state.session, isNull);
      expect(state.failure?.kind, AuthFailureKind.attestationRequired);
    },
  );

  test('a later failure clears the session it used to hold', () async {
    final repository = _FakeSessionRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(authViewModelProvider.future);
    final notifier = container.read(authViewModelProvider.notifier);

    await notifier.signInWithEmailAndPassword(
      email: 'person@example.com',
      password: 'safe-password',
    );
    expect(
      container.read(authViewModelProvider).requireValue.session?.uid,
      'user_1',
      reason: 'the first sign-in must actually put a session in state',
    );

    repository.sessionResult = const AuthError(
      AuthFailure(AuthFailureKind.sessionExpired),
    );
    await notifier.signInWithEmailAndPassword(
      email: 'person@example.com',
      password: 'safe-password',
    );

    final state = container.read(authViewModelProvider).requireValue;
    expect(state.session, isNull);
    expect(state.failure?.kind, AuthFailureKind.sessionExpired);
  });

  test('a restored Firebase session still reloads the Molo session', () async {
    final repository = _FakeSessionRepository(
      restoredUser: const AuthUser(id: 'user_1', email: 'person@example.com'),
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final state = await container.read(authViewModelProvider.future);

    expect(repository.loadSessionCalls, 1);
    expect(state.status, AuthViewStatus.signedIn);
    expect(state.session?.uid, 'user_1');
  });

  test(
    'a session failure during restore never stops the app starting',
    () async {
      final repository = _FakeSessionRepository(
        restoredUser: const AuthUser(id: 'user_1', email: 'person@example.com'),
        sessionResult: const AuthError(
          AuthFailure(AuthFailureKind.networkUnavailable),
        ),
      );
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final state = await container.read(authViewModelProvider.future);

      expect(state.status, AuthViewStatus.signedIn);
      expect(state.user?.email, 'person@example.com');
      expect(state.session, isNull);
      expect(state.failure?.kind, AuthFailureKind.networkUnavailable);
    },
  );

  test('retrying asks the repository again and clears the failure', () async {
    final repository = _FakeSessionRepository(
      restoredUser: const AuthUser(id: 'user_1', email: 'person@example.com'),
      sessionResult: const AuthError(
        AuthFailure(AuthFailureKind.networkUnavailable),
      ),
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(authViewModelProvider.future);
    expect(repository.loadSessionCalls, 1);

    final seen = <AuthViewStatus>[];
    container.listen(authViewModelProvider, (previous, next) {
      final value = next.value;
      if (value != null) {
        seen.add(value.status);
      }
    });

    repository.sessionResult = const AuthSuccess(
      MoloSession(uid: 'user_1', practiceRefs: []),
    );
    await container.read(authViewModelProvider.notifier).reloadSession();

    final state = container.read(authViewModelProvider).requireValue;
    expect(repository.loadSessionCalls, 2);
    expect(seen, contains(AuthViewStatus.loadingSession));
    expect(state.status, AuthViewStatus.signedIn);
    expect(state.session?.uid, 'user_1');
    expect(state.failure, isNull);
    expect(state.sessionFailure, isNull);
  });

  test('a provider catalogue failure is not a session failure', () async {
    // The catalogue and the session fail independently. Reporting a good
    // session as broken because the method list did not load hides a
    // workspace the user can actually reach, and offers a retry that reloads
    // the wrong thing.
    final repository = _FakeSessionRepository(
      restoredUser: const AuthUser(id: 'user_1', email: 'person@example.com'),
      methodsResult: const AuthError(
        AuthFailure(AuthFailureKind.providerUnavailable),
      ),
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final state = await container.read(authViewModelProvider.future);

    expect(state.status, AuthViewStatus.signedIn);
    expect(state.session?.uid, 'user_1');
    expect(state.failure?.kind, AuthFailureKind.providerUnavailable);
    expect(state.sessionFailure, isNull);
  });

  test('a session failure lands in the session slot', () async {
    final repository = _FakeSessionRepository(
      restoredUser: const AuthUser(id: 'user_1', email: 'person@example.com'),
      sessionResult: const AuthError(
        AuthFailure(AuthFailureKind.networkUnavailable),
      ),
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final state = await container.read(authViewModelProvider.future);

    expect(state.sessionFailure?.kind, AuthFailureKind.networkUnavailable);
  });

  test('signing out clears the session failure it was showing', () async {
    final repository = _FakeSessionRepository(
      restoredUser: const AuthUser(id: 'user_1', email: 'person@example.com'),
      sessionResult: const AuthError(
        AuthFailure(AuthFailureKind.networkUnavailable),
      ),
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(authViewModelProvider.future);
    expect(
      container.read(authViewModelProvider).requireValue.sessionFailure,
      isNotNull,
      reason: 'the failure must actually be set before sign-out clears it',
    );

    await container.read(authViewModelProvider.notifier).signOut();

    final state = container.read(authViewModelProvider).requireValue;
    expect(state.status, AuthViewStatus.signedOut);
    expect(state.sessionFailure, isNull);
  });

  test('a reload in flight cannot undo a sign-out that beat it', () async {
    // Sign out stays enabled while a session loads, so Retry then Sign out
    // leaves a reload running against a user who has gone. Settling it onto
    // the snapshot taken before the await put that user back, signed in,
    // after the router had already navigated to sign-in.
    final repository = _FakeSessionRepository(
      restoredUser: const AuthUser(id: 'user_1', email: 'person@example.com'),
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(authViewModelProvider.future);
    final notifier = container.read(authViewModelProvider.notifier);

    final gate = Completer<void>();
    repository.gate = gate;
    final reload = notifier.reloadSession();
    expect(
      container.read(authViewModelProvider).requireValue.status,
      AuthViewStatus.loadingSession,
      reason: 'the reload must actually be in flight for this to be a race',
    );

    await notifier.signOut();
    expect(
      container.read(authViewModelProvider).requireValue.status,
      AuthViewStatus.signedOut,
    );

    gate.complete();
    await reload;

    final state = container.read(authViewModelProvider).requireValue;
    expect(state.status, AuthViewStatus.signedOut);
    expect(state.user, isNull);
    expect(state.session, isNull);
  });
}

final class _FakeSessionRepository implements AuthRepository {
  _FakeSessionRepository({
    this.sessionResult = const AuthSuccess(
      MoloSession(uid: 'user_1', practiceRefs: []),
    ),
    this.methodsResult = const AuthSuccess(<AuthMethodDescriptor>[]),
    AuthUser? restoredUser,
  }) : _currentUser = restoredUser;

  /// The provider catalogue fails independently of the session, which is the
  /// whole point of keeping the two failures in separate slots.
  AuthResult<List<AuthMethodDescriptor>> methodsResult;

  /// When set, a session load blocks until the test completes it.
  Completer<void>? gate;

  /// Mutable, so a test can succeed once and then fail, which is the only way
  /// to prove a session is actually cleared rather than never set.
  AuthResult<MoloSession> sessionResult;
  int loadSessionCalls = 0;
  AuthUser? _currentUser;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<AuthResult<List<AuthMethodDescriptor>>> loadMethods() async {
    return methodsResult;
  }

  @override
  Future<AuthResult<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _currentUser = AuthUser(id: 'user_1', email: email);
    return AuthSuccess(_currentUser!);
  }

  @override
  Future<AuthResult<void>> signOut() async {
    _currentUser = null;
    return const AuthSuccess(null);
  }

  @override
  Future<AuthResult<MoloSession>> loadSession() async {
    loadSessionCalls += 1;
    // Holds the load open so a test can act while it is still in flight.
    await gate?.future;
    return sessionResult;
  }
}
