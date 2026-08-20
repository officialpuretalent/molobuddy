import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_method_descriptor.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_user.dart';
import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';

abstract interface class AuthRepository {
  AuthUser? get currentUser;

  Future<AuthResult<List<AuthMethodDescriptor>>> loadMethods();

  Future<AuthResult<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Creates an account and signs that person in.
  Future<AuthResult<AuthUser>> createAccount({
    required String email,
    required String password,
    required String displayName,
  });

  Future<AuthResult<void>> signOut();

  /// Reloads Molo's own session. Authentication does not imply authorisation,
  /// so this runs even when Firebase restored the user from persistence.
  Future<AuthResult<MoloSession>> loadSession();
}
