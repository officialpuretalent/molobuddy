import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_user.dart';
import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';
import 'package:molobuddy_app/core/auth/data/repositories/default_auth_repository.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_provider_catalogue_service.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_service.dart';
import 'package:molobuddy_app/core/auth/data/services/session_service.dart';

void main() {
  test('the repository passes the session straight through', () async {
    final repository = DefaultAuthRepository(
      _StubAuthService(),
      const BundledPreviewAuthProviderCatalogueService(),
      _StubSessionService(),
    );

    final result = await repository.loadSession();

    expect((result as AuthSuccess<MoloSession>).value.uid, 'user_1');
  });

  test('the repository passes account creation through unchanged', () async {
    final service = _RecordingAuthService();
    final repository = DefaultAuthRepository(
      service,
      const BundledPreviewAuthProviderCatalogueService(),
      _StubSessionService(),
    );

    await repository.createAccount(
      email: 'thando@example.com',
      password: 'safe-preview-password',
      displayName: 'Thando Mokoena',
    );

    expect(service.calls, [
      ('thando@example.com', 'safe-preview-password', 'Thando Mokoena'),
    ]);
  });
}

final class _RecordingAuthService implements AuthService {
  final List<(String, String, String)> calls = [];

  @override
  Future<AuthResult<AuthUser>> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    calls.add((email, password, displayName));
    return AuthSuccess(AuthUser(id: 'user_1', email: email));
  }

  @override
  AuthUser? get currentUser => null;

  @override
  Future<AuthResult<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError('signInWithEmailAndPassword');
  }

  @override
  Future<AuthResult<void>> signOut() async {
    throw UnimplementedError('signOut');
  }
}

final class _StubSessionService implements SessionService {
  @override
  Future<AuthResult<MoloSession>> loadSession() async {
    return const AuthSuccess(MoloSession(uid: 'user_1', practiceRefs: []));
  }
}

final class _StubAuthService implements AuthService {
  @override
  Future<AuthResult<AuthUser>> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    // Not part of what this fake exists to prove. Throwing keeps an accidental
    // call visible rather than letting it quietly succeed.
    throw UnimplementedError('createAccount');
  }

  @override
  AuthUser? get currentUser => null;

  @override
  Future<AuthResult<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async => const AuthError(AuthFailure(AuthFailureKind.unexpected));

  @override
  Future<AuthResult<void>> signOut() async => const AuthSuccess(null);
}
