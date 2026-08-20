import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { describe, it } from 'node:test';

import type { Firestore } from 'firebase-admin/firestore';

import { FirestorePracticeRepository } from '../../../src/contexts/practice_management/adapters/outbound/persistence/firestore_practice_repository.js';
import type { ProvisionPracticeWrite } from '../../../src/contexts/practice_management/application/ports/practice_repository.js';
import { getMoloFirestore } from '../../../src/platform/persistence/firestore.js';

const projectId = 'molobuddy-development';

function writeFor(uid: string, key: string): ProvisionPracticeWrite {
  const practiceId = `prc_${randomUUID().replaceAll('-', '')}`;
  return {
    idempotencyKey: key,
    practice: {
      practiceId,
      displayName: 'Mokoena Media Tax',
      homeRegionKey: 'za1',
      routeVersion: 1,
      status: 'active',
      createdByUid: uid,
    },
    member: {
      practiceId,
      uid,
      role: 'owner',
      status: 'active',
      displayName: 'Thando Mokoena',
      emailLower: 'thando@example.com',
    },
    practiceRef: {
      practiceId,
      displayLabel: 'Mokoena Media Tax',
      homeRegionKey: 'za1',
      routeVersion: 1,
      accessStatus: 'active',
    },
  };
}

/** The stored document, proved present rather than asserted away. */
async function storedAt(
  db: Firestore,
  path: string,
): Promise<Record<string, unknown>> {
  const data = (await db.doc(path).get()).data();
  assert.ok(data !== undefined, `no document at ${path}`);
  return data;
}

function stringField(data: Record<string, unknown>, field: string): string {
  const value = data[field];
  assert.ok(typeof value === 'string', `${field} is not a string`);
  return value;
}

describe('firestore practice repository', () => {
  it('writes the practice, the owner and the projection together', async () => {
    const db = getMoloFirestore(projectId);
    const repository = new FirestorePracticeRepository(db);
    const uid = `user_${randomUUID()}`;
    const write = writeFor(uid, 'key-1');

    const outcome = await repository.provision(write);

    assert.equal(outcome.replayed, false);
    const id = write.practice.practiceId;
    assert.equal((await db.doc(`practices/${id}`).get()).exists, true);
    assert.equal(
      stringField(await storedAt(db, `practices/${id}/members/${uid}`), 'role'),
      'owner',
    );
    assert.equal(
      stringField(
        await storedAt(db, `users/${uid}/practiceRefs/${id}`),
        'displayLabel',
      ),
      'Mokoena Media Tax',
    );
  });

  it('creates exactly one practice when a key is replayed', async () => {
    const db = getMoloFirestore(projectId);
    const repository = new FirestorePracticeRepository(db);
    const uid = `user_${randomUUID()}`;

    const first = await repository.provision(writeFor(uid, 'shared-key'));
    const second = await repository.provision(writeFor(uid, 'shared-key'));

    assert.equal(first.replayed, false);
    assert.equal(second.replayed, true);
    assert.equal(second.practiceRef.practiceId, first.practiceRef.practiceId);

    const refs = await db.collection(`users/${uid}/practiceRefs`).get();
    assert.equal(refs.size, 1);
  });

  it('creates one practice when two identical requests race', async () => {
    const db = getMoloFirestore(projectId);
    const repository = new FirestorePracticeRepository(db);
    const uid = `user_${randomUUID()}`;

    const [a, b] = await Promise.all([
      repository.provision(writeFor(uid, 'race-key')),
      repository.provision(writeFor(uid, 'race-key')),
    ]);

    assert.equal(a.practiceRef.practiceId, b.practiceRef.practiceId);
    assert.equal(
      (await db.collection(`users/${uid}/practiceRefs`).get()).size,
      1,
    );
    assert.equal([a.replayed, b.replayed].filter(Boolean).length, 1);
  });

  it('gives each record its own concurrency token, and none to the projection', async () => {
    const db = getMoloFirestore(projectId);
    const repository = new FirestorePracticeRepository(db);
    const uid = `user_${randomUUID()}`;
    const write = writeFor(uid, 'version-key');

    await repository.provision(write);

    const id = write.practice.practiceId;
    const practice = await storedAt(db, `practices/${id}`);
    const member = await storedAt(db, `practices/${id}/members/${uid}`);
    const ref = await storedAt(db, `users/${uid}/practiceRefs/${id}`);

    // A hardcoded constant would pass the format check but fail this: two
    // resources sharing one token means one ETag can validate the other.
    assert.match(stringField(practice, 'version'), /^[a-f0-9]{32}$/);
    assert.match(stringField(member, 'version'), /^[a-f0-9]{32}$/);
    assert.notEqual(
      stringField(practice, 'version'),
      stringField(member, 'version'),
    );

    // The projection is server-owned and never PATCHed, so it carries no token.
    assert.equal(ref['version'], undefined);
  });

  it('keeps one user’s key from colliding with another’s', async () => {
    const db = getMoloFirestore(projectId);
    const repository = new FirestorePracticeRepository(db);
    const first = `user_${randomUUID()}`;
    const second = `user_${randomUUID()}`;

    const a = await repository.provision(writeFor(first, 'same-key'));
    const b = await repository.provision(writeFor(second, 'same-key'));

    assert.equal(b.replayed, false);
    assert.notEqual(a.practiceRef.practiceId, b.practiceRef.practiceId);
  });

  it('records the founding answers and completes onboarding in the same write', async () => {
    const db = getMoloFirestore(projectId);
    const repository = new FirestorePracticeRepository(db);
    const uid = `user_${randomUUID()}`;
    const answers = {
      practiceName: 'Mokoena Media Tax',
      practiceSize: 'solo' as const,
      priorities: ['deadlines' as const],
      startingPoint: 'add_first_client' as const,
    };
    const write = {
      ...writeFor(uid, 'founding-key'),
      founding: { uid, answers },
    };
    await db
      .doc(`users/${uid}/onboarding/current`)
      .set({ uid, status: 'in_progress', answers, version: 'v-before' });

    const outcome = await repository.provision(write);

    const id = outcome.practiceRef.practiceId;
    const recorded = await storedAt(db, `practices/${id}/onboarding/founding`);
    assert.equal(recorded['foundedByUid'], uid);
    assert.deepEqual(recorded['answers'], answers);
    // A survey nothing updates carries no concurrency token.
    assert.equal(recorded['version'], undefined);

    const onboarding = await storedAt(db, `users/${uid}/onboarding/current`);
    assert.equal(onboarding['status'], 'complete');
    assert.equal(onboarding['completedPracticeId'], id);
    assert.notEqual(onboarding['version'], 'v-before');
  });

  it('returns the first practice when onboarding completed concurrently', async () => {
    const db = getMoloFirestore(projectId);
    const repository = new FirestorePracticeRepository(db);
    const uid = `user_${randomUUID()}`;
    const answers = { practiceName: 'Mokoena Media Tax' };

    const first = await repository.provision({
      ...writeFor(uid, 'first-key'),
      founding: { uid, answers },
    });
    // A different key, so the idempotency read cannot catch this. Only the
    // completed onboarding record can, and it must, or a user who submits
    // twice founds two practices.
    const second = await repository.provision({
      ...writeFor(uid, 'second-key'),
      founding: { uid, answers },
    });

    assert.equal(second.replayed, true);
    assert.equal(second.practiceRef.practiceId, first.practiceRef.practiceId);
    assert.equal(
      (await db.collection(`users/${uid}/practiceRefs`).get()).size,
      1,
    );
  });

  it('writes no founding record when a practice is created outside onboarding', async () => {
    const db = getMoloFirestore(projectId);
    const repository = new FirestorePracticeRepository(db);
    const uid = `user_${randomUUID()}`;
    const write = writeFor(uid, 'plain-key');

    await repository.provision(write);

    assert.equal(
      (
        await db
          .doc(`practices/${write.practice.practiceId}/onboarding/founding`)
          .get()
      ).exists,
      false,
    );
  });
});
