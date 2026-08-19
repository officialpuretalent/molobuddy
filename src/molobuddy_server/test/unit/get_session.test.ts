import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import {
  GetSession,
  maskEmail,
} from '../../src/contexts/identity_access/application/queries/get_session.js';
import type { RequestTokenVerifier } from '../../src/contexts/identity_access/index.js';

describe('get session', () => {
  it('returns a Molo session without leaking a raw email address', async () => {
    const verifier: RequestTokenVerifier = {
      async verify() {
        return {
          ok: true,
          actor: {
            uid: 'user_123',
            firebaseProjectId: 'test-project',
            appId: 'test-app',
            providerIds: ['password'],
            emailVerified: true,
            displayName: 'Molo Tester',
            email: 'tester@example.com',
          },
        };
      },
    };

    const result = await new GetSession(verifier).execute({});
    assert.deepEqual(result, {
      ok: true,
      session: {
        user: {
          uid: 'user_123',
          displayName: 'Molo Tester',
          emailMasked: 't***@example.com',
        },
        practiceRefs: [],
      },
    });
  });

  it('omits malformed email claims', () => {
    assert.equal(maskEmail('not-an-email'), undefined);
  });
});
