import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { describe, it } from 'node:test';

import type { Firestore } from 'firebase-admin/firestore';

import {
  FirestoreConnectorConnectionRepository,
  FirestoreSyncRunRepository,
  type ConnectorConnection,
  type ConnectorDataSource,
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

    await repository.saveWithDataSources(connection, [source]);

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

    await repository.saveWithDataSources(connection, [obsolete]);
    await repository.saveWithDataSources({ ...connection, status: 'active' }, [
      current,
    ]);

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
      repository.saveWithDataSources(connection, [
        { ...sourceFor(connection), practiceId: `prc_${randomUUID()}` },
      ]),
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

    await repository.save(first);
    await new Promise((resolve) => setTimeout(resolve, 10));
    await repository.save(second);

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

    await repository.saveWithDataSources(connection, [source]);

    const stored = await storedAt(
      db,
      `practices/${connection.practiceId}/connectorConnections/${connection.connectionId}/dataSources/${source.dataSourceId}`,
    );
    assert.equal(stored['providerApiDomain'], undefined);
  });
});
