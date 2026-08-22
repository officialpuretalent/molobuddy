import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/core/auth/auth_providers.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_user.dart';
import 'package:molobuddy_app/core/auth/data/repositories/default_auth_repository.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_provider_catalogue_service.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_service.dart';
import 'package:molobuddy_app/core/auth/data/services/preview_session_service.dart';

/// Records what the repository asked for, so the argument's journey is checked
/// rather than assumed.
final class _RecordingAuthService implements AuthService {
  bool? lastPersistSession;

  @override
  AuthUser? get currentUser => null;

  @override
  Future<AuthResult<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
    required bool persistSession,
  }) async {
    lastPersistSession = persistSession;
    return const AuthSuccess(
      AuthUser(id: 'u1', email: 'a@b.co', displayName: 'A'),
    );
  }

  @override
  Future<AuthResult<AuthUser>> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) async => const AuthError(AuthFailure(AuthFailureKind.unexpected));

  @override
  Future<AuthResult<void>> signOut() async => const AuthSuccess(null);
}

void main() {
  group('the repository passes the choice down untouched', () {
    late _RecordingAuthService service;
    late DefaultAuthRepository repository;

    setUp(() {
      service = _RecordingAuthService();
      repository = DefaultAuthRepository(
        service,
        const BundledPreviewAuthProviderCatalogueService(),
        PreviewSessionService(service, practices: () => const []),
      );
    });

    test('a person who asked to stay signed in', () async {
      await repository.signInWithEmailAndPassword(
        email: 'a@b.co',
        password: 'password123',
        persistSession: true,
      );
      expect(service.lastPersistSession, isTrue);
    });

    test('a person who did not', () async {
      await repository.signInWithEmailAndPassword(
        email: 'a@b.co',
        password: 'password123',
        persistSession: false,
      );
      expect(service.lastPersistSession, isFalse);
    });
  });

  test('the choice is not offered where the platform ignores it', () {
    // The test host is not the web, and neither is Android or iOS: Firebase
    // always persists there, so there is nothing to choose.
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(sessionPersistenceChoosableProvider), isFalse);
  });

  test('a view can be told the platform does offer it', () {
    final container = ProviderContainer(
      overrides: [sessionPersistenceChoosableProvider.overrideWithValue(true)],
    );
    addTearDown(container.dispose);
    expect(container.read(sessionPersistenceChoosableProvider), isTrue);
  });
}
