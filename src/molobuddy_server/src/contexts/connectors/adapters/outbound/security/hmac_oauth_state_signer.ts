import { createHmac, timingSafeEqual } from 'node:crypto';

import type { OAuthStateSigner } from '../../../application/ports/oauth_state_signer.js';

const stateIdPattern = /^oas_[a-f0-9]{32}$/;

/**
 * Stateless HMAC protection for the provider-visible state envelope. The
 * state ID itself resolves only to regional, single-use server-side state.
 */
export class HmacOAuthStateSigner implements OAuthStateSigner {
  constructor(private readonly key: Uint8Array) {
    if (key.byteLength < 32) {
      throw new Error(
        'OAuth state signing key must contain at least 256 bits.',
      );
    }
  }

  sign(stateId: string): string {
    assertStateId(stateId);
    return `v1.${stateId}.${this.signature(stateId)}`;
  }

  verify(signedState: string): string | undefined {
    const parts = signedState.split('.');
    const version = parts[0];
    const stateId = parts[1];
    const signature = parts[2];
    if (
      parts.length !== 3 ||
      version !== 'v1' ||
      stateId === undefined ||
      signature === undefined ||
      !stateIdPattern.test(stateId)
    ) {
      return undefined;
    }
    const expected = Buffer.from(this.signature(stateId));
    const received = Buffer.from(signature);
    return expected.byteLength === received.byteLength &&
      timingSafeEqual(expected, received)
      ? stateId
      : undefined;
  }

  private signature(stateId: string): string {
    return createHmac('sha256', this.key)
      .update(`molo-oauth-state:v1:${stateId}`)
      .digest('base64url');
  }
}

function assertStateId(stateId: string): void {
  if (!stateIdPattern.test(stateId)) {
    throw new Error('OAuth state ID is invalid.');
  }
}
