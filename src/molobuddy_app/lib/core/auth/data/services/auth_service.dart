import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_user.dart';

abstract interface class AuthService {
  AuthUser? get currentUser;

  /// Signs in with an email address and a password.
  ///
  /// [persistSession] says whether the session should outlive the window. Only
  /// Web can honour it: Android and iOS always persist, and an implementation
  /// there accepts the argument and ignores it rather than pretending to have a
  /// choice.
  Future<AuthResult<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
    required bool persistSession,
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
