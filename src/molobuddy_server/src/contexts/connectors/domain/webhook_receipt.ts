import type { AccountingProviderKey } from './accounting_provider.js';

export type WebhookReceipt = Readonly<{
  practiceId: string;
  connectionId: string;
  providerKey: AccountingProviderKey;
  providerEventKey: string;
  dataSourceId?: string;
  payloadQuarantineReference: string;
  followUpEventId: string;
}>;
