import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import {
  mergeAnswers,
  missingAnswerPointers,
  parseAnswerPatch,
  resumeStepFor,
  type OnboardingAnswers,
} from '../../src/contexts/practice_management/domain/onboarding.js';

const complete: OnboardingAnswers = {
  practiceName: 'Mokoena Media Tax',
  practiceSize: 'solo',
  priorities: ['deadlines'],
  startingPoint: 'add_first_client',
};

describe('resume step', () => {
  it('starts at the practice step when nothing is answered', () => {
    assert.equal(resumeStepFor({}), 'practice');
  });

  it('stays on the practice step until both of its answers are given', () => {
    assert.equal(resumeStepFor({ practiceName: 'A Practice' }), 'practice');
    assert.equal(resumeStepFor({ practiceSize: 'solo' }), 'practice');
  });

  it('moves to priorities once the practice step is answered', () => {
    assert.equal(
      resumeStepFor({ practiceName: 'A Practice', practiceSize: 'solo' }),
      'priorities',
    );
  });

  it('treats an empty priority list as unanswered', () => {
    assert.equal(resumeStepFor({ ...complete, priorities: [] }), 'priorities');
  });

  it('moves to the starting point once priorities are chosen', () => {
    // Built explicitly rather than destructured: this project's eslint has no
    // varsIgnorePattern, so the discarded sibling counts as an unused variable.
    const withoutStartingPoint: OnboardingAnswers = {
      practiceName: 'Mokoena Media Tax',
      practiceSize: 'solo',
      priorities: ['deadlines'],
    };
    assert.equal(resumeStepFor(withoutStartingPoint), 'starting_point');
  });

  it('is ready to complete when every answer is present', () => {
    assert.equal(resumeStepFor(complete), 'ready_to_complete');
  });
});

describe('completion invariant', () => {
  it('names every missing answer as a pointer', () => {
    assert.deepEqual(missingAnswerPointers({}), [
      '/answers/practiceName',
      '/answers/practiceSize',
      '/answers/priorities',
      '/answers/startingPoint',
    ]);
  });

  it('is satisfied only when nothing is missing', () => {
    assert.deepEqual(missingAnswerPointers(complete), []);
  });

  it('counts an empty priority list as missing', () => {
    assert.deepEqual(missingAnswerPointers({ ...complete, priorities: [] }), [
      '/answers/priorities',
    ]);
  });
});

describe('answer patch', () => {
  it('accepts a partial patch and trims the practice name', () => {
    const result = parseAnswerPatch({ practiceName: '  Mokoena Media Tax  ' });

    assert.equal(result.ok, true);
    assert.deepEqual(result.answers, { practiceName: 'Mokoena Media Tax' });
  });

  it('refuses an unknown field rather than dropping it', () => {
    assert.deepEqual(parseAnswerPatch({ region: 'eu1' }), {
      ok: false,
      pointer: '/answers/region',
    });
  });

  it('refuses a value outside its enumeration', () => {
    assert.deepEqual(parseAnswerPatch({ practiceSize: 'enormous' }), {
      ok: false,
      pointer: '/answers/practiceSize',
    });
    assert.deepEqual(parseAnswerPatch({ startingPoint: 'guess' }), {
      ok: false,
      pointer: '/answers/startingPoint',
    });
    assert.deepEqual(parseAnswerPatch({ priorities: ['golf'] }), {
      ok: false,
      pointer: '/answers/priorities',
    });
  });

  it('refuses an empty or duplicated priority list', () => {
    assert.equal(parseAnswerPatch({ priorities: [] }).ok, false);
    assert.equal(
      parseAnswerPatch({ priorities: ['deadlines', 'deadlines'] }).ok,
      false,
    );
  });

  it('refuses a practice name that is blank or too long', () => {
    assert.equal(parseAnswerPatch({ practiceName: '   ' }).ok, false);
    assert.equal(parseAnswerPatch({ practiceName: 'a'.repeat(121) }).ok, false);
  });

  it('refuses anything that is not an object of answers', () => {
    assert.deepEqual(parseAnswerPatch([]), { ok: false, pointer: '/answers' });
    assert.deepEqual(parseAnswerPatch(null), {
      ok: false,
      pointer: '/answers',
    });
  });

  it('accepts an empty patch, which changes nothing', () => {
    const result = parseAnswerPatch({});

    assert.equal(result.ok, true);
    assert.deepEqual(result.answers, {});
  });
});

describe('merge', () => {
  it('overwrites only what the patch carries', () => {
    const merged = mergeAnswers(complete, { practiceName: 'Renamed' });

    assert.equal(merged.practiceName, 'Renamed');
    assert.equal(merged.practiceSize, 'solo');
    assert.deepEqual(merged.priorities, ['deadlines']);
  });

  it('lets a user change an answer they already gave', () => {
    // The wizard has a back button, so a changed mind must not need a
    // different code path from a first answer.
    const merged = mergeAnswers(complete, { priorities: ['documents'] });

    assert.deepEqual(merged.priorities, ['documents']);
  });
});
