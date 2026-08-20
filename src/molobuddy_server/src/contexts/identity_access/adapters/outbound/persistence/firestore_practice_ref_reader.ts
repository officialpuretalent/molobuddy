import type { Firestore } from 'firebase-admin/firestore';

import type {
  PracticeRef,
  PracticeRefReader,
} from '../../../application/ports/practice_ref_reader.js';

export class FirestorePracticeRefReader implements PracticeRefReader {
  constructor(private readonly db: Firestore) {}

  async listForUser(uid: string): Promise<readonly PracticeRef[]> {
    const snapshot = await this.db
      .collection(`users/${uid}/practiceRefs`)
      .orderBy('displayLabel')
      .get();

    return snapshot.docs.map((doc) => doc.data() as PracticeRef);
  }
}
