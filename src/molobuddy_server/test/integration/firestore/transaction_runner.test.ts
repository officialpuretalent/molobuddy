import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import {
  getMoloFirestore,
  runInTransaction,
} from '../../../src/platform/persistence/firestore.js';

const projectId = 'molobuddy-development';

describe('firestore transaction runner', () => {
  it('commits every write in the transaction together', async () => {
    const db = getMoloFirestore(projectId);
    const first = db.doc('transactionRunnerTest/first');
    const second = db.doc('transactionRunnerTest/second');

    await runInTransaction(db, async (tx) => {
      tx.set(first, { value: 'a' });
      tx.set(second, { value: 'b' });
    });

    assert.equal((await first.get()).data()?.['value'], 'a');
    assert.equal((await second.get()).data()?.['value'], 'b');
  });

  it('commits nothing when the work throws', async () => {
    const db = getMoloFirestore(projectId);
    const doc = db.doc('transactionRunnerTest/rolledBack');

    await assert.rejects(
      runInTransaction(db, async (tx) => {
        tx.set(doc, { value: 'written' });
        throw new Error('work failed');
      }),
      /work failed/,
    );

    assert.equal((await doc.get()).exists, false);
  });

  it('returns one client for repeated calls', () => {
    assert.equal(getMoloFirestore(projectId), getMoloFirestore(projectId));
  });
});
