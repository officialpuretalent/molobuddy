import { applicationDefault, getApps, initializeApp } from 'firebase-admin/app';
import {
  getFirestore,
  type Firestore,
  type Transaction,
} from 'firebase-admin/firestore';

const firebaseAppName = 'molobuddy-control-api';

/**
 * The Firestore client for this process.
 *
 * Reuses the named Firebase app the token verifier creates, so one process
 * holds one app rather than two competing initialisations. When
 * FIRESTORE_EMULATOR_HOST is set, the Admin SDK routes here to the emulator
 * with no further configuration.
 */
export function getMoloFirestore(projectId: string): Firestore {
  const existing = getApps().find((app) => app.name === firebaseAppName);
  const app =
    existing ??
    initializeApp(
      { credential: applicationDefault(), projectId },
      firebaseAppName,
    );
  return getFirestore(app);
}

/**
 * Runs `work` in a Firestore transaction.
 *
 * Wrapping the vendor call keeps `firebase-admin` out of application code:
 * a command receives this function's behaviour through a port, never the SDK.
 */
export function runInTransaction<T>(
  db: Firestore,
  work: (tx: Transaction) => Promise<T>,
): Promise<T> {
  return db.runTransaction(work);
}
