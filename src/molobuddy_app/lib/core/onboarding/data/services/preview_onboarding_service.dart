import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';
import 'package:molobuddy_app/core/onboarding/data/models/onboarding_answers.dart';
import 'package:molobuddy_app/core/onboarding/data/models/onboarding_failure.dart';
import 'package:molobuddy_app/core/onboarding/data/models/onboarding_snapshot.dart';
import 'package:molobuddy_app/core/onboarding/data/services/onboarding_service.dart';

/// Onboarding for a build with no backend.
///
/// Enforces the same `If-Match` rule the real server does. A preview that
/// accepted any version would let a concurrency bug survive every
/// demonstration and only appear against the real API.
final class PreviewOnboardingService implements OnboardingService {
  OnboardingAnswers _answers = const OnboardingAnswers();
  String? _version;
  bool _complete = false;
  PracticeRef? _founded;
  int _counter = 0;

  /// What preview onboarding has founded, for the preview session to report.
  List<PracticeRef> get foundedPractices {
    final practice = _founded;
    return practice == null ? const [] : [practice];
  }

  @override
  Future<OnboardingResult<OnboardingSnapshot>> load() async {
    return OnboardingSuccess(_snapshot());
  }

  @override
  Future<OnboardingResult<OnboardingSnapshot>> save({
    required OnboardingAnswers answers,
    required String? expectedVersion,
  }) async {
    if (_complete) {
      return const OnboardingError(
        OnboardingFailure(OnboardingFailureKind.unexpected),
      );
    }
    final current = _version;
    if (current == null) {
      if (expectedVersion != null) {
        return _conflict();
      }
    } else if (expectedVersion != current) {
      return _conflict();
    }

    _answers = _answers.copyWith(
      practiceName: answers.practiceName,
      practiceSize: answers.practiceSize,
      priorities: answers.priorities.isEmpty ? null : answers.priorities,
      startingPoint: answers.startingPoint,
    );
    _counter += 1;
    _version = 'preview-v$_counter';
    return OnboardingSuccess(_snapshot());
  }

  @override
  Future<OnboardingResult<PracticeRef>> complete({
    required String idempotencyKey,
  }) async {
    final founded = _founded;
    if (founded != null) {
      // The key already founded this one. Answering with it rather than a
      // second practice is what the real endpoint does.
      return OnboardingSuccess(founded);
    }
    if (_missingAnswer() != null) {
      return OnboardingError(
        OnboardingFailure(
          OnboardingFailureKind.incomplete,
          pointer: _missingAnswer(),
        ),
      );
    }

    final practice = PracticeRef(
      practiceId: 'prc_preview_${idempotencyKey.hashCode.abs()}',
      displayLabel: _answers.practiceName ?? 'Your practice',
      homeRegionKey: 'za1',
      routeVersion: 1,
      accessStatus: PracticeAccessStatus.active,
    );
    _founded = practice;
    _complete = true;
    return OnboardingSuccess(practice);
  }

  OnboardingSnapshot _snapshot() {
    return OnboardingSnapshot(
      complete: _complete,
      answers: _answers,
      nextStep: _complete ? null : _resumeStep(),
      version: _version,
    );
  }

  /// Mirrors the server's derivation so a preview run resumes where a real one
  /// would. Preview is the only place this rule is duplicated, and it is
  /// duplicated because preview has no server to ask.
  OnboardingStep _resumeStep() {
    if (_answers.practiceName == null || _answers.practiceSize == null) {
      return OnboardingStep.practice;
    }
    if (_answers.priorities.isEmpty) {
      return OnboardingStep.priorities;
    }
    if (_answers.startingPoint == null) {
      return OnboardingStep.startingPoint;
    }
    return OnboardingStep.readyToComplete;
  }

  String? _missingAnswer() {
    if (_answers.practiceName == null) return '/answers/practiceName';
    if (_answers.practiceSize == null) return '/answers/practiceSize';
    if (_answers.priorities.isEmpty) return '/answers/priorities';
    if (_answers.startingPoint == null) return '/answers/startingPoint';
    return null;
  }

  static OnboardingError<OnboardingSnapshot> _conflict() {
    return const OnboardingError(
      OnboardingFailure(OnboardingFailureKind.versionConflict),
    );
  }
}
