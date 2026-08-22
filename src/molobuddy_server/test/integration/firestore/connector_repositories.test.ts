import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { describe, it } from 'node:test';

import type { Firestore } from 'firebase-admin/firestore';

import {
  FirestoreConnectorConnectionRepository,
  FirestoreSyncRunRepository,
  type ConnectorConnection,
  type ConnectorDataSource,
  type ConnectorAuditEvent,
  type SyncRun,
} from '../../../src/contexts/connectors/index.js';
import { getMoloFirestore } from '../../../src/platform/persistence/firestore.js';

const projectId = 'molobuddy-development';

function connectionFor(practiceId: string): ConnectorConnection {
  return {
    connectionId: `con_${randomUUID()}`,
    practiceId,
    providerKey: 'xero',
    connectorVersion: '0.1.0',
    status: 'awaiting_source_selection',
    requestedCapabilities: ['contacts.read'],
    grantedCapabilities: ['contacts.read'],
    grantedScopes: ['accounting.contacts.read'],
    connectedByUid: 'uid_123',
  };
}

function sourceFor(connection: ConnectorConnection): ConnectorDataSource {
  return {
    dataSourceId: `src_${randomUUID()}`,
    practiceId: connection.practiceId,
    connectionId: connection.connectionId,
    providerDataSourceId: 'provider-company-123',
    displayName: 'Mokoena Media Tax',
    selected: true,
  };
}

function auditFor(
  connection: ConnectorConnection,
  overrides: Partial<ConnectorAuditEvent> = {},
): ConnectorAuditEvent {
  return {
    practiceId: connection.practiceId,
    connectionId: connection.connectionId,
    providerKey: connection.providerKey,
    action: 'connector.sources_selected',
    actor: { kind: 'user', uid: 'uid_123' },
    correlationId: 'cor_123',
    resultingState: {
      connectionStatus: connection.status,
      selectedSourceCount: 1,
    },
    ...overrides,
  };
}

function queuedRun(connection: ConnectorConnection): SyncRun {
  return {
    syncRunId: `syn_${randomUUID()}`,
    practiceId: connection.practiceId,
    connectionId: connection.connectionId,
    dataSourceId: `src_${randomUUID()}`,
    mode: 'delta',
    status: 'queued',
    counters: {
      received: 0,
      matched: 0,
      applied: 0,
      needsReview: 0,
      failed: 0,
    },
  };
}

async function storedAt(
  db: Firestore,
  path: string,
): Promise<Record<string, unknown>> {
  const data = (await db.doc(path).get()).data();
  assert.ok(data !== undefined, `no document at ${path}`);
  return data;
}

describe('firestore connector repositories', () => {
  it('keeps connection and source reads inside the requested practice', async () => {
    const db = getMoloFirestore(projectId);
    const repository = new FirestoreConnectorConnectionRepository(db);
    const connection = connectionFor(`prc_${randomUUID()}`);
    const source = sourceFor(connection);

    await repository.saveWithDataSources(
      connection,
      [source],
      auditFor(connection),
    );

    assert.deepEqual(
      await repository.get(connection.practiceId, connection.connectionId),
      connection,
    );
    assert.deepEqual(
      await repository.get(`prc_${randomUUID()}`, connection.connectionId),
      undefined,
    );
    assert.deepEqual(
      await repository.listDataSources(
        connection.practiceId,
        connection.connectionId,
      ),
      [source],
    );
  });

  it('replaces the source set atomically and leaves no stale provider source', async () => {
    const db = getMoloFirestore(projectId);
    const repository = new FirestoreConnectorConnectionRepository(db);
    const connection = connectionFor(`prc_${randomUUID()}`);
    const obsolete = sourceFor(connection);
    const current = {
      ...sourceFor(connection),
      displayName: 'Current company',
    };

    await repository.saveWithDataSources(
      connection,
      [obsolete],
      auditFor(connection),
    );
    const active = { ...connection, status: 'active' as const };
    await repository.saveWithDataSources(active, [current], auditFor(active));

    assert.deepEqual(
      await repository.listDataSources(
        connection.practiceId,
        connection.connectionId,
      ),
      [current],
    );
    assert.equal(
      (
        await db
          .doc(
            `practices/${connection.practiceId}/connectorConnections/${connection.connectionId}/dataSources/${obsolete.dataSourceId}`,
          )
          .get()
      ).exists,
      false,
    );
  });

  it('rejects cross-practice source writes before changing persisted state', async () => {
    const db = getMoloFirestore(projectId);
    const repository = new FirestoreConnectorConnectionRepository(db);
    const connection = connectionFor(`prc_${randomUUID()}`);

    await assert.rejects(
      repository.saveWithDataSources(
        connection,
        [{ ...sourceFor(connection), practiceId: `prc_${randomUUID()}` }],
        auditFor(connection),
      ),
      /must belong to their connection/,
    );
    assert.equal(
      (
        await db
          .doc(
            `practices/${connection.practiceId}/connectorConnections/${connection.connectionId}`,
          )
          .get()
      ).exists,
      false,
    );
  });

  it('stores run history by practice and returns newest runs first', async () => {
    const db = getMoloFirestore(projectId);
    const repository = new FirestoreSyncRunRepository(db);
    const connection = connectionFor(`prc_${randomUUID()}`);
    const first = queuedRun(connection);
    const second = queuedRun(connection);

    await repository.save(
      first,
      auditFor(connection, {
        action: 'connector.sync_queued',
        actor: { kind: 'system', name: 'connector-worker' },
        resultingState: { syncRunId: first.syncRunId, syncStatus: 'queued' },
      }),
    );
    await new Promise((resolve) => setTimeout(resolve, 10));
    await repository.save(
      second,
      auditFor(connection, {
        action: 'connector.sync_queued',
        actor: { kind: 'system', name: 'connector-worker' },
        resultingState: { syncRunId: second.syncRunId, syncStatus: 'queued' },
      }),
    );

    assert.deepEqual(
      await repository.get(connection.practiceId, first.syncRunId),
      first,
    );
    assert.deepEqual(
      await repository.listForConnection(
        connection.practiceId,
        connection.connectionId,
      ),
      [second, first],
    );
  });

  it('does not serialise undefined provider domains into Firestore', async () => {
    const db = getMoloFirestore(projectId);
    const repository = new FirestoreConnectorConnectionRepository(db);
    const connection = connectionFor(`prc_${randomUUID()}`);
    const source = sourceFor(connection);

    await repository.saveWithDataSources(
      connection,
      [source],
      auditFor(connection),
    );

    const stored = await storedAt(
      db,
      `practices/${connection.practiceId}/connectorConnections/${connection.connectionId}/dataSources/${source.dataSourceId}`,
    );
    assert.equal(stored['providerApiDomain'], undefined);
  });

  it('writes allowlisted connector audit evidence with the same state change', async () => {
    const db = getMoloFirestore(projectId);
    const repository = new FirestoreConnectorConnectionRepository(db);
    const connection = connectionFor(`prc_${randomUUID()}`);

    await repository.save(
      connection,
      auditFor(connection, {
        action: 'connector.authorisation_completed',
        resultingState: { connectionStatus: 'awaiting_source_selection' },
      }),
    );

    const events = await db
      .collection(`practices/${connection.practiceId}/connectorAuditEvents`)
      .get();
    assert.equal(events.size, 1);
    const firstEvent = events.docs[0];
    assert.ok(firstEvent !== undefined);
    const event = firstEvent.data();
    assert.equal(event['action'], 'connector.authorisation_completed');
    assert.equal(event['connectionId'], connection.connectionId);
    assert.equal(event['accessToken'], undefined);
    assert.equal(event['refreshToken'], undefined);
    assert.equal(event['rawBody'], undefined);
    assert.notEqual(event['recordedAt'], undefined);
  });

  it('rejects an audit event that names a different connection', async () => {
    const db = getMoloFirestore(projectId);
    const repository = new FirestoreConnectorConnectionRepository(db);
    const connection = connectionFor(`prc_${randomUUID()}`);

    await assert.rejects(
      repository.save(
        connection,
        auditFor(connection, { connectionId: 'con_other' }),
      ),
      /must belong to its connection/,
    );
  });
});
