import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import type { LocalAuthVerifierConfig } from '../../src/bootstrap/config.js';
import { LocalRequestTokenVerifier } from '../../src/platform/auth/local_request_token_verifier.js';

const config: LocalAuthVerifierConfig = {
  mode: 'local',
  environment: 'test',
  idToken: 'known-id-token',
  appCheckToken: 'known-app-check-token',
  actor: {
    uid: 'user_123',
    displayName: 'Molo Tester',
    email: 'tester@example.com',
    emailVerified: true,
  },
};

describe('local request token verifier', () => {
  it('verifies only the configured token pair', async () => {
    const verifier = new LocalRequestTokenVerifier(config);
    const result = await verifier.verify({
      idToken: 'known-id-token',
      appCheckToken: 'known-app-check-token',
    });

    assert.equal(result.ok, true);
    assert.equal(result.actor.uid, 'user_123');
    assert.deepEqual(result.actor.providerIds, ['password']);
  });

  it('keeps authentication and App Check failures distinct', async () => {
    const verifier = new LocalRequestTokenVerifier(config);

    assert.deepEqual(await verifier.verify({}), {
      ok: false,
      code: 'authentication_required',
    });
    assert.deepEqual(await verifier.verify({ idToken: 'wrong' }), {
      ok: false,
      code: 'token_invalid',
    });
    assert.deepEqual(await verifier.verify({ idToken: 'known-id-token' }), {
      ok: false,
      code: 'app_check_required',
    });
  });

  it('also rejects production at the adapter boundary', () => {
    assert.throws(
      () =>
        new LocalRequestTokenVerifier({
          ...config,
          environment: 'production',
        }),
      /forbidden in production/,
    );
  });
});
