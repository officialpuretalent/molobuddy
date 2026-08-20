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
  const PreviewSessionService(this._authService);

  final AuthService _authService;

  @override
  Future<AuthResult<MoloSession>> loadSession() async {
    final user = _authService.currentUser;
    if (user == null) {
      return const AuthError(AuthFailure(AuthFailureKind.configurationMissing));
    }
    return AuthSuccess(
      MoloSession(
        uid: user.id,
        displayName: user.displayName,
        emailMasked: maskEmail(user.email),
        // Preview has no practice directory to read, and inventing one would
        // put fictional practice names on screen.
        practiceRefs: const [],
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
