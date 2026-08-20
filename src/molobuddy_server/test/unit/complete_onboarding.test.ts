import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import { CompleteOnboarding } from '../../src/contexts/practice_management/application/commands/complete_onboarding.js';
import { ProvisionPractice } from '../../src/contexts/practice_management/application/commands/provision_practice.js';
import type {
  AuditEvent,
  AuditEventSink,
} from '../../src/contexts/practice_management/application/ports/audit_event_sink.js';
import type {
  OnboardingRepository,
  StoredOnboarding,
} from '../../src/contexts/practice_management/application/ports/onboarding_repository.js';
import type {
  PracticeRepository,
  ProvisionPracticeOutcome,
  ProvisionPracticeWrite,
} from '../../src/contexts/practice_management/application/ports/practice_repository.js';
import type { OnboardingAnswers } from '../../src/contexts/practice_management/domain/onboarding.js';
import type { VerifiedActor } from '../../src/contexts/identity_access/index.js';

const actor: VerifiedActor = {
  uid: 'user_1',
  firebaseProjectId: 'molobuddy-development',
  appId: 'app_1',
  providerIds: ['password'],
  emailVerified: false,
  displayName: 'Thando Mokoena',
  email: 'thando@example.com',
};

const answers: OnboardingAnswers = {
  practiceName: 'Mokoena Media Tax',
  practiceSize: 'solo',
  priorities: ['deadlines'],
  startingPoint: 'add_first_client',
};

const inProgress: StoredOnboarding = {
  status: 'in_progress',
  answers,
  version: 'v-1',
};

class StubOnboarding implements OnboardingRepository {
  constructor(private readonly stored?: StoredOnboarding) {}
  async find(): Promise<StoredOnboarding | undefined> {
    return this.stored;
  }
  async save(): Promise<never> {
    throw new Error('save must not be called during completion');
  }
}

class RecordingRepository implements PracticeRepository {
  writes: ProvisionPracticeWrite[] = [];
  async provision(
    write: ProvisionPracticeWrite,
  ): Promise<ProvisionPracticeOutcome> {
    this.writes.push(write);
    return { practiceRef: write.practiceRef, replayed: false };
  }
}

class RecordingAudit implements AuditEventSink {
  events: AuditEvent[] = [];
  async record(event: AuditEvent): Promise<void> {
    this.events.push(event);
  }
}

function only<T>(items: readonly T[]): T {
  assert.equal(items.length, 1);
  const [first] = items;
  assert.ok(first !== undefined);
  return first;
}

function build(
  stored: StoredOnboarding | undefined,
  repository: PracticeRepository,
  audit: AuditEventSink = new RecordingAudit(),
) {
  return new CompleteOnboarding(
    new StubOnboarding(stored),
    new ProvisionPractice(repository, audit, 'za1'),
  );
}

describe('complete onboarding', () => {
  it('founds the practice the user named', async () => {
    const repository = new RecordingRepository();

    const result = await build(inProgress, repository).execute({
      actor,
      idempotencyKey: 'key-1',
      correlationId: 'cor_1',
    });

    assert.equal(result.ok, true);
    const write = only(repository.writes);
    assert.equal(write.practice.displayName, 'Mokoena Media Tax');
    assert.equal(write.practiceRef.displayLabel, 'Mokoena Media Tax');
  });

  it('carries the answers through so they commit with the practice', async () => {
    const repository = new RecordingRepository();

    await build(inProgress, repository).execute({
      actor,
      idempotencyKey: 'key-1',
      correlationId: 'cor_1',
    });

    const founding = only(repository.writes).founding;
    assert.ok(founding !== undefined);
    assert.equal(founding.uid, 'user_1');
    assert.deepEqual(founding.answers, answers);
  });

  it('refuses to complete with an answer missing, and writes nothing', async () => {
    const repository = new RecordingRepository();
    const partial: OnboardingAnswers = {
      practiceName: 'Mokoena Media Tax',
      practiceSize: 'solo',
      priorities: ['deadlines'],
    };

    const result = await build(
      { status: 'in_progress', answers: partial, version: 'v-1' },
      repository,
    ).execute({ actor, idempotencyKey: 'key-1', correlationId: 'cor_1' });

    assert.deepEqual(result, {
      ok: false,
      code: 'onboarding_incomplete',
      missing: ['/answers/startingPoint'],
    });
    assert.equal(repository.writes.length, 0);
  });

  it('refuses a user who has answered nothing at all', async () => {
    const repository = new RecordingRepository();

    const result = await build(undefined, repository).execute({
      actor,
      idempotencyKey: 'key-1',
      correlationId: 'cor_1',
    });

    assert.equal(result.ok, false);
    assert.equal(result.code, 'onboarding_incomplete');
    assert.equal(repository.writes.length, 0);
  });

  it('requires an idempotency key', async () => {
    const repository = new RecordingRepository();

    const result = await build(inProgress, repository).execute({
      actor,
      idempotencyKey: '   ',
      correlationId: 'cor_1',
    });

    assert.equal(result.ok, false);
    assert.equal(result.code, 'validation_error');
    assert.equal(repository.writes.length, 0);
  });

  it('records one audit event', async () => {
    const audit = new RecordingAudit();

    await build(inProgress, new RecordingRepository(), audit).execute({
      actor,
      idempotencyKey: 'key-1',
      correlationId: 'cor_1',
    });

    assert.equal(only(audit.events).action, 'practice.provisioned');
  });
});
