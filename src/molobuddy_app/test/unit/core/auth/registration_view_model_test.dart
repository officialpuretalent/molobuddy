import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/core/auth/auth_providers.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_method_descriptor.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_user.dart';
import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';
import 'package:molobuddy_app/core/auth/data/repositories/auth_repository.dart';
import 'package:molobuddy_app/core/auth/ui/view_models/auth_view_model.dart';
import 'package:molobuddy_app/core/auth/ui/view_models/registration_view_model.dart';

final class _RecordingRepository implements AuthRepository {
  _RecordingRepository({this.failure});

  final AuthFailure? failure;
  final List<(String, String, String)> created = [];

  @override
  Future<AuthResult<AuthUser>> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    created.add((email, password, displayName));
    final refusal = failure;
    if (refusal != null) {
      return AuthError(refusal);
    }
    return AuthSuccess(
      AuthUser(id: 'user_1', email: email, displayName: displayName),
    );
  }

  @override
  AuthUser? get currentUser => null;

  @override
  Future<AuthResult<List<AuthMethodDescriptor>>> loadMethods() async =>
      const AuthSuccess([]);

  @override
  Future<AuthResult<MoloSession>> loadSession() async =>
      throw UnimplementedError('loadSession');

  @override
  Future<AuthResult<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
    required bool persistSession,
  }) async => throw UnimplementedError('signInWithEmailAndPassword');

  @override
  Future<AuthResult<void>> signOut() async =>
      throw UnimplementedError('signOut');
}

Future<(RegistrationViewModel, ProviderContainer)> _build(
  _RecordingRepository repository,
) async {
  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  // Account creation goes through the auth view model, so let its first load
  // settle before the form is submitted.
  await container.read(authViewModelProvider.future);
  container.read(registrationViewModelProvider);
  return (container.read(registrationViewModelProvider.notifier), container);
}

RegistrationViewState _stateOf(ProviderContainer container) {
  return container.read(registrationViewModelProvider);
}

Future<bool> _submitValid(RegistrationViewModel model) {
  return model.createAccount(
    displayName: 'Thando Mokoena',
    email: 'Thando@Example.com',
    password: 'safe-preview-password',
    acceptedTerms: true,
  );
}

void main() {
  test('creates the account and normalises what it sends', () async {
    final repository = _RecordingRepository();
    final (model, _) = await _build(repository);

    final created = await _submitValid(model);

    expect(created, isTrue);
    expect(repository.created, [
      ('thando@example.com', 'safe-preview-password', 'Thando Mokoena'),
    ]);
  });

  test('refuses to call the provider with an unusable form', () async {
    final repository = _RecordingRepository();
    final (model, container) = await _build(repository);

    final created = await model.createAccount(
      displayName: 'T',
      email: 'not-an-email',
      password: 'short',
      acceptedTerms: false,
    );

    expect(created, isFalse);
    expect(repository.created, isEmpty);
    final state = _stateOf(container);
    expect(state.nameInvalid, isTrue);
    expect(state.emailInvalid, isTrue);
    expect(state.passwordTooShort, isTrue);
    expect(state.termsNotAccepted, isTrue);
  });

  test('reports a taken address on the email field, not as a banner', () async {
    final (model, container) = await _build(
      _RecordingRepository(
        failure: const AuthFailure(AuthFailureKind.emailAlreadyRegistered),
      ),
    );

    final created = await _submitValid(model);

    expect(created, isFalse);
    expect(_stateOf(container).emailAlreadyRegistered, isTrue);
    expect(_stateOf(container).failure, isNull);
  });

  test('reports a rejected password on the password field', () async {
    final (model, container) = await _build(
      _RecordingRepository(
        failure: const AuthFailure(AuthFailureKind.passwordRejected),
      ),
    );

    await _submitValid(model);

    expect(_stateOf(container).passwordTooShort, isTrue);
    expect(_stateOf(container).failure, isNull);
  });

  test('anything no field explains becomes a form-level failure', () async {
    // This is the path a provider takes when email-enumeration protection
    // declines to say the address is taken.
    final (model, container) = await _build(
      _RecordingRepository(
        failure: const AuthFailure(AuthFailureKind.unexpected),
      ),
    );

    await _submitValid(model);

    expect(_stateOf(container).emailAlreadyRegistered, isFalse);
    expect(_stateOf(container).failure?.kind, AuthFailureKind.unexpected);
  });

  test('clears a previous refusal when the form is submitted again', () async {
    final repository = _RecordingRepository();
    final (model, container) = await _build(repository);
    await model.createAccount(
      displayName: 'T',
      email: 'nope',
      password: 'short',
      acceptedTerms: false,
    );

    await _submitValid(model);

    final state = _stateOf(container);
    expect(state.nameInvalid, isFalse);
    expect(state.emailInvalid, isFalse);
    expect(state.termsNotAccepted, isFalse);
  });
}
