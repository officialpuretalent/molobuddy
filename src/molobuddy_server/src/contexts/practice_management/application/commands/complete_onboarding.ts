import type { VerifiedActor } from '../../../identity_access/index.js';
import { missingAnswerPointers } from '../../domain/onboarding.js';
import type { PracticeRefRecord } from '../../domain/practice.js';
import type { OnboardingRepository } from '../ports/onboarding_repository.js';
import type { ProvisionPractice } from './provision_practice.js';

export type CompleteOnboardingInput = Readonly<{
  actor: VerifiedActor;
  idempotencyKey: string;
  correlationId: string;
}>;

export type CompleteOnboardingResult =
  | Readonly<{ ok: true; practiceRef: PracticeRefRecord; replayed: boolean }>
  | Readonly<{ ok: false; code: 'validation_error'; pointer: string }>
  | Readonly<{
      ok: false;
      code: 'onboarding_incomplete';
      missing: readonly string[];
    }>;

export class CompleteOnboarding {
  constructor(
    private readonly onboarding: OnboardingRepository,
    private readonly provision: ProvisionPractice,
  ) {}

  async execute(
    input: CompleteOnboardingInput,
  ): Promise<CompleteOnboardingResult> {
    if (input.idempotencyKey.trim().length === 0) {
      return {
        ok: false,
        code: 'validation_error',
        pointer: '/headers/idempotency-key',
      };
    }

    const stored = await this.onboarding.find(input.actor.uid);
    const answers = stored?.answers ?? {};
    const missing = missingAnswerPointers(answers);
    if (missing.length > 0) {
      // The invariant, enforced here rather than by policing transitions: a
      // client cannot mark itself finished without having answered.
      return { ok: false, code: 'onboarding_incomplete', missing };
    }

    const result = await this.provision.execute({
      actor: input.actor,
      displayName: answers.practiceName,
      idempotencyKey: input.idempotencyKey,
      correlationId: input.correlationId,
      founding: { uid: input.actor.uid, answers },
    });

    if (!result.ok) {
      // The answers were validated on the way in with the same rule the
      // practice uses, so reaching here means those two rules have drifted
      // apart. That is a defect, not a caller mistake.
      return { ok: false, code: 'validation_error', pointer: result.pointer };
    }

    return {
      ok: true,
      practiceRef: result.practiceRef,
      replayed: result.replayed,
    };
  }
}
