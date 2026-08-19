import 'package:dio/dio.dart';
import 'package:molobuddy_app/core/auth/data/services/app_check_gateway.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_token_broker.dart';

/// Attaches Molo's identity and attestation tokens to outgoing API requests.
///
/// This is the only place raw tokens enter a request. It depends on
/// Molo-owned interfaces, so no vendor type reaches the networking layer.
final class MoloAuthenticatedTransport extends Interceptor {
  MoloAuthenticatedTransport({
    required this.tokenBroker,
    required this.appCheckGateway,
  });

  static const identityHeader = 'authorization';
  static const attestationHeader = 'x-firebase-appcheck';

  final AuthTokenBroker tokenBroker;
  final AppCheckGateway appCheckGateway;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final idToken = await _readQuietly(() => tokenBroker.idToken());
    if (idToken != null) {
      options.headers[identityHeader] = 'Bearer $idToken';
    }

    // A missing or failed attestation still sends the request. The server
    // answers with app_check_required, which stays distinguishable from an
    // authentication failure; guessing here would blur the two.
    final appCheckToken = await _readQuietly(appCheckGateway.token);
    if (appCheckToken != null) {
      options.headers[attestationHeader] = appCheckToken;
    }

    handler.next(options);
  }

  static Future<String?> _readQuietly(Future<String?> Function() read) async {
    try {
      return await read();
    } on Object {
      // Never surface a provider error here: it would leak vendor detail into
      // transport logs and turn a recoverable state into a request failure.
      return null;
    }
  }
}
