import { createHash } from 'node:crypto';

import { FieldValue, type Firestore } from 'firebase-admin/firestore';

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

      const value: VersionedConnectorConnection = {
        connection: write.connection,
        version: createResourceVersion(),
      };
      transaction.set(connectionDocument, {
        ...write.connection,
        version: value.version,
        updatedAt: FieldValue.serverTimestamp(),
      });
      if (write.dataSources !== undefined) {
        const sources = await transaction.get(
          this.sourceCollection(
            write.connection.practiceId,
            write.connection.connectionId,
          ),
        );
        for (const source of sources.docs) {
          transaction.delete(source.ref);
        }
        for (const source of write.dataSources) {
          transaction.set(
            this.sourceCollection(
              write.connection.practiceId,
              write.connection.connectionId,
            ).doc(source.dataSourceId),
            {
              ...withoutUndefined(source),
              updatedAt: FieldValue.serverTimestamp(),
            },
          );
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
    });
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
    const digest = createHash('sha256')
      .update(write.idempotency.actorUid)
      .update('\n')
      .update(write.idempotency.command)
      .update('\n')
      .update(write.idempotency.key)
      .digest('hex');
    return this.db.doc(
      `practices/${write.connection.practiceId}/idempotencyKeys/${digest}`,
    );
  }
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
