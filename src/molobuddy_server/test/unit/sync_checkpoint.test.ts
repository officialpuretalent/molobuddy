import assert from 'node:assert/strict';
import test from 'node:test';

import {
  mayAcquireLease,
  mayAdvanceCheckpoint,
  type SyncCheckpoint,
} from '../../src/contexts/connectors/index.js';

const checkpoint: SyncCheckpoint = {
  practiceId: 'prc_123',
  connectionId: 'con_123',
  dataSourceId: 'src_123',
  recordKind: 'invoice',
  lease: { holderId: 'worker_a', expiresAt: '2026-08-22T12:00:00.000Z' },
};

test('a sync checkpoint permits only its live lease holder to advance', () => {
  assert.equal(
    mayAdvanceCheckpoint(checkpoint, 'worker_a', '2026-08-22T11:59:59.000Z'),
    true,
  );
  assert.equal(
    mayAdvanceCheckpoint(checkpoint, 'worker_b', '2026-08-22T11:59:59.000Z'),
    false,
  );
});

test('an expired lease may be acquired by another worker', () => {
  assert.equal(
    mayAcquireLease(checkpoint, 'worker_b', '2026-08-22T12:00:00.000Z'),
    true,
  );
});
