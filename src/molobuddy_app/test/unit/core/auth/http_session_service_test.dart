import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';
import 'package:molobuddy_app/core/auth/data/services/http_session_service.dart';

void main() {
  test('reads the session out of the standard data envelope', () async {
    final service = _serviceReturning(200, '''
{"data":{"user":{"uid":"user_1","displayName":"Thando Mokoena",
"emailMasked":"t***@example.com"},"practiceRefs":[]},
"meta":{"apiVersion":"v1"}}''');

    final result = await service.loadSession();

    expect(result, isA<AuthSuccess<MoloSession>>());
    final session = (result as AuthSuccess<MoloSession>).value;
    expect(session.uid, 'user_1');
    expect(session.displayName, 'Thando Mokoena');
    expect(session.emailMasked, 't***@example.com');
    expect(session.practiceRefs, isEmpty);
  });

  test('keeps a practice reference that carries a route version', () async {
    final service = _serviceReturning(200, '''
{"data":{"user":{"uid":"user_1"},"practiceRefs":[
{"practiceId":"p_1","displayLabel":"Mokoena Tax Studio","homeRegionKey":"za1",
"routeVersion":3,"accessStatus":"active"}]}}''');

    final session =
        (await service.loadSession() as AuthSuccess<MoloSession>).value;

    expect(session.practiceRefs, hasLength(1));
    expect(session.practiceRefs.single.routeVersion, 3);
  });

  test('drops a practice reference with no route version', () async {
    // routeVersion is required by the server schema. Defaulting it would
    // invent route state, which is worse than dropping the reference.
    final service = _serviceReturning(200, '''
{"data":{"user":{"uid":"user_1"},"practiceRefs":[
{"practiceId":"p_1","displayLabel":"Mokoena Tax Studio","homeRegionKey":"za1",
"accessStatus":"active"},
{"practiceId":"p_2","displayLabel":"Other","homeRegionKey":"za1",
"routeVersion":"1","accessStatus":"active"}]}}''');

    final session =
        (await service.loadSession() as AuthSuccess<MoloSession>).value;

    expect(session.practiceRefs, isEmpty);
    expect(session.hasPractices, isFalse);
  });

  test('maps a missing attestation to its own failure kind', () async {
    final service = _serviceReturning(403, '{"code":"app_check_required"}');

    final result = await service.loadSession();

    expect(
      (result as AuthError<MoloSession>).failure.kind,
      AuthFailureKind.attestationRequired,
    );
  });

  test('maps an invalid token to an expired session', () async {
    final service = _serviceReturning(401, '{"code":"token_invalid"}');

    final result = await service.loadSession();

    expect(
      (result as AuthError<MoloSession>).failure.kind,
      AuthFailureKind.sessionExpired,
    );
  });

  test('rejects a response that omits the data envelope', () async {
    final service = _serviceReturning(200, '{"user":{"uid":"user_1"}}');

    expect(
      (await service.loadSession() as AuthError<MoloSession>).failure.kind,
      AuthFailureKind.unexpected,
    );
  });

  test('reads whether onboarding is still outstanding', () async {
    final service = _serviceReturning(200, '''
{"data":{"user":{"uid":"user_1"},"practiceRefs":[],
"onboarding":{"status":"in_progress"}}}''');

    final session =
        (await service.loadSession() as AuthSuccess<MoloSession>).value;

    expect(session.onboardingComplete, isFalse);
  });

  test('reads a finished onboarding', () async {
    final service = _serviceReturning(200, '''
{"data":{"user":{"uid":"user_1"},"practiceRefs":[],
"onboarding":{"status":"complete"}}}''');

    final session =
        (await service.loadSession() as AuthSuccess<MoloSession>).value;

    expect(session.onboardingComplete, isTrue);
  });

  test('treats an absent onboarding block as finished', () async {
    // A server that has not shipped the gate yet must not trap every user in a
    // wizard. Absence means nothing outstanding, which is the safe reading for
    // a field that only ever adds a redirect.
    final service = _serviceReturning(200, '''
{"data":{"user":{"uid":"user_1"},"practiceRefs":[]}}''');

    final session =
        (await service.loadSession() as AuthSuccess<MoloSession>).value;

    expect(session.onboardingComplete, isTrue);
  });
}

HttpSessionService _serviceReturning(int status, String body) {
  final dio = Dio(BaseOptions(validateStatus: (_) => true));
  dio.httpClientAdapter = _StubAdapter(status, body);
  return HttpSessionService(dio: dio, baseUrl: 'https://api.molo.test');
}

final class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this._status, this._body);

  final int _status;
  final String _body;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      _body,
      _status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
