import { FieldValue, type Firestore } from 'firebase-admin/firestore';

import { runInTransaction } from '../../../../../platform/persistence/firestore.js';
import type {
  ConsumeOAuthAuthorisationStateResult,
  OAuthAuthorisationState,
  OAuthAuthorisationStateStore,
} from '../../../application/ports/oauth_authorisation_state_store.js';

type StoredState = OAuthAuthorisationState & Readonly<{ consumedAt?: unknown }>;

/**
 * Short-lived, regional callback state. The collection is deliberately outside
 * a practice path: the callback learns its practice only from this state.
 */
export class FirestoreOAuthAuthorisationStateStore implements OAuthAuthorisationStateStore {
  constructor(private readonly db: Firestore) {}

  async create(state: OAuthAuthorisationState): Promise<void> {
    await this.document(state.stateId).create({
      ...withoutUndefined(state),
      createdAt: FieldValue.serverTimestamp(),
    });
  }

  async consume(
    stateId: string,
    now: string,
  ): Promise<ConsumeOAuthAuthorisationStateResult> {
    const document = this.document(stateId);
    return runInTransaction(this.db, async (transaction) => {
      const snapshot = await transaction.get(document);
      if (!snapshot.exists) {
        return { ok: false, code: 'oauth_state_invalid' };
      }
      const state = snapshot.data() as StoredState;
      if (state.consumedAt !== undefined) {
        return { ok: false, code: 'oauth_state_used' };
      }
      if (state.expiresAt <= now) {
        transaction.update(document, {
          consumedAt: FieldValue.serverTimestamp(),
          consumptionOutcome: 'expired',
        });
        return { ok: false, code: 'oauth_state_expired' };
      }
      transaction.update(document, {
        consumedAt: FieldValue.serverTimestamp(),
        consumptionOutcome: 'accepted',
      });
      return { ok: true, state: withoutStorageFields(state) };
    });
  }

  private document(stateId: string) {
    return this.db.doc(`connectorOAuthStates/${stateId}`);
  }
}

function withoutUndefined(
  state: OAuthAuthorisationState,
): Record<string, unknown> {
  const { codeVerifier, ...persisted } = state;
  return codeVerifier === undefined
    ? persisted
    : { ...persisted, codeVerifier };
}

function withoutStorageFields(state: StoredState): OAuthAuthorisationState {
  return {
    stateId: state.stateId,
    practiceId: state.practiceId,
    connectionId: state.connectionId,
    providerKey: state.providerKey,
    actorUid: state.actorUid,
    returnUri: state.returnUri,
    ...(state.codeVerifier === undefined
      ? {}
      : { codeVerifier: state.codeVerifier }),
    expiresAt: state.expiresAt,
  };
}
