import 'dart:math';

import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';
import 'package:molobuddy_app/core/onboarding/data/models/onboarding_answers.dart';
import 'package:molobuddy_app/core/onboarding/data/models/onboarding_failure.dart';
import 'package:molobuddy_app/core/onboarding/data/models/onboarding_snapshot.dart';
import 'package:molobuddy_app/core/onboarding/onboarding_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_view_model.g.dart';

final class OnboardingViewState {
  const OnboardingViewState({
    required this.step,
    required this.answers,
    this.version,
    this.busy = false,
    this.failure,
    this.loadFailure,
    this.completed = false,
    this.practice,
    this.draftPracticeName,
  });

  final OnboardingStep step;
  final OnboardingAnswers answers;

  /// The concurrency token the next save must echo, straight from the server.
  final String? version;

  /// A request is in flight. Every mutating method refuses while this is set,
  /// so a double tap cannot dispatch twice.
  final bool busy;

  /// Why the last action was refused. The wizard is still usable.
  final OnboardingFailure? failure;

  /// Why the wizard could not be read at all, and nothing else.
  ///
  /// Kept apart from [failure] because the recovery differs: a refused answer
  /// leaves a wizard to correct, a refused read leaves nothing to answer. Set
  /// only where a load result is settled, which is why [copyWith] carries it
  /// through rather than accepting it.
  final OnboardingFailure? loadFailure;

  final bool completed;
  final PracticeRef? practice;

  /// What the user has typed but not yet saved.
  ///
  /// Kept so the supporting panel can preview the practice name live, as it
  /// did when the whole wizard was in memory. It costs no request: saving
  /// happens when the step advances, not on every keystroke.
  final String? draftPracticeName;

  OnboardingViewState copyWith({
    OnboardingStep? step,
    OnboardingAnswers? answers,
    String? version,
    bool? busy,
    OnboardingFailure? failure,
    bool clearFailure = false,
    bool? completed,
    PracticeRef? practice,
    String? draftPracticeName,
  }) {
    return OnboardingViewState(
      step: step ?? this.step,
      answers: answers ?? this.answers,
      version: version ?? this.version,
      busy: busy ?? this.busy,
      failure: clearFailure ? null : failure ?? this.failure,
      loadFailure: loadFailure,
      completed: completed ?? this.completed,
      practice: practice ?? this.practice,
      draftPracticeName: draftPracticeName ?? this.draftPracticeName,
    );
  }
}

/// Drives the part of signup that happens after the account exists.
///
/// Deliberately `keepAlive`. The idempotency key must outlive a widget
/// rebuild: an auto-disposed model would mint a new one when the tree
/// rebuilt, and a retry would then found a second practice.
@Riverpod(keepAlive: true)
class OnboardingViewModel extends _$OnboardingViewModel {
  /// Minted once for the life of this wizard, so a retry after a timeout
  /// carries the same key the timed-out attempt did. That is the entire reason
  /// the server accepts a key at all.
  final String _idempotencyKey = 'onb_${_randomToken()}';

  @override
  Future<OnboardingViewState> build() async {
    return _stateFrom(await _load());
  }

  /// Asks the server for the wizard again after a read that failed.
  ///
  /// The only recovery from [OnboardingViewState.loadFailure]: without it a
  /// user whose token lapsed mid-signup has to reload the whole application.
  Future<void> reload() async {
    final current = _current();
    if (current == null || current.busy) {
      return;
    }
    state = AsyncData(current.copyWith(busy: true, clearFailure: true));

    final reloaded = await _load();
    if (!ref.mounted) {
      return;
    }
    state = AsyncData(_stateFrom(reloaded));
  }

  /// Saves one step's answers, then moves to wherever the server says next.
  Future<void> saveAnswers(OnboardingAnswers answers) async {
    final current = _current();
    if (current == null || current.busy) {
      return;
    }
    state = AsyncData(current.copyWith(busy: true, clearFailure: true));

    final result = await ref
        .read(onboardingServiceProvider)
        .save(answers: answers, expectedVersion: current.version);
    if (!ref.mounted) {
      return;
    }

    switch (result) {
      case OnboardingSuccess():
        state = AsyncData(_stateFrom(result));
      case OnboardingError(:final failure):
        if (failure.kind == OnboardingFailureKind.versionConflict) {
          // Someone else wrote first, most likely another tab. Retrying with
          // the token we hold would fail identically forever, so reload and
          // show what is actually stored.
          await _reloadAfterConflict();
          return;
        }
        state = AsyncData(current.copyWith(busy: false, failure: failure));
    }
  }

  /// Records what the user has typed, for the live preview only. Never a
  /// request: the answer is saved when the step advances.
  void previewPracticeName(String value) {
    final current = _current();
    if (current == null) {
      return;
    }
    state = AsyncData(current.copyWith(draftPracticeName: value.trim()));
  }

  /// Moves back one step. Purely local: nothing is unsaved, so there is
  /// nothing to tell the server.
  void goBack() {
    final current = _current();
    if (current == null || current.busy) {
      return;
    }
    final previous = switch (current.step) {
      OnboardingStep.practice => OnboardingStep.practice,
      OnboardingStep.priorities => OnboardingStep.practice,
      OnboardingStep.startingPoint => OnboardingStep.priorities,
      OnboardingStep.readyToComplete => OnboardingStep.startingPoint,
    };
    state = AsyncData(current.copyWith(step: previous, clearFailure: true));
  }

  /// Founds the practice, carrying the one key this wizard owns.
  Future<void> completeOnboarding() async {
    final current = _current();
    if (current == null || current.busy || current.completed) {
      return;
    }
    state = AsyncData(current.copyWith(busy: true, clearFailure: true));

    final result = await ref
        .read(onboardingServiceProvider)
        .complete(idempotencyKey: _idempotencyKey);
    if (!ref.mounted) {
      return;
    }

    state = AsyncData(switch (result) {
      OnboardingSuccess(:final value) => current.copyWith(
        busy: false,
        completed: true,
        practice: value,
        clearFailure: true,
      ),
      OnboardingError(:final failure) => current.copyWith(
        busy: false,
        failure: failure,
      ),
    });
  }

  Future<void> _reloadAfterConflict() async {
    final reloaded = await _load();
    if (!ref.mounted) {
      return;
    }
    // Saying "we have loaded the latest answers" on top of a read that failed
    // would be a state that contradicts itself. The read failure is the whole
    // story in that case.
    final next = _stateFrom(reloaded);
    state = AsyncData(
      next.loadFailure != null
          ? next
          : next.copyWith(
              failure: const OnboardingFailure(
                OnboardingFailureKind.versionConflict,
              ),
            ),
    );
  }

  Future<OnboardingResult<OnboardingSnapshot>> _load() {
    return ref.read(onboardingServiceProvider).load();
  }

  OnboardingViewState? _current() {
    return switch (state) {
      AsyncData(:final value) => value,
      _ => null,
    };
  }

  /// The step always comes from the server.
  ///
  /// Computing it here as well would be a second copy of one rule, and a
  /// resumed wizard would open on a question the user already answered.
  static OnboardingViewState _stateFrom(
    OnboardingResult<OnboardingSnapshot> result,
  ) {
    return switch (result) {
      OnboardingSuccess(:final value) => OnboardingViewState(
        step: value.nextStep ?? OnboardingStep.readyToComplete,
        answers: value.answers,
        version: value.version,
        completed: value.complete,
      ),
      // A failed read is carried, reason and all, rather than turned into an
      // empty first step. Inventing one hid the answers a returning user had
      // already given, and guaranteed their next save was refused: it would
      // have carried no version for the server to match against. The reason
      // travels because "we could not verify this device" and "something went
      // wrong" send a person looking in completely different places.
      OnboardingError(:final failure) => OnboardingViewState(
        step: OnboardingStep.practice,
        answers: const OnboardingAnswers(),
        loadFailure: failure,
      ),
    };
  }

  static String _randomToken() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
