import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import { SaveOnboardingAnswers } from '../../src/contexts/practice_management/application/commands/save_onboarding_answers.js';
import { GetOnboarding } from '../../src/contexts/practice_management/application/queries/get_onboarding.js';
import type {
  OnboardingRepository,
  SaveAnswersOutcome,
  StoredOnboarding,
} from '../../src/contexts/practice_management/application/ports/onboarding_repository.js';
import type { OnboardingAnswers } from '../../src/contexts/practice_management/domain/onboarding.js';

class InMemoryOnboarding implements OnboardingRepository {
  constructor(private stored?: StoredOnboarding) {}

  lastPatch: OnboardingAnswers | undefined;
  lastExpectedVersion: string | undefined;
  outcome: SaveAnswersOutcome | undefined;

  async find(): Promise<StoredOnboarding | undefined> {
    return this.stored;
  }

  async save(
    _uid: string,
    patch: OnboardingAnswers,
    expectedVersion: string | undefined,
  ): Promise<SaveAnswersOutcome> {
    this.lastPatch = patch;
    this.lastExpectedVersion = expectedVersion;
    const forced = this.outcome;
    if (forced !== undefined) {
      return forced;
    }
    const stored: StoredOnboarding = {
      status: 'in_progress',
      answers: patch,
      version: 'v-next',
    };
    this.stored = stored;
    return { ok: true, stored };
  }
}

describe('get onboarding', () => {
  it('describes a user who has never answered as starting at the beginning', async () => {
    const view = await new GetOnboarding(new InMemoryOnboarding()).execute(
      'user_1',
    );

    assert.deepEqual(view, {
      status: 'in_progress',
      nextStep: 'practice',
      answers: {},
    });
  });

  it('returns the answers and the version the client needs for If-Match', async () => {
    const store = new InMemoryOnboarding({
      status: 'in_progress',
      answers: { practiceName: 'Mokoena Media Tax', practiceSize: 'solo' },
      version: 'v-1',
    });

    const view = await new GetOnboarding(store).execute('user_1');

    assert.equal(view.status, 'in_progress');
    assert.equal(view.nextStep, 'priorities');
    assert.equal(view.version, 'v-1');
  });

  it('reports a finished onboarding with no next step', async () => {
    const store = new InMemoryOnboarding({
      status: 'complete',
      answers: {},
      completedPracticeId: 'prc_1',
      version: 'v-1',
    });

    const view = await new GetOnboarding(store).execute('user_1');

    assert.equal(view.status, 'complete');
    assert.equal('nextStep' in view, false);
  });
});

describe('save onboarding answers', () => {
  it('validates before it writes', async () => {
    const store = new InMemoryOnboarding();

    const result = await new SaveOnboardingAnswers(store).execute({
      uid: 'user_1',
      answers: { practiceSize: 'enormous' },
      expectedVersion: undefined,
    });

    assert.deepEqual(result, {
      ok: false,
      code: 'validation_error',
      pointer: '/answers/practiceSize',
    });
    assert.equal(store.lastPatch, undefined);
  });

  it('passes the caller version through as If-Match', async () => {
    const store = new InMemoryOnboarding();

    await new SaveOnboardingAnswers(store).execute({
      uid: 'user_1',
      answers: { practiceSize: 'solo' },
      expectedVersion: 'v-1',
    });

    assert.equal(store.lastExpectedVersion, 'v-1');
  });

  it('returns the new state with its derived next step', async () => {
    const store = new InMemoryOnboarding();

    const result = await new SaveOnboardingAnswers(store).execute({
      uid: 'user_1',
      answers: { practiceName: 'Mokoena Media Tax', practiceSize: 'solo' },
      expectedVersion: undefined,
    });

    assert.equal(result.ok, true);
    assert.equal(result.view.nextStep, 'priorities');
    assert.equal(result.view.version, 'v-next');
  });

  it('maps each refusal to the problem the API contract names', async () => {
    for (const [reason, code] of [
      ['version_mismatch', 'version_mismatch'],
      ['version_required', 'version_required'],
      ['already_complete', 'onboarding_already_complete'],
    ] as const) {
      const store = new InMemoryOnboarding();
      store.outcome = { ok: false, reason };

      const result = await new SaveOnboardingAnswers(store).execute({
        uid: 'user_1',
        answers: { practiceSize: 'solo' },
        expectedVersion: 'v-1',
      });

      assert.equal(result.ok, false);
      assert.equal(result.code, code);
    }
  });
});
