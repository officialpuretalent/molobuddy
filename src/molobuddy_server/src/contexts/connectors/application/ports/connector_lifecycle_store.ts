import type { ConnectorAuditEvent } from './connector_audit_event.js';
import type {
  ConnectorConnection,
  ConnectorDataSource,
} from '../../domain/connector_connection.js';

export type VersionedConnectorConnection = Readonly<{
  connection: ConnectorConnection;
  version: string;
}>;

export type ConnectorCommandIdempotency = Readonly<{
  actorUid: string;
  command: string;
  key: string;
  payloadHash: string;
}>;

export type ConnectorOutboxEvent = Readonly<{
  eventId: string;
  type:
    | 'connector.connection_started.v1'
    | 'connector.authorisation_completed.v1'
    | 'connector.sources_selected.v1'
    | 'connector.connection_paused.v1'
    | 'connector.connection_revoked.v1';
  connectionId: string;
  connectorKey: string;
  correlationId: string;
}>;

export type ConnectorLifecycleCommit = Readonly<{
  connection: ConnectorConnection;
  /** Undefined means creation and requires the connection not to exist. */
  expectedVersion?: string;
  /** Omit to leave data sources untouched; an empty list deliberately clears them. */
  dataSources?: readonly ConnectorDataSource[];
  idempotency: ConnectorCommandIdempotency;
  audit: ConnectorAuditEvent;
  outbox: ConnectorOutboxEvent;
}>;

export type ConnectorLifecycleCommitResult =
  | Readonly<{
      ok: true;
      value: VersionedConnectorConnection;
      replayed: boolean;
    }>
  | Readonly<{
      ok: false;
      code: 'idempotency_conflict' | 'state_conflict' | 'version_mismatch';
    }>;

/**
 * The sole lifecycle mutation boundary. An implementation commits connection
 * state, selected sources, idempotency receipt, audit event and outbox intent
 * atomically in the practice's regional cell.
 */
export interface ConnectorLifecycleStore {
  commit(
    write: ConnectorLifecycleCommit,
  ): Promise<ConnectorLifecycleCommitResult>;
}
