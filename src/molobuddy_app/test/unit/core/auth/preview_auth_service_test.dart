import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_user.dart';
import 'package:molobuddy_app/core/auth/data/services/preview_auth_service.dart';

void main() {
  test(
    'creating an account signs that person in under their own name',
    () async {
      final service = PreviewAuthService.forTesting(debugAllowed: true);

      final result = await service.createAccount(
        email: '  Thando.Mokoena@Example.com ',
        password: 'safe-preview-password',
        displayName: '  Thando Mokoena  ',
      );

      expect(result, isA<AuthSuccess<AuthUser>>());
      final user = (result as AuthSuccess<AuthUser>).value;
      expect(user.email, 'thando.mokoena@example.com');
      expect(user.displayName, 'Thando Mokoena');
      expect(service.currentUser, user);
    },
  );

  test('refuses the same address twice', () async {
    final service = PreviewAuthService.forTesting(debugAllowed: true);
    await service.createAccount(
      email: 'thando@example.com',
      password: 'safe-preview-password',
      displayName: 'Thando Mokoena',
    );
    await service.signOut();

    final again = await service.createAccount(
      email: 'thando@example.com',
      password: 'safe-preview-password',
      displayName: 'Thando Mokoena',
    );

    expect(
      (again as AuthError<AuthUser>).failure.kind,
      AuthFailureKind.emailAlreadyRegistered,
    );
  });

  test('refuses a password the real provider would refuse', () async {
    final service = PreviewAuthService.forTesting(debugAllowed: true);

    final result = await service.createAccount(
      email: 'thando@example.com',
      password: 'short',
      displayName: 'Thando Mokoena',
    );

    expect(
      (result as AuthError<AuthUser>).failure.kind,
      AuthFailureKind.passwordRejected,
    );
  });

  test('refuses to create anything in a release build', () async {
    final service = PreviewAuthService.forTesting(debugAllowed: false);

    final result = await service.createAccount(
      email: 'thando@example.com',
      password: 'safe-preview-password',
      displayName: 'Thando Mokoena',
    );

    expect(
      (result as AuthError<AuthUser>).failure.kind,
      AuthFailureKind.configurationMissing,
    );
  });
}
