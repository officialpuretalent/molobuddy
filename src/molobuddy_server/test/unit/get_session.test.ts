import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import {
  GetSession,
  maskEmail,
} from '../../src/contexts/identity_access/application/queries/get_session.js';
import type {
  PracticeRef,
  PracticeRefReader,
} from '../../src/contexts/identity_access/application/ports/practice_ref_reader.js';
import type { OnboardingStatusReader } from '../../src/contexts/identity_access/application/ports/onboarding_status_reader.js';
import type {
  RequestTokenVerifier,
  VerifiedActor,
} from '../../src/contexts/identity_access/index.js';

const actor: VerifiedActor = {
  uid: 'user_123',
  firebaseProjectId: 'test-project',
  appId: 'test-app',
  providerIds: ['password'],
  emailVerified: true,
  displayName: 'Molo Tester',
  email: 'tester@example.com',
};

function verifierAccepting(verified: VerifiedActor): RequestTokenVerifier {
  return {
    async verify() {
      return { ok: true, actor: verified };
    },
  };
}

const noPractices: PracticeRefReader = {
  async listForUser() {
    return [];
  },
};

const aPractice: PracticeRef = {
  practiceId: 'prc_1',
  displayLabel: 'Mokoena Media Tax',
  homeRegionKey: 'za1',
  routeVersion: 1,
  accessStatus: 'active',
};

function readerReturning(practices: readonly PracticeRef[]): PracticeRefReader {
  return {
    async listForUser() {
      return practices;
    },
  };
}

const notOnboarded: OnboardingStatusReader = {
  async isComplete() {
    return false;
  },
};

describe('get session', () => {
  it('returns a Molo session without leaking a raw email address', async () => {
    const result = await new GetSession(
      verifierAccepting(actor),
      noPractices,
      notOnboarded,
    ).execute({});

    assert.deepEqual(result, {
      ok: true,
      session: {
        user: {
          uid: 'user_123',
          displayName: 'Molo Tester',
          emailMasked: 't***@example.com',
        },
        practiceRefs: [],
        onboarding: { status: 'in_progress' },
      },
    });
  });

  it('omits malformed email claims', () => {
    assert.equal(maskEmail('not-an-email'), undefined);
  });

  it('returns the practices the user actually has', async () => {
    const asked: string[] = [];
    const reader: PracticeRefReader = {
      async listForUser(uid: string) {
        asked.push(uid);
        return [
          {
            practiceId: 'prc_1',
            displayLabel: 'Mokoena Media Tax',
            homeRegionKey: 'za1',
            routeVersion: 1,
            accessStatus: 'active' as const,
          },
        ];
      },
    };

    const result = await new GetSession(
      verifierAccepting(actor),
      reader,
      notOnboarded,
    ).execute({});

    assert.equal(result.ok, true);
    assert.deepEqual(
      result.session.practiceRefs.map((practice) => practice.practiceId),
      ['prc_1'],
    );
    // The uid comes from the verified token, never from the request, so one
    // user can never read another's list.
    assert.deepEqual(asked, ['user_123']);
  });

  it('returns an empty list for a user with no practice', async () => {
    const result = await new GetSession(
      verifierAccepting(actor),
      noPractices,
      notOnboarded,
    ).execute({});

    assert.equal(result.ok, true);
    assert.deepEqual(result.session.practiceRefs, []);
  });

  it('never reads a practice list for a caller it could not verify', async () => {
    let consulted = false;
    const reader: PracticeRefReader = {
      async listForUser() {
        consulted = true;
        return [];
      },
    };
    const rejecting: RequestTokenVerifier = {
      async verify() {
        return { ok: false, code: 'token_invalid' };
      },
    };

    const result = await new GetSession(
      rejecting,
      reader,
      notOnboarded,
    ).execute({});

    assert.deepEqual(result, { ok: false, code: 'token_invalid' });
    assert.equal(consulted, false);
  });

  it('reports onboarding complete for a user who has a practice', async () => {
    let consulted = false;
    const query = new GetSession(
      verifierAccepting(actor),
      readerReturning([aPractice]),
      {
        async isComplete() {
          consulted = true;
          return false;
        },
      },
    );

    const result = await query.execute({});

    assert.equal(result.ok, true);
    assert.deepEqual(result.session.onboarding, { status: 'complete' });
    // Having a practice settles it. Reading the record anyway would add a
    // Firestore round trip to the hottest endpoint for every onboarded user.
    assert.equal(consulted, false);
  });

  it('asks the record only when the user has no practice', async () => {
    const query = new GetSession(
      verifierAccepting(actor),
      noPractices,
      notOnboarded,
    );

    const result = await query.execute({});

    assert.equal(result.ok, true);
    assert.deepEqual(result.session.onboarding, { status: 'in_progress' });
  });

  it('believes a completed record even with no practice left', async () => {
    // Losing access to a practice must not push someone who already onboarded
    // back into a wizard.
    const query = new GetSession(verifierAccepting(actor), noPractices, {
      async isComplete() {
        return true;
      },
    });

    const result = await query.execute({});

    assert.equal(result.ok, true);
    assert.deepEqual(result.session.onboarding, { status: 'complete' });
  });
});
