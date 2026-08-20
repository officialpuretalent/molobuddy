import type { Firestore } from 'firebase-admin/firestore';

import type { ServerConfig } from './config.js';
import { FirestorePracticeRefReader } from '../contexts/identity_access/adapters/outbound/persistence/firestore_practice_ref_reader.js';
import {
  GetSession,
  ListAuthProviders,
  type PracticeRefReader,
  type RequestTokenVerifier,
} from '../contexts/identity_access/index.js';
import {
  FirestoreAuditEventSink,
  FirestorePracticeRepository,
} from '../contexts/practice_management/adapters/outbound/persistence/firestore_practice_repository.js';
import {
  ProvisionPractice,
  type AuditEventSink,
  type PracticeRepository,
} from '../contexts/practice_management/index.js';
import { FirebaseAdminRequestTokenVerifier } from '../platform/auth/firebase_admin_request_token_verifier.js';
import { LocalRequestTokenVerifier } from '../platform/auth/local_request_token_verifier.js';
import { getMoloFirestore } from '../platform/persistence/firestore.js';

export type ControlApiContainer = Readonly<{
  getSession: GetSession;
  listAuthProviders: ListAuthProviders;
  provisionPractice: ProvisionPractice;
  verifier: RequestTokenVerifier;
}>;

/**
 * Adapters a caller may supply instead of the real ones.
 *
 * The composition root is the only honest place to substitute persistence, and
 * a contract test that asks what the endpoint answers should not need an
 * emulator to find out.
 */
export type ControlApiDependencies = Readonly<{
  practiceRepository?: PracticeRepository;
  auditEventSink?: AuditEventSink;
  practiceRefReader?: PracticeRefReader;
}>;

export function createControlApiContainer(
  config: ServerConfig,
  dependencies: ControlApiDependencies = {},
): ControlApiContainer {
  const verifier =
    config.auth.mode === 'firebase'
      ? new FirebaseAdminRequestTokenVerifier(config.auth.projectId)
      : new LocalRequestTokenVerifier(config.auth);

  // Built on first use, so a run whose persistence is entirely supplied never
  // opens a Firestore connection it will not use.
  let firestore: Firestore | undefined;
  const database = (): Firestore =>
    (firestore ??= getMoloFirestore(
      config.auth.mode === 'firebase'
        ? config.auth.projectId
        : // The local verifier carries no project. Development is the only
          // project the local verifier is permitted to run against.
          'molobuddy-development',
    ));

  return {
    getSession: new GetSession(
      verifier,
      dependencies.practiceRefReader ??
        new FirestorePracticeRefReader(database()),
    ),
    listAuthProviders: new ListAuthProviders(),
    verifier,
    provisionPractice: new ProvisionPractice(
      dependencies.practiceRepository ??
        new FirestorePracticeRepository(database()),
      dependencies.auditEventSink ?? new FirestoreAuditEventSink(database()),
      config.regionKey,
    ),
  };
}
