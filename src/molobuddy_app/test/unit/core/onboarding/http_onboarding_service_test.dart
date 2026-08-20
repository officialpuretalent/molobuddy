import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';
import 'package:molobuddy_app/core/onboarding/data/models/onboarding_answers.dart';
import 'package:molobuddy_app/core/onboarding/data/models/onboarding_failure.dart';
import 'package:molobuddy_app/core/onboarding/data/models/onboarding_snapshot.dart';
import 'package:molobuddy_app/core/onboarding/data/services/http_onboarding_service.dart';

void main() {
  test(
    'reads status, next step, answers and version out of the envelope',
    () async {
      final service = _serviceReturning(200, '''
{"data":{"status":"in_progress","nextStep":"priorities",
"answers":{"practiceName":"Mokoena Media Tax","practiceSize":"small_team"},
"version":"v-1"}}''');

      final result = await service.load();

      final snapshot = (result as OnboardingSuccess<OnboardingSnapshot>).value;
      expect(snapshot.complete, isFalse);
      expect(snapshot.nextStep, OnboardingStep.priorities);
      expect(snapshot.answers.practiceName, 'Mokoena Media Tax');
      expect(snapshot.answers.practiceSize, PracticeSize.smallTeam);
      expect(snapshot.version, 'v-1');
    },
  );

  test('a not-started record carries no version', () async {
    final service = _serviceReturning(200, '''
{"data":{"status":"in_progress","nextStep":"practice","answers":{}}}''');

    final snapshot =
        (await service.load() as OnboardingSuccess<OnboardingSnapshot>).value;

    expect(snapshot.version, isNull);
    expect(snapshot.answers.priorities, isEmpty);
  });

  test('sends only the answers it was given, in wire form', () async {
    final captured = <RequestOptions>[];
    final service = _serviceCapturing(captured, 200, '''
{"data":{"status":"in_progress","nextStep":"priorities","answers":{}}}''');

    await service.save(
      answers: const OnboardingAnswers(practiceSize: PracticeSize.smallTeam),
      expectedVersion: 'v-1',
    );

    final sent = captured.single;
    expect(sent.headers['if-match'], 'v-1');
    expect(sent.data, {
      'answers': {'practiceSize': 'small_team'},
    });
  });

  test('omits If-Match on a first save', () async {
    final captured = <RequestOptions>[];
    final service = _serviceCapturing(captured, 200, '''
{"data":{"status":"in_progress","nextStep":"priorities","answers":{}}}''');

    await service.save(
      answers: const OnboardingAnswers(practiceName: 'Mokoena Media Tax'),
      expectedVersion: null,
    );

    expect(captured.single.headers.containsKey('if-match'), isFalse);
  });

  test('sends every answer kind in wire form', () async {
    final captured = <RequestOptions>[];
    final service = _serviceCapturing(
      captured,
      200,
      '''
{"data":{"status":"in_progress","nextStep":"ready_to_complete","answers":{}}}''',
    );

    await service.save(
      answers: const OnboardingAnswers(
        practiceName: 'Mokoena Media Tax',
        practiceSize: PracticeSize.growingTeam,
        priorities: {OnboardingPriority.deadlines},
        startingPoint: WorkspaceStartingPoint.addFirstClient,
      ),
      expectedVersion: 'v-1',
    );

    expect(captured.single.data, {
      'answers': {
        'practiceName': 'Mokoena Media Tax',
        'practiceSize': 'growing_team',
        'priorities': ['deadlines'],
        'startingPoint': 'add_first_client',
      },
    });
  });

  test('a stale or missing version is one conflict to the caller', () async {
    // Both mean what you hold is not current, and the recovery is identical:
    // reload, then write again. One kind keeps the view simpler.
    for (final probe in [
      (412, 'version_mismatch'),
      (428, 'version_required'),
    ]) {
      final service = _serviceReturning(
        probe.$1,
        '{"code":"${probe.$2}","status":${probe.$1}}',
      );

      final result = await service.save(
        answers: const OnboardingAnswers(),
        expectedVersion: 'v-1',
      );

      expect(
        (result as OnboardingError<OnboardingSnapshot>).failure.kind,
        OnboardingFailureKind.versionConflict,
      );
    }
  });

  test('a refused answer carries the pointer the server named', () async {
    final service = _serviceReturning(400, '''
{"code":"validation_error","status":400,
"errors":[{"pointer":"/answers/practiceSize","code":"validation_error",
"message":"This value is not acceptable."}]}''');

    final result = await service.save(
      answers: const OnboardingAnswers(),
      expectedVersion: 'v-1',
    );

    final failure = (result as OnboardingError<OnboardingSnapshot>).failure;
    expect(failure.kind, OnboardingFailureKind.answerRejected);
    expect(failure.pointer, '/answers/practiceSize');
  });

  test('an incomplete completion names the missing answer', () async {
    final service = _serviceReturning(409, '''
{"code":"onboarding_incomplete","status":409,
"errors":[{"pointer":"/answers/startingPoint","code":"answer_required",
"message":"This answer is not acceptable."}]}''');

    final result = await service.complete(idempotencyKey: 'onb_1');

    final failure = (result as OnboardingError<PracticeRef>).failure;
    expect(failure.kind, OnboardingFailureKind.incomplete);
    expect(failure.pointer, '/answers/startingPoint');
  });

  test('keeps attestation and session failures apart', () async {
    final attestation = _serviceReturning(
      403,
      '{"code":"app_check_required","status":403}',
    );
    final expired = _serviceReturning(
      401,
      '{"code":"token_invalid","status":401}',
    );

    expect(
      (await attestation.load() as OnboardingError<OnboardingSnapshot>)
          .failure
          .kind,
      OnboardingFailureKind.attestationRequired,
    );
    expect(
      (await expired.load() as OnboardingError<OnboardingSnapshot>)
          .failure
          .kind,
      OnboardingFailureKind.sessionExpired,
    );
  });

  test('completion sends the idempotency key and reads the practice', () async {
    final captured = <RequestOptions>[];
    final service = _serviceCapturing(captured, 201, '''
{"data":{"practiceId":"prc_1","displayLabel":"Mokoena Media Tax",
"homeRegionKey":"za1","routeVersion":1,"accessStatus":"active"}}''');

    final result = await service.complete(idempotencyKey: 'onb_abc');

    expect(captured.single.headers['idempotency-key'], 'onb_abc');
    final practice = (result as OnboardingSuccess<PracticeRef>).value;
    expect(practice.practiceId, 'prc_1');
    expect(practice.displayLabel, 'Mokoena Media Tax');
    expect(practice.accessStatus, PracticeAccessStatus.active);
  });

  test(
    'a transport failure is a network failure, not an unexpected one',
    () async {
      final dio = Dio(BaseOptions(validateStatus: (_) => true));
      dio.httpClientAdapter = _ThrowingAdapter();
      final service = HttpOnboardingService(
        dio: dio,
        baseUrl: 'https://api.molo.test',
      );

      final result = await service.load();

      expect(
        (result as OnboardingError<OnboardingSnapshot>).failure.kind,
        OnboardingFailureKind.networkUnavailable,
      );
    },
  );
}

HttpOnboardingService _serviceReturning(int status, String body) {
  final dio = Dio(BaseOptions(validateStatus: (_) => true));
  dio.httpClientAdapter = _StubAdapter(status, body);
  return HttpOnboardingService(dio: dio, baseUrl: 'https://api.molo.test');
}

HttpOnboardingService _serviceCapturing(
  List<RequestOptions> captured,
  int status,
  String body,
) {
  final dio = Dio(BaseOptions(validateStatus: (_) => true));
  dio.httpClientAdapter = _StubAdapter(status, body);
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        captured.add(options);
        handler.next(options);
      },
    ),
  );
  return HttpOnboardingService(dio: dio, baseUrl: 'https://api.molo.test');
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

final class _ThrowingAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException.connectionError(
      requestOptions: options,
      reason: 'no route to host',
    );
  }
}
