import 'package:molobuddy_app/core/onboarding/data/models/onboarding_answers.dart';

final class OnboardingSnapshot {
  const OnboardingSnapshot({
    required this.complete,
    required this.answers,
    this.nextStep,
    this.version,
  });

  final bool complete;
  final OnboardingAnswers answers;

  /// Absent once onboarding is complete: there is nowhere left to resume.
  final OnboardingStep? nextStep;

  /// The concurrency token the next save must echo back as `If-Match`.
  /// Absent before anything has been stored, which is what a first save wants.
  final String? version;
}
