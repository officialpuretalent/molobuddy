import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { describe, it } from 'node:test';

import { FirestoreConnectorAuthorizer } from '../../../src/contexts/connectors/index.js';
import { getMoloFirestore } from '../../../src/platform/persistence/firestore.js';

const projectId = 'molobuddy-development';

describe('firestore connector authorizer', () => {
  it('authorises only an active owner in the matching regional cell', async () => {
    const db = getMoloFirestore(projectId);
    const practiceId = `prc_${randomUUID().replaceAll('-', '')}`;
    await db.doc(`practices/${practiceId}`).set({
      homeRegionKey: 'za1',
      status: 'active',
    });
    await db.doc(`practices/${practiceId}/members/owner_123`).set({
      role: 'owner',
      status: 'active',
    });
    const authorizer = new FirestoreConnectorAuthorizer(db);

    assert.deepEqual(
      await authorizer.authorize({
        actor: { uid: 'owner_123' },
        practiceId,
        regionalCellKey: 'za1',
        capability: 'connectors.manage',
      }),
      { ok: true },
    );
    assert.deepEqual(
      await authorizer.authorize({
        actor: { uid: 'owner_123' },
        practiceId,
        regionalCellKey: 'eu1',
        capability: 'connectors.manage',
      }),
      { ok: false, code: 'region_route_mismatch' },
    );
  });

  it('fails closed for every non-owner membership', async () => {
    const db = getMoloFirestore(projectId);
    const practiceId = `prc_${randomUUID().replaceAll('-', '')}`;
    await db.doc(`practices/${practiceId}`).set({
      homeRegionKey: 'za1',
      status: 'active',
    });
    await db.doc(`practices/${practiceId}/members/member_123`).set({
      role: 'viewer',
      status: 'active',
    });
    const authorizer = new FirestoreConnectorAuthorizer(db);

    assert.deepEqual(
      await authorizer.authorize({
        actor: { uid: 'member_123' },
        practiceId,
        regionalCellKey: 'za1',
        capability: 'connectors.read',
      }),
      { ok: false, code: 'capability_required' },
    );
  });
});
