import assert from 'node:assert/strict';
import { after, before, describe, it } from 'node:test';

import type { FastifyInstance } from 'fastify';

import { buildControlApi } from '../../src/bootstrap/build_control_api.js';
import { testConfig } from '../fixtures/test_config.js';

type SessionResponse = Readonly<{
  data: Readonly<{
    user: Readonly<{
      uid: string;
      displayName?: string;
      emailMasked?: string;
    }>;
    practiceRefs: readonly unknown[];
  }>;
  meta: Readonly<{
    apiVersion: string;
    requestId: string;
    correlationId: string;
  }>;
}>;

describe('control API integration', () => {
  let app: FastifyInstance;

  before(async () => {
    app = await buildControlApi(testConfig());
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
});
