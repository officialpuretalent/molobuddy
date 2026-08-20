import type { Firestore } from 'firebase-admin/firestore';

import type { OnboardingStatusReader } from '../../../application/ports/onboarding_status_reader.js';

/// The path is repeated from practice_management's adapter rather than
/// imported across the context boundary. Two adapters agreeing on one
/// collection path is a smaller cost than a dependency cycle, and the path is
/// recorded in the identity and access data design so both have one source to
/// be checked against.
export class FirestoreOnboardingStatusReader implements OnboardingStatusReader {
  constructor(private readonly db: Firestore) {}

  async isComplete(uid: string): Promise<boolean> {
    const stored = (
      await this.db.doc(`users/${uid}/onboarding/current`).get()
    ).data() as Readonly<{ status?: string }> | undefined;
    return stored?.status === 'complete';
  }
}
