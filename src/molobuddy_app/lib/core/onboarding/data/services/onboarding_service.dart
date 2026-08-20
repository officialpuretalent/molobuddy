import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';
import 'package:molobuddy_app/core/onboarding/data/models/onboarding_answers.dart';
import 'package:molobuddy_app/core/onboarding/data/models/onboarding_failure.dart';
import 'package:molobuddy_app/core/onboarding/data/models/onboarding_snapshot.dart';

abstract interface class OnboardingService {
  Future<OnboardingResult<OnboardingSnapshot>> load();

  /// Saves one step's answers. [expectedVersion] is the token from the last
  /// snapshot, and is null only before anything has been stored.
  Future<OnboardingResult<OnboardingSnapshot>> save({
    required OnboardingAnswers answers,
    required String? expectedVersion,
  });

  /// Founds the practice. [idempotencyKey] is minted once per wizard, so a
  /// retry after a timeout cannot create a second practice.
  Future<OnboardingResult<PracticeRef>> complete({
    required String idempotencyKey,
  });
}

/// Used when no API base URL is configured.
final class UnavailableOnboardingService implements OnboardingService {
  const UnavailableOnboardingService();

  @override
  Future<OnboardingResult<OnboardingSnapshot>> load() async =>
      _unavailable<OnboardingSnapshot>();

  @override
  Future<OnboardingResult<OnboardingSnapshot>> save({
    required OnboardingAnswers answers,
    required String? expectedVersion,
  }) async => _unavailable<OnboardingSnapshot>();

  @override
  Future<OnboardingResult<PracticeRef>> complete({
    required String idempotencyKey,
  }) async => _unavailable<PracticeRef>();

  static OnboardingError<T> _unavailable<T>() {
    return const OnboardingError(
      OnboardingFailure(OnboardingFailureKind.configurationMissing),
    );
  }
}
