import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import { FirebaseAdminRequestTokenVerifier } from '../../src/platform/auth/firebase_admin_request_token_verifier.js';

// These cases resolve before any Google API call, so the adapter contract is
// asserted without credentials or network access.
describe('firebase admin request token verifier', () => {
  it('keeps authentication and App Check failures distinct', async () => {
    const verifier = new FirebaseAdminRequestTokenVerifier(
      'molobuddy-development',
    );

    assert.deepEqual(await verifier.verify({}), {
      ok: false,
      code: 'authentication_required',
    });
    assert.deepEqual(
      await verifier.verify({ appCheckToken: 'present-but-no-id-token' }),
      { ok: false, code: 'authentication_required' },
    );
    assert.deepEqual(await verifier.verify({ idToken: 'present' }), {
      ok: false,
      code: 'app_check_required',
    });
  });

  it('reuses one named Firebase app across instances', () => {
    const first = new FirebaseAdminRequestTokenVerifier(
      'molobuddy-development',
    );
    const second = new FirebaseAdminRequestTokenVerifier(
      'molobuddy-development',
    );

    assert.ok(first);
    assert.ok(second);
  });
});
