# Practice Provisioning Design

- **Status:** Draft v0.1, approved in brainstorming, awaiting review
- **Owner:** Product and engineering
- **Last updated:** 20 August 2026
- **Related contracts:** [identity and access data design](../data_design/identity_access.md), [client-first authentication](../backend_design/authentication.md), [repository and source structure](../backend_design/repository_structure.md), [identity and access API](../api_design/identity_access.md), [runtime platform](../backend_design/runtime_platform.md)

## 1. Decision

A practice comes into existence through one explicit, audited command:
`POST /v1/practices`. The command creates the practice, makes its caller the
first owner, and publishes a routing projection the client can navigate by. All
of it happens in a single Firestore transaction, so a practice without an owner
or without a routing entry cannot exist.

This closes the gap that `GET /v1/session` currently papers over by returning a
hardcoded empty `practiceRefs` list.

The [identity and access data design](../data_design/identity_access.md) is the
binding authority for the authorisation model. This document adds only what
that document does not specify: how the records it describes first come to
exist. Where it needed a detail that document leaves open, section 10 lists the
addition explicitly.

## 2. Scope

In scope:

1. Firestore managed from the repository: rules, indexes, and an emulator-backed
   test path.
2. The provisioning command and the three records it writes.
3. `GET /v1/session` returning real practice references.

Out of scope, each needing its own design:

- The capability and scope enforcement library. Nothing here requires it: the
  only new read is a user's own routing projection, which the data design
  states carries no capability and authorises no regional operation.
- Account creation and wiring the Flutter registration flow. The endpoint is
  proved by tests and by calling it as a real signed-in user.
- Invitations and any member beyond the founding owner.
- Taxpayer records and portal access grants.
- A second region, a separate control-plane database, and wrong-region
  rejection.

## 3. Records

### 3.1 Practice

The data design specifies the subcollections beneath a practice but not the
practice itself. Proposed:

```ts
type Practice = {
  practiceId: string;
  displayName: string;
  homeRegionKey: string;
  routeVersion: number;
  status: 'active' | 'suspended' | 'closed';
  createdByUid: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  version: string;
};
```

`homeRegionKey` is the value the authentication design's pipeline resolves at
step 5, and `status` carries the closure state its privileged tier refers to.

`version` is the **optimistic concurrency token**, not a schema stamp. The API
design makes an update return a strong `ETag` carrying the opaque resource
version, requires `If-Match` on state-changing actions, and answers a stale one
with `412 version_mismatch` and a missing one with `428 version_required`. This
field is the value behind that ETag, and it is what stops two practitioners
editing the same record from silently overwriting each other.

It follows that the token **must be regenerated on every write**. A constant is
worse than no token at all: every `If-Match` comparison would succeed, so the
first update endpoint would appear to have lost-update protection while having
none. The repository mints a fresh value each time it writes, so a document
created today already carries a usable token when the first `PATCH` arrives and
no migration is needed to make one.

A document schema stamp is a different concern, already served by
`schemaVersion` elsewhere in the architecture. This slice needs no such stamp
and adds none.

`practiceId` is a server-generated opaque identifier. It is never derived from
the practice name, because a name is neither unique nor stable and an
identifier derived from one leaks it into URLs and logs.

### 3.2 Founding owner membership

Written exactly as the data design's `PracticeMember`, with `role: 'owner'`,
`status: 'active'`, `joinedAt` set, and `displayName` and `emailLower` taken
from the verified token claims rather than from the request body.

No capability overrides are written. An owner receives its capabilities from
the role bundle.

### 3.3 Routing projection

The data design calls `users/{uid}/practiceRefs/{practiceId}` a minimal
routing and navigation projection carrying no capability, but does not give its
fields. Proposed, matching the five fields `GET /v1/session` already returns:

```ts
type PracticeRefRecord = {
  practiceId: string;
  displayLabel: string;
  homeRegionKey: string;
  routeVersion: number;
  accessStatus: 'active' | 'invited' | 'suspended';
};
```

Making the stored shape identical to the response shape removes a mapping layer
that would otherwise drift. `accessStatus` mirrors the membership status,
narrowed to the three values the API exposes; a `removed` member has their
projection deleted rather than published as a fourth state.

The projection deliberately carries **no `version`**. It is a server-owned
derived record that no client ever updates, so no `If-Match` is ever compared
against it and a concurrency token would have nothing to protect. It is rebuilt
from the membership it mirrors, never edited in place.

`routeVersion` is unrelated to that token despite the name. It invalidates a
cached region route when a practice moves region, and stays `1` for every
practice while one region exists. It is part of the session contract already
shipped in `Session`, its response schema and the Flutter client.

## 4. The provisioning command

### 4.1 Contract

```http
POST /v1/practices
Authorization: Bearer <firebase id token>
X-Firebase-AppCheck: <app check token>
Idempotency-Key: <client-generated opaque key>
Content-Type: application/json

{ "displayName": "Mokoena Media Tax" }
```

`201 Created` returns the projection, in the standard envelope:

```json
{
  "data": {
    "practiceId": "prc_...",
    "displayLabel": "Mokoena Media Tax",
    "homeRegionKey": "za1",
    "routeVersion": 1,
    "accessStatus": "active"
  },
  "meta": { "apiVersion": "v1", "requestId": "req_...", "correlationId": "cor_..." }
}
```

Returning the projection rather than a bare identifier lets a client navigate
straight into the new practice without a second round trip.

### 4.2 The region is server-assigned

The request body carries no region. The registration screen shows a region
picker, but the data design treats a client-supplied region as untrusted input,
and honouring one would let a caller place a practice in a jurisdiction they
were never granted. The server assigns `homeRegionKey` from its own
configuration, which is `za1` for every practice in this slice.

When a second region exists, region selection becomes a server-side decision
informed by the account, not a field the client sets. That change will not
alter this contract.

### 4.3 Verification tier

Standard: a verified ID token and a valid App Check token, per the
authentication pipeline's steps 1 to 4.

The data design's tier table does not list practice creation. Standard is
proposed because the actor creates a practice they will own, touching no
existing practice, no other person's access and no taxpayer data. The
privileged tier is reserved for acts against an existing practice, such as
closure or owner transfer.

A verified email is deliberately **not** required. The authentication design
requires it before joining a practice as staff, which is a different act:
accepting someone else's invitation. Requiring it here would block the founding
owner from their own workspace on an unverified address, which is the state
every newly created account starts in.

### 4.4 Repeat calls

A user may own several practices, which the session contract's list and the
`selecting_practice` state already anticipate. Two calls with different
idempotency keys therefore create two practices, deliberately.

Two calls with the same key create one. The key is stored at
`users/{uid}/idempotencyKeys/{key}` holding the resulting `practiceId`, read and
written inside the same transaction as the practice. A repeat returns
`200 OK` with the original projection rather than `201`, so a client can tell a
replay from a creation. Keys are scoped per user, so one caller's key can never
collide with another's or reveal that another's exists.

## 5. The write

One Firestore transaction performs, in order:

1. Read the idempotency key. If present, return the stored projection and stop.
2. Create `/practices/{practiceId}`.
3. Create `/practices/{practiceId}/members/{uid}` as the active owner.
4. Create `/users/{uid}/practiceRefs/{practiceId}`.
5. Append the audit event.
6. Record the idempotency key against the new `practiceId`.

Firestore transactions are atomic, so a crash at any point leaves no practice,
no orphan membership and no routing entry pointing at nothing.

The audit event is required by the data design's audit section, which mandates
one for membership creation. It records actor uid, practice, action, the
resulting safe authorisation state, correlation id and authentication
assurance, and never a raw token.

### 5.1 Ports and placement

Following the repository structure document, the command lives in a
`practice_management` context:

```text
contexts/practice_management/
  domain/aggregates/practice.ts
  application/commands/provision_practice.ts
  application/ports/practice_repository.ts
  application/ports/control_plane_projection.ts
  application/ports/audit_event_sink.ts
  adapters/inbound/http/practice_routes.ts
  adapters/outbound/persistence/firestore_practice_repository.ts
  index.ts
```

`platform/persistence/` gains the Firestore client, database selection and the
transaction runner, which that document assigns to `platform` rather than to a
context.

`ControlPlaneProjectionPort` is the seam. Today its adapter writes inside the
same transaction. When the control plane becomes a separate database, only that
adapter changes, and the contract gains an explicit statement that the
projection is eventually consistent. Nothing else in the command moves.

Domain and application code import no Firestore type, per the runtime platform
document's rule that domain and application code depend on no Google type.

## 6. Session enrichment

`GetSession` currently hardcodes `practiceRefs: []`. It gains a
`PracticeRefReaderPort`, reads `users/{uid}/practiceRefs`, and returns what it
finds, ordered by `displayLabel` so the list is stable between calls.

The response schema does not change. The Flutter client already parses
`practiceRefs` and already renders a no-practice state, so the visible effect is
that a provisioned user stops seeing that state.

Reading one's own projection requires no capability, as the data design states.
The actor's uid comes from the verified token, never from the request, so one
user cannot read another's list.

## 7. Firestore management

Three files enter the repository root: `firebase.json`, `firestore.indexes.json`
and `firestore.rules`.

The ruleset denies every client operation:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} { allow read, write: if false; }
  }
}
```

AGENTS.md forbids a feature reaching Firestore directly, every write here comes
from the Admin SDK, and the Admin SDK bypasses rules. A total denial is
therefore both correct today and a real backstop if a client SDK is ever added
without an architecture decision.

Indexes start empty. The only query, listing a user's own `practiceRefs`
ordered by `displayLabel`, is served by Firestore's automatic single-field
indexes.

The development database already exists: `(default)`, Native mode, in
`africa-south1`.

## 8. Errors

| Condition | Status | Code |
|---|---|---|
| Missing or unparseable body | 400 | `invalid_json` |
| `displayName` absent, empty, or longer than 120 characters | 400 | `validation_error` |
| Missing `Idempotency-Key` | 400 | `validation_error` |
| No ID token | 401 | `authentication_required` |
| Bad ID token | 401 | `token_invalid` |
| Missing or bad App Check token | 403 | `app_check_required` |
| Anything else | 500 | `internal_error` |

`validation_error` is already documented in the API design but not yet
implemented in `platform/http/problems.ts`; this slice adds it. Its detail names
the offending field and never echoes the submitted value.

## 9. Testing

- **Unit.** `ProvisionPractice` against in-memory ports: it writes all three
  records, sets the owner role, assigns the configured region, rejects an
  invalid name, and returns the stored projection on a replayed key.
- **Integration, Firestore emulator.** The repository adapter, which is where
  transactional behaviour actually lives: all-or-nothing on a mid-transaction
  failure, a replayed key creating exactly one practice, and two concurrent
  requests with the same key producing one practice and one `201` with one
  `200`. The DDD document already names the emulator for repository adapters.
- **Contract.** `POST /v1/practices` request and response against the schema,
  and each row of the error table.
- **Session.** `GetSession` returns the projections a user owns and never
  another user's.
- All 18 existing server tests stay green.

## 10. Additions to the identity and access data design

Each item below is something that document leaves open, decided here. Each
should be folded back into it, or corrected there, before this slice merges.

1. **The `Practice` record shape** (section 3.1). Not specified there.
2. **The `practiceRefs` projection fields** (section 3.3). Described there only
   as a minimal routing projection.
3. **The verification tier for practice creation** (section 4.3). Absent from
   its tier table; Standard proposed, with reasoning.
4. **Email verification is not required to found a practice** (section 4.3).
   The authentication design requires it to join as staff; founding is treated
   as a different act.
5. **Region is server-assigned** (section 4.2). Implied by treating client
   region as untrusted, but never stated for this command.
6. **What `version` means** (section 3.1). The data design places `version` on
   `PracticeMember` and `TaxpayerAccessGrant` without saying what it is for. It
   is the optimistic concurrency token behind the API's ETag, and it must change
   on every write. Stating this prevents the natural misreading that it is a
   schema stamp, which would lead to writing a constant and silently disabling
   lost-update protection.

## 11. Acceptance criteria

1. A signed-in user with a valid App Check token can create a practice and is
   its active owner.
2. The same request replayed with the same idempotency key creates exactly one
   practice and returns `200` on the replay.
3. Two concurrent identical requests produce one practice.
4. A failure part-way through leaves no practice, no membership and no routing
   entry.
5. `GET /v1/session` returns the new practice for its owner, and never returns
   it to any other user.
6. The Flutter welcome screen stops showing the no-practice state for a
   provisioned user, with no client change beyond running against the endpoint.
7. A client using a Firestore SDK directly is denied by rules.
8. Domain and application code contain no Firestore import.
9. A request whose body carries a region field has that field ignored, and the
   practice is created in the server-configured region.
10. Creating a practice writes exactly one audit event containing no raw token.
11. The practice and the member each carry a distinct concurrency token, and two
    writes never produce the same token. The routing projection carries none.
