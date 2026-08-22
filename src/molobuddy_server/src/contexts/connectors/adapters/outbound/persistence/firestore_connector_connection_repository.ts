import { FieldValue, type Firestore } from 'firebase-admin/firestore';

import { createResourceVersion } from '../../../../../platform/http/identifiers.js';
import { runInTransaction } from '../../../../../platform/persistence/firestore.js';
import type { ConnectorConnectionRepository } from '../../../application/ports/connector_connection_repository.js';
import type {
  ConnectorConnection,
  ConnectorDataSource,
} from '../../../domain/connector_connection.js';

/**
 * Firestore storage for non-secret connector state. Provider credentials are
 * deliberately excluded: they belong in ProviderCredentialVault.
 */
export class FirestoreConnectorConnectionRepository implements ConnectorConnectionRepository {
  constructor(private readonly db: Firestore) {}

  async get(
    practiceId: string,
    connectionId: string,
  ): Promise<ConnectorConnection | undefined> {
    const snapshot = await this.connectionDocument(
      practiceId,
      connectionId,
    ).get();
    return snapshot.exists ? asConnectorConnection(snapshot.data()) : undefined;
  }

  async save(connection: ConnectorConnection): Promise<void> {
    await this.connectionDocument(
      connection.practiceId,
      connection.connectionId,
    ).set({
      ...connection,
      updatedAt: FieldValue.serverTimestamp(),
      version: createResourceVersion(),
    });
  }

  async listDataSources(
    practiceId: string,
    connectionId: string,
  ): Promise<readonly ConnectorDataSource[]> {
    const snapshot = await this.sourceCollection(practiceId, connectionId)
      .orderBy('displayName')
      .get();
    return snapshot.docs.map((document) =>
      asConnectorDataSource(document.data()),
    );
  }

  async saveWithDataSources(
    connection: ConnectorConnection,
    sources: readonly ConnectorDataSource[],
  ): Promise<void> {
    this.assertSourcesBelongTo(connection, sources);
    const connectionDocument = this.connectionDocument(
      connection.practiceId,
      connection.connectionId,
    );
    const sourceCollection = this.sourceCollection(
      connection.practiceId,
      connection.connectionId,
    );

    await runInTransaction(this.db, async (transaction) => {
      // Firestore transactions require all reads before writes. Replacing the
      // full source set removes sources revoked at the provider as well.
      const existingSources = await transaction.get(sourceCollection);
      for (const source of existingSources.docs) {
        transaction.delete(source.ref);
      }
      transaction.set(connectionDocument, {
        ...connection,
        updatedAt: FieldValue.serverTimestamp(),
        version: createResourceVersion(),
      });
      for (const source of sources) {
        transaction.set(sourceCollection.doc(source.dataSourceId), {
          ...withoutUndefined(source),
          updatedAt: FieldValue.serverTimestamp(),
        });
      }
    });
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

  private assertSourcesBelongTo(
    connection: ConnectorConnection,
    sources: readonly ConnectorDataSource[],
  ): void {
    if (
      sources.some(
        (source) =>
          source.practiceId !== connection.practiceId ||
          source.connectionId !== connection.connectionId,
      )
    ) {
      throw new Error('Connector data sources must belong to their connection');
    }
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

function asConnectorConnection(
  stored: Record<string, unknown> | undefined,
): ConnectorConnection {
  return stripStorageFields(stored) as ConnectorConnection;
}

function asConnectorDataSource(
  stored: Record<string, unknown>,
): ConnectorDataSource {
  return stripStorageFields(stored) as ConnectorDataSource;
}

function stripStorageFields(stored: Record<string, unknown> | undefined) {
  return Object.fromEntries(
    Object.entries(stored ?? {}).filter(
      ([key]) => key !== 'updatedAt' && key !== 'version',
    ),
  );
}
