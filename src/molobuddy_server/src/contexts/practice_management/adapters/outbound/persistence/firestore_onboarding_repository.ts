import { FieldValue, type Firestore } from 'firebase-admin/firestore';

import { createResourceVersion } from '../../../../../platform/http/identifiers.js';
import { runInTransaction } from '../../../../../platform/persistence/firestore.js';
import type {
  OnboardingRepository,
  SaveAnswersOutcome,
  StoredOnboarding,
} from '../../../application/ports/onboarding_repository.js';
import { mergeAnswers } from '../../../domain/onboarding.js';
import type { OnboardingAnswers } from '../../../domain/onboarding.js';

type StoredShape = Readonly<{
  status: 'in_progress' | 'complete';
  answers: OnboardingAnswers;
  completedPracticeId?: string;
  version: string;
}>;

/**
 * The one path this record lives at.
 *
 * An adapter in identity_access reads the same document to answer the session
 * gate. It cannot import this constant without creating a context cycle, so
 * the path is recorded in the data design and both adapters are checked
 * against that.
 */
export function onboardingPath(uid: string): string {
  return `users/${uid}/onboarding/current`;
}

export class FirestoreOnboardingRepository implements OnboardingRepository {
  constructor(private readonly db: Firestore) {}

  async find(uid: string): Promise<StoredOnboarding | undefined> {
    return (await this.db.doc(onboardingPath(uid)).get()).data() as
      StoredShape | undefined;
  }

  async save(
    uid: string,
    patch: OnboardingAnswers,
    expectedVersion: string | undefined,
  ): Promise<SaveAnswersOutcome> {
    const document = this.db.doc(onboardingPath(uid));

    return runInTransaction(this.db, async (tx) => {
      // Read first: Firestore requires every read in a transaction to precede
      // its writes, and this read is what If-Match is compared against.
      const existing = (await tx.get(document)).data() as
        StoredShape | undefined;

      if (existing === undefined) {
        if (expectedVersion !== undefined) {
          // A version for a record that has never existed cannot match.
          return { ok: false, reason: 'version_mismatch' } as const;
        }
        const created: StoredShape = {
          status: 'in_progress',
          answers: patch,
          version: createResourceVersion(),
        };
        tx.set(document, {
          uid,
          ...created,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
        return { ok: true, stored: created } as const;
      }

      if (existing.status === 'complete') {
        return { ok: false, reason: 'already_complete' } as const;
      }
      if (expectedVersion === undefined) {
        return { ok: false, reason: 'version_required' } as const;
      }
      if (expectedVersion !== existing.version) {
        return { ok: false, reason: 'version_mismatch' } as const;
      }

      const updated: StoredShape = {
        status: 'in_progress',
        answers: mergeAnswers(existing.answers, patch),
        version: createResourceVersion(),
      };
      tx.set(
        document,
        { ...updated, updatedAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
      return { ok: true, stored: updated } as const;
    });
  }
}
