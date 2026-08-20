import type { OnboardingAnswers } from '../../domain/onboarding.js';

export type StoredOnboarding = Readonly<{
  status: 'in_progress' | 'complete';
  answers: OnboardingAnswers;
  completedPracticeId?: string;
  version: string;
}>;

export type SaveAnswersOutcome =
  | Readonly<{ ok: true; stored: StoredOnboarding }>
  | Readonly<{
      ok: false;
      reason: 'version_mismatch' | 'version_required' | 'already_complete';
    }>;

export interface OnboardingRepository {
  /** The record, or undefined when this user has never answered anything. */
  find(uid: string): Promise<StoredOnboarding | undefined>;

  /**
   * Merges `patch` into the stored answers under optimistic concurrency.
   *
   * `expectedVersion` is the caller's `If-Match`. It is undefined on a first
   * write, when there is no record to conflict with; a record that already
   * exists refuses an undefined version rather than overwriting blindly.
   */
  save(
    uid: string,
    patch: OnboardingAnswers,
    expectedVersion: string | undefined,
  ): Promise<SaveAnswersOutcome>;
}
