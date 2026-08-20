# Founding Onboarding Design

- **Status:** Draft v0.2, server slice implemented; client slice planned
- **Owner:** Product and engineering
- **Last updated:** 20 August 2026
- **Related contracts:** [identity and access data design](../data_design/identity_access.md), [practice provisioning design](2026-08-20-practice-provisioning-design.md), [client-first authentication](../backend_design/authentication.md), [identity and access API](../api_design/identity_access.md), [repository and source structure](../backend_design/repository_structure.md)

## 1. Decision

Registration becomes real. Creating an account creates a Firebase user, and
finishing onboarding creates the practice that user owns.

Between those two moments the user is in a **persisted, resumable onboarding
state**. Abandoning the flow does not discard progress and does not strand an
account: the answers given so far are stored server-side, and the next sign-in
— on any device — resumes where the user left off. Until onboarding completes,
the application routes the user back to it.

This replaces the current registration flow, which collects four screens of
answers, saves none of them, tells the user "Your workspace is ready" and then
sends them to the sign-in page.

## 2. Scope

In scope:

1. `AuthService` gains account creation, with a Firebase and a preview
   implementation.
2. A persisted onboarding record per user, with answers saved as they are
   given.
3. `GET /v1/session` reports whether onboarding is outstanding, so the client
   can route.
4. `POST /v1/onboarding:complete` founds the practice and completes onboarding
   in one transaction.
5. The Flutter wizard drives all of the above and resumes from server state.

This is one design delivered as **two implementation plans, in order**. The
server cannot be wired to until it accepts the calls, and the server slice is
independently testable and shippable on its own: plan one is sections 3, 5, 6
and 7; plan two is sections 4.1 and 8. Section 9 splits along the same line.

Out of scope, each needing its own design:

- Editing onboarding answers after completion.
- Accepting an invitation to join an existing practice as an alternative way to
  complete onboarding. Section 4.4 states how this design stays compatible with
  it, and deliberately does not build it.
- Creating a second practice from inside the product. `POST /v1/practices`
  already exists for that and is unchanged.
- Acting on the answers. This slice records what the user said. Shaping the
  workspace around it is later work.
- Email verification gating. The authentication design requires verification to
  join a practice as staff, not to found one, and section 4.3 of the practice
  provisioning design already settled that.

## 3. The onboarding record

One document per user, in the control plane beside the routing projections that
already live there:

```text
/users/{uid}/onboarding/current
```

```ts
type OnboardingRecord = {
  uid: string;
  status: 'in_progress' | 'complete';
  answers: {
    practiceName?: string;
    practiceSize?: 'solo' | 'small_team' | 'growing_team';
    priorities?: Array<
      'deadlines' | 'documents' | 'teamwork' | 'visibility'
    >;
    startingPoint?:
      | 'import_clients'
      | 'add_first_client'
      | 'sample_workspace';
  };
  completedPracticeId?: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  version: string;
};
```

It sits under `users/{uid}` because it exists before any practice does, and
because it belongs to the person rather than to a workspace. It is global
control-plane data, like `practiceRefs`.

`version` is the optimistic concurrency token defined in section 3.0 of the
identity and access data design. This is the first record in Molo that a client
actually updates, so it is the first place `If-Match` does real work rather than
being documented and unused. Two tabs onboarding the same account is unlikely
but possible, and losing an answer silently is exactly what the token exists to
prevent.

### 3.1 No stored step

The record stores **answers, not a step**. There is no `priorities_pending`
field and no step counter.

A stored step enum welds the persisted contract to the wizard's current shape.
Reorder two screens, merge them, or add a question, and every in-flight record
needs migrating. Storing answers means the resume point is computed fresh from
what is present, so the wizard can change shape without touching stored data.

The wire may still name a step. `GET /v1/session` returns a `nextStep`, because
a client needs somewhere to navigate. That value is **derived per request and
never written down**, which is what makes it free to change.

### 3.2 Resume order and the completion invariant

Every answer is required. The resume point is the first one missing, in this
order:

| Order | Missing answer | `nextStep` |
|---|---|---|
| 1 | `practiceName` or `practiceSize` | `practice` |
| 2 | `priorities` (absent or empty) | `priorities` |
| 3 | `startingPoint` | `starting_point` |
| 4 | nothing | `ready_to_complete` |

`practiceName` and `practiceSize` share a step because the wizard collects them
on one screen.

The server enforces one invariant rather than policing transitions:

> **Onboarding cannot complete unless every required answer is present.**

That is the property worth protecting, and it holds regardless of the order the
client asks questions in. A client that submits all four answers in a single
`PATCH` and then completes is behaving correctly, not circumventing anything.

### 3.3 What "complete" means

Onboarding is complete when **either**:

- the record says `status: 'complete'`, or
- the user has at least one entry in `users/{uid}/practiceRefs`.

The second disjunct does two jobs. It makes every user who already has a
practice — including any created before this feature existed — complete without
a migration. And it is the seam through which accepting an invitation will later
complete onboarding without founding anything: a user who joins someone else's
practice gains a `practiceRef`, and is therefore done.

The stored `status` is still kept rather than being derived away entirely.
Losing access to a practice later must not push a user who has already onboarded
back into a wizard.

### 3.4 The founding answers

On completion the answers are copied to a record owned by the practice:

```text
/practices/{practiceId}/onboarding/founding
```

It holds the four answers plus `recordedAt` and the `uid` of the founder. It is
a point-in-time survey of what the founder said at the moment the practice was
created, and it is never updated. It carries no `version`, for the reason
section 3.0 of the data design gives: nothing updates it.

These answers are deliberately **not** fields on the `Practice` record.
`priorities` is an array, and putting arrays on the core practice record invites
queries this design does not want to support. `practiceSize` is arguably
practice configuration rather than survey data, and may be promoted onto
`Practice` later; promoting a field out of a survey record is easy, demoting one
off a core record that other code already reads is not.

## 4. Flow

### 4.1 Account creation

`AuthService` gains:

```dart
Future<AuthResult<AuthUser>> createAccount({
  required String email,
  required String password,
  required String displayName,
});
```

The Firebase implementation creates the user, sets the display name, and
reloads so `currentUser.displayName` is populated. The display name matters
beyond politeness: the welcome screen greets by name and deliberately refuses to
fall back to an email address, so an account created without one is greeted with
"Welcome back" forever.

The user is signed in the moment the account exists. That is Firebase's
behaviour and this design accepts it rather than fighting it — it is why
onboarding state has to be server-side and why the router needs section 5.

**Open question, to be answered before the client slice is planned.** This
project has improved email-enumeration protection enabled. It is not established
whether Firebase still answers `email-already-in-use` on sign-up under that
setting or returns something generic. The answer decides whether "that address
already has an account" can point at the email field or must be neutral copy.
The first task of the client plan verifies this against the real project. No
part of this design changes either way; only the copy and the error mapping do.

### 4.2 Saving answers

Each wizard step saves through `PATCH /v1/onboarding` before advancing. Answers
merge into the stored set, so the wizard's back button and a changed mind both
work without special handling.

The record is created lazily on the first `PATCH`. A user who creates an account
and closes the tab immediately has no onboarding document, which reads as "no
answers yet" and resumes at the first step.

### 4.3 Completion

`POST /v1/onboarding:complete` performs, in one Firestore transaction:

1. Read the idempotency key. If present, return the stored projection and stop.
2. Read the onboarding record and confirm every required answer is present.
3. Create the practice, the founding owner membership and the routing
   projection, through the existing `ProvisionPractice` command.
4. Write `/practices/{practiceId}/onboarding/founding`.
5. Mark the user's onboarding record `complete` and record
   `completedPracticeId`.
6. Append the audit event and record the idempotency key.

Because it is one transaction, a user cannot end up marked complete without a
practice, or with a practice while still being routed back into the wizard.

The endpoint returns the `PracticeRef`, so the client can navigate straight in
without a second round trip. A replayed idempotency key returns `200` with the
original projection; a first call returns `201`.

`POST /v1/practices` is unchanged and remains the way an already-onboarded user
creates an additional practice. Both endpoints run the same `ProvisionPractice`
command, so there is exactly one code path that can bring a practice into
existence.

### 4.4 Staying compatible with invitations

Nothing here assumes founding is the only way out of onboarding. Completion is
defined in section 3.3 as "has a practice", not "founded a practice". When
invitations arrive, accepting one writes a `practiceRef` and the invited user is
complete without ever seeing a practice-name field. The wizard will need a
branch at its first step; the persisted record and the gate will not change.

This is stated so the gate does not have to be redesigned the first time someone
is invited rather than founding.

## 5. The gate

`GET /v1/session` gains:

```ts
onboarding: {
  status: 'in_progress' | 'complete';
};
```

**One field, not two.** This section originally carried a derived `nextStep`
as well. Computing it needs `resumeStepFor`, which is `practice_management`
domain logic, and `identity_access` owns the session while
`practice_management` already imports `VerifiedActor` from it. Putting the step
on the session would therefore either close a dependency cycle or duplicate the
derivation and drift from it.

Neither is necessary. The only client that needs the step is the wizard, and
the wizard fetches `GET /v1/onboarding` when it opens regardless. The session
answers the gate question; the onboarding resource answers everything else.

The client already calls `/v1/session` on every start, so the gate costs no
additional round trip, and an onboarded user carries one extra field rather
than a draft they no longer care about.

`GetSession` checks for a practice before consulting the record, per section
3.3. An onboarded user therefore costs no second read on the hottest endpoint
in the system.

The router sends a signed-in user whose onboarding is incomplete to
`/onboarding`, from wherever they tried to go.

### 5.1 This gate is user experience, not access control

It must not be described as enforcement, because it is not, and pretending
otherwise would put weight on a client check.

A user mid-onboarding has no practice. Every regional endpoint requires an
active `PracticeMember`, which they do not have, so the existing deny-by-default
authorisation model already refuses them the entire application. The redirect
exists so they meet a wizard instead of an empty screen.

The one thing the server does enforce is the invariant in section 3.2: a client
cannot mark itself complete without answering.

### 5.2 Routes

`/sign-up` means "create an account" and remains reachable only when signed out.
`/onboarding` means "finish setting up" and is reachable only when signed in
with onboarding incomplete. The account step hands off to `/onboarding` once the
account exists.

Splitting them keeps each route's precondition simple enough to state in one
line, and means a resuming user is never shown an account form they have already
completed.

## 6. API

### 6.1 `GET /v1/onboarding`

Returns the record and its `version`, which the client needs for `If-Match`. A
user with no record receives a not-started shape with empty answers and no
`version`; nothing is written.

The session carries only status and next step, not the answers, so an onboarded
user never pays for a draft they finished with. The wizard fetches the answers
once when it opens.

**Response:** `200 OK`.

**Errors:** `401 authentication_required`, `401 token_invalid`,
`403 app_check_required`.

### 6.2 `PATCH /v1/onboarding`

```http
PATCH /v1/onboarding
If-Match: "<version>"
Content-Type: application/json

{ "answers": { "practiceName": "Mokoena Media Tax", "practiceSize": "solo" } }
```

Every answer is optional in the body and merges into the stored set. Unknown
body fields are refused rather than dropped, for the reason the practice
provisioning design gives in section 4.2. Each value is validated against its
enumeration; client-supplied values are untrusted.

`If-Match` is omitted on the first write, when no record exists yet. A first
write that finds a record already present is a lost update and answers
`428 version_required`.

**Response:** `200 OK` with the updated record and a fresh `version`.

**Errors:**

| Condition | Status | Code |
|---|---|---|
| Missing or unparseable body | 400 | `invalid_json` |
| Unknown field, bad enumeration, empty `priorities`, `practiceName` empty or over 120 characters | 400 | `validation_error` |
| No ID token | 401 | `authentication_required` |
| Bad ID token | 401 | `token_invalid` |
| Missing or bad App Check token | 403 | `app_check_required` |
| Onboarding already complete | 409 | `onboarding_already_complete` |
| `If-Match` does not match the stored version | 412 | `version_mismatch` |
| Record exists and `If-Match` was not sent | 428 | `version_required` |

### 6.3 `POST /v1/onboarding:complete`

```http
POST /v1/onboarding:complete
Idempotency-Key: <client-generated opaque key>
```

No body. Every input is already stored; accepting them again here would create
two sources of truth and a way to complete with answers that were never saved.

**Response:** `201 Created` with the `PracticeRef`, or `200 OK` for a replayed
key or an already-complete onboarding.

An already-complete onboarding answers with the practice named by
`completedPracticeId`. Section 3.3 allows a user to be complete with no record
at all — someone who had a practice before this feature existed — so when that
field is absent the endpoint answers with the caller's first routing
projection, ordered as `GET /v1/session` orders it. A complete onboarding is
never an error: the caller asked for a practice to exist and one does.

**Errors:**

| Condition | Status | Code |
|---|---|---|
| Missing `Idempotency-Key` | 400 | `validation_error` |
| No ID token | 401 | `authentication_required` |
| Bad ID token | 401 | `token_invalid` |
| Missing or bad App Check token | 403 | `app_check_required` |
| A required answer is missing | 409 | `onboarding_incomplete` |
| Anything else | 500 | `internal_error` |

`onboarding_incomplete` names which answer is missing through the problem's
`errors[].pointer` and never echoes a submitted value.

### 6.4 New problem codes

`platform/http/problems.ts` gains `version_mismatch` (412), `version_required`
(428), `onboarding_incomplete` (409) and `onboarding_already_complete` (409).
The first two are named in the API design's concurrency section but have never
been implemented, because until this record nothing was updatable.

## 7. Placement

The onboarding record and its endpoints belong to `practice_management`: their
purpose is founding a practice, and completion runs that context's existing
command.

```text
contexts/practice_management/
  domain/onboarding.ts              → answers, enumerations, resume derivation
  application/ports/onboarding_repository.ts
  application/commands/save_onboarding_answers.ts
  application/commands/complete_onboarding.ts
  application/queries/get_onboarding.ts
  adapters/inbound/http/onboarding_routes.ts
  adapters/outbound/persistence/firestore_onboarding_repository.ts
```

`GET /v1/session` lives in `identity_access` and must not import
`practice_management`. It reads the gate through a port in its own context —
`OnboardingStatusReader`, mirroring how `PracticeRefReader` already works — whose
adapter reads the same collection.

That port answers a single boolean, so nothing is duplicated except the
collection path. `users/{uid}/onboarding/current` is therefore read by an
adapter in each of the two contexts and belongs to the data design rather than
to either context's private business. It is recorded there for that reason.

Deriving the resume point is domain logic and lives in `domain/onboarding`, so
both the session gate and the completion check agree by construction rather than
by two implementations happening to match.

## 8. Client

The registration view model stops being a pure in-memory state machine and
becomes an asynchronous one over the API.

- **Step 1** calls `createAccount`, then navigates to `/onboarding`.
- **Steps 2–4** each `PATCH` before advancing, and surface a failure inline
  rather than advancing on an unsaved answer.
- **The final step** calls `:complete` with an idempotency key minted once when
  the wizard opens and held for the wizard's lifetime, so a retry after a
  timeout cannot found two practices.
- **On success** the client reloads the session, so `practiceRefs` is populated
  before `/home` renders, and the user never sees the no-practice state on the
  way in.
- **On open** the wizard fetches `GET /v1/onboarding` and starts at the derived
  step, whether that is a fresh signup or a resume from another device.

Preview mode keeps working without a backend: the preview services answer with
an in-memory onboarding record and a demo practice, exactly as
`PreviewSessionService` already answers with a demo session.

The completion screen's copy is corrected. It currently claims the workspace is
ready and then routes to sign-in; it will claim it and route to the workspace,
because by then it will be true.

## 9. Testing

- **Unit, server.** Resume derivation for every combination of missing answers.
  Answer validation, including an unknown enumeration value and empty
  priorities. The completion invariant: refuse to complete with any answer
  missing.
- **Unit, server.** The session gate: complete when the record says so, complete
  when the user has a practice and no record, in progress otherwise.
- **Integration, Firestore emulator.** The completion transaction is
  all-or-nothing. A replayed idempotency key founds one practice. Two concurrent
  completions found one practice. A conflicting `PATCH` loses to `If-Match`.
- **Contract.** Every row of both error tables, and the `201`/`200` distinction.
- **Unit and widget, client.** Account creation failure mapping. Each step
  saving before it advances. A resumed wizard opening at the derived step. A
  failed completion offering a retry that reuses the key.
- **Manual, and it needs a human.** Registering a real account end to end.
  Claude cannot create accounts, so this run has to be driven by a person, the
  same way the password entry was.

## 10. Additions to existing contracts

Each should be folded into the binding document as part of the work, not left
only here.

1. **The onboarding record shape** into the identity and access data design's
   section 3, beside the routing projection it sits next to.
2. **`onboarding` on the session** into the identity and access API's `Session`
   resource and its endpoint summary.
3. **The three endpoints** into the identity and access API.
4. **The four problem codes** into the API design's error catalogue.
5. **That the gate is experience rather than enforcement** into the data
   design's section 9, where API and application behaviour is stated. Written
   down explicitly, because a future reader who assumes the client enforces it
   might feel free to remove a server check.

## 11. Acceptance criteria

1. A new user can create an account, answer four screens, and arrive in a
   workspace that contains the practice they named.
2. Every answer is readable from the server immediately after the step that
   collected it, before onboarding completes.
3. Closing the browser mid-onboarding and signing in again on a different device
   resumes at the step that was next, with earlier answers intact.
4. A signed-in user with incomplete onboarding who navigates to `/home`,
   `/sign-in` or an unknown route arrives at `/onboarding`.
5. Completion creates exactly one practice, one owner membership, one routing
   projection, one founding-answers record and one audit event.
6. A completion that fails part-way leaves onboarding incomplete and no
   practice.
7. Two concurrent completions with the same idempotency key produce one
   practice, one `201` and one `200`.
8. A `PATCH` with a stale `If-Match` is refused with `412` and does not
   overwrite.
9. A `PATCH` carrying an unknown answer value is refused with `400`, and the
   detail does not echo the value.
10. `:complete` with any required answer missing is refused with `409` and names
    the missing answer as a pointer.
11. A user who already has a practice and no onboarding record is reported
    complete and is never routed into the wizard.
12. The completion screen no longer claims a workspace is ready and then routes
    to sign-in.
13. Preview mode completes the whole flow with no backend.
