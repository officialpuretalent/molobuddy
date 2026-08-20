import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import { normalisePracticeName } from '../../src/contexts/practice_management/domain/practice.js';

describe('practice name', () => {
  it('trims surrounding whitespace', () => {
    assert.equal(
      normalisePracticeName('  Mokoena Media Tax  '),
      'Mokoena Media Tax',
    );
  });

  it('rejects an empty or whitespace-only name', () => {
    assert.equal(normalisePracticeName(''), undefined);
    assert.equal(normalisePracticeName('   '), undefined);
  });

  it('rejects a name longer than 120 characters', () => {
    assert.equal(normalisePracticeName('a'.repeat(121)), undefined);
    assert.equal(normalisePracticeName('a'.repeat(120))?.length, 120);
  });

  it('rejects a non-string', () => {
    assert.equal(normalisePracticeName(undefined), undefined);
    assert.equal(normalisePracticeName(42), undefined);
  });
});
