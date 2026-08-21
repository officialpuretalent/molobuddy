import 'package:flutter/foundation.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_user.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_service.dart';

final class PreviewAuthService implements AuthService {
  PreviewAuthService({Duration delay = const Duration(milliseconds: 550)})
    : this._(kDebugMode, delay);

  @visibleForTesting
  factory PreviewAuthService.forTesting({
    required bool debugAllowed,
    Duration delay = Duration.zero,
  }) {
    return PreviewAuthService._(debugAllowed, delay);
  }

  PreviewAuthService._(this._debugAllowed, this.delay);

  final bool _debugAllowed;
  final Duration delay;
  AuthUser? _currentUser;

  /// Accounts this preview run has created, so a repeated address is refused
  /// the way the real provider refuses one.
  final Map<String, AuthUser> _registered = {};

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<AuthResult<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
    // Preview holds its session in memory for one run, so there is nothing for
    // a lifetime to change.
    required bool persistSession,
  }) async {
    if (!_debugAllowed) {
      return const AuthError(AuthFailure(AuthFailureKind.configurationMissing));
    }

    await Future<void>.delayed(delay);
    final normalisedEmail = email.trim().toLowerCase();
    if (!_looksLikeEmail(normalisedEmail) || password.length < 8) {
      return const AuthError(AuthFailure(AuthFailureKind.invalidCredentials));
    }

    final user = AuthUser(
      id: 'preview-${normalisedEmail.hashCode.abs()}',
      email: normalisedEmail,
      displayName: _displayNameFromEmail(normalisedEmail),
    );
    _currentUser = user;
    return AuthSuccess(user);
  }

  @override
  Future<AuthResult<AuthUser>> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (!_debugAllowed) {
      return const AuthError(AuthFailure(AuthFailureKind.configurationMissing));
    }

    await Future<void>.delayed(delay);
    final normalisedEmail = email.trim().toLowerCase();
    if (!_looksLikeEmail(normalisedEmail)) {
      return const AuthError(AuthFailure(AuthFailureKind.invalidCredentials));
    }
    if (password.length < 8) {
      return const AuthError(AuthFailure(AuthFailureKind.passwordRejected));
    }
    if (_registered.containsKey(normalisedEmail)) {
      return const AuthError(
        AuthFailure(AuthFailureKind.emailAlreadyRegistered),
      );
    }

    final trimmedName = displayName.trim();
    final user = AuthUser(
      id: 'preview-${normalisedEmail.hashCode.abs()}',
      email: normalisedEmail,
      displayName: trimmedName.isEmpty ? null : trimmedName,
    );
    _registered[normalisedEmail] = user;
    _currentUser = user;
    return AuthSuccess(user);
  }

  @override
  Future<AuthResult<void>> signOut() async {
    if (!_debugAllowed) {
      return const AuthError(AuthFailure(AuthFailureKind.configurationMissing));
    }
    _currentUser = null;
    return const AuthSuccess(null);
  }

  static bool _looksLikeEmail(String value) {
    final separator = value.indexOf('@');
    return separator > 0 &&
        separator < value.length - 3 &&
        value.indexOf('.', separator) > separator + 1;
  }

  static String _displayNameFromEmail(String email) {
    final localPart = email.split('@').first;
    final words = localPart
        .split(RegExp(r'[._-]+'))
        .where((word) => word.isNotEmpty)
        .map(
          (word) => '${word.substring(0, 1).toUpperCase()}${word.substring(1)}',
        );
    final value = words.join(' ');
    return value.isEmpty ? email : value;
  }
}
