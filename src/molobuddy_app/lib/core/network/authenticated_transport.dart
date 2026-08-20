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
    required this.resend,
  });

  static const identityHeader = 'authorization';
  static const attestationHeader = 'x-firebase-appcheck';

  /// Marks a request that has already spent its one attestation retry.
  static const _retriedExtra = 'molo.appCheckRetried';

  final AuthTokenBroker tokenBroker;
  final AppCheckGateway appCheckGateway;

  /// Sends a request again through the same client. Required rather than
  /// optional: an interceptor that quietly cannot retry looks identical to
  /// one that chose not to.
  final Future<Response<Object?>> Function(RequestOptions) resend;

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
    //
    // A retry already carries a freshly minted token. Asking again would hand
    // back the same cached value the server has just refused.
    if (options.extra[_retriedExtra] != true) {
      final appCheckToken = await _readQuietly(appCheckGateway.token);
      if (appCheckToken != null) {
        options.headers[attestationHeader] = appCheckToken;
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final retried = await _retriedWithFreshAttestation(
      response.requestOptions,
      response.statusCode,
      response.data,
    );
    if (retried != null) {
      handler.resolve(retried);
      return;
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Callers that leave validateStatus alone meet a refusal here instead of
    // in onResponse. A lapsed token is no less lapsed for arriving as an
    // exception, so both paths get the same one retry.
    final retried = await _retriedWithFreshAttestation(
      err.requestOptions,
      err.response?.statusCode,
      err.response?.data,
    );
    if (retried != null) {
      handler.resolve(retried);
      return;
    }
    handler.next(err);
  }

  /// Sends the request once more with a newly minted attestation token, or
  /// `null` when this refusal is not one a fresh token could fix.
  ///
  /// Returning `null` leaves the original answer untouched, so a caller whose
  /// retry also failed sees the failure the server actually gave.
  Future<Response<Object?>?> _retriedWithFreshAttestation(
    RequestOptions options,
    int? status,
    Object? body,
  ) async {
    if (status != 403 || !_saysAttestationRequired(body)) {
      return null;
    }
    if (options.extra[_retriedExtra] == true) {
      return null;
    }

    final fresh = await _readQuietly(
      () => appCheckGateway.token(forceRefresh: true),
    );
    if (fresh == null) {
      return null;
    }

    try {
      return await resend(
        options.copyWith(
          extra: {...options.extra, _retriedExtra: true},
          headers: {...options.headers, attestationHeader: fresh},
        ),
      );
    } on DioException {
      return null;
    }
  }

  static bool _saysAttestationRequired(Object? body) {
    return body is Map && body['code'] == 'app_check_required';
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
