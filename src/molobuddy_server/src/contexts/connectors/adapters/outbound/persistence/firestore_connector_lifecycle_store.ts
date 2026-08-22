import { createHash } from 'node:crypto';

import {
  FieldValue,
  type DocumentReference,
  type Firestore,
  type Transaction,
} from 'firebase-admin/firestore';

import { createResourceVersion } from '../../../../../platform/http/identifiers.js';
import { runInTransaction } from '../../../../../platform/persistence/firestore.js';
import {
  safeConnectorAuditFields,
  type ConnectorAuditEvent,
} from '../../../application/ports/connector_audit_event.js';
import type {
  ConnectorLifecycleCommit,
  ConnectorLifecycleCommitResult,
  ConnectorLifecycleStore,
  ConnectorLifecycleTransition,
  ConnectorLifecycleTransitionResult,
  VersionedConnectorConnection,
} from '../../../application/ports/connector_lifecycle_store.js';
import type {
  ConnectorConnection,
  ConnectorDataSource,
} from '../../../domain/connector_connection.js';

type StoredConnection = ConnectorConnection & Readonly<{ version: string }>;
type StoredReceipt = Readonly<{
  payloadHash: string;
  value: VersionedConnectorConnection;
}>;

export class FirestoreConnectorLifecycleStore implements ConnectorLifecycleStore {
  constructor(private readonly db: Firestore) {}

  async get(
    practiceId: string,
    connectionId: string,
  ): Promise<VersionedConnectorConnection | undefined> {
    const snapshot = await this.connectionDocument(
      practiceId,
      connectionId,
    ).get();
    if (!snapshot.exists) {
      return undefined;
    }
    return versionedConnection(snapshot.data() as StoredConnection);
  }

  async commit(
    write: ConnectorLifecycleCommit,
  ): Promise<ConnectorLifecycleCommitResult> {
    this.assertWriteIsConsistent(write);
    const connectionDocument = this.connectionDocument(
      write.connection.practiceId,
      write.connection.connectionId,
    );
    const receiptDocument = this.idempotencyDocument(write);

    return runInTransaction(this.db, async (transaction) => {
      const receiptSnapshot = await transaction.get(receiptDocument);
      if (receiptSnapshot.exists) {
        const receipt = receiptSnapshot.data() as StoredReceipt;
        return receipt.payloadHash === write.idempotency.payloadHash
          ? { ok: true, value: receipt.value, replayed: true }
          : { ok: false, code: 'idempotency_conflict' };
      }

      const existingSnapshot = await transaction.get(connectionDocument);
      const existing = existingSnapshot.exists
        ? (existingSnapshot.data() as StoredConnection)
        : undefined;
      if (write.expectedVersion === undefined) {
        if (existing !== undefined) {
          return { ok: false, code: 'state_conflict' };
        }
      } else if (existing?.version !== write.expectedVersion) {
        return { ok: false, code: 'version_mismatch' };
      }

      return this.writeInTransaction(transaction, write, receiptDocument);
    });
  }

  async transition(
    transition: ConnectorLifecycleTransition,
  ): Promise<ConnectorLifecycleTransitionResult> {
    const connectionDocument = this.connectionDocument(
      transition.practiceId,
      transition.connectionId,
    );
    const receiptDocument = this.idempotencyDocumentFor(
      transition.practiceId,
      transition.idempotency,
    );
    return runInTransaction(this.db, async (transaction) => {
      const receiptSnapshot = await transaction.get(receiptDocument);
      if (receiptSnapshot.exists) {
        const receipt = receiptSnapshot.data() as StoredReceipt;
        return receipt.payloadHash === transition.idempotency.payloadHash
          ? { ok: true, value: receipt.value, replayed: true }
          : { ok: false, code: 'idempotency_conflict' };
      }
      const currentSnapshot = await transaction.get(connectionDocument);
      const current = currentSnapshot.exists
        ? versionedConnection(currentSnapshot.data() as StoredConnection)
        : undefined;
      const prepared = transition.prepare(current);
      if (!prepared.ok) {
        return prepared;
      }
      const write: ConnectorLifecycleCommit = {
        ...prepared.write,
        expectedVersion: transition.expectedVersion,
        idempotency: transition.idempotency,
      };
      this.assertWriteIsConsistent(write);
      if (write.connection.connectionId !== transition.connectionId) {
        throw new Error('Connector transition changed its connection identity');
      }
      if (current?.version !== transition.expectedVersion) {
        return { ok: false, code: 'version_mismatch' };
      }
      return this.writeInTransaction(transaction, write, receiptDocument);
    });
  }

  private async writeInTransaction(
    transaction: Transaction,
    write: ConnectorLifecycleCommit,
    receiptDocument: DocumentReference,
  ): Promise<ConnectorLifecycleCommitResult> {
    const sourceCollection = this.sourceCollection(
      write.connection.practiceId,
      write.connection.connectionId,
    );
    // Firestore transactions require every read before the first write.
    const existingSources =
      write.dataSources === undefined
        ? undefined
        : await transaction.get(sourceCollection);
    const value: VersionedConnectorConnection = {
      connection: write.connection,
      version: createResourceVersion(),
    };
    transaction.set(
      this.connectionDocument(
        write.connection.practiceId,
        write.connection.connectionId,
      ),
      {
        ...write.connection,
        version: value.version,
        updatedAt: FieldValue.serverTimestamp(),
      },
    );
    if (write.dataSources !== undefined) {
      for (const source of existingSources?.docs ?? []) {
        transaction.delete(source.ref);
      }
      for (const source of write.dataSources) {
        transaction.set(sourceCollection.doc(source.dataSourceId), {
          ...withoutUndefined(source),
          updatedAt: FieldValue.serverTimestamp(),
        });
      }
    }
    transaction.set(
      this.auditDocument(write.connection.practiceId, write.outbox.eventId),
      auditDocument(write.audit),
    );
    transaction.set(
      this.outboxDocument(write.connection.practiceId, write.outbox.eventId),
      {
        ...write.outbox,
        occurredAt: FieldValue.serverTimestamp(),
        status: 'pending',
      },
    );
    transaction.set(receiptDocument, {
      payloadHash: write.idempotency.payloadHash,
      value,
      recordedAt: FieldValue.serverTimestamp(),
    });
    return { ok: true, value, replayed: false };
  }

  private assertWriteIsConsistent(write: ConnectorLifecycleCommit): void {
    const { connection, audit, outbox } = write;
    if (
      audit.practiceId !== connection.practiceId ||
      audit.connectorKey !== connection.providerKey ||
      audit.target.kind !== 'connection' ||
      audit.target.id !== connection.connectionId ||
      outbox.connectionId !== connection.connectionId ||
      outbox.connectorKey !== connection.providerKey ||
      outbox.correlationId !== audit.correlationId
    ) {
      throw new Error('Connector lifecycle commit has inconsistent evidence');
    }
    if (
      write.dataSources?.some(
        (source) =>
          source.practiceId !== connection.practiceId ||
          source.connectionId !== connection.connectionId,
      )
    ) {
      throw new Error('Connector data sources must belong to their connection');
    }
  }

  private connectionDocument(practiceId: string, connectionId: string) {
    return this.db.doc(
      `practices/${practiceId}/connectorConnections/${connectionId}`,
    );
  }

  private sourceCollection(practiceId: string, connectionId: string) {
    return this.connectionDocument(practiceId, connectionId).collection(
      'dataSources',
    );
  }

  private auditDocument(practiceId: string, eventId: string) {
    return this.db.doc(
      `practices/${practiceId}/connectorAuditEvents/${eventId}`,
    );
  }

  private outboxDocument(practiceId: string, eventId: string) {
    return this.db.doc(`practices/${practiceId}/connectorOutbox/${eventId}`);
  }

  private idempotencyDocument(write: ConnectorLifecycleCommit) {
    return this.idempotencyDocumentFor(
      write.connection.practiceId,
      write.idempotency,
    );
  }

  private idempotencyDocumentFor(
    practiceId: string,
    idempotency: ConnectorLifecycleCommit['idempotency'],
  ) {
    const digest = createHash('sha256')
      .update(idempotency.actorUid)
      .update('\n')
      .update(idempotency.command)
      .update('\n')
      .update(idempotency.key)
      .digest('hex');
    return this.db.doc(`practices/${practiceId}/idempotencyKeys/${digest}`);
  }
}

function versionedConnection(
  stored: StoredConnection,
): VersionedConnectorConnection {
  return {
    connection: {
      connectionId: stored.connectionId,
      practiceId: stored.practiceId,
      providerKey: stored.providerKey,
      connectorVersion: stored.connectorVersion,
      status: stored.status,
      requestedCapabilities: stored.requestedCapabilities,
      grantedCapabilities: stored.grantedCapabilities,
      grantedScopes: stored.grantedScopes,
      connectedByUid: stored.connectedByUid,
    },
    version: stored.version,
  };
}

function withoutUndefined(
  source: ConnectorDataSource,
): Record<string, unknown> {
  const { providerApiDomain, ...persisted } = source;
  return providerApiDomain === undefined
    ? persisted
    : { ...persisted, providerApiDomain };
}

function auditDocument(audit: ConnectorAuditEvent): Record<string, unknown> {
  return {
    ...safeConnectorAuditFields(audit),
    recordedAt: FieldValue.serverTimestamp(),
  };
}
