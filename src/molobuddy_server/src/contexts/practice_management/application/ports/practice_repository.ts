import type { OnboardingAnswers } from '../../domain/onboarding.js';
import type {
  Practice,
  PracticeMemberRecord,
  PracticeRefRecord,
} from '../../domain/practice.js';

/**
 * Present when this practice is being founded by finishing onboarding.
 *
 * Carried on the write rather than done as a second call, so the founding
 * answers and the completed onboarding record commit with the practice. A
 * separate call could leave a practice whose onboarding still says it is
 * outstanding, which would route its owner back into a wizard.
 */
export type FoundingOnboarding = Readonly<{
  uid: string;
  answers: OnboardingAnswers;
}>;

export type ProvisionPracticeWrite = Readonly<{
  practice: Practice;
  member: PracticeMemberRecord;
  practiceRef: PracticeRefRecord;
  idempotencyKey: string;
  founding?: FoundingOnboarding;
}>;

export type ProvisionPracticeOutcome = Readonly<{
  practiceRef: PracticeRefRecord;
  /** True when a stored idempotency key made this a replay rather than a creation. */
  replayed: boolean;
}>;

export interface PracticeRepository {
  /**
   * Writes the practice, its founding owner, the routing projection and the
   * idempotency key atomically, or returns the earlier result for a key that
   * has already been used by this actor.
   */
  provision(write: ProvisionPracticeWrite): Promise<ProvisionPracticeOutcome>;
}
