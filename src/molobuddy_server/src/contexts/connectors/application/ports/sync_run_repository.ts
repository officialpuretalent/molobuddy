import type { SyncRun } from '../../domain/sync_run.js';

/** A durable run/lease implementation will back this port in the regional cell. */
export interface SyncRunRepository {
  get(practiceId: string, syncRunId: string): Promise<SyncRun | undefined>;

  save(syncRun: SyncRun): Promise<void>;

  listForConnection(
    practiceId: string,
    connectionId: string,
  ): Promise<readonly SyncRun[]>;
}
