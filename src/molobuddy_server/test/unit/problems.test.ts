import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import { problemForCode } from '../../src/platform/http/problems.js';
import {
  createOpaqueId,
  createResourceVersion,
} from '../../src/platform/http/identifiers.js';

describe('platform problem catalogue', () => {
  it('describes a validation error as a 400 the caller can act on', () => {
    const problem = problemForCode('validation_error');

    assert.equal(problem.status, 400);
    assert.equal(problem.code, 'validation_error');
    assert.ok(problem.title.length > 0);
    assert.ok(problem.detail.length > 0);
  });
});

describe('opaque identifiers', () => {
  it('mints a practice identifier that never embeds a name', () => {
    const id = createOpaqueId('prc');

    assert.match(id, /^prc_[a-f0-9]{32}$/);
  });
});

describe('resource version', () => {
  it('mints a different token every time', () => {
    const tokens = new Set(
      Array.from({ length: 100 }, () => createResourceVersion()),
    );

    assert.equal(tokens.size, 100);
  });

  it('is an opaque token safe to place in an ETag', () => {
    assert.match(createResourceVersion(), /^[a-f0-9]{32}$/);
  });
});

describe('concurrency and onboarding problems', () => {
  it('maps each new code to the status the API design names', () => {
    assert.equal(problemForCode('version_mismatch').status, 412);
    assert.equal(problemForCode('version_required').status, 428);
    assert.equal(problemForCode('onboarding_incomplete').status, 409);
    assert.equal(problemForCode('onboarding_already_complete').status, 409);
  });

  it('gives every code a title and a detail that says what to do', () => {
    for (const code of [
      'version_mismatch',
      'version_required',
      'onboarding_incomplete',
      'onboarding_already_complete',
    ] as const) {
      const problem = problemForCode(code);
      assert.ok(problem.title.length > 0, `${code} has no title`);
      assert.ok(problem.detail.length > 0, `${code} has no detail`);
    }
  });
});
