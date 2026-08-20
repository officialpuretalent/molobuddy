import type {
  Practice,
  PracticeMemberRecord,
  PracticeRefRecord,
} from '../../domain/practice.js';

export type ProvisionPracticeWrite = Readonly<{
  practice: Practice;
  member: PracticeMemberRecord;
  practiceRef: PracticeRefRecord;
  idempotencyKey: string;
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
