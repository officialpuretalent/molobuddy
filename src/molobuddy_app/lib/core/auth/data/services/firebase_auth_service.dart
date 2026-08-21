import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_user.dart';
import 'package:molobuddy_app/core/auth/data/models/firebase_public_configuration.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_service.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_token_broker.dart';

final class FirebaseAuthService implements AuthService {
  FirebaseAuthService._(this._auth, this.app);

  final firebase.FirebaseAuth _auth;

  /// The initialised Firebase app, so attestation activates against the same
  /// instance rather than initialising a second one.
  final FirebaseApp app;

  static Future<FirebaseAuthService> initialise(
    FirebasePublicConfiguration configuration,
  ) async {
    final app = await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: configuration.apiKey,
        appId: configuration.appId,
        messagingSenderId: configuration.messagingSenderId,
        projectId: configuration.projectId,
        authDomain: configuration.authDomain,
      ),
    );
    return FirebaseAuthService._(
      firebase.FirebaseAuth.instanceFor(app: app),
      app,
    );
  }

  @override
  AuthUser? get currentUser => _mapUser(_auth.currentUser);

  /// The broker the authenticated transport uses to read raw ID tokens.
  ///
  /// Exposed here so the token source stays the same signed-in session this
  /// service owns, rather than a second Firebase handle.
  AuthTokenBroker get tokenBroker => _FirebaseAuthTokenBroker(_auth);

  @override
  Future<AuthResult<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
    required bool persistSession,
  }) async {
    try {
      // Web is the only platform where a session's lifetime is a choice.
      // Android and iOS persist unconditionally, so the guard is a capability
      // check rather than a device check.
      if (kIsWeb) {
        await _auth.setPersistence(
          persistSession
              ? firebase.Persistence.LOCAL
              : firebase.Persistence.SESSION,
        );
      }
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = _mapUser(credential.user);
      if (user == null) {
        return const AuthError(AuthFailure(AuthFailureKind.unexpected));
      }
      return AuthSuccess(user);
    } on firebase.FirebaseAuthException catch (error) {
      return AuthError(AuthFailure(_mapFailure(error.code)));
    } on FirebaseException {
      return const AuthError(AuthFailure(AuthFailureKind.providerUnavailable));
    }
  }

  @override
  Future<AuthResult<AuthUser>> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final created = credential.user;
      if (created == null) {
        return const AuthError(AuthFailure(AuthFailureKind.unexpected));
      }

      // Set the name before anyone reads it, and reload so currentUser carries
      // it. Without the reload the first greeting after signup has no name and
      // the app looks like it forgot what the user just typed.
      await created.updateDisplayName(displayName.trim());
      await created.reload();

      final user = _mapUser(_auth.currentUser) ?? _mapUser(created);
      if (user == null) {
        return const AuthError(AuthFailure(AuthFailureKind.unexpected));
      }
      return AuthSuccess(user);
    } on firebase.FirebaseAuthException catch (error) {
      return AuthError(AuthFailure(_mapSignUpFailure(error.code)));
    } on FirebaseException {
      return const AuthError(AuthFailure(AuthFailureKind.providerUnavailable));
    }
  }

  @override
  Future<AuthResult<void>> signOut() async {
    try {
      await _auth.signOut();
      return const AuthSuccess(null);
    } on firebase.FirebaseAuthException catch (error) {
      return AuthError(AuthFailure(_mapFailure(error.code)));
    }
  }

  static AuthUser? _mapUser(firebase.User? user) {
    if (user == null || user.email == null) {
      return null;
    }
    return AuthUser(
      id: user.uid,
      email: user.email!,
      displayName: user.displayName,
    );
  }

  /// Kept apart from [_mapFailure] because sign-up and sign-in answer
  /// differently to the same situation.
  static AuthFailureKind _mapSignUpFailure(String code) {
    return switch (code) {
      'email-already-in-use' => AuthFailureKind.emailAlreadyRegistered,
      'weak-password' => AuthFailureKind.passwordRejected,
      'invalid-email' => AuthFailureKind.invalidCredentials,
      'network-request-failed' => AuthFailureKind.networkUnavailable,
      'operation-not-allowed' ||
      'too-many-requests' => AuthFailureKind.providerUnavailable,
      // Email-enumeration protection may answer a taken address generically.
      // Neutral copy is correct then: guessing would tell the user something
      // the provider deliberately declined to.
      _ => AuthFailureKind.unexpected,
    };
  }

  static AuthFailureKind _mapFailure(String code) {
    return switch (code) {
      'invalid-credential' ||
      'user-not-found' ||
      'wrong-password' ||
      'invalid-email' => AuthFailureKind.invalidCredentials,
      'network-request-failed' => AuthFailureKind.networkUnavailable,
      'operation-not-allowed' ||
      'too-many-requests' ||
      'user-disabled' => AuthFailureKind.providerUnavailable,
      _ => AuthFailureKind.unexpected,
    };
  }
}

final class _FirebaseAuthTokenBroker implements AuthTokenBroker {
  _FirebaseAuthTokenBroker(this._auth);

  final firebase.FirebaseAuth _auth;

  @override
  Future<String?> idToken({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }
    try {
      // The SDK owns refresh and persistence; this reads the current token
      // and only forces a refresh when a caller has seen an expiry response.
      return await user.getIdToken(forceRefresh);
    } on Object {
      return null;
    }
  }
}
