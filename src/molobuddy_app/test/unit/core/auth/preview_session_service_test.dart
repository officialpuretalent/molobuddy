import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_user.dart';
import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_service.dart';
import 'package:molobuddy_app/core/auth/data/services/preview_session_service.dart';

void main() {
  test('a preview session describes the signed-in preview user', () async {
    const service = PreviewSessionService(
      _StaticAuthService(
        AuthUser(
          id: 'preview-1',
          email: 'thandi@example.com',
          displayName: 'Thandi Mokoena',
        ),
      ),
    );

    final result = await service.loadSession();

    expect(result, isA<AuthSuccess<MoloSession>>());
    final session = (result as AuthSuccess<MoloSession>).value;
    expect(session.uid, 'preview-1');
    expect(session.displayName, 'Thandi Mokoena');
    // The same shape the server returns, so preview never shows an address
    // the real build would have masked.
    expect(session.emailMasked, 't***@example.com');
    expect(session.practiceRefs, isEmpty);
    expect(session.hasPractices, isFalse);
  });

  test('a preview session masks the address the way the server does', () async {
    // Mirrors maskEmail in the server's get_session query: first character,
    // then three stars, then the domain after the last separator.
    const cases = <String, String?>{
      'thandi@example.com': 't***@example.com',
      'a@b.co': 'a***@b.co',
      'first.last+tag@sub.example.co.za': 'f***@sub.example.co.za',
      'odd@name@example.com': 'o***@example.com',
      'not-an-email': null,
      '@example.com': null,
      'trailing@': null,
    };

    for (final entry in cases.entries) {
      const id = 'preview-1';
      final service = PreviewSessionService(
        _StaticAuthService(AuthUser(id: id, email: entry.key)),
      );

      final result = await service.loadSession();

      expect(result, isA<AuthSuccess<MoloSession>>(), reason: entry.key);
      expect(
        (result as AuthSuccess<MoloSession>).value.emailMasked,
        entry.value,
        reason: entry.key,
      );
    }
  });

  test(
    'a preview build with nobody signed in has no session to show',
    () async {
      const service = PreviewSessionService(_StaticAuthService(null));

      final result = await service.loadSession();

      expect(result, isA<AuthError<MoloSession>>());
      expect(
        (result as AuthError<MoloSession>).failure.kind,
        AuthFailureKind.configurationMissing,
      );
    },
  );
}

final class _StaticAuthService implements AuthService {
  const _StaticAuthService(this.currentUser);

  @override
  final AuthUser? currentUser;

  @override
  Future<AuthResult<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw UnsupportedError('not used by the session service');
  }

  @override
  Future<AuthResult<void>> signOut() async {
    throw UnsupportedError('not used by the session service');
  }
}
