import type { AccountingRecordKind } from './accounting_provider.js';

export type SyncCheckpoint = Readonly<{
  practiceId: string;
  connectionId: string;
  dataSourceId: string;
  recordKind: AccountingRecordKind;
  cursor?: string;
  overlapStartedAt?: string;
  lease: Readonly<{ holderId: string; expiresAt: string }>;
}>;

export function mayAcquireLease(
  checkpoint: SyncCheckpoint | undefined,
  holderId: string,
  now: string,
): boolean {
  return (
    checkpoint === undefined ||
    checkpoint.lease.holderId === holderId ||
    checkpoint.lease.expiresAt <= now
  );
}

export function mayAdvanceCheckpoint(
  checkpoint: SyncCheckpoint,
  holderId: string,
  now: string,
): boolean {
  return (
    checkpoint.lease.holderId === holderId && checkpoint.lease.expiresAt > now
  );
}
