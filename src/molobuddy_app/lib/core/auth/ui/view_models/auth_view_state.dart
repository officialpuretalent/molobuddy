import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_method_descriptor.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_user.dart';

enum AuthViewStatus { signedOut, authenticating, signedIn, signingOut }

final class AuthViewState {
  const AuthViewState({
    required this.status,
    required this.methods,
    this.user,
    this.failure,
    this.emailInvalid = false,
    this.passwordTooShort = false,
  });

  const AuthViewState.signedOut({
    this.methods = const [],
    this.failure,
    this.emailInvalid = false,
    this.passwordTooShort = false,
  }) : status = AuthViewStatus.signedOut,
       user = null;

  final AuthViewStatus status;
  final List<AuthMethodDescriptor> methods;
  final AuthUser? user;
  final AuthFailure? failure;
  final bool emailInvalid;
  final bool passwordTooShort;

  bool get isBusy {
    return status == AuthViewStatus.authenticating ||
        status == AuthViewStatus.signingOut;
  }

  AuthViewState copyWith({
    AuthViewStatus? status,
    List<AuthMethodDescriptor>? methods,
    AuthUser? user,
    bool clearUser = false,
    AuthFailure? failure,
    bool clearFailure = false,
    bool? emailInvalid,
    bool? passwordTooShort,
  }) {
    return AuthViewState(
      status: status ?? this.status,
      methods: methods ?? this.methods,
      user: clearUser ? null : user ?? this.user,
      failure: clearFailure ? null : failure ?? this.failure,
      emailInvalid: emailInvalid ?? this.emailInvalid,
      passwordTooShort: passwordTooShort ?? this.passwordTooShort,
    );
  }
}
