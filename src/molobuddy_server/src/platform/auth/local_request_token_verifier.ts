import { timingSafeEqual } from 'node:crypto';

import type { LocalAuthVerifierConfig } from '../../bootstrap/config.js';
import type {
  PresentedRequestTokens,
  RequestTokenVerifier,
  TokenVerificationResult,
  VerifiedActor,
} from '../../contexts/identity_access/index.js';

export class LocalRequestTokenVerifier implements RequestTokenVerifier {
  private readonly actor: VerifiedActor;

  constructor(private readonly config: LocalAuthVerifierConfig) {
    if (config.environment === 'production') {
      throw new Error(
        'The local authentication verifier is forbidden in production.',
      );
    }

    this.actor = {
      uid: config.actor.uid,
      firebaseProjectId: 'local-development',
      appId: 'local-development-app',
      providerIds: ['password'],
      emailVerified: config.actor.emailVerified,
      ...(config.actor.displayName === undefined
        ? {}
        : { displayName: config.actor.displayName }),
      ...(config.actor.email === undefined
        ? {}
        : { email: config.actor.email }),
    };
  }

  verify(tokens: PresentedRequestTokens): Promise<TokenVerificationResult> {
    if (tokens.idToken === undefined) {
      return Promise.resolve({ ok: false, code: 'authentication_required' });
    }
    if (!safeEqual(tokens.idToken, this.config.idToken)) {
      return Promise.resolve({ ok: false, code: 'token_invalid' });
    }
    if (tokens.appCheckToken === undefined) {
      return Promise.resolve({ ok: false, code: 'app_check_required' });
    }
    if (!safeEqual(tokens.appCheckToken, this.config.appCheckToken)) {
      return Promise.resolve({ ok: false, code: 'app_check_required' });
    }
    return Promise.resolve({ ok: true, actor: this.actor });
  }
}

function safeEqual(left: string, right: string): boolean {
  const leftBuffer = Buffer.from(left);
  const rightBuffer = Buffer.from(right);
  return (
    leftBuffer.length === rightBuffer.length &&
    timingSafeEqual(leftBuffer, rightBuffer)
  );
}
