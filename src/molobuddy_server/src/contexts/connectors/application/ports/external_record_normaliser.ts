import type {
  AccountingProviderKey,
  AccountingRecordKind,
} from '../../domain/accounting_provider.js';
import type { NormalisedExternalRecord } from '../../domain/external_record.js';

/**
 * Maps provider DTOs privately inside an adapter into Molo's canonical intake
 * envelope. A normaliser cannot write Taxpayer, Tax Work or Document records.
 */
export interface ExternalRecordNormaliser {
  normalise(input: ProviderRecordForNormalisation): NormalisedExternalRecord;
}

export type ProviderRecordForNormalisation = Readonly<{
  providerKey: AccountingProviderKey;
  dataSourceId: string;
  recordKind: AccountingRecordKind;
  retrievedAt: string;
  sourcePayloadReference: string;
  providerRecord: unknown;
}>;
