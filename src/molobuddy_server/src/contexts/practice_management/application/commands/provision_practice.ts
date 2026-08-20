import { createOpaqueId } from '../../../../platform/http/identifiers.js';
import type { VerifiedActor } from '../../../identity_access/index.js';
import { normalisePracticeName } from '../../domain/practice.js';
import type { PracticeRefRecord } from '../../domain/practice.js';
import type { AuditEventSink } from '../ports/audit_event_sink.js';
import type { FoundingOnboarding } from '../ports/practice_repository.js';
import type { PracticeRepository } from '../ports/practice_repository.js';

export type ProvisionPracticeInput = Readonly<{
  actor: VerifiedActor;
  displayName: unknown;
  idempotencyKey: string;
  correlationId: string;
  founding?: FoundingOnboarding;
}>;

export type ProvisionPracticeResult =
  | Readonly<{ ok: true; practiceRef: PracticeRefRecord; replayed: boolean }>
  | Readonly<{ ok: false; code: 'validation_error'; pointer: string }>;

export class ProvisionPractice {
  constructor(
    private readonly repository: PracticeRepository,
    private readonly audit: AuditEventSink,
    private readonly homeRegionKey: string,
  ) {}

  async execute(
    input: ProvisionPracticeInput,
  ): Promise<ProvisionPracticeResult> {
    const displayName = normalisePracticeName(input.displayName);
    if (displayName === undefined) {
      return { ok: false, code: 'validation_error', pointer: '/displayName' };
    }
    if (input.idempotencyKey.trim().length === 0) {
      return {
        ok: false,
        code: 'validation_error',
        pointer: '/headers/idempotency-key',
      };
    }

    const practiceId = createOpaqueId('prc');
    const outcome = await this.repository.provision({
      idempotencyKey: input.idempotencyKey.trim(),
      // exactOptionalPropertyTypes refuses an explicit undefined for an
      // optional property, so this is spread rather than assigned.
      ...(input.founding === undefined ? {} : { founding: input.founding }),
      practice: {
        practiceId,
        displayName,
        // Server-assigned. A client-supplied region is untrusted input and is
        // never read, even when the request carries one.
        homeRegionKey: this.homeRegionKey,
        routeVersion: 1,
        status: 'active',
        createdByUid: input.actor.uid,
      },
      member: {
        practiceId,
        uid: input.actor.uid,
        role: 'owner',
        status: 'active',
        // Identity comes from the verified token, never from the body.
        displayName: input.actor.displayName ?? input.actor.uid,
        emailLower: (input.actor.email ?? '').toLowerCase(),
      },
      practiceRef: {
        practiceId,
        displayLabel: displayName,
        homeRegionKey: this.homeRegionKey,
        routeVersion: 1,
        accessStatus: 'active',
      },
    });

    if (!outcome.replayed) {
      await this.audit.record({
        actorUid: input.actor.uid,
        practiceId: outcome.practiceRef.practiceId,
        action: 'practice.provisioned',
        correlationId: input.correlationId,
        resultingState: { role: 'owner', status: 'active' },
      });
    }

    return {
      ok: true,
      practiceRef: outcome.practiceRef,
      replayed: outcome.replayed,
    };
  }
}
