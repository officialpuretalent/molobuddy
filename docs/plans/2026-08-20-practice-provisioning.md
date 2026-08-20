# Practice Provisioning Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a practice and its founding owner through one audited command, and return it from `GET /v1/session` so the client stops seeing the no-practice state.

**Architecture:** A new `practice_management` context owns the command. `platform/persistence` owns the Firestore client and transaction runner, so no domain or application file imports a Google type. One Firestore transaction writes the practice, the owner membership, the routing projection, the audit event and the idempotency key together, which makes a partial practice impossible. The projection write sits behind `ControlPlaneProjectionPort`, the single adapter that changes when the control plane becomes a separate database.

**Tech Stack:** Node.js 24, TypeScript, Fastify 5, firebase-admin 14.2.0, `node --test`, Firestore emulator via the Firebase CLI.

**Spec:** [`docs/plans/2026-08-20-practice-provisioning-design.md`](2026-08-20-practice-provisioning-design.md). Its binding authority is [`docs/data_design/identity_access.md`](../data_design/identity_access.md).

## Global Constraints

- Domain and application code import no Fastify, Firebase or Google Cloud type. Only `platform` and `adapters/outbound` may.
- A context's `index.ts` is its only import surface, and must not re-export aggregates, repositories or provider types.
- Every regional endpoint declares its capability and scope in the endpoint summary. This slice's only new endpoint is Standard tier and needs no capability, which the spec justifies.
- Client-supplied region, role, capability or acting-user values are untrusted and must be ignored.
- Raw ID tokens and App Check tokens never enter logs, audit events, error details or responses.
- Error details never echo a submitted value and never name a resource the caller may not know exists.
- Problem responses use the existing Problem Details shape in `platform/http/problems.ts`.
- `practiceId` is server-generated and opaque. It is never derived from the practice name.
- Verification gates, all green before each commit: `npm run check` in `src/molobuddy_server`. Tasks touching Firestore also run `npm run test:firestore`.

---

## File Structure

| File | Responsibility |
|---|---|
| `firebase.json` (create, repo root) | Emulator and rules/index deploy targets |
| `firestore.rules` (create, repo root) | Deny every client operation |
| `firestore.indexes.json` (create, repo root) | Composite indexes; starts empty |
| `src/platform/persistence/firestore.ts` (create) | Firestore client, database selection, transaction runner |
| `src/platform/http/problems.ts` (modify) | Add `validation_error` |
| `src/platform/http/identifiers.ts` (modify) | Allow the `prc` id prefix |
| `src/platform/http/schemas.ts` (modify) | Request and response schemas for the new endpoint |
| `src/contexts/practice_management/domain/practice.ts` (create) | `Practice` record type and its invariants |
| `src/contexts/practice_management/application/ports/practice_repository.ts` (create) | Persistence port for provisioning |
| `src/contexts/practice_management/application/ports/audit_event_sink.ts` (create) | Audit port |
| `src/contexts/practice_management/application/commands/provision_practice.ts` (create) | The command |
| `src/contexts/practice_management/adapters/outbound/persistence/firestore_practice_repository.ts` (create) | The transaction |
| `src/contexts/practice_management/adapters/inbound/http/practice_routes.ts` (create) | `POST /v1/practices` |
| `src/contexts/practice_management/index.ts` (create) | Import surface |
| `src/contexts/identity_access/application/ports/practice_ref_reader.ts` (create) | Read port for the projection |
| `src/contexts/identity_access/application/queries/get_session.ts` (modify) | Return real refs |
| `src/bootstrap/container.ts` (modify) | Wire the new command and reader |
| `src/bootstrap/build_control_api.ts` (modify) | Register the new routes |

---

### Task 1: Firestore platform and emulator harness

Nothing can be persisted or tested until Firestore is reachable from the server and from tests. This task folds in the Firebase config files because its deliverable, a working transaction against the emulator, needs them.

**Files:**
- Create: `firebase.json`, `firestore.rules`, `firestore.indexes.json` (repo root)
- Create: `src/molobuddy_server/src/platform/persistence/firestore.ts`
- Modify: `src/molobuddy_server/package.json`
- Test: `src/molobuddy_server/test/integration/firestore/transaction_runner.test.ts`

**Interfaces:**
- Produces: `getMoloFirestore(projectId: string): Firestore` and `runInTransaction<T>(db: Firestore, work: (tx: Transaction) => Promise<T>): Promise<T>`.

- [ ] **Step 1: Write the Firebase config files**

`firebase.json` at the repository root:

```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "emulators": {
    "firestore": { "port": 8081 },
    "ui": { "enabled": false },
    "singleProjectMode": true
  }
}
```

`firestore.rules`:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Molo clients never reach Firestore directly. Every write comes from the
    // Admin SDK, which bypasses these rules. A total denial is the backstop if
    // a client SDK is ever added without an architecture decision.
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

`firestore.indexes.json`:

```json
{
  "indexes": [],
  "fieldOverrides": []
}
```

Port 8081 is deliberate: the control API already uses 8080.

- [ ] **Step 2: Add the emulator test script**

In `src/molobuddy_server/package.json`, add to `scripts`:

```json
"test:firestore": "npm run build && firebase emulators:exec --only firestore --project molobuddy-development --config ../../firebase.json \"node --test dist/test/integration/firestore/*.test.js\""
```

Leave `check` unchanged so the ordinary gate does not require the Firebase CLI.

- [ ] **Step 3: Write the failing test**

Create `test/integration/firestore/transaction_runner.test.ts`:

```ts
import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import {
  getMoloFirestore,
  runInTransaction,
} from '../../../src/platform/persistence/firestore.js';

const projectId = 'molobuddy-development';

describe('firestore transaction runner', () => {
  it('commits every write in the transaction together', async () => {
    const db = getMoloFirestore(projectId);
    const first = db.doc('transactionRunnerTest/first');
    const second = db.doc('transactionRunnerTest/second');

    await runInTransaction(db, async (tx) => {
      tx.set(first, { value: 'a' });
      tx.set(second, { value: 'b' });
    });

    assert.equal((await first.get()).data()?.value, 'a');
    assert.equal((await second.get()).data()?.value, 'b');
  });

  it('commits nothing when the work throws', async () => {
    const db = getMoloFirestore(projectId);
    const doc = db.doc('transactionRunnerTest/rolledBack');

    await assert.rejects(
      runInTransaction(db, async (tx) => {
        tx.set(doc, { value: 'written' });
        throw new Error('work failed');
      }),
      /work failed/,
    );

    assert.equal((await doc.get()).exists, false);
  });

  it('returns one client for repeated calls', () => {
    assert.equal(getMoloFirestore(projectId), getMoloFirestore(projectId));
  });
});
```

- [ ] **Step 4: Run the test and watch it fail**

```bash
cd src/molobuddy_server && npm run test:firestore
```

Expected: FAIL. TypeScript cannot resolve `src/platform/persistence/firestore.js`.

- [ ] **Step 5: Write the implementation**

Create `src/platform/persistence/firestore.ts`:

```ts
import { applicationDefault, getApps, initializeApp } from 'firebase-admin/app';
import {
  getFirestore,
  type Firestore,
  type Transaction,
} from 'firebase-admin/firestore';

const firebaseAppName = 'molobuddy-control-api';

/**
 * The Firestore client for this process.
 *
 * Reuses the named Firebase app the token verifier creates, so one process
 * holds one app rather than two competing initialisations. When
 * FIRESTORE_EMULATOR_HOST is set, the Admin SDK routes here to the emulator
 * with no further configuration.
 */
export function getMoloFirestore(projectId: string): Firestore {
  const existing = getApps().find((app) => app.name === firebaseAppName);
  const app =
    existing ??
    initializeApp(
      { credential: applicationDefault(), projectId },
      firebaseAppName,
    );
  return getFirestore(app);
}

/**
 * Runs `work` in a Firestore transaction.
 *
 * Wrapping the vendor call keeps `firebase-admin` out of application code:
 * a command receives this function's behaviour through a port, never the SDK.
 */
export function runInTransaction<T>(
  db: Firestore,
  work: (tx: Transaction) => Promise<T>,
): Promise<T> {
  return db.runTransaction(work);
}
```

- [ ] **Step 6: Run the test and watch it pass**

```bash
npm run test:firestore
```

Expected: PASS, 3 tests.

- [ ] **Step 7: Pin the deny-all ruleset**

Add to `test/unit/firestore_rules.test.ts`:

```ts
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { describe, it } from 'node:test';

describe('firestore rules', () => {
  it('denies every client read and write', () => {
    const rules = readFileSync(
      new URL('../../../../firestore.rules', import.meta.url),
      'utf8',
    );

    assert.match(rules, /allow read, write: if false;/);
    assert.doesNotMatch(rules, /if true/);
    assert.doesNotMatch(rules, /allow (read|write|create|update|delete):\s*if request/);
  });
});
```

This pins the intent cheaply. It is not a substitute for a rules-engine test,
which would need the client SDK as a dependency; the value here is that
loosening the ruleset cannot pass unnoticed.

- [ ] **Step 8: Confirm the ordinary gate is unaffected**

```bash
npm run check
```

Expected: 18 tests, all green.

- [ ] **Step 9: Commit**

```bash
git add firebase.json firestore.rules firestore.indexes.json src/molobuddy_server/package.json src/molobuddy_server/src/platform/persistence src/molobuddy_server/test/integration/firestore src/molobuddy_server/test/unit/firestore_rules.test.ts
git commit -m "feat: manage Firestore from the repository and add a transaction runner"
```

---

### Task 2: Validation problem code and practice id prefix

Two small platform additions the later tasks depend on. They are one task because neither is worth its own review gate.

**Files:**
- Modify: `src/molobuddy_server/src/platform/http/problems.ts`
- Modify: `src/molobuddy_server/src/platform/http/identifiers.ts`
- Test: `src/molobuddy_server/test/unit/problems.test.ts` (create)

**Interfaces:**
- Produces: `ProblemCode` gains `'validation_error'`; `createOpaqueId` accepts `'prc'`.

- [ ] **Step 1: Write the failing test**

Create `test/unit/problems.test.ts`:

```ts
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
```

- [ ] **Step 2: Run the test and watch it fail**

```bash
cd src/molobuddy_server && npm run test:unit
```

Expected: FAIL. `problemForCode` is not exported, and `'prc'` is not an allowed prefix.

- [ ] **Step 3: Add the validation code and the accessor**

In `src/platform/http/problems.ts`, add `'validation_error'` to the `ProblemCode` union, add this entry to the `problems` record, and export an accessor so the catalogue is testable:

```ts
  validation_error: {
    status: 400,
    code: 'validation_error',
    title: 'The request is not valid.',
    detail: 'Check the highlighted fields and try again.',
  },
```

```ts
export function problemForCode(code: ProblemCode): ProblemInput {
  return problems[code];
}
```

Also export the `ProblemCode` type so route code can name it:

```ts
export type { ProblemCode };
```

- [ ] **Step 4: Allow the practice prefix**

In `src/platform/http/identifiers.ts`, widen the prefix union:

```ts
export function createOpaqueId(
  prefix: 'req' | 'cor' | 'prb' | 'prc',
): string {
  return `${prefix}_${randomUUID().replaceAll('-', '')}`;
}
```

- [ ] **Step 5: Add the concurrency token minter**

Still in `src/platform/http/identifiers.ts`:

```ts
/**
 * A fresh optimistic concurrency token.
 *
 * This is the value behind the API's strong ETag. `If-Match` is compared
 * against it to prevent lost updates, so it MUST be regenerated on every write.
 * A constant here would make every comparison succeed and silently disable the
 * protection it appears to provide.
 */
export function createResourceVersion(): string {
  return randomUUID().replaceAll('-', '');
}
```

- [ ] **Step 6: Run the test and watch it pass**

```bash
npm run test:unit
```

Expected: PASS, 4 new tests.

- [ ] **Step 7: Commit**

```bash
npm run check
git add src/molobuddy_server/src/platform/http src/molobuddy_server/test/unit/problems.test.ts
git commit -m "feat: add a validation problem code, practice ids and resource versions"
```

---

### Task 3: Practice domain and ports

Types and interfaces only, with a test that pins the invariants worth protecting. No persistence yet.

**Files:**
- Create: `src/molobuddy_server/src/contexts/practice_management/domain/practice.ts`
- Create: `src/molobuddy_server/src/contexts/practice_management/application/ports/practice_repository.ts`
- Create: `src/molobuddy_server/src/contexts/practice_management/application/ports/audit_event_sink.ts`
- Test: `src/molobuddy_server/test/unit/practice_domain.test.ts`

**Interfaces:**
- Produces: `Practice`, `PracticeMemberRecord`, `PracticeRefRecord`, `normalisePracticeName`, `PracticeRepository`, `ProvisionPracticeWrite`, `ProvisionPracticeOutcome`, `AuditEventSink`, `AuditEvent`.

- [ ] **Step 1: Write the failing test**

Create `test/unit/practice_domain.test.ts`:

```ts
import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import { normalisePracticeName } from '../../src/contexts/practice_management/domain/practice.js';

describe('practice name', () => {
  it('trims surrounding whitespace', () => {
    assert.equal(normalisePracticeName('  Mokoena Media Tax  '), 'Mokoena Media Tax');
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
```

- [ ] **Step 2: Run the test and watch it fail**

```bash
npm run test:unit
```

Expected: FAIL, cannot resolve `practice.js`.

- [ ] **Step 3: Write the domain file**

Create `domain/practice.ts`:

```ts
export type PracticeStatus = 'active' | 'suspended' | 'closed';

/**
 * A practice as the domain knows it.
 *
 * Deliberately carries no `version`. That field is the optimistic concurrency
 * token behind the API's ETag, it must change on every write, and it is
 * therefore owned by the repository rather than by a command. Putting it here
 * would invite a caller to pin it, which is exactly how lost-update protection
 * gets silently disabled.
 */
export type Practice = Readonly<{
  practiceId: string;
  displayName: string;
  homeRegionKey: string;
  routeVersion: number;
  status: PracticeStatus;
  createdByUid: string;
}>;

/** The founding owner. Written exactly as the identity and access data design's PracticeMember. */
export type PracticeMemberRecord = Readonly<{
  practiceId: string;
  uid: string;
  role: 'owner';
  status: 'active';
  displayName: string;
  emailLower: string;
}>;

/**
 * The control-plane routing projection.
 *
 * Deliberately identical to the shape GET /v1/session returns, so there is no
 * mapping layer between storage and contract that could drift.
 */
export type PracticeRefRecord = Readonly<{
  practiceId: string;
  displayLabel: string;
  homeRegionKey: string;
  routeVersion: number;
  accessStatus: 'active' | 'invited' | 'suspended';
}>;

const maximumNameLength = 120;

/**
 * Returns the storable practice name, or undefined when it is not acceptable.
 *
 * Returning undefined rather than throwing keeps the decision in the caller,
 * which owns how a rejection is reported.
 */
export function normalisePracticeName(value: unknown): string | undefined {
  if (typeof value !== 'string') {
    return undefined;
  }
  const trimmed = value.trim();
  if (trimmed.length === 0 || trimmed.length > maximumNameLength) {
    return undefined;
  }
  return trimmed;
}
```

- [ ] **Step 4: Write the ports**

Create `application/ports/practice_repository.ts`:

```ts
import type {
  Practice,
  PracticeMemberRecord,
  PracticeRefRecord,
} from '../../domain/practice.js';

export type ProvisionPracticeWrite = Readonly<{
  practice: Practice;
  member: PracticeMemberRecord;
  practiceRef: PracticeRefRecord;
  idempotencyKey: string;
}>;

export type ProvisionPracticeOutcome = Readonly<{
  practiceRef: PracticeRefRecord;
  /** True when a stored idempotency key made this a replay rather than a creation. */
  replayed: boolean;
}>;

export interface PracticeRepository {
  /**
   * Writes the practice, its founding owner, the routing projection and the
   * idempotency key atomically, or returns the earlier result for a key that
   * has already been used by this actor.
   */
  provision(write: ProvisionPracticeWrite): Promise<ProvisionPracticeOutcome>;
}
```

Create `application/ports/audit_event_sink.ts`:

```ts
export type AuditEvent = Readonly<{
  actorUid: string;
  practiceId: string;
  action: 'practice.provisioned';
  correlationId: string;
  /** Safe authorisation state after the action. Never a token or a credential. */
  resultingState: Readonly<{ role: 'owner'; status: 'active' }>;
}>;

export interface AuditEventSink {
  record(event: AuditEvent): Promise<void>;
}
```

- [ ] **Step 5: Guard the dependency rule**

Create `test/unit/vendor_containment.test.ts`. The repository structure document
forbids a Google type in domain or application code, and nothing enforces it:

```ts
import assert from 'node:assert/strict';
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { describe, it } from 'node:test';

function filesUnder(directory: string): string[] {
  return readdirSync(directory).flatMap((entry) => {
    const full = join(directory, entry);
    return statSync(full).isDirectory()
      ? filesUnder(full)
      : full.endsWith('.ts')
        ? [full]
        : [];
  });
}

describe('context dependency rules', () => {
  it('keeps vendor SDKs out of domain and application code', () => {
    const offenders: string[] = [];

    for (const file of filesUnder('src/contexts')) {
      const normalised = file.replaceAll('\\', '/');
      if (
        !normalised.includes('/domain/') &&
        !normalised.includes('/application/')
      ) {
        continue;
      }
      const source = readFileSync(file, 'utf8');
      for (const vendor of ['firebase-admin', 'fastify', '@google-cloud']) {
        if (source.includes(`from '${vendor}`)) {
          offenders.push(`${normalised} imports ${vendor}`);
        }
      }
    }

    assert.deepEqual(offenders, []);
  });
});
```

- [ ] **Step 6: Run the tests and watch them pass**

```bash
npm run test:unit
```

Expected: PASS, 5 tests. Confirm the guard bites by temporarily adding
`import { FieldValue } from 'firebase-admin/firestore';` to
`domain/practice.ts`, re-running, seeing the failure, then removing it.

- [ ] **Step 7: Commit**

```bash
npm run check
git add src/molobuddy_server/src/contexts/practice_management src/molobuddy_server/test/unit/practice_domain.test.ts src/molobuddy_server/test/unit/vendor_containment.test.ts
git commit -m "feat: add the practice domain shapes and provisioning ports"
```

---

### Task 4: The provisioning command

**Files:**
- Create: `src/molobuddy_server/src/contexts/practice_management/application/commands/provision_practice.ts`
- Create: `src/molobuddy_server/src/contexts/practice_management/index.ts`
- Test: `src/molobuddy_server/test/unit/provision_practice.test.ts`

**Interfaces:**
- Consumes: `PracticeRepository`, `AuditEventSink`, `normalisePracticeName`, `createOpaqueId`, `VerifiedActor`.
- Produces: `ProvisionPractice` with `execute(input: ProvisionPracticeInput): Promise<ProvisionPracticeResult>`, where the result is `{ ok: true; practiceRef: PracticeRefRecord; replayed: boolean }` or `{ ok: false; code: 'validation_error'; pointer: string }`.

- [ ] **Step 1: Write the failing test**

Create `test/unit/provision_practice.test.ts`:

```ts
import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import { ProvisionPractice } from '../../src/contexts/practice_management/application/commands/provision_practice.js';
import type {
  PracticeRepository,
  ProvisionPracticeOutcome,
  ProvisionPracticeWrite,
} from '../../src/contexts/practice_management/application/ports/practice_repository.js';
import type {
  AuditEvent,
  AuditEventSink,
} from '../../src/contexts/practice_management/application/ports/audit_event_sink.js';
import type { VerifiedActor } from '../../src/contexts/identity_access/index.js';

const actor: VerifiedActor = {
  uid: 'user_1',
  firebaseProjectId: 'molobuddy-development',
  appId: 'app_1',
  providerIds: ['password'],
  emailVerified: false,
  displayName: 'Thando Mokoena',
  email: 'Thando@Example.com',
};

class RecordingRepository implements PracticeRepository {
  writes: ProvisionPracticeWrite[] = [];
  replayed = false;

  async provision(
    write: ProvisionPracticeWrite,
  ): Promise<ProvisionPracticeOutcome> {
    this.writes.push(write);
    return { practiceRef: write.practiceRef, replayed: this.replayed };
  }
}

class RecordingAudit implements AuditEventSink {
  events: AuditEvent[] = [];
  async record(event: AuditEvent): Promise<void> {
    this.events.push(event);
  }
}

function build(repository: PracticeRepository, audit: AuditEventSink) {
  return new ProvisionPractice(repository, audit, 'za1');
}

describe('provision practice', () => {
  it('makes the caller the active owner of a new practice', async () => {
    const repository = new RecordingRepository();
    const audit = new RecordingAudit();

    const result = await build(repository, audit).execute({
      actor,
      displayName: 'Mokoena Media Tax',
      idempotencyKey: 'key-1',
      correlationId: 'cor_1',
    });

    assert.equal(result.ok, true);
    const write = repository.writes[0]!;
    assert.match(write.practice.practiceId, /^prc_/);
    assert.equal(write.practice.displayName, 'Mokoena Media Tax');
    assert.equal(write.practice.status, 'active');
    assert.equal(write.practice.createdByUid, 'user_1');
    assert.equal(write.member.role, 'owner');
    assert.equal(write.member.status, 'active');
    assert.equal(write.practiceRef.accessStatus, 'active');
    assert.equal(write.practiceRef.displayLabel, 'Mokoena Media Tax');
  });

  it('assigns the server region and ignores anything the client sent', async () => {
    const repository = new RecordingRepository();
    const result = await build(repository, new RecordingAudit()).execute({
      actor,
      displayName: 'Mokoena Media Tax',
      idempotencyKey: 'key-1',
      correlationId: 'cor_1',
    });

    assert.equal(result.ok, true);
    assert.equal(repository.writes[0]!.practice.homeRegionKey, 'za1');
    assert.equal(repository.writes[0]!.practiceRef.homeRegionKey, 'za1');
    assert.equal(repository.writes[0]!.practice.routeVersion, 1);
  });

  it('stores the email lowercased and takes identity from the token, not the body', async () => {
    const repository = new RecordingRepository();
    await build(repository, new RecordingAudit()).execute({
      actor,
      displayName: 'Mokoena Media Tax',
      idempotencyKey: 'key-1',
      correlationId: 'cor_1',
    });

    assert.equal(repository.writes[0]!.member.emailLower, 'thando@example.com');
    assert.equal(repository.writes[0]!.member.displayName, 'Thando Mokoena');
  });

  it('rejects an unusable name without writing anything', async () => {
    const repository = new RecordingRepository();
    const result = await build(repository, new RecordingAudit()).execute({
      actor,
      displayName: '   ',
      idempotencyKey: 'key-1',
      correlationId: 'cor_1',
    });

    assert.deepEqual(result, {
      ok: false,
      code: 'validation_error',
      pointer: '/displayName',
    });
    assert.equal(repository.writes.length, 0);
  });

  it('rejects a missing idempotency key without writing anything', async () => {
    const repository = new RecordingRepository();
    const result = await build(repository, new RecordingAudit()).execute({
      actor,
      displayName: 'Mokoena Media Tax',
      idempotencyKey: '',
      correlationId: 'cor_1',
    });

    assert.equal(result.ok, false);
    assert.equal(repository.writes.length, 0);
  });

  it('records one audit event carrying no token', async () => {
    const audit = new RecordingAudit();
    await build(new RecordingRepository(), audit).execute({
      actor,
      displayName: 'Mokoena Media Tax',
      idempotencyKey: 'key-1',
      correlationId: 'cor_1',
    });

    assert.equal(audit.events.length, 1);
    assert.equal(audit.events[0]!.action, 'practice.provisioned');
    assert.equal(audit.events[0]!.actorUid, 'user_1');
    assert.equal(JSON.stringify(audit.events[0]).includes('token'), false);
  });

  it('does not record a second audit event for a replay', async () => {
    const repository = new RecordingRepository();
    repository.replayed = true;
    const audit = new RecordingAudit();

    const result = await build(repository, audit).execute({
      actor,
      displayName: 'Mokoena Media Tax',
      idempotencyKey: 'key-1',
      correlationId: 'cor_1',
    });

    assert.equal(result.ok, true);
    assert.equal(audit.events.length, 0);
  });
});
```

- [ ] **Step 2: Run the test and watch it fail**

```bash
npm run test:unit
```

Expected: FAIL, cannot resolve `provision_practice.js`.

- [ ] **Step 3: Write the command**

Create `application/commands/provision_practice.ts`:

```ts
import { createOpaqueId } from '../../../../platform/http/identifiers.js';
import type { VerifiedActor } from '../../../identity_access/index.js';
import { normalisePracticeName } from '../../domain/practice.js';
import type { PracticeRefRecord } from '../../domain/practice.js';
import type { AuditEventSink } from '../ports/audit_event_sink.js';
import type { PracticeRepository } from '../ports/practice_repository.js';

export type ProvisionPracticeInput = Readonly<{
  actor: VerifiedActor;
  displayName: unknown;
  idempotencyKey: string;
  correlationId: string;
}>;

export type ProvisionPracticeResult =
  | Readonly<{ ok: true; practiceRef: PracticeRefRecord; replayed: boolean }>
  | Readonly<{ ok: false; code: 'validation_error'; pointer: string }>;

export class ProvisionPractice {
  constructor(
    private readonly repository: PracticeRepository,
    private readonly audit: AuditEventSink,
    private readonly homeRegionKey: string,
  ) {}

  async execute(input: ProvisionPracticeInput): Promise<ProvisionPracticeResult> {
    const displayName = normalisePracticeName(input.displayName);
    if (displayName === undefined) {
      return { ok: false, code: 'validation_error', pointer: '/displayName' };
    }
    if (input.idempotencyKey.trim().length === 0) {
      return {
        ok: false,
        code: 'validation_error',
        pointer: '/headers/idempotency-key',
      };
    }

    const practiceId = createOpaqueId('prc');
    const outcome = await this.repository.provision({
      idempotencyKey: input.idempotencyKey.trim(),
      practice: {
        practiceId,
        displayName,
        // Server-assigned. A client-supplied region is untrusted input and is
        // never read, even when the request carries one.
        homeRegionKey: this.homeRegionKey,
        routeVersion: 1,
        status: 'active',
        createdByUid: input.actor.uid,
      },
      member: {
        practiceId,
        uid: input.actor.uid,
        role: 'owner',
        status: 'active',
        // Identity comes from the verified token, never from the body.
        displayName: input.actor.displayName ?? input.actor.uid,
        emailLower: (input.actor.email ?? '').toLowerCase(),
      },
      practiceRef: {
        practiceId,
        displayLabel: displayName,
        homeRegionKey: this.homeRegionKey,
        routeVersion: 1,
        accessStatus: 'active',
      },
    });

    if (!outcome.replayed) {
      await this.audit.record({
        actorUid: input.actor.uid,
        practiceId: outcome.practiceRef.practiceId,
        action: 'practice.provisioned',
        correlationId: input.correlationId,
        resultingState: { role: 'owner', status: 'active' },
      });
    }

    return {
      ok: true,
      practiceRef: outcome.practiceRef,
      replayed: outcome.replayed,
    };
  }
}
```

- [ ] **Step 4: Write the context import surface**

Create `src/contexts/practice_management/index.ts`:

```ts
export { ProvisionPractice } from './application/commands/provision_practice.js';

export type {
  ProvisionPracticeInput,
  ProvisionPracticeResult,
} from './application/commands/provision_practice.js';
export type { PracticeRefRecord } from './domain/practice.js';
export type { PracticeRepository } from './application/ports/practice_repository.js';
export type { AuditEventSink } from './application/ports/audit_event_sink.js';
```

- [ ] **Step 5: Run the test and watch it pass**

```bash
npm run test:unit
```

Expected: PASS, 7 tests.

- [ ] **Step 6: Commit**

```bash
npm run check
git add src/molobuddy_server/src/contexts/practice_management src/molobuddy_server/test/unit/provision_practice.test.ts
git commit -m "feat: provision a practice with its founding owner"
```

---

### Task 5: Firestore repository adapter

Where the transactional behaviour actually lives, so this is where the emulator earns its place.

**Files:**
- Create: `src/molobuddy_server/src/contexts/practice_management/adapters/outbound/persistence/firestore_practice_repository.ts`
- Test: `src/molobuddy_server/test/integration/firestore/practice_repository.test.ts`

**Interfaces:**
- Consumes: `PracticeRepository`, `ProvisionPracticeWrite`, `getMoloFirestore`, `runInTransaction`.
- Produces: `FirestorePracticeRepository`, and `FirestoreAuditEventSink` writing to `/auditEvents/{autoId}`.

- [ ] **Step 1: Write the failing test**

Create `test/integration/firestore/practice_repository.test.ts`:

```ts
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { describe, it } from 'node:test';

import { FirestorePracticeRepository } from '../../../src/contexts/practice_management/adapters/outbound/persistence/firestore_practice_repository.js';
import type { ProvisionPracticeWrite } from '../../../src/contexts/practice_management/application/ports/practice_repository.js';
import { getMoloFirestore } from '../../../src/platform/persistence/firestore.js';

const projectId = 'molobuddy-development';

function writeFor(uid: string, key: string): ProvisionPracticeWrite {
  const practiceId = `prc_${randomUUID().replaceAll('-', '')}`;
  return {
    idempotencyKey: key,
    practice: {
      practiceId,
      displayName: 'Mokoena Media Tax',
      homeRegionKey: 'za1',
      routeVersion: 1,
      status: 'active',
      createdByUid: uid,
    },
    member: {
      practiceId,
      uid,
      role: 'owner',
      status: 'active',
      displayName: 'Thando Mokoena',
      emailLower: 'thando@example.com',
    },
    practiceRef: {
      practiceId,
      displayLabel: 'Mokoena Media Tax',
      homeRegionKey: 'za1',
      routeVersion: 1,
      accessStatus: 'active',
    },
  };
}

describe('firestore practice repository', () => {
  it('writes the practice, the owner and the projection together', async () => {
    const db = getMoloFirestore(projectId);
    const repository = new FirestorePracticeRepository(db);
    const uid = `user_${randomUUID()}`;
    const write = writeFor(uid, 'key-1');

    const outcome = await repository.provision(write);

    assert.equal(outcome.replayed, false);
    const id = write.practice.practiceId;
    assert.equal((await db.doc(`practices/${id}`).get()).exists, true);
    assert.equal((await db.doc(`practices/${id}/members/${uid}`).get()).data()?.role, 'owner');
    assert.equal(
      (await db.doc(`users/${uid}/practiceRefs/${id}`).get()).data()?.displayLabel,
      'Mokoena Media Tax',
    );
  });

  it('creates exactly one practice when a key is replayed', async () => {
    const db = getMoloFirestore(projectId);
    const repository = new FirestorePracticeRepository(db);
    const uid = `user_${randomUUID()}`;

    const first = await repository.provision(writeFor(uid, 'shared-key'));
    const second = await repository.provision(writeFor(uid, 'shared-key'));

    assert.equal(first.replayed, false);
    assert.equal(second.replayed, true);
    assert.equal(second.practiceRef.practiceId, first.practiceRef.practiceId);

    const refs = await db.collection(`users/${uid}/practiceRefs`).get();
    assert.equal(refs.size, 1);
  });

  it('creates one practice when two identical requests race', async () => {
    const db = getMoloFirestore(projectId);
    const repository = new FirestorePracticeRepository(db);
    const uid = `user_${randomUUID()}`;

    const [a, b] = await Promise.all([
      repository.provision(writeFor(uid, 'race-key')),
      repository.provision(writeFor(uid, 'race-key')),
    ]);

    assert.equal(a.practiceRef.practiceId, b.practiceRef.practiceId);
    assert.equal((await db.collection(`users/${uid}/practiceRefs`).get()).size, 1);
    assert.equal([a.replayed, b.replayed].filter(Boolean).length, 1);
  });

  it('gives each record its own concurrency token, and none to the projection', async () => {
    const db = getMoloFirestore(projectId);
    const repository = new FirestorePracticeRepository(db);
    const uid = `user_${randomUUID()}`;
    const write = writeFor(uid, 'version-key');

    await repository.provision(write);

    const id = write.practice.practiceId;
    const practice = (await db.doc(`practices/${id}`).get()).data()!;
    const member = (await db.doc(`practices/${id}/members/${uid}`).get()).data()!;
    const ref = (await db.doc(`users/${uid}/practiceRefs/${id}`).get()).data()!;

    // A hardcoded constant would pass the format check but fail this: two
    // resources sharing one token means one ETag can validate the other.
    assert.match(practice.version, /^[a-f0-9]{32}$/);
    assert.match(member.version, /^[a-f0-9]{32}$/);
    assert.notEqual(practice.version, member.version);

    // The projection is server-owned and never PATCHed, so it carries no token.
    assert.equal(ref.version, undefined);
  });

  it('keeps one user’s key from colliding with another’s', async () => {
    const db = getMoloFirestore(projectId);
    const repository = new FirestorePracticeRepository(db);
    const first = `user_${randomUUID()}`;
    const second = `user_${randomUUID()}`;

    const a = await repository.provision(writeFor(first, 'same-key'));
    const b = await repository.provision(writeFor(second, 'same-key'));

    assert.equal(b.replayed, false);
    assert.notEqual(a.practiceRef.practiceId, b.practiceRef.practiceId);
  });
});
```

- [ ] **Step 2: Run the test and watch it fail**

```bash
npm run test:firestore
```

Expected: FAIL, cannot resolve `firestore_practice_repository.js`.

- [ ] **Step 3: Write the adapter**

Create `adapters/outbound/persistence/firestore_practice_repository.ts`:

```ts
import { FieldValue, type Firestore } from 'firebase-admin/firestore';

import { createResourceVersion } from '../../../../../platform/http/identifiers.js';
import { runInTransaction } from '../../../../../platform/persistence/firestore.js';
import type {
  AuditEvent,
  AuditEventSink,
} from '../../../application/ports/audit_event_sink.js';
import type {
  PracticeRepository,
  ProvisionPracticeOutcome,
  ProvisionPracticeWrite,
} from '../../../application/ports/practice_repository.js';
import type { PracticeRefRecord } from '../../../domain/practice.js';

export class FirestorePracticeRepository implements PracticeRepository {
  constructor(private readonly db: Firestore) {}

  async provision(
    write: ProvisionPracticeWrite,
  ): Promise<ProvisionPracticeOutcome> {
    const uid = write.member.uid;
    const keyDoc = this.db.doc(
      `users/${uid}/idempotencyKeys/${write.idempotencyKey}`,
    );

    return runInTransaction(this.db, async (tx) => {
      // Read first: Firestore requires every read in a transaction to precede
      // its writes, and this read is what makes a replay return the original.
      const existing = await tx.get(keyDoc);
      if (existing.exists) {
        return {
          practiceRef: existing.data()!.practiceRef as PracticeRefRecord,
          replayed: true,
        };
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

      return { practiceRef: write.practiceRef, replayed: false };
    });
  }
}

export class FirestoreAuditEventSink implements AuditEventSink {
  constructor(private readonly db: Firestore) {}

  async record(event: AuditEvent): Promise<void> {
    await this.db.collection('auditEvents').add({
      ...event,
      recordedAt: FieldValue.serverTimestamp(),
    });
  }
}
```

- [ ] **Step 4: Run the test and watch it pass**

```bash
npm run test:firestore
```

Expected: PASS, 5 tests. If the racing test is flaky, that is a real finding, not a test problem: Firestore retries a contended transaction, and the read-then-write ordering above is what makes the retry converge on one practice. Do not add a sleep.

- [ ] **Step 5: Commit**

```bash
npm run check
git add src/molobuddy_server/src/contexts/practice_management/adapters src/molobuddy_server/test/integration/firestore/practice_repository.test.ts
git commit -m "feat: persist a provisioned practice in one transaction"
```

---

### Task 6: The endpoint

**Files:**
- Create: `src/molobuddy_server/src/contexts/practice_management/adapters/inbound/http/practice_routes.ts`
- Modify: `src/molobuddy_server/src/platform/http/schemas.ts`
- Modify: `src/molobuddy_server/src/bootstrap/container.ts`
- Modify: `src/molobuddy_server/src/bootstrap/build_control_api.ts`
- Test: `src/molobuddy_server/test/contract/practice_provisioning.test.ts`

**Interfaces:**
- Consumes: `ProvisionPractice`, `RequestTokenVerifier`, `sendProblem`, `responseMeta`.
- Produces: `registerPracticeRoutes(app, container)`; the container gains `provisionPractice: ProvisionPractice` and `verifier: RequestTokenVerifier`.

- [ ] **Step 1: Add the schemas**

In `src/platform/http/schemas.ts`, add:

```ts
export const practiceRefSchema = {
  type: 'object',
  additionalProperties: false,
  required: [
    'practiceId',
    'displayLabel',
    'homeRegionKey',
    'routeVersion',
    'accessStatus',
  ],
  properties: {
    practiceId: { type: 'string', minLength: 1, maxLength: 160 },
    displayLabel: { type: 'string', minLength: 1, maxLength: 200 },
    homeRegionKey: { type: 'string', minLength: 1, maxLength: 64 },
    routeVersion: { type: 'integer', minimum: 1 },
    accessStatus: { enum: ['active', 'invited', 'suspended'] },
  },
} as const;

export const createPracticeBodySchema = {
  type: 'object',
  additionalProperties: false,
  required: ['displayName'],
  properties: {
    displayName: { type: 'string', minLength: 1, maxLength: 120 },
  },
} as const;

export const createPracticeResponseSchema = {
  type: 'object',
  additionalProperties: false,
  required: ['data', 'meta'],
  properties: {
    data: practiceRefSchema,
    meta: responseMetaSchema,
  },
} as const;
```

`additionalProperties: false` on the body makes a client-supplied `region` a
rejected request rather than a silently ignored field.

**This deviates from the spec**, whose acceptance criterion 9 says such a field
is ignored and the practice still created. Rejecting is the better contract: it
tells a client immediately that a field it believes it is sending has no effect,
rather than letting it assume a region was honoured. Task 8 corrects the spec to
match. If you prefer the spec's original behaviour, drop `additionalProperties`
from the body schema and change the contract test accordingly, but do not leave
the two documents disagreeing.

- [ ] **Step 2: Write the failing contract test**

Create `test/contract/practice_provisioning.test.ts`, following the existing `test/contract/auth_contract.test.ts` for how it builds the app and presents the local verifier's token pair. Assert:

```ts
// 1. A valid request returns 201, and the body matches createPracticeResponseSchema.
// 2. The same Idempotency-Key returns 200 with an identical data payload.
// 3. A body with no displayName returns 400 validation_error.
// 4. A body carrying an extra "region" field returns 400.
// 5. No Idempotency-Key header returns 400 validation_error.
// 6. No authorization header returns 401 authentication_required.
// 7. A bad id token returns 401 token_invalid.
// 8. A missing App Check token returns 403 app_check_required.
```

Write each of those eight as a real test body using `app.inject`, in the style of the existing contract test. Use an in-memory `PracticeRepository` fake injected through the container so the contract test needs no emulator.

- [ ] **Step 3: Run the test and watch it fail**

```bash
npm run test:contract
```

Expected: FAIL. The route does not exist, so every case returns 404.

- [ ] **Step 4: Write the route**

Create `adapters/inbound/http/practice_routes.ts`:

```ts
import type { FastifyInstance, FastifyRequest } from 'fastify';

import type { ControlApiContainer } from '../../../../../bootstrap/container.js';
import {
  createPracticeBodySchema,
  createPracticeResponseSchema,
  problemResponses,
} from '../../../../../platform/http/schemas.js';
import { sendProblem } from '../../../../../platform/http/problems.js';
import { responseMeta } from '../../../../../platform/http/request_context.js';

export function registerPracticeRoutes(
  app: FastifyInstance,
  container: ControlApiContainer,
): void {
  app.post(
    '/v1/practices',
    {
      schema: {
        body: createPracticeBodySchema,
        response: {
          200: createPracticeResponseSchema,
          201: createPracticeResponseSchema,
          ...problemResponses,
        },
      },
    },
    async (request, reply) => {
      const verification = await container.verifier.verify(
        readTokens(request),
      );
      if (!verification.ok) {
        return sendProblem(reply, request, verification.code);
      }

      const idempotencyKey = request.headers['idempotency-key'];
      const result = await container.provisionPractice.execute({
        actor: verification.actor,
        displayName: (request.body as { displayName?: unknown }).displayName,
        idempotencyKey: typeof idempotencyKey === 'string' ? idempotencyKey : '',
        correlationId: responseMeta(request).correlationId,
      });

      if (!result.ok) {
        return sendProblem(reply, request, result.code);
      }

      return reply
        .code(result.replayed ? 200 : 201)
        .send({ data: result.practiceRef, meta: responseMeta(request) });
    },
  );
}

function readTokens(request: FastifyRequest): Readonly<{
  idToken?: string;
  appCheckToken?: string;
}> {
  const appCheck = request.headers['x-firebase-appcheck'];
  const match = /^Bearer ([^\s]+)$/i.exec(request.headers.authorization ?? '');

  return {
    ...(match === null ? {} : { idToken: match[1] }),
    ...(typeof appCheck === 'string' && appCheck.length > 0
      ? { appCheckToken: appCheck }
      : {}),
  };
}
```

- [ ] **Step 5: Wire the container and the app**

In `src/bootstrap/container.ts`, keep the verifier in a local, expose it on the container, and construct the command from the Firestore adapters:

```ts
  const db = getMoloFirestore(
    config.auth.mode === 'firebase' ? config.auth.projectId : 'molobuddy-development',
  );

  return {
    getSession: new GetSession(verifier),
    listAuthProviders: new ListAuthProviders(),
    verifier,
    provisionPractice: new ProvisionPractice(
      new FirestorePracticeRepository(db),
      new FirestoreAuditEventSink(db),
      config.regionKey,
    ),
  };
```

Add `verifier: RequestTokenVerifier` and `provisionPractice: ProvisionPractice` to `ControlApiContainer`.

In `src/bootstrap/build_control_api.ts`, call `registerPracticeRoutes(app, container)` beside the existing `registerIdentityAccessRoutes(app, container)`.

- [ ] **Step 6: Run the test and watch it pass**

```bash
npm run test:contract && npm run check
```

Expected: PASS, 8 new contract tests, everything else green.

- [ ] **Step 7: Commit**

```bash
git add src/molobuddy_server/src src/molobuddy_server/test/contract/practice_provisioning.test.ts
git commit -m "feat: create a practice over the control API"
```

---

### Task 7: Session returns real practice references

**Files:**
- Create: `src/molobuddy_server/src/contexts/identity_access/application/ports/practice_ref_reader.ts`
- Create: `src/molobuddy_server/src/contexts/identity_access/adapters/outbound/persistence/firestore_practice_ref_reader.ts`
- Modify: `src/molobuddy_server/src/contexts/identity_access/application/queries/get_session.ts`
- Modify: `src/molobuddy_server/src/contexts/identity_access/index.ts`
- Modify: `src/molobuddy_server/src/bootstrap/container.ts`
- Test: `src/molobuddy_server/test/unit/get_session.test.ts` (modify)

**Interfaces:**
- Produces: `PracticeRefReader` with `listForUser(uid: string): Promise<readonly PracticeRef[]>`, where `PracticeRef` is the type already declared inside `Session`.

- [ ] **Step 1: Write the failing test**

Add to `test/unit/get_session.test.ts`, keeping every existing test unchanged:

```ts
  it('returns the practices the user actually has', async () => {
    const reader = {
      listForUser: async (uid: string) => {
        assert.equal(uid, 'user_123');
        return [
          {
            practiceId: 'prc_1',
            displayLabel: 'Mokoena Media Tax',
            homeRegionKey: 'za1',
            routeVersion: 1,
            accessStatus: 'active' as const,
          },
        ];
      },
    };
    const query = new GetSession(verifierAccepting(actor), reader);

    const result = await query.execute(validTokens);

    assert.equal(result.ok, true);
    assert.deepEqual(result.session.practiceRefs.map((p) => p.practiceId), [
      'prc_1',
    ]);
  });

  it('returns an empty list for a user with no practice', async () => {
    const query = new GetSession(verifierAccepting(actor), {
      listForUser: async () => [],
    });

    const result = await query.execute(validTokens);

    assert.equal(result.ok, true);
    assert.deepEqual(result.session.practiceRefs, []);
  });
```

Reuse whatever fixture names the existing file already defines for the verifier, actor and tokens rather than inventing new ones.

- [ ] **Step 2: Run the test and watch it fail**

```bash
npm run test:unit
```

Expected: FAIL. `GetSession` takes one constructor argument.

- [ ] **Step 3: Write the port**

Create `application/ports/practice_ref_reader.ts`:

```ts
import type { Session } from '../queries/get_session.js';

export type PracticeRef = Session['practiceRefs'][number];

export interface PracticeRefReader {
  /** The routing projections belonging to this user, ordered by display label. */
  listForUser(uid: string): Promise<readonly PracticeRef[]>;
}
```

- [ ] **Step 4: Use it in the query**

In `get_session.ts`, take the reader as a second constructor argument and replace the hardcoded list:

```ts
  constructor(
    private readonly verifier: RequestTokenVerifier,
    private readonly practiceRefs: PracticeRefReader,
  ) {}
```

and in `execute`, after the actor is known:

```ts
    const practiceRefs = await this.practiceRefs.listForUser(actor.uid);
```

then return `practiceRefs` in place of the literal `[]`. The uid comes from the verified actor, never from the request, so one user cannot read another's list.

- [ ] **Step 5: Write the Firestore reader**

Create `adapters/outbound/persistence/firestore_practice_ref_reader.ts`:

```ts
import type { Firestore } from 'firebase-admin/firestore';

import type {
  PracticeRef,
  PracticeRefReader,
} from '../../../application/ports/practice_ref_reader.js';

export class FirestorePracticeRefReader implements PracticeRefReader {
  constructor(private readonly db: Firestore) {}

  async listForUser(uid: string): Promise<readonly PracticeRef[]> {
    const snapshot = await this.db
      .collection(`users/${uid}/practiceRefs`)
      .orderBy('displayLabel')
      .get();

    return snapshot.docs.map((doc) => doc.data() as PracticeRef);
  }
}
```

- [ ] **Step 6: Wire it and export the port type**

In `container.ts`, pass `new FirestorePracticeRefReader(db)` as the second argument to `GetSession`. In `identity_access/index.ts`, export the `PracticeRefReader` type alongside the existing exports.

- [ ] **Step 7: Run the tests and watch them pass**

```bash
npm run check
```

Expected: PASS, including the two new tests and every pre-existing one.

- [ ] **Step 8: Verify the client-visible payoff by hand**

This is the acceptance criterion the automated tests cannot reach, because it
spans both applications and needs no client change.

```bash
cd src/molobuddy_server && npm run dev
```

With `AUTH_VERIFIER=firebase`, sign in to the Flutter app, call
`POST /v1/practices` as that user with a valid ID token and App Check token,
then reload the app. The welcome screen must stop showing "You are signed in.
No practice has been connected to this account yet." and the practice must
appear. Record the observed result in the task report.

- [ ] **Step 9: Commit**

```bash
git add src/molobuddy_server/src src/molobuddy_server/test/unit/get_session.test.ts
git commit -m "feat: return the caller's real practices from the session"
```

---

### Task 8: Fold the decisions back into the design documents

The spec's section 10 lists five details it decided that the data design leaves open. Leaving them only in the spec is how two documents start disagreeing.

**Files:**
- Modify: `docs/data_design/identity_access.md`
- Modify: `docs/local_development.md`
- Modify: `docs/api_design/identity_access.md`

- [ ] **Step 1: Add the two record shapes to the data design**

In `docs/data_design/identity_access.md` section 3, add the `Practice` record and the `PracticeRefRecord` projection fields exactly as the spec's sections 3.1 and 3.3 define them. Note beside the projection that its shape is deliberately identical to the session response.

- [ ] **Step 2: Add the tier and the verification rule**

In its section 8 tier table, add a row: creating a practice is Standard tier. Beneath the table, state that founding a practice does not require a verified email, and why: the authentication design requires verification to join an existing practice as staff, which is a different act.

- [ ] **Step 3: State that region is server-assigned**

In its section 2, alongside the existing statement that a client-supplied region is untrusted, add that `homeRegionKey` is assigned by the server at provisioning and is never accepted from a request body.

- [ ] **Step 4: Document the endpoint**

In `docs/api_design/identity_access.md`, add `POST /v1/practices`: its request body, the `Idempotency-Key` header, the 201 and 200 responses, and the error table from the spec's section 8.

- [ ] **Step 5: Explain what `version` means in the data design**

`docs/data_design/identity_access.md` puts `version: string` on
`PracticeMember` and `TaxpayerAccessGrant` without ever saying what it is for,
and the same bare field appears on most records across the API design. The
natural misreading is that it stamps a document schema, which leads to writing
a constant and silently disabling lost-update protection.

Add a short subsection to its section 3 stating: `version` is the optimistic
concurrency token behind the API's strong ETag; `If-Match` is compared against
it and a stale value returns `412 version_mismatch`; it must be regenerated on
every write; a constant defeats it entirely; and a document schema stamp is a
separate concern served by `schemaVersion`. Note also that a server-owned
derived projection carries no `version`, because nothing updates it.

- [ ] **Step 6: Correct acceptance criterion 9 in the spec**

In `docs/plans/2026-08-20-practice-provisioning-design.md`, criterion 9 currently
says a request carrying a region field has it ignored. The implementation
rejects the request with `400 validation_error` instead, because the body schema
sets `additionalProperties: false`. Rewrite the criterion to state the rejection,
and note in section 4.2 that an unknown body field is refused rather than
dropped.

- [ ] **Step 7: Add the emulator to the runbook**

In `docs/local_development.md`, add a short section: Firestore is managed from the repository root, `npm run test:firestore` runs the emulator-backed tests, and the emulator uses port 8081 because the control API holds 8080.

- [ ] **Step 8: Commit**

```bash
git add docs
git commit -m "docs: fold the provisioning decisions into the design contracts"
```

---

## Out of Scope

Named so the plan cannot quietly grow:

- The capability and scope enforcement library. The only new read is a user's own routing projection, which carries no capability.
- Account creation and wiring the Flutter registration flow to the endpoint.
- Invitations and any member beyond the founding owner.
- Taxpayer records and portal access grants.
- A second region, a separate control-plane database, and wrong-region rejection.
- Deploying rules or indexes to the cloud project. This slice manages them in the repository and exercises them in the emulator.
