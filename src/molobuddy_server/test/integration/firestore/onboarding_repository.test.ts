import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { describe, it } from 'node:test';

import { FirestoreOnboardingRepository } from '../../../src/contexts/practice_management/adapters/outbound/persistence/firestore_onboarding_repository.js';
import type {
  SaveAnswersOutcome,
  StoredOnboarding,
} from '../../../src/contexts/practice_management/application/ports/onboarding_repository.js';
import { getMoloFirestore } from '../../../src/platform/persistence/firestore.js';

const projectId = 'molobuddy-development';

function repository(): FirestoreOnboardingRepository {
  return new FirestoreOnboardingRepository(getMoloFirestore(projectId));
}

/** The stored record, proved present rather than asserted away. */
function present(stored: StoredOnboarding | undefined): StoredOnboarding {
  assert.ok(stored !== undefined, 'expected a stored onboarding record');
  return stored;
}

function saved(outcome: SaveAnswersOutcome): StoredOnboarding {
  assert.equal(outcome.ok, true);
  return outcome.stored;
}

describe('firestore onboarding repository', () => {
  it('has nothing for a user who has never answered', async () => {
    assert.equal(await repository().find(`user_${randomUUID()}`), undefined);
  });

  it('creates the record on a first write with no version', async () => {
    const uid = `user_${randomUUID()}`;
    const store = repository();

    const first = saved(
      await store.save(uid, { practiceName: 'Mokoena Media Tax' }, undefined),
    );

    assert.equal(first.status, 'in_progress');
    assert.equal(first.answers.practiceName, 'Mokoena Media Tax');
    assert.match(first.version, /^[a-f0-9]{32}$/);
    assert.equal(present(await store.find(uid)).version, first.version);
  });

  it('merges a later answer without losing an earlier one', async () => {
    const uid = `user_${randomUUID()}`;
    const store = repository();

    const first = saved(
      await store.save(uid, { practiceSize: 'solo' }, undefined),
    );
    const second = saved(
      await store.save(uid, { priorities: ['deadlines'] }, first.version),
    );

    assert.equal(second.answers.practiceSize, 'solo');
    assert.deepEqual(second.answers.priorities, ['deadlines']);
  });

  it('mints a new version on every write', async () => {
    const uid = `user_${randomUUID()}`;
    const store = repository();

    const first = saved(
      await store.save(uid, { practiceSize: 'solo' }, undefined),
    );
    const second = saved(
      await store.save(uid, { practiceSize: 'small_team' }, first.version),
    );

    // A constant would pass every If-Match comparison and silently remove the
    // protection this whole file exists to prove.
    assert.notEqual(second.version, first.version);
  });

  it('refuses a stale version and changes nothing', async () => {
    const uid = `user_${randomUUID()}`;
    const store = repository();

    const first = saved(
      await store.save(uid, { practiceSize: 'solo' }, undefined),
    );
    saved(await store.save(uid, { practiceSize: 'small_team' }, first.version));

    const stale = await store.save(
      uid,
      { practiceSize: 'growing_team' },
      first.version,
    );

    assert.deepEqual(stale, { ok: false, reason: 'version_mismatch' });
    assert.equal(
      present(await store.find(uid)).answers.practiceSize,
      'small_team',
    );
  });

  it('refuses a write with no version once a record exists', async () => {
    const uid = `user_${randomUUID()}`;
    const store = repository();

    saved(await store.save(uid, { practiceSize: 'solo' }, undefined));

    assert.deepEqual(
      await store.save(uid, { practiceSize: 'small_team' }, undefined),
      { ok: false, reason: 'version_required' },
    );
  });

  it('refuses a version for a record that does not exist', async () => {
    const outcome = await repository().save(
      `user_${randomUUID()}`,
      { practiceSize: 'solo' },
      'a'.repeat(32),
    );

    assert.deepEqual(outcome, { ok: false, reason: 'version_mismatch' });
  });

  it('lets only one of two racing writes win', async () => {
    const uid = `user_${randomUUID()}`;
    const store = repository();
    const first = saved(
      await store.save(uid, { practiceSize: 'solo' }, undefined),
    );

    const [a, b] = await Promise.all([
      store.save(uid, { priorities: ['deadlines'] }, first.version),
      store.save(uid, { priorities: ['documents'] }, first.version),
    ]);

    assert.equal([a.ok, b.ok].filter(Boolean).length, 1);
  });
});
