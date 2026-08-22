import type { SyncRun } from '../../domain/sync_run.js';
import type { ConnectorAuditEvent } from './connector_audit_event.js';

/** A durable run/lease implementation will back this port in the regional cell. */
export interface SyncRunRepository {
  get(practiceId: string, syncRunId: string): Promise<SyncRun | undefined>;

  save(syncRun: SyncRun, audit: ConnectorAuditEvent): Promise<void>;

  listForConnection(
    practiceId: string,
    connectionId: string,
  ): Promise<readonly SyncRun[]>;
}
