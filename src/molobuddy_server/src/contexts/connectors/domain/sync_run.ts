export type SyncRunStatus =
  'cancelled' | 'complete' | 'failed' | 'needs_review' | 'queued' | 'running';

export type SyncRun = Readonly<{
  syncRunId: string;
  practiceId: string;
  connectionId: string;
  dataSourceId: string;
  mode: 'delta' | 'full' | 'selected_sources';
  status: SyncRunStatus;
  counters: Readonly<{
    received: number;
    matched: number;
    applied: number;
    needsReview: number;
    failed: number;
  }>;
}>;

export function queueSyncRun(
  input: Omit<SyncRun, 'counters' | 'status'>,
): SyncRun {
  return {
    ...input,
    status: 'queued',
    counters: {
      received: 0,
      matched: 0,
      applied: 0,
      needsReview: 0,
      failed: 0,
    },
  };
}

export function startSyncRun(syncRun: SyncRun): SyncRun | undefined {
  return syncRun.status === 'queued'
    ? { ...syncRun, status: 'running' }
    : undefined;
}

export function completeSyncRun(
  syncRun: SyncRun,
  counters: SyncRun['counters'],
): SyncRun | undefined {
  return syncRun.status === 'running'
    ? { ...syncRun, status: 'complete', counters }
    : undefined;
}
