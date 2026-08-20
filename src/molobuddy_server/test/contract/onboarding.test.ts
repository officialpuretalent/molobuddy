import assert from 'node:assert/strict';
import { after, before, describe, it } from 'node:test';

import type { FastifyInstance } from 'fastify';

import { buildControlApi } from '../../src/bootstrap/build_control_api.js';
import type {
  OnboardingRepository,
  SaveAnswersOutcome,
  StoredOnboarding,
} from '../../src/contexts/practice_management/application/ports/onboarding_repository.js';
import type {
  PracticeRepository,
  ProvisionPracticeOutcome,
  ProvisionPracticeWrite,
} from '../../src/contexts/practice_management/application/ports/practice_repository.js';
import type { PracticeRefRecord } from '../../src/contexts/practice_management/index.js';
import {
  mergeAnswers,
  type OnboardingAnswers,
} from '../../src/contexts/practice_management/domain/onboarding.js';
import { testConfig } from '../fixtures/test_config.js';

type OnboardingResponse = Readonly<{
  data: Readonly<{
    status: string;
    nextStep?: string;
    answers: Record<string, unknown>;
    version?: string;
  }>;
}>;

type PracticeResponse = Readonly<{ data: PracticeRefRecord }>;

type ProblemResponse = Readonly<{
  status: number;
  code: string;
  detail: string;
  errors?: readonly Readonly<{ pointer: string; code: string }>[];
}>;

/**
 * Enough of the record to prove the HTTP contract.
 *
 * The branch order is copied from the Firestore adapter rather than invented,
 * because two sets of If-Match rules is how the contract test and the real
 * server come to disagree.
 */
class InMemoryOnboarding implements OnboardingRepository {
  private stored: StoredOnboarding | undefined;
  private counter = 0;

  async find(): Promise<StoredOnboarding | undefined> {
    return this.stored;
  }

  async save(
    _uid: string,
    patch: OnboardingAnswers,
    expectedVersion: string | undefined,
  ): Promise<SaveAnswersOutcome> {
    const existing = this.stored;
    if (existing === undefined) {
      if (expectedVersion !== undefined) {
        return { ok: false, reason: 'version_mismatch' };
      }
      this.stored = {
        status: 'in_progress',
        answers: patch,
        version: this.nextVersion(),
      };
      return { ok: true, stored: this.stored };
    }
    if (existing.status === 'complete') {
      return { ok: false, reason: 'already_complete' };
    }
    if (expectedVersion === undefined) {
      return { ok: false, reason: 'version_required' };
    }
    if (expectedVersion !== existing.version) {
      return { ok: false, reason: 'version_mismatch' };
    }
    this.stored = {
      status: 'in_progress',
      answers: mergeAnswers(existing.answers, patch),
      version: this.nextVersion(),
    };
    return { ok: true, stored: this.stored };
  }

  private nextVersion(): string {
    this.counter += 1;
    return `v-${String(this.counter)}`;
  }
}

class InMemoryPractices implements PracticeRepository {
  private readonly used = new Map<string, PracticeRefRecord>();

  async provision(
    write: ProvisionPracticeWrite,
  ): Promise<ProvisionPracticeOutcome> {
    const key = `${write.member.uid}:${write.idempotencyKey}`;
    const existing = this.used.get(key);
    if (existing !== undefined) {
      return { practiceRef: existing, replayed: true };
    }
    this.used.set(key, write.practiceRef);
    return { practiceRef: write.practiceRef, replayed: false };
  }
}

const validHeaders = {
  authorization: 'Bearer known-id-token',
  'x-firebase-appcheck': 'known-app-check-token',
} as const;

const everyAnswer = {
  practiceName: 'Mokoena Media Tax',
  practiceSize: 'solo',
  priorities: ['deadlines'],
  startingPoint: 'add_first_client',
};

const routes = [
  { method: 'GET' as const, url: '/v1/onboarding' },
  { method: 'PATCH' as const, url: '/v1/onboarding' },
  { method: 'POST' as const, url: '/v1/onboarding:complete' },
];

function payloadFor(
  method: string,
): Readonly<{ payload?: Record<string, unknown> }> {
  // exactOptionalPropertyTypes refuses an explicit undefined for an optional
  // property, so an absent payload is an absent key rather than undefined.
  return method === 'PATCH'
    ? { payload: { answers: { practiceSize: 'solo' } } }
    : {};
}

async function freshApp(): Promise<FastifyInstance> {
  return buildControlApi(testConfig(), {
    onboardingRepository: new InMemoryOnboarding(),
    practiceRepository: new InMemoryPractices(),
    auditEventSink: {
      record: async () => {
        // Auditing is proved elsewhere; this contract is about what the
        // endpoints answer.
      },
    },
  });
}

describe('onboarding HTTP contract', () => {
  let app: FastifyInstance;

  before(async () => {
    app = await freshApp();
  });

  after(async () => {
    await app.close();
  });

  it('starts a user who has answered nothing at the first question', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/v1/onboarding',
      headers: validHeaders,
    });
    const body = response.json<OnboardingResponse>();

    assert.equal(response.statusCode, 200);
    assert.equal(body.data.status, 'in_progress');
    assert.equal(body.data.nextStep, 'practice');
    assert.deepEqual(body.data.answers, {});
    assert.equal(body.data.version, undefined);
  });

  it('creates the record on a first save with no If-Match', async () => {
    const scoped = await freshApp();
    const response = await scoped.inject({
      method: 'PATCH',
      url: '/v1/onboarding',
      headers: validHeaders,
      payload: { answers: { practiceName: 'Mokoena Media Tax' } },
    });
    await scoped.close();
    const body = response.json<OnboardingResponse>();

    assert.equal(response.statusCode, 200);
    assert.equal(body.data.answers['practiceName'], 'Mokoena Media Tax');
    assert.ok((body.data.version ?? '').length > 0);
  });

  it('merges a later answer and moves the version on', async () => {
    const scoped = await freshApp();
    const first = await scoped.inject({
      method: 'PATCH',
      url: '/v1/onboarding',
      headers: validHeaders,
      payload: { answers: { practiceName: 'Mokoena Media Tax' } },
    });
    const version = first.json<OnboardingResponse>().data.version;
    const second = await scoped.inject({
      method: 'PATCH',
      url: '/v1/onboarding',
      headers: { ...validHeaders, 'if-match': version ?? '' },
      payload: { answers: { practiceSize: 'solo' } },
    });
    await scoped.close();
    const body = second.json<OnboardingResponse>();

    assert.equal(second.statusCode, 200);
    assert.equal(body.data.answers['practiceName'], 'Mokoena Media Tax');
    assert.equal(body.data.nextStep, 'priorities');
    assert.notEqual(body.data.version, version);
  });

  it('refuses a stale version', async () => {
    const scoped = await freshApp();
    const first = await scoped.inject({
      method: 'PATCH',
      url: '/v1/onboarding',
      headers: validHeaders,
      payload: { answers: { practiceSize: 'solo' } },
    });
    const stale = first.json<OnboardingResponse>().data.version ?? '';
    await scoped.inject({
      method: 'PATCH',
      url: '/v1/onboarding',
      headers: { ...validHeaders, 'if-match': stale },
      payload: { answers: { practiceSize: 'small_team' } },
    });
    const response = await scoped.inject({
      method: 'PATCH',
      url: '/v1/onboarding',
      headers: { ...validHeaders, 'if-match': stale },
      payload: { answers: { practiceSize: 'growing_team' } },
    });
    await scoped.close();

    assert.equal(response.statusCode, 412);
    assert.equal(response.json<ProblemResponse>().code, 'version_mismatch');
  });

  it('refuses a blind write once a record exists', async () => {
    const scoped = await freshApp();
    await scoped.inject({
      method: 'PATCH',
      url: '/v1/onboarding',
      headers: validHeaders,
      payload: { answers: { practiceSize: 'solo' } },
    });
    const response = await scoped.inject({
      method: 'PATCH',
      url: '/v1/onboarding',
      headers: validHeaders,
      payload: { answers: { practiceSize: 'small_team' } },
    });
    await scoped.close();

    assert.equal(response.statusCode, 428);
    assert.equal(response.json<ProblemResponse>().code, 'version_required');
  });

  it('refuses an unknown answer without repeating what was sent', async () => {
    const response = await app.inject({
      method: 'PATCH',
      url: '/v1/onboarding',
      headers: validHeaders,
      payload: { answers: { region: 'eu1' } },
    });

    assert.equal(response.statusCode, 400);
    assert.equal(response.body.includes('eu1'), false);
  });

  it('names the offending answer without repeating its value', async () => {
    const response = await app.inject({
      method: 'PATCH',
      url: '/v1/onboarding',
      headers: validHeaders,
      payload: { answers: { practiceSize: 'enormous' } },
    });
    const body = response.json<ProblemResponse>();

    assert.equal(response.statusCode, 400);
    assert.equal(body.code, 'validation_error');
    assert.equal(body.errors?.[0]?.pointer, '/answers/practiceSize');
    assert.equal(response.body.includes('enormous'), false);
  });

  it('founds the practice once every answer is present', async () => {
    const scoped = await freshApp();
    await scoped.inject({
      method: 'PATCH',
      url: '/v1/onboarding',
      headers: validHeaders,
      payload: { answers: everyAnswer },
    });
    const response = await scoped.inject({
      method: 'POST',
      url: '/v1/onboarding:complete',
      headers: { ...validHeaders, 'idempotency-key': 'complete-1' },
    });
    await scoped.close();
    const body = response.json<PracticeResponse>();

    assert.equal(response.statusCode, 201);
    assert.match(body.data.practiceId, /^prc_[a-f0-9]{32}$/);
    assert.equal(body.data.displayLabel, 'Mokoena Media Tax');
    assert.equal(body.data.accessStatus, 'active');
  });

  it('answers a replayed completion with 200 and the same practice', async () => {
    const scoped = await freshApp();
    await scoped.inject({
      method: 'PATCH',
      url: '/v1/onboarding',
      headers: validHeaders,
      payload: { answers: everyAnswer },
    });
    const headers = { ...validHeaders, 'idempotency-key': 'complete-replay' };
    const first = await scoped.inject({
      method: 'POST',
      url: '/v1/onboarding:complete',
      headers,
    });
    const second = await scoped.inject({
      method: 'POST',
      url: '/v1/onboarding:complete',
      headers,
    });
    await scoped.close();

    assert.equal(first.statusCode, 201);
    assert.equal(second.statusCode, 200);
    assert.deepEqual(
      second.json<PracticeResponse>().data,
      first.json<PracticeResponse>().data,
    );
  });

  it('refuses completion while an answer is missing, and names it', async () => {
    const scoped = await freshApp();
    await scoped.inject({
      method: 'PATCH',
      url: '/v1/onboarding',
      headers: validHeaders,
      payload: {
        answers: {
          practiceName: 'Mokoena Media Tax',
          practiceSize: 'solo',
          priorities: ['deadlines'],
        },
      },
    });
    const response = await scoped.inject({
      method: 'POST',
      url: '/v1/onboarding:complete',
      headers: { ...validHeaders, 'idempotency-key': 'complete-partial' },
    });
    await scoped.close();
    const body = response.json<ProblemResponse>();

    assert.equal(response.statusCode, 409);
    assert.equal(body.code, 'onboarding_incomplete');
    assert.equal(body.errors?.[0]?.pointer, '/answers/startingPoint');
  });

  it('requires an idempotency key to complete', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/v1/onboarding:complete',
      headers: validHeaders,
    });

    assert.equal(response.statusCode, 400);
    assert.equal(response.json<ProblemResponse>().code, 'validation_error');
  });

  it('requires an identity token on every route', async () => {
    for (const route of routes) {
      const response = await app.inject({
        method: route.method,
        url: route.url,
        headers: {
          'x-firebase-appcheck': 'known-app-check-token',
          'idempotency-key': 'anonymous',
        },
        ...payloadFor(route.method),
      });

      assert.equal(response.statusCode, 401, route.url);
      assert.equal(
        response.json<ProblemResponse>().code,
        'authentication_required',
      );
    }
  });

  it('rejects an identity token it cannot verify on every route', async () => {
    for (const route of routes) {
      const response = await app.inject({
        method: route.method,
        url: route.url,
        headers: {
          ...validHeaders,
          authorization: 'Bearer not-the-known-token',
          'idempotency-key': 'bad-token',
        },
        ...payloadFor(route.method),
      });

      assert.equal(response.statusCode, 401, route.url);
      assert.equal(response.json<ProblemResponse>().code, 'token_invalid');
    }
  });

  it('keeps a missing App Check token as its own failure on every route', async () => {
    for (const route of routes) {
      const response = await app.inject({
        method: route.method,
        url: route.url,
        headers: {
          authorization: 'Bearer known-id-token',
          'idempotency-key': 'no-app-check',
        },
        ...payloadFor(route.method),
      });

      assert.equal(response.statusCode, 403, route.url);
      assert.equal(response.json<ProblemResponse>().code, 'app_check_required');
    }
  });
});
