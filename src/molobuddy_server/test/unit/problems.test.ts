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
