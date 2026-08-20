import assert from 'node:assert/strict';
import { after, before, describe, it } from 'node:test';

import type { FastifyInstance } from 'fastify';

import { buildControlApi } from '../../src/bootstrap/build_control_api.js';
import type {
  AuditEvent,
  AuditEventSink,
} from '../../src/contexts/practice_management/application/ports/audit_event_sink.js';
import type {
  PracticeRepository,
  ProvisionPracticeOutcome,
  ProvisionPracticeWrite,
} from '../../src/contexts/practice_management/application/ports/practice_repository.js';
import type { PracticeRefRecord } from '../../src/contexts/practice_management/index.js';
import { testConfig } from '../fixtures/test_config.js';

type PracticeResponse = Readonly<{
  data: PracticeRefRecord;
  meta: Readonly<{
    apiVersion: string;
    requestId: string;
    correlationId: string;
  }>;
}>;

type ProblemResponse = Readonly<{
  status: number;
  code: string;
  detail: string;
  correlationId: string;
}>;

/**
 * Enough of the repository to prove the HTTP contract.
 *
 * The transaction is the Firestore adapter's job and is covered against the
 * emulator, so this test needs no emulator to say what the endpoint answers.
 */
class InMemoryPracticeRepository implements PracticeRepository {
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

class RecordingAuditEventSink implements AuditEventSink {
  readonly events: AuditEvent[] = [];

  async record(event: AuditEvent): Promise<void> {
    this.events.push(event);
  }
}

const validHeaders = {
  authorization: 'Bearer known-id-token',
  'x-firebase-appcheck': 'known-app-check-token',
} as const;

describe('practice provisioning HTTP contract', () => {
  let app: FastifyInstance;
  let audit: RecordingAuditEventSink;

  before(async () => {
    audit = new RecordingAuditEventSink();
    app = await buildControlApi(testConfig(), {
      practiceRepository: new InMemoryPracticeRepository(),
      auditEventSink: audit,
    });
  });

  after(async () => {
    await app.close();
  });

  it('creates a practice and returns its routing projection', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/v1/practices',
      headers: {
        ...validHeaders,
        'idempotency-key': 'contract-create',
        'x-correlation-id': 'cor_practice_create',
      },
      payload: { displayName: 'Mokoena Media Tax' },
    });
    const body = response.json<PracticeResponse>();

    assert.equal(response.statusCode, 201);
    assert.deepEqual(Object.keys(body.data).sort(), [
      'accessStatus',
      'displayLabel',
      'homeRegionKey',
      'practiceId',
      'routeVersion',
    ]);
    assert.match(body.data.practiceId, /^prc_[a-f0-9]{32}$/);
    assert.equal(body.data.displayLabel, 'Mokoena Media Tax');
    assert.equal(body.data.homeRegionKey, 'za1');
    assert.equal(body.data.routeVersion, 1);
    assert.equal(body.data.accessStatus, 'active');
    assert.equal(body.meta.correlationId, 'cor_practice_create');
    assert.equal(audit.events.length, 1);
  });

  it('answers a replayed idempotency key with 200 and the original practice', async () => {
    const headers = {
      ...validHeaders,
      'idempotency-key': 'contract-replay',
    };
    const first = await app.inject({
      method: 'POST',
      url: '/v1/practices',
      headers,
      payload: { displayName: 'Mokoena Media Tax' },
    });
    const second = await app.inject({
      method: 'POST',
      url: '/v1/practices',
      headers,
      payload: { displayName: 'Mokoena Media Tax' },
    });

    assert.equal(first.statusCode, 201);
    assert.equal(second.statusCode, 200);
    assert.deepEqual(
      second.json<PracticeResponse>().data,
      first.json<PracticeResponse>().data,
    );
  });

  it('rejects a body with no display name', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/v1/practices',
      headers: { ...validHeaders, 'idempotency-key': 'contract-no-name' },
      payload: {},
    });

    assert.equal(response.statusCode, 400);
    assert.equal(response.json<ProblemResponse>().code, 'validation_error');
  });

  it('refuses an unknown body field rather than silently dropping it', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/v1/practices',
      headers: { ...validHeaders, 'idempotency-key': 'contract-region' },
      payload: { displayName: 'Mokoena Media Tax', region: 'eu1' },
    });
    const body = response.json<ProblemResponse>();

    assert.equal(response.statusCode, 400);
    assert.equal(body.code, 'validation_error');
    // The detail must not echo what the caller submitted.
    assert.equal(body.detail.includes('eu1'), false);
  });

  it('requires an idempotency key', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/v1/practices',
      headers: validHeaders,
      payload: { displayName: 'Mokoena Media Tax' },
    });

    assert.equal(response.statusCode, 400);
    assert.equal(response.json<ProblemResponse>().code, 'validation_error');
  });

  it('requires an identity token', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/v1/practices',
      headers: {
        'x-firebase-appcheck': 'known-app-check-token',
        'idempotency-key': 'contract-anonymous',
      },
      payload: { displayName: 'Mokoena Media Tax' },
    });

    assert.equal(response.statusCode, 401);
    assert.equal(
      response.json<ProblemResponse>().code,
      'authentication_required',
    );
  });

  it('rejects an identity token it cannot verify', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/v1/practices',
      headers: {
        ...validHeaders,
        authorization: 'Bearer not-the-known-token',
        'idempotency-key': 'contract-bad-token',
      },
      payload: { displayName: 'Mokoena Media Tax' },
    });

    assert.equal(response.statusCode, 401);
    assert.equal(response.json<ProblemResponse>().code, 'token_invalid');
  });

  it('keeps a missing App Check token as its own failure', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/v1/practices',
      headers: {
        authorization: 'Bearer known-id-token',
        'idempotency-key': 'contract-no-app-check',
      },
      payload: { displayName: 'Mokoena Media Tax' },
    });

    assert.equal(response.statusCode, 403);
    assert.equal(response.json<ProblemResponse>().code, 'app_check_required');
  });
});
