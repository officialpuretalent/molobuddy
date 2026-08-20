import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_method_descriptor.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_user.dart';
import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';

enum AuthViewStatus {
  signedOut,
  authenticating,
  loadingSession,
  signedIn,
  signingOut,
}

final class AuthViewState {
  const AuthViewState({
    required this.status,
    required this.methods,
    this.user,
    this.session,
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
       user = null,
       session = null;

  final AuthViewStatus status;
  final List<AuthMethodDescriptor> methods;
  final AuthUser? user;
  final MoloSession? session;
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
    MoloSession? session,
    bool clearSession = false,
    AuthFailure? failure,
    bool clearFailure = false,
    bool? emailInvalid,
    bool? passwordTooShort,
  }) {
    return AuthViewState(
      status: status ?? this.status,
      methods: methods ?? this.methods,
      user: clearUser ? null : user ?? this.user,
      session: clearSession ? null : session ?? this.session,
      failure: clearFailure ? null : failure ?? this.failure,
      emailInvalid: emailInvalid ?? this.emailInvalid,
      passwordTooShort: passwordTooShort ?? this.passwordTooShort,
    );
  }
}
