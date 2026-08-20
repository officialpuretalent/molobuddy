import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_user.dart';

abstract interface class AuthService {
  AuthUser? get currentUser;

  Future<AuthResult<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Creates an account and signs that person in.
  ///
  /// [displayName] is set on the created user rather than left for later. The
  /// welcome screen greets by name and deliberately refuses to fall back to an
  /// email address, so an account created without one is greeted anonymously
  /// forever.
  Future<AuthResult<AuthUser>> createAccount({
    required String email,
    required String password,
    required String displayName,
  });

  Future<AuthResult<void>> signOut();
}
