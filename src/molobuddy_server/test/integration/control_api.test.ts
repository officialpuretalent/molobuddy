import assert from 'node:assert/strict';
import { after, before, describe, it } from 'node:test';

import type { FastifyInstance } from 'fastify';

import { buildControlApi } from '../../src/bootstrap/build_control_api.js';
import type {
  PracticeRef,
  PracticeRefReader,
} from '../../src/contexts/identity_access/index.js';
import { testConfig } from '../fixtures/test_config.js';

type SessionResponse = Readonly<{
  data: Readonly<{
    user: Readonly<{
      uid: string;
      displayName?: string;
      emailMasked?: string;
    }>;
    practiceRefs: readonly Readonly<{
      practiceId: string;
      displayLabel: string;
    }>[];
    onboarding: Readonly<{ status: string }>;
  }>;
  meta: Readonly<{
    apiVersion: string;
    requestId: string;
    correlationId: string;
  }>;
}>;

/**
 * Persistence is supplied, not reached for.
 *
 * The gate must not depend on a network or on whoever runs it holding Google
 * credentials, so nothing here opens a Firestore connection. What Firestore
 * itself does is proved against the emulator by the integration/firestore
 * suite.
 */
function readerReturning(practices: readonly PracticeRef[]): PracticeRefReader {
  return {
    async listForUser() {
      return practices;
    },
  };
}

describe('control API integration', () => {
  let app: FastifyInstance;

  before(async () => {
    app = await buildControlApi(testConfig(), {
      practiceRefReader: readerReturning([]),
      // Supplied, not reached for. Without this the gate opens a live
      // connection to the real development project and the gate becomes a
      // test of whoever is running it.
      onboardingStatusReader: { isComplete: async () => false },
    });
  });

  after(async () => {
    await app.close();
  });

  it('serves safe public health', async () => {
    const response = await app.inject({ method: 'GET', url: '/health' });

    assert.equal(response.statusCode, 200);
    assert.deepEqual(response.json(), {
      status: 'ok',
      regionKey: 'za1',
      release: 'test-release',
    });
  });

  it('establishes a local verified session through the complete HTTP slice', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/v1/session',
      headers: {
        authorization: 'Bearer known-id-token',
        'x-firebase-appcheck': 'known-app-check-token',
        'x-correlation-id': 'cor_integration_123',
      },
    });
    const body = response.json<SessionResponse>();

    assert.equal(response.statusCode, 200);
    assert.deepEqual(body.data, {
      user: {
        uid: 'user_123',
        displayName: 'Molo Tester',
        emailMasked: 't***@example.com',
      },
      practiceRefs: [],
      onboarding: { status: 'in_progress' },
    });
    assert.equal(body.meta.correlationId, 'cor_integration_123');
    assert.equal(response.headers['x-correlation-id'], 'cor_integration_123');
    assert.equal(response.headers['x-request-id'], body.meta.requestId);
  });

  it('allows only configured browser origins without credential mode', async () => {
    const allowed = await app.inject({
      method: 'GET',
      url: '/v1/auth/providers',
      headers: { origin: 'http://localhost:3000' },
    });
    const denied = await app.inject({
      method: 'GET',
      url: '/v1/auth/providers',
      headers: { origin: 'https://attacker.example' },
    });

    assert.equal(
      allowed.headers['access-control-allow-origin'],
      'http://localhost:3000',
    );
    assert.equal(
      allowed.headers['access-control-allow-credentials'],
      undefined,
    );
    assert.equal(denied.headers['access-control-allow-origin'], undefined);
  });

  it('carries the caller\u2019s practices through the whole HTTP slice', async () => {
    const withPractice = await buildControlApi(testConfig(), {
      onboardingStatusReader: { isComplete: async () => false },
      practiceRefReader: readerReturning([
        {
          practiceId: 'prc_1',
          displayLabel: 'Mokoena Media Tax',
          homeRegionKey: 'za1',
          routeVersion: 1,
          accessStatus: 'active',
        },
      ]),
    });

    const response = await withPractice.inject({
      method: 'GET',
      url: '/v1/session',
      headers: {
        authorization: 'Bearer known-id-token',
        'x-firebase-appcheck': 'known-app-check-token',
      },
    });
    await withPractice.close();

    assert.equal(response.statusCode, 200);
    // A practice settles the gate, so the injected reader saying otherwise
    // must not matter.
    assert.deepEqual(response.json<SessionResponse>().data.onboarding, {
      status: 'complete',
    });
    assert.deepEqual(response.json<SessionResponse>().data.practiceRefs, [
      {
        practiceId: 'prc_1',
        displayLabel: 'Mokoena Media Tax',
        homeRegionKey: 'za1',
        routeVersion: 1,
        accessStatus: 'active',
      },
    ]);
  });
});
