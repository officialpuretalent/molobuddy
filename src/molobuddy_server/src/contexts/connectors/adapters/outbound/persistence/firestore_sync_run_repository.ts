import { FieldValue, type Firestore } from 'firebase-admin/firestore';

import { createResourceVersion } from '../../../../../platform/http/identifiers.js';
import type { SyncRunRepository } from '../../../application/ports/sync_run_repository.js';
import type { SyncRun } from '../../../domain/sync_run.js';

/** Durable, practice-scoped sync-run history. Leases/checkpoints remain a later port. */
export class FirestoreSyncRunRepository implements SyncRunRepository {
  constructor(private readonly db: Firestore) {}

  async get(
    practiceId: string,
    syncRunId: string,
  ): Promise<SyncRun | undefined> {
    const snapshot = await this.runDocument(practiceId, syncRunId).get();
    return snapshot.exists ? asSyncRun(snapshot.data()) : undefined;
  }

  async save(syncRun: SyncRun): Promise<void> {
    await this.runDocument(syncRun.practiceId, syncRun.syncRunId).set({
      ...syncRun,
      updatedAt: FieldValue.serverTimestamp(),
      version: createResourceVersion(),
    });
  }

  async listForConnection(
    practiceId: string,
    connectionId: string,
  ): Promise<readonly SyncRun[]> {
    const snapshot = await this.db
      .collection(`practices/${practiceId}/connectorSyncRuns`)
      .where('connectionId', '==', connectionId)
      .orderBy('updatedAt', 'desc')
      .get();
    return snapshot.docs.map((document) => asSyncRun(document.data()));
  }

  private runDocument(practiceId: string, syncRunId: string) {
    return this.db.doc(
      `practices/${practiceId}/connectorSyncRuns/${syncRunId}`,
    );
  }
}

function asSyncRun(stored: Record<string, unknown> | undefined): SyncRun {
  return Object.fromEntries(
    Object.entries(stored ?? {}).filter(
      ([key]) => key !== 'updatedAt' && key !== 'version',
    ),
  ) as SyncRun;
}
