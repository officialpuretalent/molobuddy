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
      final adapter = await _call(
        tokenBroker: _StubBroker('id-token-value'),
        appCheckGateway: _StubGateway('app-check-value'),
      );

      expect(adapter.headers['authorization'], 'Bearer id-token-value');
      expect(adapter.headers['x-firebase-appcheck'], 'app-check-value');
    },
  );

  test('sends no identity header when the user is signed out', () async {
    final adapter = await _call(
      tokenBroker: _StubBroker(null),
      appCheckGateway: _StubGateway('app-check-value'),
    );

    expect(adapter.headers.containsKey('authorization'), isFalse);
    expect(adapter.headers['x-firebase-appcheck'], 'app-check-value');
  });

  test('sends no App Check header when attestation is unavailable', () async {
    final adapter = await _call(
      tokenBroker: _StubBroker('id-token-value'),
      appCheckGateway: _StubGateway(null),
    );

    expect(adapter.headers['authorization'], 'Bearer id-token-value');
    expect(adapter.headers.containsKey('x-firebase-appcheck'), isFalse);
  });

  test('a failing attestation never blocks the request', () async {
    final adapter = await _call(
      tokenBroker: _StubBroker('id-token-value'),
      appCheckGateway: _ThrowingGateway(),
    );

    expect(adapter.headers['authorization'], 'Bearer id-token-value');
    expect(adapter.headers.containsKey('x-firebase-appcheck'), isFalse);
  });

  test('a refused attestation is retried once with a fresh token', () async {
    // The token the SDK hands out is cached for about half an hour, so one
    // that lapsed mid-session is refused until something asks for a new one.
    final adapter = _RecordingAdapter(answers: [_refused, _ok]);

    final call = await _call(
      tokenBroker: _StubBroker('id-token-value'),
      appCheckGateway: _RefreshingGateway(stale: 'stale', fresh: 'fresh'),
      adapter: adapter,
    );

    expect(adapter.attestations, ['stale', 'fresh']);
    expect(call.statusCode, 200);
  });

  test('the retry happens once, never in a loop', () async {
    final adapter = _RecordingAdapter(answers: [_refused, _refused, _ok]);

    await _call(
      tokenBroker: _StubBroker('id-token-value'),
      appCheckGateway: _RefreshingGateway(stale: 'stale', fresh: 'fresh'),
      adapter: adapter,
    );

    expect(adapter.attestations, ['stale', 'fresh']);
  });

  test('the caller still sees the refusal when the retry fails too', () async {
    final adapter = _RecordingAdapter(answers: [_refused, _refused]);

    final call = await _call(
      tokenBroker: _StubBroker('id-token-value'),
      appCheckGateway: _RefreshingGateway(stale: 'stale', fresh: 'fresh'),
      adapter: adapter,
    );

    expect(call.statusCode, 403);
  });

  test('only an attestation refusal is retried', () async {
    // A 403 for any other reason is the server's answer, not a stale token.
    final adapter = _RecordingAdapter(
      answers: [(403, '{"code":"forbidden"}'), _ok],
    );

    await _call(
      tokenBroker: _StubBroker('id-token-value'),
      appCheckGateway: _RefreshingGateway(stale: 'stale', fresh: 'fresh'),
      adapter: adapter,
    );

    expect(adapter.attestations, ['stale']);
  });

  test('a refusal with no fresh token to offer is not retried', () async {
    final adapter = _RecordingAdapter(answers: [_refused, _ok]);

    await _call(
      tokenBroker: _StubBroker('id-token-value'),
      appCheckGateway: _StubGateway(null),
      adapter: adapter,
    );

    expect(adapter.attestations, isEmpty);
    expect(adapter.calls, 1);
  });

  test('a refusal reaching the caller as an error is retried too', () async {
    // Callers that do not widen validateStatus see a 403 as a DioException,
    // and a stale token is no less stale for arriving down that path.
    final adapter = _RecordingAdapter(answers: [_refused, _ok]);

    final call = await _call(
      tokenBroker: _StubBroker('id-token-value'),
      appCheckGateway: _RefreshingGateway(stale: 'stale', fresh: 'fresh'),
      adapter: adapter,
      tolerateFailure: false,
    );

    expect(adapter.attestations, ['stale', 'fresh']);
    expect(call.statusCode, 200);
  });
}

const _refused = (403, '{"code":"app_check_required"}');
const _ok = (200, '{"data":{}}');

Future<_RecordingAdapter> _call({
  required AuthTokenBroker tokenBroker,
  required AppCheckGateway appCheckGateway,
  _RecordingAdapter? adapter,
  bool tolerateFailure = true,
}) async {
  final recording = adapter ?? _RecordingAdapter(answers: const [_ok]);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.molo.test'));
  dio.httpClientAdapter = recording;
  dio.interceptors.add(
    MoloAuthenticatedTransport(
      tokenBroker: tokenBroker,
      appCheckGateway: appCheckGateway,
      resend: dio.fetch,
    ),
  );

  recording.response = await dio.get<Object?>(
    '/v1/session',
    options: Options(validateStatus: tolerateFailure ? (_) => true : null),
  );
  return recording;
}

final class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({required this.answers});

  /// One (status, body) pair per call, in order. The last one repeats.
  final List<(int, String)> answers;

  Map<String, dynamic> headers = const {};
  final List<String> attestations = [];
  int calls = 0;
  late Response<Object?> response;

  int? get statusCode => response.statusCode;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    headers = Map<String, dynamic>.from(options.headers);
    final attestation = options.headers['x-firebase-appcheck'];
    if (attestation is String) {
      attestations.add(attestation);
    }
    final answer = answers[calls < answers.length ? calls : answers.length - 1];
    calls += 1;
    return ResponseBody.fromString(
      answer.$2,
      answer.$1,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
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
  Future<String?> token({bool forceRefresh = false}) async => _token;
}

/// Hands out a lapsed token until somebody insists on a new one.
final class _RefreshingGateway implements AppCheckGateway {
  _RefreshingGateway({required this.stale, required this.fresh});

  final String stale;
  final String fresh;
  bool _refreshed = false;

  @override
  Future<String?> token({bool forceRefresh = false}) async {
    if (forceRefresh) {
      _refreshed = true;
    }
    return _refreshed ? fresh : stale;
  }
}

final class _ThrowingGateway implements AppCheckGateway {
  @override
  Future<String?> token({bool forceRefresh = false}) async =>
      throw StateError('attestation unavailable');
}
