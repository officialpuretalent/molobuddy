import assert from 'node:assert/strict';
import { after, before, describe, it } from 'node:test';

import Fastify, { type FastifyInstance } from 'fastify';

import { buildControlApi } from '../../src/bootstrap/build_control_api.js';
import { authProvidersResponseSchema } from '../../src/platform/http/schemas.js';
import { testConfig } from '../fixtures/test_config.js';

type ProvidersResponse = Readonly<{
  data: Readonly<{
    providers: readonly Readonly<{
      providerId: string;
      kind: string;
      displayNameKey: string;
      availability: string;
      enabledPlatforms: readonly string[];
      supportsLinking: boolean;
      sortOrder: number;
    }>[];
  }>;
  meta: Readonly<{
    apiVersion: string;
    requestId: string;
    correlationId: string;
  }>;
}>;

type ProblemResponse = Readonly<{
  type: string;
  title: string;
  status: number;
  detail: string;
  instance: string;
  code: string;
  correlationId: string;
}>;

describe('identity and access HTTP contract', () => {
  let app: FastifyInstance;

  before(async () => {
    app = await buildControlApi(testConfig());
  });

  after(async () => {
    await app.close();
  });

  it('publishes email/password and the deliberate Google stub', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/v1/auth/providers?platform=web&appVersion=0.1.0',
      headers: { 'x-correlation-id': 'cor_contract_123' },
    });
    const body = response.json<ProvidersResponse>();

    assert.equal(response.statusCode, 200);
    assert.deepEqual(body.data.providers, [
      {
        providerId: 'password',
        kind: 'email_password',
        displayNameKey: 'auth.provider.emailPassword',
        availability: 'available',
        enabledPlatforms: ['android', 'ios', 'web'],
        supportsLinking: true,
        sortOrder: 10,
      },
      {
        providerId: 'google.com',
        kind: 'federated',
        displayNameKey: 'auth.provider.google',
        availability: 'coming_soon',
        enabledPlatforms: ['android', 'ios', 'web'],
        supportsLinking: true,
        sortOrder: 20,
      },
    ]);
    assert.equal(body.meta.apiVersion, 'v1');
    assert.equal(body.meta.correlationId, 'cor_contract_123');
    assert.match(body.meta.requestId, /^req_[a-f0-9]{32}$/);
  });

  it('returns allowlisted RFC 9457 problem details for unsupported query fields', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/v1/auth/providers?unknown=value',
      headers: { 'x-correlation-id': 'cor_problem_123' },
    });
    const body = response.json<ProblemResponse>();

    assert.equal(response.statusCode, 400);
    assert.match(
      response.headers['content-type'] ?? '',
      /application\/problem\+json/,
    );
    assert.deepEqual(
      {
        status: body.status,
        code: body.code,
        correlationId: body.correlationId,
      },
      {
        status: 400,
        code: 'invalid_query',
        correlationId: 'cor_problem_123',
      },
    );
    assert.match(body.type, /\/problems\/invalid-query$/);
    assert.match(body.instance, /^\/v1\/problems\/prb_[a-f0-9]{32}$/);
    assert.equal('stack' in body, false);
  });

  it('keeps missing identity and missing App Check as separate failures', async () => {
    const missingIdentity = await app.inject({
      method: 'GET',
      url: '/v1/session',
    });
    const missingAppCheck = await app.inject({
      method: 'GET',
      url: '/v1/session',
      headers: { authorization: 'Bearer known-id-token' },
    });

    assert.equal(missingIdentity.statusCode, 401);
    assert.equal(
      missingIdentity.json<ProblemResponse>().code,
      'authentication_required',
    );
    assert.equal(missingAppCheck.statusCode, 403);
    assert.equal(
      missingAppCheck.json<ProblemResponse>().code,
      'app_check_required',
    );
  });

  it('uses response schemas as a sensitive-field allowlist', async () => {
    const probe = Fastify({ logger: false });
    probe.get(
      '/probe',
      { schema: { response: { 200: authProvidersResponseSchema } } },
      async () => ({
        data: {
          providers: [
            {
              providerId: 'password',
              kind: 'email_password',
              displayNameKey: 'auth.provider.emailPassword',
              availability: 'available',
              enabledPlatforms: ['web'],
              supportsLinking: true,
              sortOrder: 10,
              providerSecret: 'must-not-leak',
            },
          ],
          internalTenant: 'must-not-leak',
        },
        meta: {
          apiVersion: 'v1',
          requestId: 'req_probe',
          correlationId: 'cor_probe',
        },
        debug: 'must-not-leak',
      }),
    );

    const response = await probe.inject({ method: 'GET', url: '/probe' });
    await probe.close();

    assert.equal(response.statusCode, 200);
    assert.equal(response.body.includes('must-not-leak'), false);
  });
});
