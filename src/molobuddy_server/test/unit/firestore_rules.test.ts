import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { describe, it } from 'node:test';

// Five levels up from dist/test/unit reaches the repository root, where
// Firestore configuration lives beside firebase.json.
const rulesUrl = new URL('../../../../../firestore.rules', import.meta.url);

describe('firestore rules', () => {
  it('denies every client read and write', () => {
    const rules = readFileSync(rulesUrl, 'utf8');

    assert.match(rules, /allow read, write: if false;/);
    assert.doesNotMatch(rules, /if true/);
    assert.doesNotMatch(
      rules,
      /allow (read|write|create|update|delete):\s*if request/,
    );
  });
});
