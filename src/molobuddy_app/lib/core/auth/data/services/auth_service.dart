import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_user.dart';

abstract interface class AuthService {
  AuthUser? get currentUser;

  Future<AuthResult<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<AuthResult<void>> signOut();
}
