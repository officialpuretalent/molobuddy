import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';

abstract interface class SessionService {
  Future<AuthResult<MoloSession>> loadSession();
}

/// Used when no API base URL is configured, such as preview builds.
final class UnavailableSessionService implements SessionService {
  const UnavailableSessionService();

  @override
  Future<AuthResult<MoloSession>> loadSession() async {
    return const AuthError(AuthFailure(AuthFailureKind.configurationMissing));
  }
}
