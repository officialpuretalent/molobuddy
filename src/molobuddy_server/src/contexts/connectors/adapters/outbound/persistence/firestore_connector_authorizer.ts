import type { Firestore } from 'firebase-admin/firestore';

import type {
  ConnectorAuthorisationResult,
  ConnectorAuthorizer,
} from '../../../application/ports/connector_authorizer.js';

/**
 * A fail-closed initial policy: only an active owner receives connector
 * authority. Future role bundles extend this adapter; no endpoint trusts a
 * role or capability supplied by a client.
 */
export class FirestoreConnectorAuthorizer implements ConnectorAuthorizer {
  constructor(private readonly db: Firestore) {}

  async authorize(input: {
    actor: { uid: string };
    practiceId: string;
    regionalCellKey: string;
    capability: string;
  }): Promise<ConnectorAuthorisationResult> {
    const practice = await this.db.doc(`practices/${input.practiceId}`).get();
    if (!practice.exists) {
      return { ok: false, code: 'resource_not_found' };
    }
    const record = practice.data() as
      Readonly<{ homeRegionKey?: string; status?: string }> | undefined;
    if (record?.homeRegionKey !== input.regionalCellKey) {
      return { ok: false, code: 'region_route_mismatch' };
    }
    if (record.status !== 'active') {
      return { ok: false, code: 'capability_required' };
    }
    const member = await this.db
      .doc(`practices/${input.practiceId}/members/${input.actor.uid}`)
      .get();
    const membership = member.data() as
      Readonly<{ role?: string; status?: string }> | undefined;
    return membership?.role === 'owner' && membership.status === 'active'
      ? { ok: true }
      : { ok: false, code: 'capability_required' };
  }
}
