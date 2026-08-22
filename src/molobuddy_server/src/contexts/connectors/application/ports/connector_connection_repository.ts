import type {
  ConnectorConnection,
  ConnectorDataSource,
} from '../../domain/connector_connection.js';

/**
 * The regional persistence boundary for consent and source selection. Secret
 * values remain in ProviderCredentialVault and are intentionally absent here.
 */
export interface ConnectorConnectionRepository {
  get(connectionId: string): Promise<ConnectorConnection | undefined>;

  save(connection: ConnectorConnection): Promise<void>;

  listDataSources(
    connectionId: string,
  ): Promise<readonly ConnectorDataSource[]>;

  saveDataSources(sources: readonly ConnectorDataSource[]): Promise<void>;
}
