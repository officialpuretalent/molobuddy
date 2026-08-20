import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';
import 'package:molobuddy_app/core/onboarding/data/models/onboarding_answers.dart';
import 'package:molobuddy_app/core/onboarding/data/models/onboarding_failure.dart';
import 'package:molobuddy_app/core/onboarding/data/models/onboarding_snapshot.dart';
import 'package:molobuddy_app/core/onboarding/data/services/onboarding_service.dart';
import 'package:molobuddy_app/core/onboarding/onboarding_providers.dart';
import 'package:molobuddy_app/core/onboarding/ui/view_models/onboarding_view_model.dart';

const _readyToComplete = OnboardingSnapshot(
  complete: false,
  nextStep: OnboardingStep.readyToComplete,
  version: 'v-1',
  answers: OnboardingAnswers(
    practiceName: 'Mokoena Media Tax',
    practiceSize: PracticeSize.solo,
    priorities: {OnboardingPriority.deadlines},
    startingPoint: WorkspaceStartingPoint.addFirstClient,
  ),
);

const _atPractice = OnboardingSnapshot(
  complete: false,
  nextStep: OnboardingStep.practice,
  answers: OnboardingAnswers(),
);

final class _FakeOnboardingService implements OnboardingService {
  _FakeOnboardingService(this._snapshot);

  OnboardingSnapshot _snapshot;
  final List<String> idempotencyKeys = [];
  final List<String?> savedVersions = [];
  OnboardingFailure? loadFailure;
  OnboardingFailure? saveFailure;
  OnboardingFailure? completeFailure;
  int loads = 0;

  @override
  Future<OnboardingResult<OnboardingSnapshot>> load() async {
    loads += 1;
    final failure = loadFailure;
    if (failure != null) {
      return OnboardingError(failure);
    }
    return OnboardingSuccess(_snapshot);
  }

  @override
  Future<OnboardingResult<OnboardingSnapshot>> save({
    required OnboardingAnswers answers,
    required String? expectedVersion,
  }) async {
    savedVersions.add(expectedVersion);
    final failure = saveFailure;
    if (failure != null) {
      return OnboardingError(failure);
    }
    _snapshot = OnboardingSnapshot(
      complete: false,
      nextStep: OnboardingStep.priorities,
      version: 'v-next',
      answers: answers,
    );
    return OnboardingSuccess(_snapshot);
  }

  @override
  Future<OnboardingResult<PracticeRef>> complete({
    required String idempotencyKey,
  }) async {
    idempotencyKeys.add(idempotencyKey);
    final failure = completeFailure;
    if (failure != null) {
      return OnboardingError(failure);
    }
    return const OnboardingSuccess(
      PracticeRef(
        practiceId: 'prc_1',
        displayLabel: 'Mokoena Media Tax',
        homeRegionKey: 'za1',
        routeVersion: 1,
        accessStatus: PracticeAccessStatus.active,
      ),
    );
  }
}

ProviderContainer _containerWith(OnboardingService service) {
  final container = ProviderContainer(
    overrides: [onboardingServiceProvider.overrideWithValue(service)],
  );
  addTearDown(container.dispose);
  return container;
}

Future<(OnboardingViewModel, ProviderContainer)> _ready(
  OnboardingService service,
) async {
  final container = _containerWith(service);
  await container.read(onboardingViewModelProvider.future);
  return (container.read(onboardingViewModelProvider.notifier), container);
}

OnboardingViewState _stateOf(ProviderContainer container) {
  return container.read(onboardingViewModelProvider).requireValue;
}

void main() {
  test('opens at the step the server derived', () async {
    final (_, container) = await _ready(
      _FakeOnboardingService(_readyToComplete),
    );

    expect(_stateOf(container).step, OnboardingStep.readyToComplete);
    expect(_stateOf(container).answers.practiceName, 'Mokoena Media Tax');
  });

  test('resumes mid-way rather than starting over', () async {
    const partway = OnboardingSnapshot(
      complete: false,
      nextStep: OnboardingStep.startingPoint,
      version: 'v-2',
      answers: OnboardingAnswers(
        practiceName: 'Mokoena Media Tax',
        practiceSize: PracticeSize.solo,
        priorities: {OnboardingPriority.deadlines},
      ),
    );
    final (_, container) = await _ready(_FakeOnboardingService(partway));

    expect(_stateOf(container).step, OnboardingStep.startingPoint);
  });

  test('sends the version it holds and adopts the one it is given', () async {
    final service = _FakeOnboardingService(_atPractice);
    final (model, container) = await _ready(service);

    await model.saveAnswers(
      const OnboardingAnswers(practiceName: 'Mokoena Media Tax'),
    );

    expect(service.savedVersions, [null]);
    expect(_stateOf(container).version, 'v-next');
  });

  test(
    'advances to the step the server derived, never a guessed one',
    () async {
      final service = _FakeOnboardingService(_atPractice);
      final (model, container) = await _ready(service);

      await model.saveAnswers(
        const OnboardingAnswers(practiceName: 'Mokoena Media Tax'),
      );

      expect(_stateOf(container).step, OnboardingStep.priorities);
    },
  );

  test('a failed save keeps the user where they are', () async {
    final service = _FakeOnboardingService(_atPractice)
      ..saveFailure = const OnboardingFailure(
        OnboardingFailureKind.networkUnavailable,
      );
    final (model, container) = await _ready(service);

    await model.saveAnswers(
      const OnboardingAnswers(practiceName: 'Mokoena Media Tax'),
    );

    expect(_stateOf(container).step, OnboardingStep.practice);
    expect(
      _stateOf(container).failure?.kind,
      OnboardingFailureKind.networkUnavailable,
    );
  });

  test('a version conflict reloads rather than retrying blind', () async {
    final service = _FakeOnboardingService(_atPractice)
      ..saveFailure = const OnboardingFailure(
        OnboardingFailureKind.versionConflict,
      );
    final (model, _) = await _ready(service);
    final loadsBefore = service.loads;

    await model.saveAnswers(
      const OnboardingAnswers(practiceName: 'Mokoena Media Tax'),
    );

    expect(service.loads, loadsBefore + 1);
  });

  test('going back moves one step without asking the server', () async {
    final service = _FakeOnboardingService(_readyToComplete);
    final (model, container) = await _ready(service);
    final loadsBefore = service.loads;

    model.goBack();

    expect(_stateOf(container).step, OnboardingStep.startingPoint);
    expect(service.savedVersions, isEmpty);
    expect(service.loads, loadsBefore);
  });

  test('reuses one idempotency key across a retry', () async {
    // A fresh key on retry founds a second practice. This is the reason the
    // view model is keepAlive.
    final service = _FakeOnboardingService(_readyToComplete)
      ..completeFailure = const OnboardingFailure(
        OnboardingFailureKind.networkUnavailable,
      );
    final (model, _) = await _ready(service);

    await model.completeOnboarding();
    service.completeFailure = null;
    await model.completeOnboarding();

    expect(service.idempotencyKeys, hasLength(2));
    expect(service.idempotencyKeys.first, service.idempotencyKeys.last);
  });

  test('a completed onboarding exposes the practice it founded', () async {
    final (model, container) = await _ready(
      _FakeOnboardingService(_readyToComplete),
    );

    await model.completeOnboarding();

    expect(_stateOf(container).completed, isTrue);
    expect(_stateOf(container).practice?.displayLabel, 'Mokoena Media Tax');
  });

  test('a failed read keeps the reason it was given', () async {
    // Reporting every failed read as "unexpected" sent a user with a broken
    // App Check token looking for a bug that was not there.
    final service = _FakeOnboardingService(_atPractice)
      ..loadFailure = const OnboardingFailure(
        OnboardingFailureKind.attestationRequired,
      );
    final (_, container) = await _ready(service);

    expect(
      _stateOf(container).loadFailure?.kind,
      OnboardingFailureKind.attestationRequired,
    );
  });

  test('a failed read is not dressed up as an answerable wizard', () async {
    // The old behaviour invented an empty first step. For anyone resuming,
    // that both hid their stored answers and guaranteed the next save was
    // refused, because it carried no version to match against.
    final service = _FakeOnboardingService(_readyToComplete)
      ..loadFailure = const OnboardingFailure(
        OnboardingFailureKind.networkUnavailable,
      );
    final (_, container) = await _ready(service);

    expect(_stateOf(container).loadFailure, isNotNull);
    expect(_stateOf(container).version, isNull);
  });

  test('retrying a failed read adopts what the server holds', () async {
    final service = _FakeOnboardingService(_readyToComplete)
      ..loadFailure = const OnboardingFailure(
        OnboardingFailureKind.networkUnavailable,
      );
    final (model, container) = await _ready(service);
    service.loadFailure = null;

    await model.reload();

    expect(_stateOf(container).loadFailure, isNull);
    expect(_stateOf(container).step, OnboardingStep.readyToComplete);
    expect(_stateOf(container).version, 'v-1');
  });

  test('a reload that fails again says so rather than clearing', () async {
    final service = _FakeOnboardingService(_readyToComplete)
      ..loadFailure = const OnboardingFailure(
        OnboardingFailureKind.networkUnavailable,
      );
    final (model, container) = await _ready(service);

    await model.reload();

    expect(
      _stateOf(container).loadFailure?.kind,
      OnboardingFailureKind.networkUnavailable,
    );
  });

  test(
    'a conflict whose reload fails does not fall back to step one',
    () async {
      final service = _FakeOnboardingService(_readyToComplete)
        ..saveFailure = const OnboardingFailure(
          OnboardingFailureKind.versionConflict,
        );
      final (model, container) = await _ready(service);
      service.loadFailure = const OnboardingFailure(
        OnboardingFailureKind.networkUnavailable,
      );

      await model.saveAnswers(
        const OnboardingAnswers(practiceName: 'Mokoena Media Tax'),
      );

      expect(_stateOf(container).loadFailure, isNotNull);
    },
  );

  test('a double tap cannot submit twice', () async {
    final service = _FakeOnboardingService(_readyToComplete);
    final (model, _) = await _ready(service);

    await Future.wait([model.completeOnboarding(), model.completeOnboarding()]);

    expect(service.idempotencyKeys, hasLength(1));
  });
}
