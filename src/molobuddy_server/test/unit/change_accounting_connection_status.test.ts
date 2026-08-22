import assert from 'node:assert/strict';
import test from 'node:test';

import {
  ChangeAccountingConnectionStatus,
  type ConnectorLifecycleCommit,
  type ConnectorLifecycleCommitResult,
  type ConnectorLifecycleStore,
  type ConnectorLifecycleTransition,
  type ConnectorLifecycleTransitionResult,
  type VersionedConnectorConnection,
} from '../../src/contexts/connectors/index.js';
import type { VerifiedActor } from '../../src/contexts/identity_access/index.js';

const actor: VerifiedActor = {
  uid: 'uid_123',
  firebaseProjectId: 'molobuddy-development',
  appId: 'app_123',
  providerIds: ['password'],
  emailVerified: true,
};

class InMemoryLifecycleStore implements ConnectorLifecycleStore {
  readonly writes: ConnectorLifecycleCommit[] = [];
  private readonly connections = new Map<
    string,
    VersionedConnectorConnection
  >();
  private readonly receipts = new Map<
    string,
    Readonly<{ payloadHash: string; value: VersionedConnectorConnection }>
  >();

  constructor(seed: VersionedConnectorConnection) {
    this.connections.set(
      key(seed.connection.practiceId, seed.connection.connectionId),
      seed,
    );
  }

  async get(practiceId: string, connectionId: string) {
    return this.connections.get(key(practiceId, connectionId));
  }

  async commit(): Promise<ConnectorLifecycleCommitResult> {
    throw new Error('Unexpected direct lifecycle commit');
  }

  async transition(
    request: ConnectorLifecycleTransition,
  ): Promise<ConnectorLifecycleTransitionResult> {
    const receiptKey = `${request.idempotency.actorUid}:${request.idempotency.command}:${request.idempotency.key}`;
    const receipt = this.receipts.get(receiptKey);
    if (receipt !== undefined) {
      return receipt.payloadHash === request.idempotency.payloadHash
        ? { ok: true, value: receipt.value, replayed: true }
        : { ok: false, code: 'idempotency_conflict' };
    }
    const current = await this.get(request.practiceId, request.connectionId);
    const prepared = request.prepare(current);
    if (!prepared.ok) {
      return prepared;
    }
    if (current?.version !== request.expectedVersion) {
      return { ok: false, code: 'version_mismatch' };
    }
    const write: ConnectorLifecycleCommit = {
      ...prepared.write,
      expectedVersion: request.expectedVersion,
      idempotency: request.idempotency,
    };
    const value: VersionedConnectorConnection = {
      connection: write.connection,
      version: 'version_456',
    };
    this.writes.push(write);
    this.connections.set(key(request.practiceId, request.connectionId), value);
    this.receipts.set(receiptKey, {
      payloadHash: request.idempotency.payloadHash,
      value,
    });
    return { ok: true, value, replayed: false };
  }
}

function seededStore(status: 'active' | 'paused' = 'active') {
  return new InMemoryLifecycleStore({
    connection: {
      connectionId: 'con_123',
      practiceId: 'prc_123',
      providerKey: 'xero',
      connectorVersion: '0.1.0',
      status,
      requestedCapabilities: ['contacts.read'],
      grantedCapabilities: ['contacts.read'],
      grantedScopes: ['offline_access'],
      connectedByUid: actor.uid,
    },
    version: 'version_123',
  });
}

function input(action: 'pause' | 'resume' | 'revoke') {
  return {
    actor,
    practiceId: 'prc_123',
    connectionId: 'con_123',
    action,
    expectedVersion: 'version_123',
    idempotencyKey: 'request-key',
    correlationId: 'cor_123',
  } as const;
}

test('pauses a connection once and replays the durable result', async () => {
  const store = seededStore();
  const command = new ChangeAccountingConnectionStatus(store);

  const first = await command.execute(input('pause'));
  const replay = await command.execute(input('pause'));

  assert.equal(first.ok, true);
  assert.equal(first.connection.status, 'paused');
  assert.equal(first.version, 'version_456');
  assert.equal(first.replayed, false);
  assert.equal(replay.ok, true);
  assert.equal(replay.replayed, true);
  assert.equal(store.writes.length, 1);
  const write = store.writes.at(0);
  assert.ok(write);
  assert.equal(write.audit.action, 'accounting.connection_paused');
  assert.equal(write.outbox.type, 'connector.connection_paused.v1');
});

test('resumes a paused connection and rejects a stale version', async () => {
  const store = seededStore('paused');
  const command = new ChangeAccountingConnectionStatus(store);

  const resumed = await command.execute(input('resume'));
  const stale = await command.execute({
    ...input('revoke'),
    expectedVersion: 'version_stale',
    idempotencyKey: 'other-key',
  });

  assert.equal(resumed.ok, true);
  assert.equal(resumed.connection.status, 'active');
  assert.deepEqual(stale, { ok: false, code: 'version_mismatch' });
});

test('rejects an impossible lifecycle transition without writing evidence', async () => {
  const store = seededStore('paused');
  const result = await new ChangeAccountingConnectionStatus(store).execute(
    input('pause'),
  );

  assert.deepEqual(result, {
    ok: false,
    code: 'invalid_connection_transition',
  });
  assert.equal(store.writes.length, 0);
});

function key(practiceId: string, connectionId: string): string {
  return `${practiceId}:${connectionId}`;
}
