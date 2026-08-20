import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_service.dart';
import 'package:molobuddy_app/core/auth/data/services/session_service.dart';

/// Describes the session a preview build already knows about, without calling
/// the control API.
///
/// Preview exists so the product can be demonstrated with no backend. A
/// preview build has no identity token and no attestation, so asking the
/// server would only ever come back as `authentication_required`. Refusing to
/// answer at all was worse: it left the welcome screen showing an error the
/// user had no way to clear. So preview answers from the user it signed in,
/// in the same shape the server would have returned.
final class PreviewSessionService implements SessionService {
  PreviewSessionService(
    this._authService, {
    List<PracticeRef> Function()? practices,
  }) : _practices = practices ?? _none;

  final AuthService _authService;

  /// Whatever preview onboarding has founded in this run.
  ///
  /// Read through a function rather than held here, so this service stays a
  /// reader and preview onboarding stays the one place a preview practice
  /// comes into existence.
  final List<PracticeRef> Function() _practices;

  static List<PracticeRef> _none() => const [];

  @override
  Future<AuthResult<MoloSession>> loadSession() async {
    final user = _authService.currentUser;
    if (user == null) {
      return const AuthError(AuthFailure(AuthFailureKind.configurationMissing));
    }
    final practices = _practices();
    return AuthSuccess(
      MoloSession(
        uid: user.id,
        // Preview mirrors the server's rule from the data design: having a
        // practice settles it. Preview founds one only through onboarding, so
        // until then setup is genuinely outstanding.
        onboardingComplete: practices.isNotEmpty,
        displayName: user.displayName,
        emailMasked: maskEmail(user.email),
        practiceRefs: practices,
      ),
    );
  }

  /// Mirrors `maskEmail` in the server's get_session query, so preview shows
  /// the same masked address a real session would.
  static String? maskEmail(String email) {
    final separator = email.lastIndexOf('@');
    if (separator <= 0 || separator == email.length - 1) {
      return null;
    }
    final local = email.substring(0, separator);
    final domain = email.substring(separator + 1);
    return '${local.substring(0, 1)}***@$domain';
  }
}
