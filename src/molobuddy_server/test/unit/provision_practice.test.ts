import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import { ProvisionPractice } from '../../src/contexts/practice_management/application/commands/provision_practice.js';
import type {
  PracticeRepository,
  ProvisionPracticeOutcome,
  ProvisionPracticeWrite,
} from '../../src/contexts/practice_management/application/ports/practice_repository.js';
import type {
  AuditEvent,
  AuditEventSink,
} from '../../src/contexts/practice_management/application/ports/audit_event_sink.js';
import type { VerifiedActor } from '../../src/contexts/identity_access/index.js';

const actor: VerifiedActor = {
  uid: 'user_1',
  firebaseProjectId: 'molobuddy-development',
  appId: 'app_1',
  providerIds: ['password'],
  emailVerified: false,
  displayName: 'Thando Mokoena',
  email: 'Thando@Example.com',
};

class RecordingRepository implements PracticeRepository {
  writes: ProvisionPracticeWrite[] = [];
  replayed = false;

  async provision(
    write: ProvisionPracticeWrite,
  ): Promise<ProvisionPracticeOutcome> {
    this.writes.push(write);
    return { practiceRef: write.practiceRef, replayed: this.replayed };
  }
}

class RecordingAudit implements AuditEventSink {
  events: AuditEvent[] = [];
  async record(event: AuditEvent): Promise<void> {
    this.events.push(event);
  }
}

function build(repository: PracticeRepository, audit: AuditEventSink) {
  return new ProvisionPractice(repository, audit, 'za1');
}

/** The one element the caller expects, proved rather than asserted away. */
function only<T>(items: readonly T[]): T {
  assert.equal(items.length, 1);
  const [first] = items;
  assert.ok(first !== undefined);
  return first;
}

describe('provision practice', () => {
  it('makes the caller the active owner of a new practice', async () => {
    const repository = new RecordingRepository();
    const audit = new RecordingAudit();

    const result = await build(repository, audit).execute({
      actor,
      displayName: 'Mokoena Media Tax',
      idempotencyKey: 'key-1',
      correlationId: 'cor_1',
    });

    assert.equal(result.ok, true);
    const write = only(repository.writes);
    assert.match(write.practice.practiceId, /^prc_/);
    assert.equal(write.practice.displayName, 'Mokoena Media Tax');
    assert.equal(write.practice.status, 'active');
    assert.equal(write.practice.createdByUid, 'user_1');
    assert.equal(write.member.role, 'owner');
    assert.equal(write.member.status, 'active');
    assert.equal(write.practiceRef.accessStatus, 'active');
    assert.equal(write.practiceRef.displayLabel, 'Mokoena Media Tax');
  });

  it('assigns the server region and ignores anything the client sent', async () => {
    const repository = new RecordingRepository();
    const result = await build(repository, new RecordingAudit()).execute({
      actor,
      displayName: 'Mokoena Media Tax',
      idempotencyKey: 'key-1',
      correlationId: 'cor_1',
    });

    assert.equal(result.ok, true);
    const write = only(repository.writes);
    assert.equal(write.practice.homeRegionKey, 'za1');
    assert.equal(write.practiceRef.homeRegionKey, 'za1');
    assert.equal(write.practice.routeVersion, 1);
  });

  it('stores the email lowercased and takes identity from the token, not the body', async () => {
    const repository = new RecordingRepository();
    await build(repository, new RecordingAudit()).execute({
      actor,
      displayName: 'Mokoena Media Tax',
      idempotencyKey: 'key-1',
      correlationId: 'cor_1',
    });

    const write = only(repository.writes);
    assert.equal(write.member.emailLower, 'thando@example.com');
    assert.equal(write.member.displayName, 'Thando Mokoena');
  });

  it('rejects an unusable name without writing anything', async () => {
    const repository = new RecordingRepository();
    const result = await build(repository, new RecordingAudit()).execute({
      actor,
      displayName: '   ',
      idempotencyKey: 'key-1',
      correlationId: 'cor_1',
    });

    assert.deepEqual(result, {
      ok: false,
      code: 'validation_error',
      pointer: '/displayName',
    });
    assert.equal(repository.writes.length, 0);
  });

  it('rejects a missing idempotency key without writing anything', async () => {
    const repository = new RecordingRepository();
    const result = await build(repository, new RecordingAudit()).execute({
      actor,
      displayName: 'Mokoena Media Tax',
      idempotencyKey: '',
      correlationId: 'cor_1',
    });

    assert.equal(result.ok, false);
    assert.equal(repository.writes.length, 0);
  });

  it('records one audit event carrying no token', async () => {
    const audit = new RecordingAudit();
    await build(new RecordingRepository(), audit).execute({
      actor,
      displayName: 'Mokoena Media Tax',
      idempotencyKey: 'key-1',
      correlationId: 'cor_1',
    });

    const event = only(audit.events);
    assert.equal(event.action, 'practice.provisioned');
    assert.equal(event.actorUid, 'user_1');
    assert.equal(JSON.stringify(event).includes('token'), false);
  });

  it('does not record a second audit event for a replay', async () => {
    const repository = new RecordingRepository();
    repository.replayed = true;
    const audit = new RecordingAudit();

    const result = await build(repository, audit).execute({
      actor,
      displayName: 'Mokoena Media Tax',
      idempotencyKey: 'key-1',
      correlationId: 'cor_1',
    });

    assert.equal(result.ok, true);
    assert.equal(audit.events.length, 0);
  });
});
