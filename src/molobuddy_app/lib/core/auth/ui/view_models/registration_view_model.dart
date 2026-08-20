import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/ui/view_models/auth_view_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'registration_view_model.g.dart';

/// The account step, and only the account step.
///
/// Everything after it is persisted server-side and lives in
/// `OnboardingViewModel`. Splitting them is what lets an interrupted signup
/// resume: wizard state that only exists in memory cannot survive a closed
/// tab, and an account either exists or it does not.
final class RegistrationViewState {
  const RegistrationViewState({
    this.displayName = '',
    this.email = '',
    this.submitting = false,
    this.nameInvalid = false,
    this.emailInvalid = false,
    this.passwordTooShort = false,
    this.termsNotAccepted = false,
    this.emailAlreadyRegistered = false,
    this.failure,
  });

  final String displayName;
  final String email;

  /// A request is in flight. The button is disabled while it is, so a double
  /// tap cannot create two accounts.
  final bool submitting;

  final bool nameInvalid;
  final bool emailInvalid;
  final bool passwordTooShort;
  final bool termsNotAccepted;

  /// Shown on the email field rather than as a form-level error, because it is
  /// a fact about that field. Only ever set when the provider actually says so.
  final bool emailAlreadyRegistered;

  /// Anything the provider refused that no single field explains.
  final AuthFailure? failure;

  RegistrationViewState copyWith({
    String? displayName,
    String? email,
    bool? submitting,
    bool? nameInvalid,
    bool? emailInvalid,
    bool? passwordTooShort,
    bool? termsNotAccepted,
    bool? emailAlreadyRegistered,
    AuthFailure? failure,
    bool clearFailure = false,
  }) {
    return RegistrationViewState(
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      submitting: submitting ?? this.submitting,
      nameInvalid: nameInvalid ?? this.nameInvalid,
      emailInvalid: emailInvalid ?? this.emailInvalid,
      passwordTooShort: passwordTooShort ?? this.passwordTooShort,
      termsNotAccepted: termsNotAccepted ?? this.termsNotAccepted,
      emailAlreadyRegistered:
          emailAlreadyRegistered ?? this.emailAlreadyRegistered,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}

@riverpod
class RegistrationViewModel extends _$RegistrationViewModel {
  @override
  RegistrationViewState build() => const RegistrationViewState();

  /// Creates the account, and reports whether the caller may navigate on.
  ///
  /// Navigation is the view's job, not this model's; returning a bool keeps
  /// the model testable without a widget tree.
  Future<bool> createAccount({
    required String displayName,
    required String email,
    required String password,
    required bool acceptedTerms,
  }) async {
    if (state.submitting) {
      return false;
    }

    final cleanName = displayName.trim();
    final cleanEmail = email.trim().toLowerCase();
    final nameInvalid = cleanName.length < 2;
    final emailInvalid = !_looksLikeEmail(cleanEmail);
    final passwordTooShort = password.length < 8;
    final termsNotAccepted = !acceptedTerms;
    state = state.copyWith(
      displayName: cleanName,
      email: cleanEmail,
      nameInvalid: nameInvalid,
      emailInvalid: emailInvalid,
      passwordTooShort: passwordTooShort,
      termsNotAccepted: termsNotAccepted,
      emailAlreadyRegistered: false,
      clearFailure: true,
    );
    if (nameInvalid || emailInvalid || passwordTooShort || termsNotAccepted) {
      return false;
    }

    state = state.copyWith(submitting: true);
    // Through the auth view model rather than the repository, so the model
    // that owns "who is signed in" learns about the new account. Going
    // straight to the repository left the app holding a signed-out session
    // for a signed-in user.
    final result = await ref
        .read(authViewModelProvider.notifier)
        .createAccount(
          email: cleanEmail,
          password: password,
          displayName: cleanName,
        );
    if (!ref.mounted) {
      return false;
    }

    switch (result) {
      case AuthSuccess():
        state = state.copyWith(submitting: false, clearFailure: true);
        return true;
      case AuthError(:final failure):
        state = state.copyWith(
          submitting: false,
          // Each of these is a fact about one field, so it is reported there.
          // Everything else, including a provider that declines to say an
          // address is taken, becomes a neutral form-level message.
          emailAlreadyRegistered:
              failure.kind == AuthFailureKind.emailAlreadyRegistered,
          emailInvalid: failure.kind == AuthFailureKind.invalidCredentials,
          passwordTooShort: failure.kind == AuthFailureKind.passwordRejected,
          failure:
              failure.kind == AuthFailureKind.emailAlreadyRegistered ||
                  failure.kind == AuthFailureKind.invalidCredentials ||
                  failure.kind == AuthFailureKind.passwordRejected
              ? null
              : failure,
        );
        return false;
    }
  }

  static bool _looksLikeEmail(String value) {
    final separator = value.indexOf('@');
    return separator > 0 &&
        separator < value.length - 3 &&
        value.indexOf('.', separator) > separator + 1;
  }
}
