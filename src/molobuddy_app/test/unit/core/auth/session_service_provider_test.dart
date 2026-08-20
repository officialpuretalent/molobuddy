import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/bootstrap/app_environment.dart';
import 'package:molobuddy_app/core/auth/auth_providers.dart';
import 'package:molobuddy_app/core/auth/data/models/firebase_public_configuration.dart';
import 'package:molobuddy_app/core/auth/data/services/app_check_gateway.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_token_broker.dart';
import 'package:molobuddy_app/core/auth/data/services/http_session_service.dart';
import 'package:molobuddy_app/core/auth/data/services/session_service.dart';

const _firebaseConfiguration = FirebasePublicConfiguration(
  apiKey: 'key',
  appId: 'app',
  messagingSenderId: 'sender',
  projectId: 'molobuddy-development',
);

void main() {
  test('a preview build never calls the control API for a session', () {
    // A preview build has no token broker and no attestation, so a call would
    // come back as authentication_required and strand the user in a sign-in
    // loop. A configured base URL must not be enough to start one.
    final container = _containerFor(
      const AppEnvironment(
        authMode: AuthRuntimeMode.preview,
        apiBaseUrl: 'http://localhost:8080',
        firebaseConfiguration: null,
      ),
    );

    expect(
      container.read(sessionServiceProvider),
      isA<UnavailableSessionService>(),
    );
  });

  test('an unavailable build never calls the control API either', () {
    final container = _containerFor(
      const AppEnvironment(
        authMode: AuthRuntimeMode.unavailable,
        apiBaseUrl: 'https://api.molo.test',
        firebaseConfiguration: null,
      ),
    );

    expect(
      container.read(sessionServiceProvider),
      isA<UnavailableSessionService>(),
    );
  });

  test('a Firebase build with a base URL reads the session over HTTP', () {
    final container = _containerFor(
      const AppEnvironment(
        authMode: AuthRuntimeMode.firebase,
        apiBaseUrl: 'https://api.molo.test',
        firebaseConfiguration: _firebaseConfiguration,
      ),
    );

    expect(container.read(sessionServiceProvider), isA<HttpSessionService>());
  });

  test('a Firebase build without a base URL has nowhere to ask', () {
    final container = _containerFor(
      const AppEnvironment(
        authMode: AuthRuntimeMode.firebase,
        apiBaseUrl: null,
        firebaseConfiguration: _firebaseConfiguration,
      ),
    );

    expect(
      container.read(sessionServiceProvider),
      isA<UnavailableSessionService>(),
    );
  });
}

ProviderContainer _containerFor(AppEnvironment environment) {
  final container = ProviderContainer(
    overrides: [
      appEnvironmentProvider.overrideWithValue(environment),
      authTokenBrokerProvider.overrideWithValue(
        const UnavailableAuthTokenBroker(),
      ),
      appCheckGatewayProvider.overrideWithValue(
        const UnavailableAppCheckGateway(),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}
