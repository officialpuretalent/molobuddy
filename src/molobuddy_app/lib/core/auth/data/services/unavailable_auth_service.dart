import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_user.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_service.dart';

final class UnavailableAuthService implements AuthService {
  const UnavailableAuthService();

  @override
  AuthUser? get currentUser => null;

  @override
  Future<AuthResult<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return const AuthError(AuthFailure(AuthFailureKind.configurationMissing));
  }

  @override
  Future<AuthResult<void>> signOut() async {
    return const AuthError(AuthFailure(AuthFailureKind.configurationMissing));
  }
}
