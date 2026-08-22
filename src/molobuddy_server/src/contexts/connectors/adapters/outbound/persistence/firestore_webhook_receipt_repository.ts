import { createHash } from 'node:crypto';

import { FieldValue, type Firestore } from 'firebase-admin/firestore';

import { runInTransaction } from '../../../../../platform/persistence/firestore.js';
import type {
  RecordWebhookReceiptResult,
  WebhookReceiptRepository,
} from '../../../application/ports/webhook_receipt_repository.js';
import type { WebhookReceipt } from '../../../domain/webhook_receipt.js';

/** Provider-event deduplication plus a durable, region-local worker intent. */
export class FirestoreWebhookReceiptRepository implements WebhookReceiptRepository {
  constructor(private readonly db: Firestore) {}

  async record(receipt: WebhookReceipt): Promise<RecordWebhookReceiptResult> {
    const id = createHash('sha256')
      .update(receipt.connectionId)
      .update('\n')
      .update(receipt.providerEventKey)
      .digest('hex');
    const receiptDocument = this.db.doc(
      `practices/${receipt.practiceId}/webhookReceipts/${id}`,
    );
    const outboxDocument = this.db.doc(
      `practices/${receipt.practiceId}/connectorOutbox/${receipt.followUpEventId}`,
    );

    return runInTransaction(this.db, async (transaction) => {
      if ((await transaction.get(receiptDocument)).exists) {
        return { accepted: false, replayed: true };
      }
      transaction.set(receiptDocument, {
        ...withoutUndefined(receipt),
        receivedAt: FieldValue.serverTimestamp(),
      });
      transaction.set(outboxDocument, {
        eventId: receipt.followUpEventId,
        type: 'connector.webhook_received.v1',
        connectionId: receipt.connectionId,
        connectorKey: receipt.providerKey,
        status: 'pending',
        occurredAt: FieldValue.serverTimestamp(),
      });
      return { accepted: true };
    });
  }
}

function withoutUndefined(receipt: WebhookReceipt): Record<string, unknown> {
  const { dataSourceId, ...persisted } = receipt;
  return dataSourceId === undefined
    ? persisted
    : { ...persisted, dataSourceId };
}
