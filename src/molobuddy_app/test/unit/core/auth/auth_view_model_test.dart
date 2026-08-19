import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/core/auth/auth_providers.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_method_descriptor.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_user.dart';
import 'package:molobuddy_app/core/auth/data/repositories/auth_repository.dart';
import 'package:molobuddy_app/core/auth/ui/view_models/auth_view_model.dart';
import 'package:molobuddy_app/core/auth/ui/view_models/auth_view_state.dart';

void main() {
  test('validates email and password before calling the repository', () async {
    final repository = _FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(authViewModelProvider.future);

    await container
        .read(authViewModelProvider.notifier)
        .signInWithEmailAndPassword(email: 'not-an-email', password: 'short');

    final state = container.read(authViewModelProvider).requireValue;
    expect(state.emailInvalid, isTrue);
    expect(state.passwordTooShort, isTrue);
    expect(repository.signInCalls, 0);
  });

  test('publishes the signed-in Molo user after repository success', () async {
    final repository = _FakeAuthRepository();
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
    expect(state.user?.email, 'person@example.com');
    expect(repository.signInCalls, 1);
  });
}

final class _FakeAuthRepository implements AuthRepository {
  int signInCalls = 0;
  AuthUser? _currentUser;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<AuthResult<List<AuthMethodDescriptor>>> loadMethods() async {
    return const AuthSuccess([
      AuthMethodDescriptor.emailPassword,
      AuthMethodDescriptor.googleComingSoon,
    ]);
  }

  @override
  Future<AuthResult<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    signInCalls += 1;
    _currentUser = AuthUser(id: 'user-1', email: email);
    return AuthSuccess(_currentUser!);
  }

  @override
  Future<AuthResult<void>> signOut() async {
    _currentUser = null;
    return const AuthSuccess(null);
  }
}
