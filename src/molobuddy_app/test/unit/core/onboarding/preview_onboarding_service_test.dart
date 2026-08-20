import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';
import 'package:molobuddy_app/core/onboarding/data/models/onboarding_answers.dart';
import 'package:molobuddy_app/core/onboarding/data/models/onboarding_failure.dart';
import 'package:molobuddy_app/core/onboarding/data/models/onboarding_snapshot.dart';
import 'package:molobuddy_app/core/onboarding/data/services/preview_onboarding_service.dart';

OnboardingSnapshot _saved(OnboardingResult<OnboardingSnapshot> result) {
  return (result as OnboardingSuccess<OnboardingSnapshot>).value;
}

void main() {
  test('starts at the first question with nothing stored', () async {
    final service = PreviewOnboardingService();

    final snapshot = _saved(await service.load());

    expect(snapshot.complete, isFalse);
    expect(snapshot.nextStep, OnboardingStep.practice);
    expect(snapshot.version, isNull);
  });

  test('advances the derived step as answers arrive', () async {
    final service = PreviewOnboardingService();

    final first = _saved(
      await service.save(
        answers: const OnboardingAnswers(
          practiceName: 'Mokoena Media Tax',
          practiceSize: PracticeSize.solo,
        ),
        expectedVersion: null,
      ),
    );
    expect(first.nextStep, OnboardingStep.priorities);

    final second = _saved(
      await service.save(
        answers: const OnboardingAnswers(
          priorities: {OnboardingPriority.deadlines},
        ),
        expectedVersion: first.version,
      ),
    );
    expect(second.nextStep, OnboardingStep.startingPoint);
    expect(second.answers.practiceName, 'Mokoena Media Tax');
  });

  test('refuses a stale version, exactly as the real server does', () async {
    // A preview that accepted any version would let a concurrency bug survive
    // every demonstration and appear only against the real API.
    final service = PreviewOnboardingService();
    final first = _saved(
      await service.save(
        answers: const OnboardingAnswers(practiceSize: PracticeSize.solo),
        expectedVersion: null,
      ),
    );
    await service.save(
      answers: const OnboardingAnswers(practiceSize: PracticeSize.smallTeam),
      expectedVersion: first.version,
    );

    final stale = await service.save(
      answers: const OnboardingAnswers(practiceSize: PracticeSize.growingTeam),
      expectedVersion: first.version,
    );

    expect(
      (stale as OnboardingError<OnboardingSnapshot>).failure.kind,
      OnboardingFailureKind.versionConflict,
    );
  });

  test('refuses completion while an answer is missing', () async {
    final service = PreviewOnboardingService();
    await service.save(
      answers: const OnboardingAnswers(
        practiceName: 'Mokoena Media Tax',
        practiceSize: PracticeSize.solo,
      ),
      expectedVersion: null,
    );

    final result = await service.complete(idempotencyKey: 'onb_1');

    final failure = (result as OnboardingError<PracticeRef>).failure;
    expect(failure.kind, OnboardingFailureKind.incomplete);
    expect(failure.pointer, '/answers/priorities');
  });

  test('founds one practice and reports it to the session', () async {
    final service = PreviewOnboardingService();
    var version = _saved(
      await service.save(
        answers: const OnboardingAnswers(
          practiceName: 'Mokoena Media Tax',
          practiceSize: PracticeSize.solo,
        ),
        expectedVersion: null,
      ),
    ).version;
    version = _saved(
      await service.save(
        answers: const OnboardingAnswers(
          priorities: {OnboardingPriority.deadlines},
        ),
        expectedVersion: version,
      ),
    ).version;
    await service.save(
      answers: const OnboardingAnswers(
        startingPoint: WorkspaceStartingPoint.addFirstClient,
      ),
      expectedVersion: version,
    );

    final first = await service.complete(idempotencyKey: 'onb_1');
    final replay = await service.complete(idempotencyKey: 'onb_1');

    final practice = (first as OnboardingSuccess<PracticeRef>).value;
    expect(practice.displayLabel, 'Mokoena Media Tax');
    expect((replay as OnboardingSuccess<PracticeRef>).value, practice);
    expect(service.foundedPractices, [practice]);
    expect(_saved(await service.load()).complete, isTrue);
  });
}
