# Founding Onboarding — Server Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist a resumable onboarding record per user, report whether onboarding is outstanding from `GET /v1/session`, and found the practice from stored answers in one transaction.

**Architecture:** The record and its three endpoints live in `practice_management`, because their purpose is founding a practice and completion runs that context's existing `ProvisionPractice` command. Completion adds two documents to the transaction that command already runs, so there stays exactly one code path that can bring a practice into existence. `identity_access` learns only whether a user is finished, through a port in its own context.

**Tech Stack:** Node.js 24, TypeScript, Fastify 5, firebase-admin 14.2.0, `node --test`, Firestore emulator via the Firebase CLI.

**Spec:** [`docs/plans/2026-08-20-founding-onboarding-design.md`](2026-08-20-founding-onboarding-design.md). This plan implements its sections 3, 5, 6 and 7. Sections 4.1 and 8 are the client slice and are a separate plan.

## Global Constraints

- Domain and application code import no Fastify, Firebase or Google Cloud type. `test/unit/vendor_containment.test.ts` enforces this; run it after every task.
- A context's `index.ts` is its only import surface for another context, and must not re-export aggregates, repositories or provider types.
- **`identity_access` must not import `practice_management`.** `practice_management` already imports `VerifiedActor` from `identity_access`, so the reverse direction is a cycle. Task 8 exists in the shape it does because of this.
- Client-supplied region, role, capability, acting-user and answer values are untrusted. Every enumeration is validated server-side.
- Raw ID tokens and App Check tokens never enter logs, audit events, error details or responses.
- Error details never echo a submitted value and never name a resource the caller may not know exists.
- `version` is regenerated on every write. A constant would make every `If-Match` comparison succeed and silently remove the protection.
- This codebase's eslint **forbids non-null assertions**, in test files too. Prove array and map access with a helper that asserts, or narrow with `assert.ok(x !== undefined)`.
- `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes` and `noPropertyAccessFromIndexSignature` are on. Build optional properties with conditional spread, and read index signatures with `data['field']`.
- Verification gates, all green before each commit: `npm run check` in `src/molobuddy_server`. Tasks touching Firestore also run `npm run test:firestore`.
- `npm run check` must reach no network and need no Google credentials. Anything touching real Firestore is an emulator test or a manual check.

---

## Deviations from the spec, decided here

Both are corrected in the spec by Task 9. They are listed up front so no task is surprised by them.

**1. The session reports `status` only. `nextStep` is gone.**

Spec section 5 puts `nextStep` on the session. Computing it requires `resumeStepFor`, which is `practice_management` domain logic, and `identity_access` owns the session — so the session would either import a context that already imports it, which is a cycle, or duplicate the derivation and drift from it.

Neither is necessary. A client that needs the step is the wizard, and the wizard fetches `GET /v1/onboarding` when it opens regardless. The session's job is the gate: one boolean question, one field. The extra round trip falls only on users mid-onboarding, only once.

**2. The already-complete branch of `:complete` reads the projection rather than storing it.**

Spec section 6.3 says an already-complete onboarding answers with the practice named by `completedPracticeId`. That requires a second read to turn an id into a projection. Storing the whole projection on the onboarding record would avoid the read but duplicates data `practiceRefs` already owns. The read is cheap and sits in a transaction that is already reading, so the record stays legible. No spec change needed for this one, only a note that the read exists.

---

## File Structure

| File | Responsibility |
|---|---|
| `src/platform/http/problems.ts` (modify) | Four new codes; `errors[]` pointers on a problem |
| `src/platform/http/schemas.ts` (modify) | Onboarding request and response schemas; new problem statuses |
| `src/contexts/practice_management/domain/onboarding.ts` (create) | Answers, enumerations, resume derivation, the completion invariant |
| `src/contexts/practice_management/application/ports/onboarding_repository.ts` (create) | Read and concurrency-checked upsert |
| `src/contexts/practice_management/application/queries/get_onboarding.ts` (create) | Read the record for the wizard |
| `src/contexts/practice_management/application/commands/save_onboarding_answers.ts` (create) | Validate and merge one step's answers |
| `src/contexts/practice_management/application/commands/complete_onboarding.ts` (create) | Found the practice from stored answers |
| `src/contexts/practice_management/application/ports/practice_repository.ts` (modify) | `founding` on the write |
| `src/contexts/practice_management/adapters/outbound/persistence/firestore_onboarding_repository.ts` (create) | The record, with `If-Match` |
| `src/contexts/practice_management/adapters/outbound/persistence/firestore_practice_repository.ts` (modify) | Two more documents in the same transaction |
| `src/contexts/practice_management/adapters/inbound/http/onboarding_routes.ts` (create) | The three endpoints |
| `src/contexts/practice_management/index.ts` (modify) | Import surface |
| `src/contexts/identity_access/application/ports/onboarding_status_reader.ts` (create) | The gate, as one boolean |
| `src/contexts/identity_access/adapters/outbound/persistence/firestore_onboarding_status_reader.ts` (create) | Its adapter |
| `src/contexts/identity_access/application/queries/get_session.ts` (modify) | Carry the gate |
| `src/bootstrap/container.ts` (modify) | Wire it all |
| `src/bootstrap/build_control_api.ts` (modify) | Register the routes |

---

### Task 1: Problem codes and pointer details

Four codes the API design names and nothing has ever implemented, plus the `errors[]` array the problem schema already allows and `sendProblem` has never been able to send.

**Files:**
- Modify: `src/molobuddy_server/src/platform/http/problems.ts`
- Modify: `src/molobuddy_server/src/platform/http/schemas.ts`
- Test: `src/molobuddy_server/test/unit/problems.test.ts`

**Interfaces:**
- Produces: `ProblemCode` gains `onboarding_incomplete`, `onboarding_already_complete`, `version_mismatch`, `version_required`. `sendProblem` gains a fourth parameter `errors: readonly ProblemPointer[]`. `problemResponses` gains 409, 412 and 428.

- [x] **Step 1: Write the failing test**

Add to `test/unit/problems.test.ts`:

```ts
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
```

- [x] **Step 2: Run the test and watch it fail**

```bash
cd src/molobuddy_server && npm run test:unit
```

Expected: FAIL. `'version_mismatch'` is not assignable to `ProblemCode`.

- [x] **Step 3: Add the codes**

In `src/platform/http/problems.ts`, extend the union after `resource_not_found`:

```ts
  | 'resource_not_found'
  | 'onboarding_incomplete'
  | 'onboarding_already_complete'
  | 'version_mismatch'
  | 'version_required'
```

and add these entries to the `problems` record, after `resource_not_found`:

```ts
  onboarding_incomplete: {
    status: 409,
    code: 'onboarding_incomplete',
    title: 'Setup is not finished.',
    detail: 'Answer the remaining questions and try again.',
  },
  onboarding_already_complete: {
    status: 409,
    code: 'onboarding_already_complete',
    title: 'Setup is already finished.',
    detail: 'This account has already been set up.',
  },
  version_mismatch: {
    status: 412,
    code: 'version_mismatch',
    title: 'Someone changed this first.',
    detail: 'Reload to get the current version, then try again.',
  },
  version_required: {
    status: 428,
    code: 'version_required',
    title: 'The current version is required.',
    detail: 'Send the current version with this request and try again.',
  },
```

- [x] **Step 4: Let a problem carry pointers**

Still in `problems.ts`, add the type and widen `sendProblem`:

```ts
/**
 * One field-level reason a request was refused.
 *
 * `pointer` is a JSON pointer at the offending field. It names the field and
 * never the value, so nothing the caller submitted is echoed back.
 */
export type ProblemPointer = Readonly<{
  pointer: string;
  code: string;
  message: string;
}>;
```

```ts
export function sendProblem(
  reply: FastifyReply,
  request: FastifyRequest,
  code: ProblemCode,
  errors: readonly ProblemPointer[] = [],
): FastifyReply {
```

and inside the sent object, after `correlationId`:

```ts
      ...(errors.length === 0 ? {} : { errors }),
```

- [x] **Step 5: Let the new statuses through the response schemas**

In `src/platform/http/schemas.ts`, add to `problemResponses`:

```ts
  409: problemSchema,
  412: problemSchema,
  428: problemSchema,
```

A status with no schema is serialised unvalidated, which would defeat the allowlist the contract test in `auth_contract.test.ts` relies on.

- [x] **Step 6: Run the tests and watch them pass**

```bash
npm run test:unit
```

Expected: PASS, 2 new tests.

- [x] **Step 7: Commit**

```bash
npm run check
git add src/molobuddy_server/src/platform/http src/molobuddy_server/test/unit/problems.test.ts
git commit -m "feat: add concurrency and onboarding problem codes with field pointers"
```

---

### Task 2: The onboarding domain

Answers, their enumerations, the resume derivation and the completion invariant. Pure functions, no persistence. This is where the spec's "answers, not a step" decision is actually enforced.

**Files:**
- Create: `src/molobuddy_server/src/contexts/practice_management/domain/onboarding.ts`
- Test: `src/molobuddy_server/test/unit/onboarding_domain.test.ts`

**Interfaces:**
- Consumes: `normalisePracticeName` from `./practice.js`.
- Produces: `OnboardingAnswers`, `OnboardingStep`, `PracticeSize`, `OnboardingPriority`, `StartingPoint`, `practiceSizes`, `onboardingPriorities`, `startingPoints`, `resumeStepFor(answers)`, `missingAnswerPointers(answers)`, `parseAnswerPatch(value)`, `mergeAnswers(stored, patch)`.

- [x] **Step 1: Write the failing test**

Create `test/unit/onboarding_domain.test.ts`:

```ts
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
    const { startingPoint: _omitted, ...withoutStartingPoint } = complete;
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
    assert.deepEqual(parseAnswerPatch(null), { ok: false, pointer: '/answers' });
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
```

- [x] **Step 2: Run the test and watch it fail**

```bash
npm run test:unit
```

Expected: FAIL, cannot resolve `onboarding.js`.

- [x] **Step 3: Write the domain**

Create `src/contexts/practice_management/domain/onboarding.ts`:

```ts
import { normalisePracticeName } from './practice.js';

export const practiceSizes = ['solo', 'small_team', 'growing_team'] as const;
export type PracticeSize = (typeof practiceSizes)[number];

export const onboardingPriorities = [
  'deadlines',
  'documents',
  'teamwork',
  'visibility',
] as const;
export type OnboardingPriority = (typeof onboardingPriorities)[number];

export const startingPoints = [
  'import_clients',
  'add_first_client',
  'sample_workspace',
] as const;
export type StartingPoint = (typeof startingPoints)[number];

export type OnboardingAnswers = Readonly<{
  practiceName?: string;
  practiceSize?: PracticeSize;
  priorities?: readonly OnboardingPriority[];
  startingPoint?: StartingPoint;
}>;

/**
 * Where a returning user picks up.
 *
 * Derived from which answers are present, never stored. A stored step enum
 * would weld this contract to the wizard's current shape, so reordering two
 * screens would need a migration of every in-flight record.
 */
export type OnboardingStep =
  | 'practice'
  | 'priorities'
  | 'starting_point'
  | 'ready_to_complete';

export function resumeStepFor(answers: OnboardingAnswers): OnboardingStep {
  if (
    answers.practiceName === undefined ||
    answers.practiceSize === undefined
  ) {
    return 'practice';
  }
  if (answers.priorities === undefined || answers.priorities.length === 0) {
    return 'priorities';
  }
  if (answers.startingPoint === undefined) {
    return 'starting_point';
  }
  return 'ready_to_complete';
}

/**
 * JSON pointers for every required answer still missing.
 *
 * This is the completion invariant. The server enforces it rather than
 * policing transitions, so a client that answers everything in one request is
 * behaving correctly rather than circumventing anything.
 */
export function missingAnswerPointers(
  answers: OnboardingAnswers,
): readonly string[] {
  const missing: string[] = [];
  if (answers.practiceName === undefined) {
    missing.push('/answers/practiceName');
  }
  if (answers.practiceSize === undefined) {
    missing.push('/answers/practiceSize');
  }
  if (answers.priorities === undefined || answers.priorities.length === 0) {
    missing.push('/answers/priorities');
  }
  if (answers.startingPoint === undefined) {
    missing.push('/answers/startingPoint');
  }
  return missing;
}

export type AnswerPatchResult =
  | Readonly<{ ok: true; answers: OnboardingAnswers }>
  | Readonly<{ ok: false; pointer: string }>;

const knownAnswers = new Set([
  'practiceName',
  'practiceSize',
  'priorities',
  'startingPoint',
]);

/**
 * Validates one step's answers.
 *
 * Every value here is client-supplied and untrusted, so each is checked
 * against its enumeration rather than stored as given. An unknown field is
 * refused rather than dropped: silently ignoring it would let a client believe
 * it had set something and be wrong until somebody checked.
 */
export function parseAnswerPatch(value: unknown): AnswerPatchResult {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    return { ok: false, pointer: '/answers' };
  }

  const source = value as Record<string, unknown>;
  for (const field of Object.keys(source)) {
    if (!knownAnswers.has(field)) {
      return { ok: false, pointer: `/answers/${field}` };
    }
  }

  const answers: {
    practiceName?: string;
    practiceSize?: PracticeSize;
    priorities?: readonly OnboardingPriority[];
    startingPoint?: StartingPoint;
  } = {};

  const rawName = source['practiceName'];
  if (rawName !== undefined) {
    // The same rule the practice itself uses. Two rules for one name is how an
    // answer onboarding accepted becomes a practice that cannot be created.
    const name = normalisePracticeName(rawName);
    if (name === undefined) {
      return { ok: false, pointer: '/answers/practiceName' };
    }
    answers.practiceName = name;
  }

  const rawSize = source['practiceSize'];
  if (rawSize !== undefined) {
    if (!isMember(practiceSizes, rawSize)) {
      return { ok: false, pointer: '/answers/practiceSize' };
    }
    answers.practiceSize = rawSize;
  }

  const rawPriorities = source['priorities'];
  if (rawPriorities !== undefined) {
    if (!Array.isArray(rawPriorities) || rawPriorities.length === 0) {
      return { ok: false, pointer: '/answers/priorities' };
    }
    const chosen: OnboardingPriority[] = [];
    for (const entry of rawPriorities) {
      if (!isMember(onboardingPriorities, entry) || chosen.includes(entry)) {
        return { ok: false, pointer: '/answers/priorities' };
      }
      chosen.push(entry);
    }
    answers.priorities = chosen;
  }

  const rawStartingPoint = source['startingPoint'];
  if (rawStartingPoint !== undefined) {
    if (!isMember(startingPoints, rawStartingPoint)) {
      return { ok: false, pointer: '/answers/startingPoint' };
    }
    answers.startingPoint = rawStartingPoint;
  }

  return { ok: true, answers };
}

/** Applies a patch over stored answers, leaving anything it does not carry. */
export function mergeAnswers(
  stored: OnboardingAnswers,
  patch: OnboardingAnswers,
): OnboardingAnswers {
  return { ...stored, ...patch };
}

function isMember<T extends string>(
  allowed: readonly T[],
  value: unknown,
): value is T {
  return (
    typeof value === 'string' && (allowed as readonly string[]).includes(value)
  );
}
```

- [x] **Step 4: Run the tests and watch them pass**

```bash
npm run test:unit
```

Expected: PASS, 18 new tests.

- [x] **Step 5: Confirm the containment guard still bites**

Temporarily add `import type { Timestamp } from 'firebase-admin/firestore';` to `domain/onboarding.ts` plus a type that uses it, run `npm run test:unit`, watch `vendor_containment.test.ts` fail naming the new file, then remove both. An unused import fails the build instead, which is a different guard proving a different thing.

- [x] **Step 6: Commit**

```bash
npm run check
git add src/molobuddy_server/src/contexts/practice_management/domain/onboarding.ts src/molobuddy_server/test/unit/onboarding_domain.test.ts
git commit -m "feat: derive the onboarding resume point from the answers given"
```

---

### Task 3: The onboarding repository

The port and its Firestore adapter, including `If-Match`. This is where the concurrency token does its first real work, so the emulator earns its place here.

**Files:**
- Create: `src/molobuddy_server/src/contexts/practice_management/application/ports/onboarding_repository.ts`
- Create: `src/molobuddy_server/src/contexts/practice_management/adapters/outbound/persistence/firestore_onboarding_repository.ts`
- Test: `src/molobuddy_server/test/integration/firestore/onboarding_repository.test.ts`

**Interfaces:**
- Consumes: `OnboardingAnswers`, `mergeAnswers`, `runInTransaction`, `createResourceVersion`.
- Produces: `StoredOnboarding`, `SaveAnswersOutcome`, `OnboardingRepository` with `find(uid)` and `save(uid, patch, expectedVersion)`; `FirestoreOnboardingRepository`; `onboardingPath(uid)`.

- [x] **Step 1: Write the port**

Create `application/ports/onboarding_repository.ts`:

```ts
import type { OnboardingAnswers } from '../../domain/onboarding.js';

export type StoredOnboarding = Readonly<{
  status: 'in_progress' | 'complete';
  answers: OnboardingAnswers;
  completedPracticeId?: string;
  version: string;
}>;

export type SaveAnswersOutcome =
  | Readonly<{ ok: true; stored: StoredOnboarding }>
  | Readonly<{
      ok: false;
      reason: 'version_mismatch' | 'version_required' | 'already_complete';
    }>;

export interface OnboardingRepository {
  /** The record, or undefined when this user has never answered anything. */
  find(uid: string): Promise<StoredOnboarding | undefined>;

  /**
   * Merges `patch` into the stored answers under optimistic concurrency.
   *
   * `expectedVersion` is the caller's `If-Match`. It is undefined on a first
   * write, when there is no record to conflict with; a record that already
   * exists refuses an undefined version rather than overwriting blindly.
   */
  save(
    uid: string,
    patch: OnboardingAnswers,
    expectedVersion: string | undefined,
  ): Promise<SaveAnswersOutcome>;
}
```

- [x] **Step 2: Write the failing test**

Create `test/integration/firestore/onboarding_repository.test.ts`:

```ts
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { describe, it } from 'node:test';

import { FirestoreOnboardingRepository } from '../../../src/contexts/practice_management/adapters/outbound/persistence/firestore_onboarding_repository.js';
import type {
  SaveAnswersOutcome,
  StoredOnboarding,
} from '../../../src/contexts/practice_management/application/ports/onboarding_repository.js';
import { getMoloFirestore } from '../../../src/platform/persistence/firestore.js';

const projectId = 'molobuddy-development';

function repository(): FirestoreOnboardingRepository {
  return new FirestoreOnboardingRepository(getMoloFirestore(projectId));
}

/** The stored record, proved present rather than asserted away. */
function present(stored: StoredOnboarding | undefined): StoredOnboarding {
  assert.ok(stored !== undefined, 'expected a stored onboarding record');
  return stored;
}

function saved(outcome: SaveAnswersOutcome): StoredOnboarding {
  assert.equal(outcome.ok, true);
  return outcome.stored;
}

describe('firestore onboarding repository', () => {
  it('has nothing for a user who has never answered', async () => {
    assert.equal(await repository().find(`user_${randomUUID()}`), undefined);
  });

  it('creates the record on a first write with no version', async () => {
    const uid = `user_${randomUUID()}`;
    const store = repository();

    const first = saved(
      await store.save(uid, { practiceName: 'Mokoena Media Tax' }, undefined),
    );

    assert.equal(first.status, 'in_progress');
    assert.equal(first.answers.practiceName, 'Mokoena Media Tax');
    assert.match(first.version, /^[a-f0-9]{32}$/);
    assert.equal(present(await store.find(uid)).version, first.version);
  });

  it('merges a later answer without losing an earlier one', async () => {
    const uid = `user_${randomUUID()}`;
    const store = repository();

    const first = saved(
      await store.save(uid, { practiceSize: 'solo' }, undefined),
    );
    const second = saved(
      await store.save(uid, { priorities: ['deadlines'] }, first.version),
    );

    assert.equal(second.answers.practiceSize, 'solo');
    assert.deepEqual(second.answers.priorities, ['deadlines']);
  });

  it('mints a new version on every write', async () => {
    const uid = `user_${randomUUID()}`;
    const store = repository();

    const first = saved(
      await store.save(uid, { practiceSize: 'solo' }, undefined),
    );
    const second = saved(
      await store.save(uid, { practiceSize: 'small_team' }, first.version),
    );

    // A constant would pass every If-Match comparison and silently remove the
    // protection this whole file exists to prove.
    assert.notEqual(second.version, first.version);
  });

  it('refuses a stale version and changes nothing', async () => {
    const uid = `user_${randomUUID()}`;
    const store = repository();

    const first = saved(
      await store.save(uid, { practiceSize: 'solo' }, undefined),
    );
    saved(await store.save(uid, { practiceSize: 'small_team' }, first.version));

    const stale = await store.save(
      uid,
      { practiceSize: 'growing_team' },
      first.version,
    );

    assert.deepEqual(stale, { ok: false, reason: 'version_mismatch' });
    assert.equal(
      present(await store.find(uid)).answers.practiceSize,
      'small_team',
    );
  });

  it('refuses a write with no version once a record exists', async () => {
    const uid = `user_${randomUUID()}`;
    const store = repository();

    saved(await store.save(uid, { practiceSize: 'solo' }, undefined));

    assert.deepEqual(
      await store.save(uid, { practiceSize: 'small_team' }, undefined),
      { ok: false, reason: 'version_required' },
    );
  });

  it('refuses a version for a record that does not exist', async () => {
    const outcome = await repository().save(
      `user_${randomUUID()}`,
      { practiceSize: 'solo' },
      'a'.repeat(32),
    );

    assert.deepEqual(outcome, { ok: false, reason: 'version_mismatch' });
  });

  it('lets only one of two racing writes win', async () => {
    const uid = `user_${randomUUID()}`;
    const store = repository();
    const first = saved(
      await store.save(uid, { practiceSize: 'solo' }, undefined),
    );

    const [a, b] = await Promise.all([
      store.save(uid, { priorities: ['deadlines'] }, first.version),
      store.save(uid, { priorities: ['documents'] }, first.version),
    ]);

    assert.equal([a.ok, b.ok].filter(Boolean).length, 1);
  });
});
```

- [x] **Step 3: Run the test and watch it fail**

```bash
npm run test:firestore
```

Expected: FAIL, cannot resolve `firestore_onboarding_repository.js`.

- [x] **Step 4: Write the adapter**

Create `adapters/outbound/persistence/firestore_onboarding_repository.ts`:

```ts
import { FieldValue, type Firestore } from 'firebase-admin/firestore';

import { createResourceVersion } from '../../../../../platform/http/identifiers.js';
import { runInTransaction } from '../../../../../platform/persistence/firestore.js';
import type {
  OnboardingRepository,
  SaveAnswersOutcome,
  StoredOnboarding,
} from '../../../application/ports/onboarding_repository.js';
import { mergeAnswers } from '../../../domain/onboarding.js';
import type { OnboardingAnswers } from '../../../domain/onboarding.js';

type StoredShape = Readonly<{
  status: 'in_progress' | 'complete';
  answers: OnboardingAnswers;
  completedPracticeId?: string;
  version: string;
}>;

/**
 * The one path this record lives at.
 *
 * An adapter in identity_access reads the same document to answer the session
 * gate. It cannot import this constant without creating a context cycle, so
 * the path is recorded in the data design and both adapters are checked
 * against that.
 */
export function onboardingPath(uid: string): string {
  return `users/${uid}/onboarding/current`;
}

export class FirestoreOnboardingRepository implements OnboardingRepository {
  constructor(private readonly db: Firestore) {}

  async find(uid: string): Promise<StoredOnboarding | undefined> {
    return (await this.db.doc(onboardingPath(uid)).get()).data() as
      | StoredShape
      | undefined;
  }

  async save(
    uid: string,
    patch: OnboardingAnswers,
    expectedVersion: string | undefined,
  ): Promise<SaveAnswersOutcome> {
    const document = this.db.doc(onboardingPath(uid));

    return runInTransaction(this.db, async (tx) => {
      // Read first: Firestore requires every read in a transaction to precede
      // its writes, and this read is what If-Match is compared against.
      const existing = (await tx.get(document)).data() as
        | StoredShape
        | undefined;

      if (existing === undefined) {
        if (expectedVersion !== undefined) {
          // A version for a record that has never existed cannot match.
          return { ok: false, reason: 'version_mismatch' } as const;
        }
        const created: StoredShape = {
          status: 'in_progress',
          answers: patch,
          version: createResourceVersion(),
        };
        tx.set(document, {
          uid,
          ...created,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
        return { ok: true, stored: created } as const;
      }

      if (existing.status === 'complete') {
        return { ok: false, reason: 'already_complete' } as const;
      }
      if (expectedVersion === undefined) {
        return { ok: false, reason: 'version_required' } as const;
      }
      if (expectedVersion !== existing.version) {
        return { ok: false, reason: 'version_mismatch' } as const;
      }

      const updated: StoredShape = {
        status: 'in_progress',
        answers: mergeAnswers(existing.answers, patch),
        version: createResourceVersion(),
      };
      tx.set(
        document,
        { ...updated, updatedAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
      return { ok: true, stored: updated } as const;
    });
  }
}
```

- [x] **Step 5: Run the test and watch it pass**

```bash
npm run test:firestore
```

Expected: PASS, 8 new tests. The racing test relies on Firestore aborting and retrying one transaction, which then re-reads and finds the version has moved. Do not add a sleep.

- [x] **Step 6: Commit**

```bash
npm run check
git add src/molobuddy_server/src/contexts/practice_management src/molobuddy_server/test/integration/firestore/onboarding_repository.test.ts
git commit -m "feat: persist onboarding answers under optimistic concurrency"
```

---

### Task 4: Read and save commands

Two small application services over the port. No HTTP yet.

**Files:**
- Create: `src/molobuddy_server/src/contexts/practice_management/application/queries/get_onboarding.ts`
- Create: `src/molobuddy_server/src/contexts/practice_management/application/commands/save_onboarding_answers.ts`
- Test: `src/molobuddy_server/test/unit/onboarding_commands.test.ts`

**Interfaces:**
- Consumes: `OnboardingRepository`, `parseAnswerPatch`, `resumeStepFor`.
- Produces: `OnboardingView = { status, nextStep?, answers, version? }`; `GetOnboarding.execute(uid)`; `SaveOnboardingAnswers.execute({uid, answers, expectedVersion})` returning `SaveOnboardingResult`.

- [x] **Step 1: Write the failing test**

Create `test/unit/onboarding_commands.test.ts`:

```ts
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
  constructor(private stored: StoredOnboarding | undefined = undefined) {}

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
```

- [x] **Step 2: Run the test and watch it fail**

```bash
npm run test:unit
```

Expected: FAIL, cannot resolve `get_onboarding.js`.

- [x] **Step 3: Write the query**

Create `application/queries/get_onboarding.ts`:

```ts
import type {
  OnboardingAnswers,
  OnboardingStep,
} from '../../domain/onboarding.js';
import { resumeStepFor } from '../../domain/onboarding.js';
import type { OnboardingRepository } from '../ports/onboarding_repository.js';

export type OnboardingView = Readonly<{
  status: 'in_progress' | 'complete';
  /** Absent once onboarding is complete: there is nowhere left to resume. */
  nextStep?: OnboardingStep;
  answers: OnboardingAnswers;
  /** Absent when nothing is stored yet, which is what a first write expects. */
  version?: string;
}>;

export class GetOnboarding {
  constructor(private readonly repository: OnboardingRepository) {}

  async execute(uid: string): Promise<OnboardingView> {
    const stored = await this.repository.find(uid);
    if (stored === undefined) {
      // Absence is not an error. It reads as "no answers yet", which resumes
      // at the first question and expects a first write with no If-Match.
      return { status: 'in_progress', nextStep: 'practice', answers: {} };
    }
    if (stored.status === 'complete') {
      return {
        status: 'complete',
        answers: stored.answers,
        version: stored.version,
      };
    }
    return {
      status: 'in_progress',
      nextStep: resumeStepFor(stored.answers),
      answers: stored.answers,
      version: stored.version,
    };
  }
}
```

- [x] **Step 4: Write the command**

Create `application/commands/save_onboarding_answers.ts`:

```ts
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
        | 'version_mismatch'
        | 'version_required'
        | 'onboarding_already_complete';
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
```

- [x] **Step 5: Run the tests and watch them pass**

```bash
npm run test:unit
```

Expected: PASS, 7 new tests.

- [x] **Step 6: Commit**

```bash
npm run check
git add src/molobuddy_server/src/contexts/practice_management/application src/molobuddy_server/test/unit/onboarding_commands.test.ts
git commit -m "feat: read and save onboarding answers through the domain rules"
```

---

### Task 5: Found the practice from onboarding, in one transaction

Extends the provisioning write with an optional founding block, so completion adds two documents to the transaction `ProvisionPractice` already runs rather than opening a second write path into practice creation.

**Files:**
- Modify: `src/molobuddy_server/src/contexts/practice_management/application/ports/practice_repository.ts`
- Modify: `src/molobuddy_server/src/contexts/practice_management/adapters/outbound/persistence/firestore_practice_repository.ts`
- Test: `src/molobuddy_server/test/integration/firestore/practice_repository.test.ts`

**Interfaces:**
- Produces: `FoundingOnboarding = { uid, answers }`; `ProvisionPracticeWrite` gains `founding?: FoundingOnboarding`.

- [x] **Step 1: Write the failing test**

Add to `test/integration/firestore/practice_repository.test.ts`, keeping every existing test unchanged:

```ts
  it('records the founding answers and completes onboarding in the same write', async () => {
    const db = getMoloFirestore(projectId);
    const repository = new FirestorePracticeRepository(db);
    const uid = `user_${randomUUID()}`;
    const answers = {
      practiceName: 'Mokoena Media Tax',
      practiceSize: 'solo' as const,
      priorities: ['deadlines' as const],
      startingPoint: 'add_first_client' as const,
    };
    const write = { ...writeFor(uid, 'founding-key'), founding: { uid, answers } };
    await db
      .doc(`users/${uid}/onboarding/current`)
      .set({ uid, status: 'in_progress', answers, version: 'v-before' });

    const outcome = await repository.provision(write);

    const id = outcome.practiceRef.practiceId;
    const recorded = await storedAt(db, `practices/${id}/onboarding/founding`);
    assert.equal(recorded['foundedByUid'], uid);
    assert.deepEqual(recorded['answers'], answers);
    // A survey nothing updates carries no concurrency token.
    assert.equal(recorded['version'], undefined);

    const onboarding = await storedAt(db, `users/${uid}/onboarding/current`);
    assert.equal(onboarding['status'], 'complete');
    assert.equal(onboarding['completedPracticeId'], id);
    assert.notEqual(onboarding['version'], 'v-before');
  });

  it('returns the first practice when onboarding completed concurrently', async () => {
    const db = getMoloFirestore(projectId);
    const repository = new FirestorePracticeRepository(db);
    const uid = `user_${randomUUID()}`;
    const answers = { practiceName: 'Mokoena Media Tax' };

    const first = await repository.provision({
      ...writeFor(uid, 'first-key'),
      founding: { uid, answers },
    });
    // A different key, so the idempotency read cannot catch this. Only the
    // completed onboarding record can, and it must, or a user who submits
    // twice founds two practices.
    const second = await repository.provision({
      ...writeFor(uid, 'second-key'),
      founding: { uid, answers },
    });

    assert.equal(second.replayed, true);
    assert.equal(second.practiceRef.practiceId, first.practiceRef.practiceId);
    assert.equal(
      (await db.collection(`users/${uid}/practiceRefs`).get()).size,
      1,
    );
  });

  it('writes no founding record when a practice is created outside onboarding', async () => {
    const db = getMoloFirestore(projectId);
    const repository = new FirestorePracticeRepository(db);
    const uid = `user_${randomUUID()}`;
    const write = writeFor(uid, 'plain-key');

    await repository.provision(write);

    assert.equal(
      (
        await db
          .doc(`practices/${write.practice.practiceId}/onboarding/founding`)
          .get()
      ).exists,
      false,
    );
  });
```

- [x] **Step 2: Run the test and watch it fail**

```bash
npm run test:firestore
```

Expected: FAIL. `founding` is not a property of `ProvisionPracticeWrite`.

- [x] **Step 3: Extend the port**

In `application/ports/practice_repository.ts`, add the import and the type:

```ts
import type { OnboardingAnswers } from '../../domain/onboarding.js';

/**
 * Present when this practice is being founded by finishing onboarding.
 *
 * Carried on the write rather than done as a second call, so the founding
 * answers and the completed onboarding record commit with the practice. A
 * separate call could leave a practice whose onboarding still says it is
 * outstanding, which would route its owner back into a wizard.
 */
export type FoundingOnboarding = Readonly<{
  uid: string;
  answers: OnboardingAnswers;
}>;
```

and add to `ProvisionPracticeWrite`:

```ts
  founding?: FoundingOnboarding;
```

- [x] **Step 4: Extend the adapter**

In `firestore_practice_repository.ts`, replace the transaction body so every read precedes every write:

```ts
    return runInTransaction(this.db, async (tx) => {
      // Every read first. Firestore requires it, and these reads are what make
      // a replay and a concurrent completion return the original rather than
      // founding a second practice.
      const existing = (await tx.get(keyDoc)).data() as
        | StoredIdempotencyKey
        | undefined;
      if (existing !== undefined) {
        return { practiceRef: existing.practiceRef, replayed: true };
      }

      const founding = write.founding;
      const onboardingDoc =
        founding === undefined
          ? undefined
          : this.db.doc(`users/${founding.uid}/onboarding/current`);

      if (founding !== undefined && onboardingDoc !== undefined) {
        const onboarding = (await tx.get(onboardingDoc)).data() as
          | Readonly<{ status?: string; completedPracticeId?: string }>
          | undefined;
        const completedId = onboarding?.completedPracticeId;
        if (onboarding?.status === 'complete' && completedId !== undefined) {
          const alreadyFounded = (
            await tx.get(
              this.db.doc(`users/${founding.uid}/practiceRefs/${completedId}`),
            )
          ).data() as PracticeRefRecord | undefined;
          if (alreadyFounded !== undefined) {
            return { practiceRef: alreadyFounded, replayed: true };
          }
        }
      }

      const practiceId = write.practice.practiceId;
      // Each resource gets its own freshly minted concurrency token. They are
      // separate resources with separate ETags, so they must not share one.
      tx.set(this.db.doc(`practices/${practiceId}`), {
        ...write.practice,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        version: createResourceVersion(),
      });
      tx.set(this.db.doc(`practices/${practiceId}/members/${uid}`), {
        ...write.member,
        joinedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        version: createResourceVersion(),
      });
      tx.set(
        this.db.doc(`users/${uid}/practiceRefs/${practiceId}`),
        write.practiceRef,
      );
      tx.set(keyDoc, {
        practiceRef: write.practiceRef,
        createdAt: FieldValue.serverTimestamp(),
      });

      if (founding !== undefined && onboardingDoc !== undefined) {
        // A point-in-time survey of what the founder said. Never updated, so
        // it carries no concurrency token.
        tx.set(this.db.doc(`practices/${practiceId}/onboarding/founding`), {
          foundedByUid: founding.uid,
          answers: founding.answers,
          recordedAt: FieldValue.serverTimestamp(),
        });
        tx.set(
          onboardingDoc,
          {
            status: 'complete',
            completedPracticeId: practiceId,
            version: createResourceVersion(),
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      }

      return { practiceRef: write.practiceRef, replayed: false };
    });
```

`PracticeRefRecord` is already imported in this file. `createResourceVersion` is too.

- [x] **Step 5: Run the tests and watch them pass**

```bash
npm run test:firestore
```

Expected: PASS, 8 tests in this file, 19 across the emulator suite.

- [x] **Step 6: Commit**

```bash
npm run check
git add src/molobuddy_server/src/contexts/practice_management src/molobuddy_server/test/integration/firestore/practice_repository.test.ts
git commit -m "feat: complete onboarding in the transaction that founds the practice"
```

---

### Task 6: The completion command

**Files:**
- Create: `src/molobuddy_server/src/contexts/practice_management/application/commands/complete_onboarding.ts`
- Modify: `src/molobuddy_server/src/contexts/practice_management/application/commands/provision_practice.ts`
- Modify: `src/molobuddy_server/src/contexts/practice_management/index.ts`
- Test: `src/molobuddy_server/test/unit/complete_onboarding.test.ts`

**Interfaces:**
- Consumes: `OnboardingRepository`, `ProvisionPractice`, `missingAnswerPointers`, `VerifiedActor`.
- Produces: `CompleteOnboarding.execute({actor, idempotencyKey, correlationId})` returning `{ok: true, practiceRef, replayed}`, `{ok: false, code: 'validation_error', pointer}` or `{ok: false, code: 'onboarding_incomplete', missing}`. `ProvisionPracticeInput` gains `founding?: FoundingOnboarding`.

- [x] **Step 1: Write the failing test**

Create `test/unit/complete_onboarding.test.ts`:

```ts
import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import { CompleteOnboarding } from '../../src/contexts/practice_management/application/commands/complete_onboarding.js';
import { ProvisionPractice } from '../../src/contexts/practice_management/application/commands/provision_practice.js';
import type {
  AuditEvent,
  AuditEventSink,
} from '../../src/contexts/practice_management/application/ports/audit_event_sink.js';
import type {
  OnboardingRepository,
  StoredOnboarding,
} from '../../src/contexts/practice_management/application/ports/onboarding_repository.js';
import type {
  PracticeRepository,
  ProvisionPracticeOutcome,
  ProvisionPracticeWrite,
} from '../../src/contexts/practice_management/application/ports/practice_repository.js';
import type { VerifiedActor } from '../../src/contexts/identity_access/index.js';

const actor: VerifiedActor = {
  uid: 'user_1',
  firebaseProjectId: 'molobuddy-development',
  appId: 'app_1',
  providerIds: ['password'],
  emailVerified: false,
  displayName: 'Thando Mokoena',
  email: 'thando@example.com',
};

const answers = {
  practiceName: 'Mokoena Media Tax',
  practiceSize: 'solo' as const,
  priorities: ['deadlines' as const],
  startingPoint: 'add_first_client' as const,
};

const inProgress: StoredOnboarding = {
  status: 'in_progress',
  answers,
  version: 'v-1',
};

class StubOnboarding implements OnboardingRepository {
  constructor(private readonly stored: StoredOnboarding | undefined) {}
  async find(): Promise<StoredOnboarding | undefined> {
    return this.stored;
  }
  async save(): Promise<never> {
    throw new Error('save must not be called during completion');
  }
}

class RecordingRepository implements PracticeRepository {
  writes: ProvisionPracticeWrite[] = [];
  async provision(
    write: ProvisionPracticeWrite,
  ): Promise<ProvisionPracticeOutcome> {
    this.writes.push(write);
    return { practiceRef: write.practiceRef, replayed: false };
  }
}

class RecordingAudit implements AuditEventSink {
  events: AuditEvent[] = [];
  async record(event: AuditEvent): Promise<void> {
    this.events.push(event);
  }
}

function only<T>(items: readonly T[]): T {
  assert.equal(items.length, 1);
  const [first] = items;
  assert.ok(first !== undefined);
  return first;
}

function build(
  stored: StoredOnboarding | undefined,
  repository: PracticeRepository,
  audit: AuditEventSink = new RecordingAudit(),
) {
  return new CompleteOnboarding(
    new StubOnboarding(stored),
    new ProvisionPractice(repository, audit, 'za1'),
  );
}

describe('complete onboarding', () => {
  it('founds the practice the user named', async () => {
    const repository = new RecordingRepository();

    const result = await build(inProgress, repository).execute({
      actor,
      idempotencyKey: 'key-1',
      correlationId: 'cor_1',
    });

    assert.equal(result.ok, true);
    const write = only(repository.writes);
    assert.equal(write.practice.displayName, 'Mokoena Media Tax');
    assert.equal(write.practiceRef.displayLabel, 'Mokoena Media Tax');
  });

  it('carries the answers through so they commit with the practice', async () => {
    const repository = new RecordingRepository();

    await build(inProgress, repository).execute({
      actor,
      idempotencyKey: 'key-1',
      correlationId: 'cor_1',
    });

    const founding = only(repository.writes).founding;
    assert.ok(founding !== undefined);
    assert.equal(founding.uid, 'user_1');
    assert.deepEqual(founding.answers, answers);
  });

  it('refuses to complete with an answer missing, and writes nothing', async () => {
    const repository = new RecordingRepository();
    const { startingPoint: _omitted, ...partial } = answers;

    const result = await build(
      { status: 'in_progress', answers: partial, version: 'v-1' },
      repository,
    ).execute({ actor, idempotencyKey: 'key-1', correlationId: 'cor_1' });

    assert.deepEqual(result, {
      ok: false,
      code: 'onboarding_incomplete',
      missing: ['/answers/startingPoint'],
    });
    assert.equal(repository.writes.length, 0);
  });

  it('refuses a user who has answered nothing at all', async () => {
    const repository = new RecordingRepository();

    const result = await build(undefined, repository).execute({
      actor,
      idempotencyKey: 'key-1',
      correlationId: 'cor_1',
    });

    assert.equal(result.ok, false);
    assert.equal(result.code, 'onboarding_incomplete');
    assert.equal(repository.writes.length, 0);
  });

  it('requires an idempotency key', async () => {
    const repository = new RecordingRepository();

    const result = await build(inProgress, repository).execute({
      actor,
      idempotencyKey: '   ',
      correlationId: 'cor_1',
    });

    assert.equal(result.ok, false);
    assert.equal(result.code, 'validation_error');
    assert.equal(repository.writes.length, 0);
  });

  it('records one audit event', async () => {
    const audit = new RecordingAudit();

    await build(inProgress, new RecordingRepository(), audit).execute({
      actor,
      idempotencyKey: 'key-1',
      correlationId: 'cor_1',
    });

    assert.equal(only(audit.events).action, 'practice.provisioned');
  });
});
```

- [x] **Step 2: Run the test and watch it fail**

```bash
npm run test:unit
```

Expected: FAIL, cannot resolve `complete_onboarding.js`.

- [x] **Step 3: Let the provisioning command carry the founding block**

In `application/commands/provision_practice.ts`, add the import:

```ts
import type { FoundingOnboarding } from '../ports/practice_repository.js';
```

add to `ProvisionPracticeInput`:

```ts
  founding?: FoundingOnboarding;
```

and inside the `this.repository.provision({...})` call, after `idempotencyKey`:

```ts
      ...(input.founding === undefined ? {} : { founding: input.founding }),
```

The conditional spread is required: `exactOptionalPropertyTypes` refuses an explicit `undefined` for an optional property.

- [x] **Step 4: Write the command**

Create `application/commands/complete_onboarding.ts`:

```ts
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
```

- [x] **Step 5: Extend the import surface**

In `src/contexts/practice_management/index.ts`, add:

```ts
export { CompleteOnboarding } from './application/commands/complete_onboarding.js';
export { SaveOnboardingAnswers } from './application/commands/save_onboarding_answers.js';
export { GetOnboarding } from './application/queries/get_onboarding.js';

export type { OnboardingView } from './application/queries/get_onboarding.js';
export type { OnboardingRepository } from './application/ports/onboarding_repository.js';
```

- [x] **Step 6: Run the tests and watch them pass**

```bash
npm run test:unit && npm run test:firestore
```

Expected: PASS, 6 new unit tests, emulator suite unchanged and green.

- [x] **Step 7: Commit**

```bash
npm run check
git add src/molobuddy_server/src/contexts/practice_management src/molobuddy_server/test/unit/complete_onboarding.test.ts
git commit -m "feat: found a practice from stored onboarding answers"
```

---

### Task 7: The three endpoints

**Files:**
- Create: `src/molobuddy_server/src/contexts/practice_management/adapters/inbound/http/onboarding_routes.ts`
- Modify: `src/molobuddy_server/src/platform/http/schemas.ts`
- Modify: `src/molobuddy_server/src/bootstrap/container.ts`
- Modify: `src/molobuddy_server/src/bootstrap/build_control_api.ts`
- Test: `src/molobuddy_server/test/contract/onboarding.test.ts`

**Interfaces:**
- Consumes: `GetOnboarding`, `SaveOnboardingAnswers`, `CompleteOnboarding`, `RequestTokenVerifier`, `sendProblem`, `ProblemPointer`, `responseMeta`.
- Produces: `registerOnboardingRoutes(app, container)`; `ControlApiContainer` gains `getOnboarding`, `saveOnboardingAnswers`, `completeOnboarding`; `ControlApiDependencies` gains `onboardingRepository`.

- [x] **Step 1: Add the schemas**

In `src/platform/http/schemas.ts`, add before `practiceRefSchema`:

```ts
const onboardingAnswersSchema = {
  type: 'object',
  additionalProperties: false,
  properties: {
    practiceName: { type: 'string', minLength: 1, maxLength: 120 },
    practiceSize: { enum: ['solo', 'small_team', 'growing_team'] },
    priorities: {
      type: 'array',
      minItems: 1,
      maxItems: 4,
      uniqueItems: true,
      items: { enum: ['deadlines', 'documents', 'teamwork', 'visibility'] },
    },
    startingPoint: {
      enum: ['import_clients', 'add_first_client', 'sample_workspace'],
    },
  },
} as const;

export const onboardingPatchBodySchema = {
  type: 'object',
  additionalProperties: false,
  required: ['answers'],
  properties: { answers: onboardingAnswersSchema },
} as const;

export const onboardingResponseSchema = {
  type: 'object',
  additionalProperties: false,
  required: ['data', 'meta'],
  properties: {
    data: {
      type: 'object',
      additionalProperties: false,
      required: ['status', 'answers'],
      properties: {
        status: { enum: ['in_progress', 'complete'] },
        nextStep: {
          enum: [
            'practice',
            'priorities',
            'starting_point',
            'ready_to_complete',
          ],
        },
        answers: onboardingAnswersSchema,
        version: { type: 'string', minLength: 1, maxLength: 128 },
      },
    },
    meta: responseMetaSchema,
  },
} as const;
```

The body schema repeats the domain's enumerations on purpose: Fastify rejects the obvious cases before a handler runs, and `parseAnswerPatch` is what actually decides, because the schema is a convenience and the domain is the contract. Task 8 adds a test that the two lists agree.

- [x] **Step 2: Write the failing contract test**

Create `test/contract/onboarding.test.ts`, following `practice_provisioning.test.ts` for how it builds the app and presents the local verifier's token pair. Inject an in-memory `OnboardingRepository` and `PracticeRepository` through the container, so the contract test needs no emulator. The in-memory onboarding repository must implement the same `If-Match` rules as the Firestore one; copy the branch order from Task 3's adapter rather than inventing a second set of rules.

Write each of these as a real test body using `app.inject`:

```ts
// 1.  GET with no record returns 200, status in_progress, nextStep practice,
//     empty answers and no version.
// 2.  PATCH with no If-Match creates the record, returns 200 and a version.
// 3.  PATCH with the returned version merges and returns a different version.
// 4.  PATCH with a stale If-Match returns 412 version_mismatch.
// 5.  PATCH with no If-Match once a record exists returns 428 version_required.
// 6.  PATCH with an unknown answer field returns 400, and the response body
//     does not contain the submitted value.
// 7.  PATCH with a value outside its enumeration returns 400 validation_error
//     carrying errors[0].pointer '/answers/practiceSize'.
// 8.  POST :complete with every answer present returns 201 and a PracticeRef.
// 9.  POST :complete replayed with the same Idempotency-Key returns 200 and the
//     identical data payload.
// 10. POST :complete with an answer missing returns 409 onboarding_incomplete
//     carrying errors[0].pointer '/answers/startingPoint'.
// 11. POST :complete with no Idempotency-Key returns 400 validation_error.
// 12. Each of the three routes with no authorization header returns 401
//     authentication_required.
// 13. Each of the three routes with a bad id token returns 401 token_invalid.
// 14. Each of the three routes with no App Check token returns 403
//     app_check_required.
```

Cases 12 to 14 iterate the three routes rather than being written nine times.

Case 6 asserts on the whole body rather than only the detail, because a pointer is allowed to name the field and nothing is allowed to repeat the value.

Case 7 written out, so the shape of the other thirteen is not left to taste:

```ts
  it('names the offending answer without repeating its value', async () => {
    const response = await app.inject({
      method: 'PATCH',
      url: '/v1/onboarding',
      headers: validHeaders,
      payload: { answers: { practiceSize: 'enormous' } },
    });
    const body = response.json<ProblemResponse>();

    assert.equal(response.statusCode, 400);
    assert.equal(body.code, 'validation_error');
    assert.deepEqual(body.errors?.[0]?.pointer, '/answers/practiceSize');
    assert.equal(response.body.includes('enormous'), false);
  });
```

`ProblemResponse` needs an optional `errors` array added to the local type this
file declares; `practice_provisioning.test.ts` declares one without it.

- [x] **Step 3: Run the test and watch it fail**

```bash
npm run test:contract
```

Expected: FAIL. The routes do not exist, so every case returns 404.

- [x] **Step 4: Write the routes**

Create `adapters/inbound/http/onboarding_routes.ts`:

```ts
import type { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';

import type { ControlApiContainer } from '../../../../../bootstrap/container.js';
import type { VerifiedActor } from '../../../../identity_access/index.js';
import { sendProblem } from '../../../../../platform/http/problems.js';
import type { ProblemPointer } from '../../../../../platform/http/problems.js';
import { responseMeta } from '../../../../../platform/http/request_context.js';
import {
  createPracticeResponseSchema,
  onboardingPatchBodySchema,
  onboardingResponseSchema,
  problemResponses,
} from '../../../../../platform/http/schemas.js';

export function registerOnboardingRoutes(
  app: FastifyInstance,
  container: ControlApiContainer,
): void {
  app.get(
    '/v1/onboarding',
    {
      schema: {
        response: { 200: onboardingResponseSchema, ...problemResponses },
      },
    },
    async (request, reply) => {
      const actor = await verified(container, request, reply);
      if (actor === undefined) {
        return reply;
      }
      return reply.code(200).send({
        data: await container.getOnboarding.execute(actor.uid),
        meta: responseMeta(request),
      });
    },
  );

  app.patch(
    '/v1/onboarding',
    {
      schema: {
        body: onboardingPatchBodySchema,
        response: { 200: onboardingResponseSchema, ...problemResponses },
      },
    },
    async (request, reply) => {
      const actor = await verified(container, request, reply);
      if (actor === undefined) {
        return reply;
      }

      const result = await container.saveOnboardingAnswers.execute({
        uid: actor.uid,
        answers: (request.body as { answers?: unknown }).answers,
        expectedVersion: readIfMatch(request),
      });
      if (!result.ok) {
        return sendProblem(
          reply,
          request,
          result.code,
          result.code === 'validation_error'
            ? [pointerFor(result.pointer, 'validation_error')]
            : [],
        );
      }

      return reply
        .code(200)
        .send({ data: result.view, meta: responseMeta(request) });
    },
  );

  app.post(
    '/v1/onboarding:complete',
    {
      schema: {
        response: {
          200: createPracticeResponseSchema,
          201: createPracticeResponseSchema,
          ...problemResponses,
        },
      },
    },
    async (request, reply) => {
      const actor = await verified(container, request, reply);
      if (actor === undefined) {
        return reply;
      }

      const key = request.headers['idempotency-key'];
      const result = await container.completeOnboarding.execute({
        actor,
        idempotencyKey: typeof key === 'string' ? key : '',
        correlationId: responseMeta(request).correlationId,
      });
      if (!result.ok) {
        return sendProblem(
          reply,
          request,
          result.code,
          result.code === 'validation_error'
            ? [pointerFor(result.pointer, 'validation_error')]
            : result.missing.map((pointer) =>
                pointerFor(pointer, 'answer_required'),
              ),
        );
      }

      return reply
        .code(result.replayed ? 200 : 201)
        .send({ data: result.practiceRef, meta: responseMeta(request) });
    },
  );
}

/**
 * The verified caller, or undefined once a problem has been sent.
 *
 * Returning undefined rather than throwing keeps the three handlers reading
 * the same way, and keeps verification ahead of every read of the body.
 */
async function verified(
  container: ControlApiContainer,
  request: FastifyRequest,
  reply: FastifyReply,
): Promise<VerifiedActor | undefined> {
  const verification = await container.verifier.verify(readTokens(request));
  if (!verification.ok) {
    await sendProblem(reply, request, verification.code);
    return undefined;
  }
  return verification.actor;
}

function pointerFor(pointer: string, code: string): ProblemPointer {
  // The pointer names the field. The message never repeats the value, so
  // nothing the caller submitted is echoed back.
  return { pointer, code, message: 'This answer is not acceptable.' };
}

/** The entity tag from `If-Match`, unquoted, or undefined when absent. */
function readIfMatch(request: FastifyRequest): string | undefined {
  const header = request.headers['if-match'];
  if (typeof header !== 'string' || header.length === 0) {
    return undefined;
  }
  const match = /^(?:W\/)?"?([^"]+)"?$/.exec(header.trim());
  return match?.[1];
}

function readTokens(request: FastifyRequest): Readonly<{
  idToken?: string;
  appCheckToken?: string;
}> {
  const appCheck = request.headers['x-firebase-appcheck'];
  const match = /^Bearer ([^\s]+)$/i.exec(request.headers.authorization ?? '');
  const idToken = match?.[1];

  return {
    ...(idToken === undefined ? {} : { idToken }),
    ...(typeof appCheck === 'string' && appCheck.length > 0
      ? { appCheckToken: appCheck }
      : {}),
  };
}
```

- [x] **Step 5: Wire the container and the app**

In `src/bootstrap/container.ts`:

- add `onboardingRepository?: OnboardingRepository` to `ControlApiDependencies`;
- add `getOnboarding: GetOnboarding`, `saveOnboardingAnswers: SaveOnboardingAnswers` and `completeOnboarding: CompleteOnboarding` to `ControlApiContainer`;
- lift `provisionPractice` into a local so the endpoint and the completion command share one instance rather than two configured identically:

```ts
  const onboarding =
    dependencies.onboardingRepository ??
    new FirestoreOnboardingRepository(database());
  const provisionPractice = new ProvisionPractice(
    dependencies.practiceRepository ??
      new FirestorePracticeRepository(database()),
    dependencies.auditEventSink ?? new FirestoreAuditEventSink(database()),
    config.regionKey,
  );

  return {
    getSession: new GetSession(
      verifier,
      dependencies.practiceRefReader ??
        new FirestorePracticeRefReader(database()),
    ),
    listAuthProviders: new ListAuthProviders(),
    verifier,
    provisionPractice,
    getOnboarding: new GetOnboarding(onboarding),
    saveOnboardingAnswers: new SaveOnboardingAnswers(onboarding),
    completeOnboarding: new CompleteOnboarding(onboarding, provisionPractice),
  };
```

In `src/bootstrap/build_control_api.ts`, call `registerOnboardingRoutes(app, container)` beside the existing registrations, add `'PATCH'` to the CORS `methods` list, and add `'If-Match'` to `allowedHeaders`. Without both, the browser this endpoint exists for cannot call it.

- [x] **Step 6: Run the tests and watch them pass**

```bash
npm run test:contract && npm run check
```

Expected: PASS, 14 new contract tests, everything else green.

- [x] **Step 7: Commit**

```bash
git add src/molobuddy_server/src src/molobuddy_server/test/contract/onboarding.test.ts
git commit -m "feat: read, save and complete onboarding over the control API"
```

---

### Task 8: The session gate

**Files:**
- Create: `src/molobuddy_server/src/contexts/identity_access/application/ports/onboarding_status_reader.ts`
- Create: `src/molobuddy_server/src/contexts/identity_access/adapters/outbound/persistence/firestore_onboarding_status_reader.ts`
- Modify: `src/molobuddy_server/src/contexts/identity_access/application/queries/get_session.ts`
- Modify: `src/molobuddy_server/src/contexts/identity_access/index.ts`
- Modify: `src/molobuddy_server/src/platform/http/schemas.ts`
- Modify: `src/molobuddy_server/src/bootstrap/container.ts`
- Modify: `src/molobuddy_server/test/integration/control_api.test.ts`
- Test: `src/molobuddy_server/test/unit/get_session.test.ts`
- Test: `src/molobuddy_server/test/unit/onboarding_enumerations.test.ts`

**Interfaces:**
- Produces: `OnboardingStatusReader` with `isComplete(uid: string): Promise<boolean>`; `Session` gains `onboarding: { status: 'in_progress' | 'complete' }`.

- [x] **Step 1: Write the failing test**

Add to `test/unit/get_session.test.ts`, reusing its existing fixtures and adding a `readerReturning` helper and an `aPractice` fixture mirroring the ones in `test/integration/control_api.test.ts`:

```ts
  it('reports onboarding complete for a user who has a practice', async () => {
    let consulted = false;
    const query = new GetSession(
      verifierAccepting(actor),
      readerReturning([aPractice]),
      {
        async isComplete() {
          consulted = true;
          return false;
        },
      },
    );

    const result = await query.execute({});

    assert.equal(result.ok, true);
    assert.deepEqual(result.session.onboarding, { status: 'complete' });
    // Having a practice settles it. Reading the record anyway would add a
    // Firestore round trip to the hottest endpoint for every onboarded user.
    assert.equal(consulted, false);
  });

  it('asks the record only when the user has no practice', async () => {
    const query = new GetSession(verifierAccepting(actor), noPractices, {
      async isComplete() {
        return false;
      },
    });

    const result = await query.execute({});

    assert.equal(result.ok, true);
    assert.deepEqual(result.session.onboarding, { status: 'in_progress' });
  });

  it('believes a completed record even with no practice left', async () => {
    // Losing access to a practice must not push someone who already onboarded
    // back into a wizard.
    const query = new GetSession(verifierAccepting(actor), noPractices, {
      async isComplete() {
        return true;
      },
    });

    const result = await query.execute({});

    assert.equal(result.ok, true);
    assert.deepEqual(result.session.onboarding, { status: 'complete' });
  });
```

Create `test/unit/onboarding_enumerations.test.ts`:

```ts
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
```

- [x] **Step 2: Run the tests and watch them fail**

```bash
npm run test:unit
```

Expected: FAIL. `GetSession` takes two constructor arguments, and `onboarding_status_reader.js` does not resolve.

- [x] **Step 3: Write the port**

Create `application/ports/onboarding_status_reader.ts`:

```ts
/**
 * Whether this user has finished setting up.
 *
 * One boolean, deliberately. The resume step is practice_management domain
 * logic, and that context already imports this one, so computing it here would
 * be a cycle and duplicating it would drift. A client that needs the step
 * fetches GET /v1/onboarding, which the wizard does when it opens anyway.
 */
export interface OnboardingStatusReader {
  isComplete(uid: string): Promise<boolean>;
}
```

- [x] **Step 4: Use it in the query**

In `get_session.ts`, add the import, the gate type, the third constructor argument, and the computation:

```ts
import type { OnboardingStatusReader } from '../ports/onboarding_status_reader.js';

export type OnboardingGate = Readonly<{
  status: 'in_progress' | 'complete';
}>;
```

Add `onboarding: OnboardingGate;` to `Session`, add the constructor argument:

```ts
  constructor(
    private readonly verifier: RequestTokenVerifier,
    private readonly practiceRefs: PracticeRefReader,
    private readonly onboarding: OnboardingStatusReader,
  ) {}
```

and after the practices are loaded:

```ts
    const practiceRefs = await this.practiceRefs.listForUser(actor.uid);
    // A practice settles it without a second read. Only a user who has none
    // needs the record consulted, which is every user exactly once.
    const onboardingComplete =
      practiceRefs.length > 0 || (await this.onboarding.isComplete(actor.uid));
```

then return `onboarding: { status: onboardingComplete ? 'complete' : 'in_progress' }` in the session.

- [x] **Step 5: Write the adapter**

Create `adapters/outbound/persistence/firestore_onboarding_status_reader.ts`:

```ts
import type { Firestore } from 'firebase-admin/firestore';

import type { OnboardingStatusReader } from '../../../application/ports/onboarding_status_reader.js';

export class FirestoreOnboardingStatusReader implements OnboardingStatusReader {
  constructor(private readonly db: Firestore) {}

  async isComplete(uid: string): Promise<boolean> {
    const stored = (
      await this.db.doc(`users/${uid}/onboarding/current`).get()
    ).data() as Readonly<{ status?: string }> | undefined;
    return stored?.status === 'complete';
  }
}
```

The path is repeated from `practice_management`'s adapter rather than imported across the context boundary. Two adapters agreeing on one collection path is a smaller cost than a dependency cycle, and Task 9 records the path in the data design so both have one source to be checked against.

- [x] **Step 6: Add the response schema and wire it**

In `sessionResponseSchema`, add `'onboarding'` to `data.required` and this to `data.properties`:

```ts
        onboarding: {
          type: 'object',
          additionalProperties: false,
          required: ['status'],
          properties: { status: { enum: ['in_progress', 'complete'] } },
        },
```

In `identity_access/index.ts`, export the `OnboardingStatusReader` type alongside the existing exports.

In `container.ts`, add `onboardingStatusReader?: OnboardingStatusReader` to `ControlApiDependencies` and pass `dependencies.onboardingStatusReader ?? new FirestoreOnboardingStatusReader(database())` as `GetSession`'s third argument.

- [x] **Step 7: Keep the existing suites honest**

Two existing suites assert an exact session object and will fail the moment `Session` gains a field. Both must be updated, and neither is optional.

`test/unit/get_session.test.ts`'s first test does `assert.deepEqual(result, {...})` over the whole session. Add `onboarding: { status: 'in_progress' }` to its expectation, and give its `GetSession` a third argument — the same `noPractices` user with `{ async isComplete() { return false; } }`.

`test/integration/control_api.test.ts` asserts the exact `data` of a session response, so both expectations now need `onboarding`. Inject a reader in `before` so the gate needs no network:

```ts
      onboardingStatusReader: { isComplete: async () => false },
```

The existing session test has no practices, so it expects `onboarding: { status: 'in_progress' }`. The test that returns a practice expects `complete`.

- [x] **Step 8: Run everything**

```bash
npm run check && npm run test:firestore
```

Expected: PASS. Confirm the session integration test still runs in single-digit milliseconds; a jump to over a second means a reader reached the real project.

- [x] **Step 9: Commit**

```bash
git add src/molobuddy_server/src src/molobuddy_server/test
git commit -m "feat: report whether onboarding is outstanding from the session"
```

---

### Task 9: Fold the decisions back into the design documents

**Files:**
- Modify: `docs/plans/2026-08-20-founding-onboarding-design.md`
- Modify: `docs/data_design/identity_access.md`
- Modify: `docs/api_design/identity_access.md`

- [x] **Step 1: Correct the spec's session contract**

Section 5 gives the session a `nextStep`. The implementation does not, because computing it would either create a cycle between `identity_access` and `practice_management` or duplicate the derivation. Rewrite section 5's block as `onboarding: { status: 'in_progress' | 'complete' }`, state the cycle as the reason, and note that the wizard learns its step from `GET /v1/onboarding`, which it already calls when it opens.

- [x] **Step 2: Record the collection path as shared**

Add to spec section 7 that `users/{uid}/onboarding/current` is read by an adapter in each of the two contexts, and that the path is therefore part of the data design rather than either context's private business.

- [x] **Step 3: Add the records to the data design**

In `docs/data_design/identity_access.md` section 3, beside the routing projection, add the `OnboardingRecord` shape from spec section 3 and the founding-answers record from section 3.4. State that the founding record carries no `version` and why, consistent with section 3.0.

- [x] **Step 4: State the completion rule**

In the same section, state that onboarding is complete when the record says so or the user has at least one `practiceRef`, and that the second disjunct is what makes every pre-existing user complete without a migration and what will let an accepted invitation complete onboarding without founding anything.

- [x] **Step 5: State that the gate is not enforcement**

In `docs/data_design/identity_access.md` section 9, state that the onboarding redirect is user experience. A user mid-onboarding has no practice and every regional endpoint requires an active membership, so deny-by-default already refuses them; the redirect exists so they meet a wizard instead of an empty screen. Say it explicitly, so a reader who assumes the client enforces it does not remove a server check that never existed.

- [x] **Step 6: Document the endpoints**

In `docs/api_design/identity_access.md`, add `GET /v1/onboarding`, `PATCH /v1/onboarding` and `POST /v1/onboarding:complete` with their request shapes, responses and full error tables from spec section 6. Add all three to the endpoint summary, with concurrency `—`, `If-Match required` and `Idempotency key`. Add `onboarding` to the `Session` resource.

- [x] **Step 7: Document the new problem codes**

Add `onboarding_incomplete`, `onboarding_already_complete`, `version_mismatch` and `version_required` wherever the API design catalogues problem codes, noting that the last two are the concurrency mechanism section 7 of the API design README describes and that this is their first use.

- [x] **Step 8: Commit**

```bash
git add docs
git commit -m "docs: fold the onboarding server decisions into the design contracts"
```

---

## Execution notes

Recorded after the fact, because the plan did not predict them.

- **Schema rejections now carry field pointers too.** The body schema refuses
  an out-of-range enumeration before any handler runs, so the domain's pointer
  never fired and a caller learned which endpoint refused them but not which
  field. The error handler derives pointers from the validator's own errors,
  which gives every endpoint in the API field-level detail rather than only the
  two written here. Only the path is taken; the message is Molo's own, because
  a validator's wording is not a contract and some keywords quote the value
  back.
- **This project has no eslint `varsIgnorePattern`**, so destructure-to-omit
  (`const { x: _omitted, ...rest }`) counts as an unused variable. Build the
  partial fixture explicitly instead — and from literals, because
  `exactOptionalPropertyTypes` also refuses a copied optional.
- **`= undefined` on a constructor parameter is a lint error**
  (`no-useless-default-assignment`). Use `?` instead.
- **An empty async method is a lint error.** A no-op fake needs a comment in
  its body.
- **`app.inject` refuses an explicit `undefined` payload** under
  `exactOptionalPropertyTypes`. Spread the key in rather than assigning it.
- **The prediction about the integration suite was right.** Wiring the gate
  without injecting a reader took the session test from 1 ms to 1397 ms — a
  live call to the real development project, green only for someone holding
  Google credentials.

## Out of Scope

Named so the plan cannot quietly grow:

- Account creation, the wizard, the router gate and preview mode. That is the client plan.
- Acting on the answers. This slice records what the user said.
- Accepting an invitation as an alternative completion path. Spec section 4.4 states how this design stays compatible with it.
- Editing onboarding answers after completion.
- Deleting an abandoned draft. It is one small document per unfinished signup, and no retention rule has been asked for.
