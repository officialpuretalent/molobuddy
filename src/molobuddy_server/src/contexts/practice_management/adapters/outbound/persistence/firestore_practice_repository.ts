import { FieldValue, type Firestore } from 'firebase-admin/firestore';

import { createResourceVersion } from '../../../../../platform/http/identifiers.js';
import { runInTransaction } from '../../../../../platform/persistence/firestore.js';
import type {
  AuditEvent,
  AuditEventSink,
} from '../../../application/ports/audit_event_sink.js';
import type {
  PracticeRepository,
  ProvisionPracticeOutcome,
  ProvisionPracticeWrite,
} from '../../../application/ports/practice_repository.js';
import type { PracticeRefRecord } from '../../../domain/practice.js';

type StoredIdempotencyKey = Readonly<{ practiceRef: PracticeRefRecord }>;

export class FirestorePracticeRepository implements PracticeRepository {
  constructor(private readonly db: Firestore) {}

  async provision(
    write: ProvisionPracticeWrite,
  ): Promise<ProvisionPracticeOutcome> {
    const uid = write.member.uid;
    const keyDoc = this.db.doc(
      `users/${uid}/idempotencyKeys/${write.idempotencyKey}`,
    );

    return runInTransaction(this.db, async (tx) => {
      // Read first: Firestore requires every read in a transaction to precede
      // its writes, and this read is what makes a replay return the original.
      const existing = (await tx.get(keyDoc)).data() as
        StoredIdempotencyKey | undefined;
      if (existing !== undefined) {
        return { practiceRef: existing.practiceRef, replayed: true };
      }

      const practiceId = write.practice.practiceId;
      // Each resource gets its own freshly minted concurrency token. They are
      // separate resources with separate ETags, so they must not share one.
      tx.set(this.db.doc(`practices/${practiceId}`), {
        ...write.practice,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        version: createResourceVersion(),
      });
      tx.set(this.db.doc(`practices/${practiceId}/members/${uid}`), {
        ...write.member,
        joinedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        version: createResourceVersion(),
      });
      tx.set(
        this.db.doc(`users/${uid}/practiceRefs/${practiceId}`),
        write.practiceRef,
      );
      tx.set(keyDoc, {
        practiceRef: write.practiceRef,
        createdAt: FieldValue.serverTimestamp(),
      });

      return { practiceRef: write.practiceRef, replayed: false };
    });
  }
}

export class FirestoreAuditEventSink implements AuditEventSink {
  constructor(private readonly db: Firestore) {}

  async record(event: AuditEvent): Promise<void> {
    await this.db.collection('auditEvents').add({
      ...event,
      recordedAt: FieldValue.serverTimestamp(),
    });
  }
}
