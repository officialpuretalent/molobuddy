import assert from 'node:assert/strict';
import test from 'node:test';

import {
  StartAccountingConnection,
  type ConnectorLifecycleCommit,
  type ConnectorLifecycleCommitResult,
  type ConnectorLifecycleStore,
  type VersionedConnectorConnection,
  StaticAccountingProviderRegistry,
  documentedAccountingProviderAdapters,
} from '../../src/contexts/connectors/index.js';
import type { VerifiedActor } from '../../src/contexts/identity_access/index.js';

const actor: VerifiedActor = {
  uid: 'uid_123',
  firebaseProjectId: 'molobuddy-development',
  appId: 'app_123',
  providerIds: ['password'],
  emailVerified: true,
};

class RecordingStore implements ConnectorLifecycleStore {
  writes: ConnectorLifecycleCommit[] = [];

  async commit(
    write: ConnectorLifecycleCommit,
  ): Promise<ConnectorLifecycleCommitResult> {
    this.writes.push(write);
    const value: VersionedConnectorConnection = {
      connection: write.connection,
      version: 'version_123',
    };
    return { ok: true, value, replayed: false };
  }
}

function build(store = new RecordingStore()) {
  return {
    store,
    command: new StartAccountingConnection(
      new StaticAccountingProviderRegistry(
        documentedAccountingProviderAdapters,
      ),
      store,
    ),
  };
}

test('starts a versioned, auditable and idempotent accounting connection', async () => {
  const { command, store } = build();

  const result = await command.execute({
    actor,
    practiceId: 'prc_123',
    providerKey: 'xero',
    requestedCapabilities: ['contacts.read'],
    idempotencyKey: 'start-key',
    correlationId: 'cor_123',
  });

  assert.equal(result.ok, true);
  assert.equal(result.connection.connection.status, 'authorising');
  assert.equal(store.writes.length, 1);
  const [write] = store.writes;
  assert.ok(write !== undefined);
  assert.equal(write.audit.action, 'accounting.authorisation_started');
  assert.equal(write.outbox.type, 'connector.connection_started.v1');
  assert.equal(write.audit.target.id, write.connection.connectionId);
});

test('refuses an empty or unsupported capability request before writing', async () => {
  const { command, store } = build();

  const empty = await command.execute({
    actor,
    practiceId: 'prc_123',
    providerKey: 'xero',
    requestedCapabilities: [],
    idempotencyKey: 'start-key',
    correlationId: 'cor_123',
  });
  const unsupported = await command.execute({
    actor,
    practiceId: 'prc_123',
    providerKey: 'xero',
    requestedCapabilities: ['unknown.read'] as never,
    idempotencyKey: 'start-key-2',
    correlationId: 'cor_123',
  });

  assert.deepEqual(empty, { ok: false, code: 'invalid_request' });
  assert.deepEqual(unsupported, { ok: false, code: 'unsupported_capability' });
  assert.equal(store.writes.length, 0);
});
