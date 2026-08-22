import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { describe, it } from 'node:test';

import {
  FirestoreConnectorLifecycleStore,
  type ConnectorLifecycleCommit,
} from '../../../src/contexts/connectors/index.js';
import { getMoloFirestore } from '../../../src/platform/persistence/firestore.js';

const projectId = 'molobuddy-development';

function writeFor(
  practiceId: string,
  overrides: Partial<ConnectorLifecycleCommit> = {},
): ConnectorLifecycleCommit {
  const connectionId = `con_${randomUUID().replaceAll('-', '')}`;
  return {
    connection: {
      connectionId,
      practiceId,
      providerKey: 'xero',
      connectorVersion: '0.1.0',
      status: 'authorising',
      requestedCapabilities: ['contacts.read'],
      grantedCapabilities: [],
      grantedScopes: [],
      connectedByUid: 'uid_123',
    },
    idempotency: {
      actorUid: 'uid_123',
      command: 'connector.start',
      key: 'key_123',
      payloadHash: 'payload_123',
    },
    audit: {
      practiceId,
      connectorKey: 'xero',
      action: 'accounting.authorisation_started',
      actor: { kind: 'user', uid: 'uid_123' },
      correlationId: 'cor_123',
      target: { kind: 'connection', id: connectionId },
      outcome: 'accepted',
      safeFacts: { statusCode: 'authorising' },
    },
    outbox: {
      eventId: `evt_${randomUUID().replaceAll('-', '')}`,
      type: 'connector.connection_started.v1',
      connectionId,
      connectorKey: 'xero',
      correlationId: 'cor_123',
    },
    ...overrides,
  };
}

describe('firestore connector lifecycle store', () => {
  it('commits state, audit, outbox and idempotency receipt together', async () => {
    const db = getMoloFirestore(projectId);
    const store = new FirestoreConnectorLifecycleStore(db);
    const practiceId = `prc_${randomUUID().replaceAll('-', '')}`;
    const write = writeFor(practiceId);

    const result = await store.commit(write);

    assert.equal(result.ok, true);
    assert.equal(result.replayed, false);
    assert.match(result.value.version, /^[a-f0-9]{32}$/);
    assert.equal(
      (
        await db
          .doc(
            `practices/${practiceId}/connectorConnections/${write.connection.connectionId}`,
          )
          .get()
      ).exists,
      true,
    );
    assert.equal(
      (
        await db
          .doc(
            `practices/${practiceId}/connectorAuditEvents/${write.outbox.eventId}`,
          )
          .get()
      ).exists,
      true,
    );
    assert.equal(
      (
        await db
          .doc(
            `practices/${practiceId}/connectorOutbox/${write.outbox.eventId}`,
          )
          .get()
      ).exists,
      true,
    );
    assert.equal(
      (await db.collection(`practices/${practiceId}/idempotencyKeys`).get())
        .size,
      1,
    );
  });

  it('replays a matching command without another audit or outbox event', async () => {
    const db = getMoloFirestore(projectId);
    const store = new FirestoreConnectorLifecycleStore(db);
    const practiceId = `prc_${randomUUID().replaceAll('-', '')}`;
    const write = writeFor(practiceId);

    const first = await store.commit(write);
    const replay = await store.commit(write);

    assert.equal(first.ok, true);
    assert.equal(replay.ok, true);
    assert.equal(replay.replayed, true);
    assert.deepEqual(replay.value, first.value);
    assert.equal(
      (
        await db
          .collection(`practices/${practiceId}/connectorAuditEvents`)
          .get()
      ).size,
      1,
    );
    assert.equal(
      (await db.collection(`practices/${practiceId}/connectorOutbox`).get())
        .size,
      1,
    );
  });

  it('rejects idempotency reuse with another payload and stale versions', async () => {
    const db = getMoloFirestore(projectId);
    const store = new FirestoreConnectorLifecycleStore(db);
    const practiceId = `prc_${randomUUID().replaceAll('-', '')}`;
    const write = writeFor(practiceId);
    const first = await store.commit(write);
    assert.equal(first.ok, true);

    const conflicting = await store.commit({
      ...write,
      idempotency: { ...write.idempotency, payloadHash: 'payload_other' },
    });
    assert.deepEqual(conflicting, { ok: false, code: 'idempotency_conflict' });

    const stale = await store.commit({
      ...write,
      expectedVersion: 'stale_version',
      idempotency: { ...write.idempotency, key: 'key_456' },
      outbox: {
        ...write.outbox,
        eventId: `evt_${randomUUID().replaceAll('-', '')}`,
      },
    });
    assert.deepEqual(stale, { ok: false, code: 'version_mismatch' });
  });
});
