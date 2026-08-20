import 'package:dio/dio.dart';
import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';
import 'package:molobuddy_app/core/onboarding/data/models/onboarding_answers.dart';
import 'package:molobuddy_app/core/onboarding/data/models/onboarding_failure.dart';
import 'package:molobuddy_app/core/onboarding/data/models/onboarding_snapshot.dart';
import 'package:molobuddy_app/core/onboarding/data/services/onboarding_service.dart';

final class HttpOnboardingService implements OnboardingService {
  factory HttpOnboardingService({required Dio dio, required String baseUrl}) {
    return HttpOnboardingService._(
      dio,
      baseUrl.replaceFirst(RegExp(r'/$'), ''),
    );
  }

  HttpOnboardingService._(this._dio, this._baseUrl);

  final Dio _dio;
  final String _baseUrl;

  static Options get _options => Options(
    validateStatus: (_) => true,
    sendTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  );

  @override
  Future<OnboardingResult<OnboardingSnapshot>> load() async {
    try {
      final response = await _dio.get<Object>(
        '$_baseUrl/v1/onboarding',
        options: _options,
      );
      return _snapshotFrom(response);
    } on DioException {
      return const OnboardingError(
        OnboardingFailure(OnboardingFailureKind.networkUnavailable),
      );
    }
  }

  @override
  Future<OnboardingResult<OnboardingSnapshot>> save({
    required OnboardingAnswers answers,
    required String? expectedVersion,
  }) async {
    try {
      final response = await _dio.patch<Object>(
        '$_baseUrl/v1/onboarding',
        data: {'answers': _answerPayload(answers)},
        options: _options.copyWith(
          // A first write has nothing to conflict with, and the server refuses
          // an If-Match for a record that has never existed.
          headers: expectedVersion == null
              ? null
              : {'if-match': expectedVersion},
        ),
      );
      return _snapshotFrom(response);
    } on DioException {
      return const OnboardingError(
        OnboardingFailure(OnboardingFailureKind.networkUnavailable),
      );
    }
  }

  @override
  Future<OnboardingResult<PracticeRef>> complete({
    required String idempotencyKey,
  }) async {
    try {
      final response = await _dio.post<Object>(
        '$_baseUrl/v1/onboarding:complete',
        options: _options.copyWith(
          headers: {'idempotency-key': idempotencyKey},
        ),
      );

      final status = response.statusCode ?? 0;
      if (status != 200 && status != 201) {
        return OnboardingError(_failureFor(response.data));
      }

      final data = _dataOf(response.data);
      final practice = data == null ? null : PracticeRef.fromWire(data);
      if (practice == null) {
        return const OnboardingError(
          OnboardingFailure(OnboardingFailureKind.unexpected),
        );
      }
      return OnboardingSuccess(practice);
    } on DioException {
      return const OnboardingError(
        OnboardingFailure(OnboardingFailureKind.networkUnavailable),
      );
    }
  }

  /// Only the answers that are present.
  ///
  /// A PATCH that sent nulls would clear answers the user never touched, and
  /// the wizard's back button would quietly erase progress.
  static Map<String, Object?> _answerPayload(OnboardingAnswers answers) {
    final practiceName = answers.practiceName;
    final practiceSize = answers.practiceSize;
    final startingPoint = answers.startingPoint;
    return {
      if (practiceName != null && practiceName.isNotEmpty)
        'practiceName': practiceName,
      if (practiceSize != null)
        'practiceSize': practiceSizeWireValue(practiceSize),
      if (answers.priorities.isNotEmpty)
        'priorities': answers.priorities.map(priorityWireValue).toList(),
      if (startingPoint != null)
        'startingPoint': startingPointWireValue(startingPoint),
    };
  }

  static OnboardingResult<OnboardingSnapshot> _snapshotFrom(
    Response<Object> response,
  ) {
    if ((response.statusCode ?? 0) != 200) {
      return OnboardingError(_failureFor(response.data));
    }
    final data = _dataOf(response.data);
    if (data == null) {
      return const OnboardingError(
        OnboardingFailure(OnboardingFailureKind.unexpected),
      );
    }

    final rawAnswers = data['answers'];
    final answers = rawAnswers is Map<String, dynamic>
        ? _answersFrom(rawAnswers)
        : const OnboardingAnswers();

    return OnboardingSuccess(
      OnboardingSnapshot(
        complete: data['status'] == 'complete',
        answers: answers,
        nextStep: onboardingStepFromWire(data['nextStep']),
        version: data['version'] is String ? data['version'] as String : null,
      ),
    );
  }

  static OnboardingAnswers _answersFrom(Map<String, dynamic> raw) {
    final priorities = raw['priorities'];
    return OnboardingAnswers(
      practiceName: raw['practiceName'] is String
          ? raw['practiceName'] as String
          : null,
      practiceSize: practiceSizeFromWire(raw['practiceSize']),
      priorities: priorities is List
          ? priorities.map(priorityFromWire).nonNulls.toSet()
          : const {},
      startingPoint: startingPointFromWire(raw['startingPoint']),
    );
  }

  static Map<String, dynamic>? _dataOf(Object? body) {
    if (body is! Map<String, dynamic>) {
      return null;
    }
    final data = body['data'];
    return data is Map<String, dynamic> ? data : null;
  }

  static OnboardingFailure _failureFor(Object? body) {
    final map = body is Map<String, dynamic> ? body : const <String, dynamic>{};
    final pointer = _firstPointer(map);
    return switch (map['code']) {
      // Both mean the same thing to a client: what you hold is not current.
      // The recovery is identical, so one kind keeps the view simpler.
      'version_mismatch' || 'version_required' => const OnboardingFailure(
        OnboardingFailureKind.versionConflict,
      ),
      'validation_error' => OnboardingFailure(
        OnboardingFailureKind.answerRejected,
        pointer: pointer,
      ),
      'onboarding_incomplete' => OnboardingFailure(
        OnboardingFailureKind.incomplete,
        pointer: pointer,
      ),
      'app_check_required' => const OnboardingFailure(
        OnboardingFailureKind.attestationRequired,
      ),
      'token_invalid' || 'authentication_required' => const OnboardingFailure(
        OnboardingFailureKind.sessionExpired,
      ),
      _ => const OnboardingFailure(OnboardingFailureKind.unexpected),
    };
  }

  static String? _firstPointer(Map<String, dynamic> body) {
    final errors = body['errors'];
    if (errors is! List || errors.isEmpty) {
      return null;
    }
    final first = errors.first;
    if (first is! Map<String, dynamic>) {
      return null;
    }
    final pointer = first['pointer'];
    return pointer is String && pointer.isNotEmpty ? pointer : null;
  }
}
