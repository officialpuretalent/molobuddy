import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { describe, it } from 'node:test';

import {
  FirestoreOAuthAuthorisationStateStore,
  FirestoreWebhookReceiptRepository,
} from '../../../src/contexts/connectors/index.js';
import { getMoloFirestore } from '../../../src/platform/persistence/firestore.js';

const projectId = 'molobuddy-development';

describe('firestore connector security stores', () => {
  it('consumes an OAuth state exactly once', async () => {
    const store = new FirestoreOAuthAuthorisationStateStore(
      getMoloFirestore(projectId),
    );
    const stateId = `state_${randomUUID().replaceAll('-', '')}`;
    await store.create({
      stateId,
      practiceId: 'prc_123',
      connectionId: 'con_123',
      providerKey: 'xero',
      actorUid: 'uid_123',
      returnUri: 'molo://settings/connectors/callback',
      expiresAt: '2026-08-22T12:00:00.000Z',
    });

    const first = await store.consume(stateId, '2026-08-22T11:00:00.000Z');
    const second = await store.consume(stateId, '2026-08-22T11:00:01.000Z');

    assert.equal(first.ok, true);
    assert.equal(second.ok, false);
    assert.equal(second.code, 'oauth_state_used');
  });

  it('deduplicates a webhook receipt and queues one follow-up event', async () => {
    const db = getMoloFirestore(projectId);
    const repository = new FirestoreWebhookReceiptRepository(db);
    const practiceId = `prc_${randomUUID().replaceAll('-', '')}`;
    const receipt = {
      practiceId,
      connectionId: 'con_123',
      providerKey: 'xero' as const,
      providerEventKey: 'event_123',
      payloadQuarantineReference: 'quarantine_123',
      followUpEventId: 'evt_123',
    };

    assert.deepEqual(await repository.record(receipt), { accepted: true });
    assert.deepEqual(await repository.record(receipt), {
      accepted: false,
      replayed: true,
    });
    assert.equal(
      (await db.collection(`practices/${practiceId}/webhookReceipts`).get())
        .size,
      1,
    );
    assert.equal(
      (
        await db
          .doc(
            `practices/${practiceId}/connectorOutbox/${receipt.followUpEventId}`,
          )
          .get()
      ).exists,
      true,
    );
  });
});
