import type {
  ConnectorConnection,
  ConnectorDataSource,
} from '../../domain/connector_connection.js';

/**
 * The regional persistence boundary for consent and source selection. Secret
 * values remain in ProviderCredentialVault and are intentionally absent here.
 */
export interface ConnectorConnectionRepository {
  get(
    practiceId: string,
    connectionId: string,
  ): Promise<ConnectorConnection | undefined>;

  save(connection: ConnectorConnection): Promise<void>;

  listDataSources(
    practiceId: string,
    connectionId: string,
  ): Promise<readonly ConnectorDataSource[]>;

  /**
   * Saves the post-authorisation aggregate in one durable write. A connection
   * cannot become active unless its selected sources persist alongside it.
   */
  saveWithDataSources(
    connection: ConnectorConnection,
    sources: readonly ConnectorDataSource[],
  ): Promise<void>;
}
