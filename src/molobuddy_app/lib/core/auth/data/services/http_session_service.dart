import 'package:dio/dio.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';
import 'package:molobuddy_app/core/auth/data/services/session_service.dart';

final class HttpSessionService implements SessionService {
  factory HttpSessionService({required Dio dio, required String baseUrl}) {
    return HttpSessionService._(dio, baseUrl.replaceFirst(RegExp(r'/$'), ''));
  }

  HttpSessionService._(this._dio, this._baseUrl);

  final Dio _dio;
  final String _baseUrl;

  @override
  Future<AuthResult<MoloSession>> loadSession() async {
    try {
      final response = await _dio.get<Object>(
        '$_baseUrl/v1/session',
        options: Options(
          validateStatus: (_) => true,
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      final status = response.statusCode ?? 0;
      if (status != 200) {
        return AuthError(AuthFailure(_failureForProblem(response.data)));
      }

      final session = _parseSession(response.data);
      if (session == null) {
        return const AuthError(AuthFailure(AuthFailureKind.unexpected));
      }
      return AuthSuccess(session);
    } on DioException {
      return const AuthError(AuthFailure(AuthFailureKind.networkUnavailable));
    } on FormatException {
      return const AuthError(AuthFailure(AuthFailureKind.unexpected));
    }
  }

  static AuthFailureKind _failureForProblem(Object? body) {
    final code = body is Map<String, dynamic> ? body['code'] : null;
    return switch (code) {
      'app_check_required' => AuthFailureKind.attestationRequired,
      'token_invalid' => AuthFailureKind.sessionExpired,
      'authentication_required' => AuthFailureKind.sessionExpired,
      _ => AuthFailureKind.unexpected,
    };
  }

  static MoloSession? _parseSession(Object? body) {
    if (body is! Map<String, dynamic>) {
      return null;
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      return null;
    }
    final user = data['user'];
    if (user is! Map<String, dynamic>) {
      return null;
    }
    final uid = user['uid'];
    if (uid is! String || uid.isEmpty) {
      return null;
    }

    // Anything that is not in_progress reads as complete, so an unknown future
    // status can never lock a user into the wizard.
    final onboarding = data['onboarding'];
    final onboardingComplete =
        onboarding is! Map<String, dynamic> ||
        onboarding['status'] != 'in_progress';

    final refs = data['practiceRefs'];
    return MoloSession(
      onboardingComplete: onboardingComplete,
      uid: uid,
      displayName: _optionalString(user['displayName']),
      emailMasked: _optionalString(user['emailMasked']),
      preferredLocale: _optionalString(user['preferredLocale']),
      practiceRefs: refs is List
          ? refs
                .whereType<Map<String, dynamic>>()
                .map(_parsePractice)
                .nonNulls
                .toList()
          : const [],
    );
  }

  static PracticeRef? _parsePractice(Map<String, dynamic> raw) {
    final practiceId = raw['practiceId'];
    final displayLabel = raw['displayLabel'];
    final homeRegionKey = raw['homeRegionKey'];
    // The server schema makes routeVersion required. Inventing route state is
    // worse than dropping a practice we cannot address, so an absent or
    // non-integer value rejects the reference.
    final routeVersion = raw['routeVersion'];
    if (practiceId is! String ||
        displayLabel is! String ||
        homeRegionKey is! String ||
        routeVersion is! int) {
      return null;
    }
    return PracticeRef(
      practiceId: practiceId,
      displayLabel: displayLabel,
      homeRegionKey: homeRegionKey,
      routeVersion: routeVersion,
      accessStatus: switch (raw['accessStatus']) {
        'active' => PracticeAccessStatus.active,
        'invited' => PracticeAccessStatus.invited,
        _ => PracticeAccessStatus.suspended,
      },
    );
  }

  static String? _optionalString(Object? value) {
    return value is String && value.isNotEmpty ? value : null;
  }
}
