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
}

final class _StubSessionService implements SessionService {
  @override
  Future<AuthResult<MoloSession>> loadSession() async {
    return const AuthSuccess(MoloSession(uid: 'user_1', practiceRefs: []));
  }
}

final class _StubAuthService implements AuthService {
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
