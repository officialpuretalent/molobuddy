import type { WebhookReceipt } from '../../domain/webhook_receipt.js';

export type RecordWebhookReceiptResult =
  Readonly<{ accepted: true }> | Readonly<{ accepted: false; replayed: true }>;

/** Persists receipt, quarantine reference and asynchronous intent atomically. */
export interface WebhookReceiptRepository {
  record(receipt: WebhookReceipt): Promise<RecordWebhookReceiptResult>;
}
