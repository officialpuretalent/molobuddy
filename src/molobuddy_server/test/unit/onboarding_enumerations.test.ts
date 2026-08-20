import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import {
  onboardingPriorities,
  practiceSizes,
  startingPoints,
} from '../../src/contexts/practice_management/domain/onboarding.js';
import { onboardingPatchBodySchema } from '../../src/platform/http/schemas.js';

const answers = onboardingPatchBodySchema.properties.answers.properties;

describe('onboarding enumerations', () => {
  it('keeps the request schema and the domain in agreement', () => {
    // The schema is a convenience that rejects the obvious cases early; the
    // domain is the contract. Two lists that disagree means one refuses an
    // answer the other accepts.
    assert.deepEqual([...answers.practiceSize.enum], [...practiceSizes]);
    assert.deepEqual(
      [...answers.priorities.items.enum],
      [...onboardingPriorities],
    );
    assert.deepEqual([...answers.startingPoint.enum], [...startingPoints]);
  });
});
