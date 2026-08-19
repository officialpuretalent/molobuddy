import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/core/auth/data/services/app_check_gateway.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_token_broker.dart';
import 'package:molobuddy_app/core/network/authenticated_transport.dart';

void main() {
  test(
    'attaches the identity and App Check tokens the control API reads',
    () async {
      final headers = await _capturedHeaders(
        tokenBroker: _StubBroker('id-token-value'),
        appCheckGateway: _StubGateway('app-check-value'),
      );

      expect(headers['authorization'], 'Bearer id-token-value');
      expect(headers['x-firebase-appcheck'], 'app-check-value');
    },
  );

  test('sends no identity header when the user is signed out', () async {
    final headers = await _capturedHeaders(
      tokenBroker: _StubBroker(null),
      appCheckGateway: _StubGateway('app-check-value'),
    );

    expect(headers.containsKey('authorization'), isFalse);
    expect(headers['x-firebase-appcheck'], 'app-check-value');
  });

  test('sends no App Check header when attestation is unavailable', () async {
    final headers = await _capturedHeaders(
      tokenBroker: _StubBroker('id-token-value'),
      appCheckGateway: _StubGateway(null),
    );

    expect(headers['authorization'], 'Bearer id-token-value');
    expect(headers.containsKey('x-firebase-appcheck'), isFalse);
  });

  test('a failing attestation never blocks the request', () async {
    final headers = await _capturedHeaders(
      tokenBroker: _StubBroker('id-token-value'),
      appCheckGateway: _ThrowingGateway(),
    );

    expect(headers['authorization'], 'Bearer id-token-value');
    expect(headers.containsKey('x-firebase-appcheck'), isFalse);
  });
}

Future<Map<String, dynamic>> _capturedHeaders({
  required AuthTokenBroker tokenBroker,
  required AppCheckGateway appCheckGateway,
}) async {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.molo.test'));
  final adapter = _RecordingAdapter();
  dio.httpClientAdapter = adapter;
  dio.interceptors.add(
    MoloAuthenticatedTransport(
      tokenBroker: tokenBroker,
      appCheckGateway: appCheckGateway,
    ),
  );

  await dio.get<void>('/v1/session');
  return adapter.headers;
}

final class _RecordingAdapter implements HttpClientAdapter {
  Map<String, dynamic> headers = const {};

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    headers = Map<String, dynamic>.from(options.headers);
    return ResponseBody.fromString('', 200);
  }
}

final class _StubBroker implements AuthTokenBroker {
  _StubBroker(this._token);

  final String? _token;

  @override
  Future<String?> idToken({bool forceRefresh = false}) async => _token;
}

final class _StubGateway implements AppCheckGateway {
  _StubGateway(this._token);

  final String? _token;

  @override
  Future<String?> token() async => _token;
}

final class _ThrowingGateway implements AppCheckGateway {
  @override
  Future<String?> token() async => throw StateError('attestation unavailable');
}
