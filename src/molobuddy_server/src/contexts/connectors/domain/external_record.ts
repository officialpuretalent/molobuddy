import type {
  AccountingProviderKey,
  AccountingRecordKind,
} from './accounting_provider.js';

/**
 * The stable, intentionally small envelope available to matching and review
 * workflows. Provider-specific fields remain in the source evidence layer.
 */
export type NormalisedExternalRecord = Readonly<{
  providerKey: AccountingProviderKey;
  dataSourceId: string;
  recordKind: AccountingRecordKind;
  providerRecordId: string;
  providerVersion?: string;
  providerUpdatedAt?: string;
  retrievedAt: string;
  isDeleted: boolean;
  reference?: string;
  displayName?: string;
  issueDate?: string;
  dueDate?: string;
  currencyCode?: string;
  totalMinorUnits?: bigint;
  counterpartyProviderRecordId?: string;
  sourcePayloadReference: string;
}>;

/**
 * Provider IDs are only unique within a provider account and source entity.
 * This key is safe to use for idempotency; it is not a user-facing ID.
 */
export function externalRecordIdentity(
  record: Pick<
    NormalisedExternalRecord,
    'dataSourceId' | 'providerKey' | 'providerRecordId' | 'recordKind'
  >,
): string {
  return [
    record.providerKey,
    record.dataSourceId,
    record.recordKind,
    record.providerRecordId,
  ].join(':');
}
