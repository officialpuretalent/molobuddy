import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_method_descriptor.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_user.dart';

abstract interface class AuthRepository {
  AuthUser? get currentUser;

  Future<AuthResult<List<AuthMethodDescriptor>>> loadMethods();

  Future<AuthResult<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<AuthResult<void>> signOut();
}
