import { parseAnswerPatch, resumeStepFor } from '../../domain/onboarding.js';
import type { OnboardingRepository } from '../ports/onboarding_repository.js';
import type { OnboardingView } from '../queries/get_onboarding.js';

export type SaveOnboardingInput = Readonly<{
  uid: string;
  answers: unknown;
  expectedVersion: string | undefined;
}>;

export type SaveOnboardingResult =
  | Readonly<{ ok: true; view: OnboardingView }>
  | Readonly<{ ok: false; code: 'validation_error'; pointer: string }>
  | Readonly<{
      ok: false;
      code:
        'version_mismatch' | 'version_required' | 'onboarding_already_complete';
    }>;

export class SaveOnboardingAnswers {
  constructor(private readonly repository: OnboardingRepository) {}

  async execute(input: SaveOnboardingInput): Promise<SaveOnboardingResult> {
    const parsed = parseAnswerPatch(input.answers);
    if (!parsed.ok) {
      return { ok: false, code: 'validation_error', pointer: parsed.pointer };
    }

    const outcome = await this.repository.save(
      input.uid,
      parsed.answers,
      input.expectedVersion,
    );
    if (!outcome.ok) {
      return {
        ok: false,
        code:
          outcome.reason === 'already_complete'
            ? 'onboarding_already_complete'
            : outcome.reason,
      };
    }

    return {
      ok: true,
      view: {
        status: 'in_progress',
        nextStep: resumeStepFor(outcome.stored.answers),
        answers: outcome.stored.answers,
        version: outcome.stored.version,
      },
    };
  }
}
