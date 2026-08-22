import type { AccountingProviderKey } from '../../domain/accounting_provider.js';
import type { ConnectorConnectionStatus } from '../../domain/connector_connection.js';
import type { SyncRunStatus } from '../../domain/sync_run.js';

/**
 * Allowlisted connector evidence. It intentionally has no field capable of
 * carrying credentials, provider request/response bodies, or webhook bytes.
 */
export type ConnectorAuditEvent = Readonly<{
  practiceId: string;
  connectionId: string;
  providerKey: AccountingProviderKey;
  action:
    | 'connector.authorisation_started'
    | 'connector.authorisation_completed'
    | 'connector.sources_selected'
    | 'connector.paused'
    | 'connector.revoked'
    | 'connector.sync_queued'
    | 'connector.sync_started'
    | 'connector.sync_completed'
    | 'connector.sync_failed'
    | 'connector.credential_rotated'
    | 'connector.credential_revoked'
    | 'connector.webhook_verified'
    | 'connector.webhook_rejected';
  actor:
    | Readonly<{ kind: 'user'; uid: string }>
    | Readonly<{ kind: 'system'; name: 'connector-worker' }>;
  correlationId: string;
  resultingState: Readonly<{
    connectionStatus?: ConnectorConnectionStatus;
    syncRunId?: string;
    syncStatus?: SyncRunStatus;
    selectedSourceCount?: number;
    credentialGeneration?: number;
  }>;
}>;
