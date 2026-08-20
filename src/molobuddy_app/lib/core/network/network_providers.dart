import 'package:dio/dio.dart';
import 'package:molobuddy_app/core/auth/auth_providers.dart';
import 'package:molobuddy_app/core/network/authenticated_transport.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_providers.g.dart';

/// The one HTTP client that carries Molo's identity and attestation tokens.
///
/// Anything calling an authenticated Molo endpoint uses this, so tokens are
/// attached in exactly one place.
@Riverpod(keepAlive: true)
Dio authenticatedDio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      headers: const {'accept': 'application/json'},
      connectTimeout: const Duration(seconds: 5),
    ),
  );
  dio.interceptors.add(
    MoloAuthenticatedTransport(
      tokenBroker: ref.watch(authTokenBrokerProvider),
      appCheckGateway: ref.watch(appCheckGatewayProvider),
    ),
  );
  return dio;
}
