import type { AccountingProviderKey } from '../../domain/accounting_provider.js';

/**
 * Provider-specific verification happens over the original bytes before any
 * JSON parsing. A verified event is still only a sync trigger, never a domain
 * command or a source-of-truth record.
 */
export interface ProviderWebhookVerifier {
  verify(input: ProviderWebhookRequest): ProviderWebhookVerification;
}

export type ProviderWebhookRequest = Readonly<{
  providerKey: AccountingProviderKey;
  headers: Readonly<Record<string, string | undefined>>;
  rawBody: Uint8Array;
  receivedAt: string;
}>;

export type ProviderWebhookVerification =
  | Readonly<{
      status: 'invalid';
      reason: 'signature_invalid' | 'timestamp_invalid';
    }>
  | Readonly<{
      status: 'verified';
      providerEventKey: string;
      dataSourceHint?: string;
    }>;
