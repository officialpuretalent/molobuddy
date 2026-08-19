import type { ServerConfig } from './config.js';
import {
  GetSession,
  ListAuthProviders,
} from '../contexts/identity_access/index.js';
import { FirebaseAdminRequestTokenVerifier } from '../platform/auth/firebase_admin_request_token_verifier.js';
import { LocalRequestTokenVerifier } from '../platform/auth/local_request_token_verifier.js';

export type ControlApiContainer = Readonly<{
  getSession: GetSession;
  listAuthProviders: ListAuthProviders;
}>;

export function createControlApiContainer(
  config: ServerConfig,
): ControlApiContainer {
  const verifier =
    config.auth.mode === 'firebase'
      ? new FirebaseAdminRequestTokenVerifier(config.auth.projectId)
      : new LocalRequestTokenVerifier(config.auth);

  return {
    getSession: new GetSession(verifier),
    listAuthProviders: new ListAuthProviders(),
  };
}
