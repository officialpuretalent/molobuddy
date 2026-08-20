import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/core/auth/auth_providers.dart';
import 'package:molobuddy_app/core/auth/data/services/app_check_gateway.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_token_broker.dart';
import 'package:molobuddy_app/core/network/authenticated_transport.dart';
import 'package:molobuddy_app/core/network/network_providers.dart';

void main() {
  test('the shared client carries the authenticated transport', () {
    final container = ProviderContainer(
      overrides: [
        authTokenBrokerProvider.overrideWithValue(
          const UnavailableAuthTokenBroker(),
        ),
        appCheckGatewayProvider.overrideWithValue(
          const UnavailableAppCheckGateway(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final dio = container.read(authenticatedDioProvider);

    expect(
      dio.interceptors.whereType<MoloAuthenticatedTransport>(),
      hasLength(1),
    );
  });

  test('the shared client bounds how long a reply may take', () {
    // Start-up waits on /v1/session before it can settle. Connecting is
    // already bounded, but a server that accepts the connection and then says
    // nothing would stall the app indefinitely without this.
    final container = ProviderContainer(
      overrides: [
        authTokenBrokerProvider.overrideWithValue(
          const UnavailableAuthTokenBroker(),
        ),
        appCheckGatewayProvider.overrideWithValue(
          const UnavailableAppCheckGateway(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final options = container.read(authenticatedDioProvider).options;

    expect(options.connectTimeout, isNotNull);
    expect(options.receiveTimeout, isNotNull);
    expect(
      options.receiveTimeout,
      lessThanOrEqualTo(const Duration(seconds: 30)),
    );
  });
}
