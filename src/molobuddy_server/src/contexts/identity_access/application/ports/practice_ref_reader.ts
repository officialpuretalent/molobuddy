import type { Session } from '../queries/get_session.js';

export type PracticeRef = Session['practiceRefs'][number];

export interface PracticeRefReader {
  /** The routing projections belonging to this user, ordered by display label. */
  listForUser(uid: string): Promise<readonly PracticeRef[]>;
}
