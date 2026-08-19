import { getAppCheck } from 'firebase-admin/app-check';
import { applicationDefault, getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

import type {
  PresentedRequestTokens,
  RequestTokenVerifier,
  TokenVerificationResult,
} from '../../contexts/identity_access/index.js';

const firebaseAppName = 'molobuddy-control-api';

export class FirebaseAdminRequestTokenVerifier implements RequestTokenVerifier {
  private readonly app;

  constructor(private readonly projectId: string) {
    const existing = getApps().find((app) => app.name === firebaseAppName);
    this.app =
      existing ??
      initializeApp(
        {
          credential: applicationDefault(),
          projectId,
        },
        firebaseAppName,
      );
  }

  async verify(
    tokens: PresentedRequestTokens,
  ): Promise<TokenVerificationResult> {
    if (tokens.idToken === undefined) {
      return { ok: false, code: 'authentication_required' };
    }
    if (tokens.appCheckToken === undefined) {
      return { ok: false, code: 'app_check_required' };
    }

    let appCheck;
    try {
      appCheck = await getAppCheck(this.app).verifyToken(tokens.appCheckToken);
    } catch {
      return { ok: false, code: 'app_check_required' };
    }

    let identity;
    try {
      identity = await getAuth(this.app).verifyIdToken(tokens.idToken);
    } catch {
      return { ok: false, code: 'token_invalid' };
    }

    const signInProvider = identity.firebase.sign_in_provider;
    const displayName = readStringClaim(identity, 'name');
    const preferredLocale = readStringClaim(identity, 'locale');

    return {
      ok: true,
      actor: {
        uid: identity.uid,
        firebaseProjectId: this.projectId,
        appId: appCheck.appId,
        providerIds: signInProvider === '' ? [] : [signInProvider],
        emailVerified: identity.email_verified === true,
        ...(displayName === undefined ? {} : { displayName }),
        ...(identity.email === undefined ? {} : { email: identity.email }),
        ...(preferredLocale === undefined ? {} : { preferredLocale }),
      },
    };
  }
}

function readStringClaim(
  claims: Readonly<Record<string, unknown>>,
  name: string,
): string | undefined {
  const value = claims[name];
  return typeof value === 'string' && value.length > 0 ? value : undefined;
}
