import type {
  OnboardingAnswers,
  OnboardingStep,
} from '../../domain/onboarding.js';
import { resumeStepFor } from '../../domain/onboarding.js';
import type { OnboardingRepository } from '../ports/onboarding_repository.js';

export type OnboardingView = Readonly<{
  status: 'in_progress' | 'complete';
  /** Absent once onboarding is complete: there is nowhere left to resume. */
  nextStep?: OnboardingStep;
  answers: OnboardingAnswers;
  /** Absent when nothing is stored yet, which is what a first write expects. */
  version?: string;
}>;

export class GetOnboarding {
  constructor(private readonly repository: OnboardingRepository) {}

  async execute(uid: string): Promise<OnboardingView> {
    const stored = await this.repository.find(uid);
    if (stored === undefined) {
      // Absence is not an error. It reads as "no answers yet", which resumes
      // at the first question and expects a first write with no If-Match.
      return { status: 'in_progress', nextStep: 'practice', answers: {} };
    }
    if (stored.status === 'complete') {
      return {
        status: 'complete',
        answers: stored.answers,
        version: stored.version,
      };
    }
    return {
      status: 'in_progress',
      nextStep: resumeStepFor(stored.answers),
      answers: stored.answers,
      version: stored.version,
    };
  }
}
