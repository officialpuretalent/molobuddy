import type { SyncCheckpoint } from '../../domain/sync_checkpoint.js';

/** Lease acquisition and cursor advance must occur in the worker's transaction. */
export interface SyncCheckpointRepository {
  get(
    practiceId: string,
    connectionId: string,
    dataSourceId: string,
    recordKind: string,
  ): Promise<SyncCheckpoint | undefined>;

  save(checkpoint: SyncCheckpoint): Promise<void>;
}
