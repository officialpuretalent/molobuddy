import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/repositories/default_auth_repository.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_provider_catalogue_service.dart';
import 'package:molobuddy_app/core/auth/data/services/preview_auth_service.dart';

void main() {
  test(
    'preview repository signs in and clears its session on sign-out',
    () async {
      final service = PreviewAuthService.forTesting(debugAllowed: true);
      final repository = DefaultAuthRepository(
        service,
        const BundledPreviewAuthProviderCatalogueService(),
      );

      final signIn = await repository.signInWithEmailAndPassword(
        email: 'Thando.Mokoena@example.com ',
        password: 'safe-preview-password',
      );

      expect(signIn, isA<AuthSuccess<Object>>());
      expect(repository.currentUser?.email, 'thando.mokoena@example.com');
      expect(repository.currentUser?.displayName, 'Thando Mokoena');

      final signOut = await repository.signOut();

      expect(signOut, isA<AuthSuccess<void>>());
      expect(repository.currentUser, isNull);
    },
  );

  test('preview adapter fails closed when debug use is not allowed', () async {
    final service = PreviewAuthService.forTesting(debugAllowed: false);

    final result = await service.signInWithEmailAndPassword(
      email: 'person@example.com',
      password: 'safe-preview-password',
    );

    expect(result, isA<AuthError<Object>>());
    expect(
      (result as AuthError<Object>).failure.kind,
      AuthFailureKind.configurationMissing,
    );
    expect(service.currentUser, isNull);
  });
}
