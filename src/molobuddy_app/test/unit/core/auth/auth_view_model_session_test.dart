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
}

final class _FakeSessionRepository implements AuthRepository {
  _FakeSessionRepository({
    this.sessionResult = const AuthSuccess(
      MoloSession(uid: 'user_1', practiceRefs: []),
    ),
  });

  final AuthResult<MoloSession> sessionResult;
  int loadSessionCalls = 0;
  AuthUser? _currentUser;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<AuthResult<List<AuthMethodDescriptor>>> loadMethods() async {
    return const AuthSuccess(<AuthMethodDescriptor>[]);
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
    return sessionResult;
  }
}
