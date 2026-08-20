# Identity and Access API

- **Status:** Draft v0.1
- **Base contract:** [API Design](README.md)
- **Domain owner:** Identity and access

This domain identifies the caller, resolves the caller's authorised practices, and manages practice membership and taxpayer access. It does not own practice settings or taxpayer records.

## Resources

```ts
type Session = {
  user: {
    uid: string;
    displayName?: string;
    emailMasked?: string;
    preferredLocale?: string;
  };
  practiceRefs: Array<{
    practiceId: string;
    displayLabel: string;
    homeRegionKey: string;
    routeVersion: number;
    accessStatus: 'active' | 'invited' | 'suspended';
  }>;
  onboarding: {
    status: 'in_progress' | 'complete';
  };
};

type Onboarding = {
  status: 'in_progress' | 'complete';
  nextStep?: 'practice' | 'priorities' | 'starting_point' | 'ready_to_complete';
  answers: {
    practiceName?: string;
    practiceSize?: 'solo' | 'small_team' | 'growing_team';
    priorities?: Array<'deadlines' | 'documents' | 'teamwork' | 'visibility'>;
    startingPoint?: 'import_clients' | 'add_first_client' | 'sample_workspace';
  };
  version?: string;
};

type PracticeRoute = {
  practiceId: string;
  regionKey: string;
  routeVersion: number;
  apiBaseUrl: string;
  expiresAt: string;
};

type PracticeMember = {
  practiceId: string;
  uid: string;
  role: 'owner' | 'admin' | 'manager' | 'practitioner' | 'reviewer' | 'assistant';
  status: 'invited' | 'active' | 'suspended' | 'removed';
  displayName: string;
  emailMasked: string;
  capabilityOverrides?: Record<string, boolean>;
  joinedAt?: string;
  updatedAt: string;
  version: string;
};

type TaxpayerAccessGrant = {
  taxpayerId: string;
  uid: string;
  role: 'self' | 'director' | 'trustee' | 'representative' | 'viewer' | 'uploader';
  scopes: Array<'taxpayer.read' | 'workItems.read' | 'documentRequests.read' | 'documents.read' | 'documents.upload' | 'requests.respond'>;
  status: 'invited' | 'active' | 'suspended' | 'expired' | 'revoked';
  validFrom?: string;
  validTo?: string;
  version: string;
};

type AuthProvider = {
  providerId: 'password' | 'google.com' | string;
  kind: 'email_password' | 'federated';
  displayNameKey: string;
  availability: 'available' | 'coming_soon' | 'unavailable';
  enabledPlatforms: Array<'android' | 'ios' | 'web'>;
  supportsLinking: boolean;
  sortOrder: number;
};
```

The `practiceRefs` entry above is the `PracticeRef` that `POST /v1/practices`
returns, and it is stored in that exact shape. It carries no `version`: it is a
server-owned derived projection that no client updates, so there is no
`If-Match` for a token to protect.

`displayLabel` is the only practice presentation snapshot allowed in the control plane. It must not include taxpayer, work, document or connector information.

## Endpoint summary

| Method | Path | Plane | Capability | Concurrency |
|---|---|---|---|---|
| `GET` | `/v1/auth/providers` | Global | Public safe configuration; App Check where available | — |
| `GET` | `/v1/session` | Global | Authenticated user | — |
| `POST` | `/v1/session:resolve-practice` | Global | Authorised practice reference | — |
| `POST` | `/v1/practices` | Global | Authenticated user; no capability | Idempotency key |
| `GET` | `/v1/onboarding` | Global | Authenticated user; own record only | — |
| `PATCH` | `/v1/onboarding` | Global | Authenticated user; own record only | `If-Match` required |
| `POST` | `/v1/onboarding:complete` | Global | Authenticated user; no capability | Idempotency key |
| `GET` | `/v1/practices/{practiceId}/members` | Regional | `members.read` | — |
| `POST` | `/v1/practices/{practiceId}/invitations` | Regional | `members.invite` | Idempotency key |
| `POST` | `/v1/invitations:accept` | Global edge | Valid invite + authenticated user | Idempotency key |
| `PATCH` | `/v1/practices/{practiceId}/members/{uid}` | Regional | `members.manage` | `If-Match` required |
| `POST` | `/v1/practices/{practiceId}/taxpayers/{taxpayerId}/access-grants` | Regional | `taxpayerAccess.manage` | Idempotency key |
| `PATCH` | `/v1/practices/{practiceId}/taxpayers/{taxpayerId}/access-grants/{uid}` | Regional | `taxpayerAccess.manage` | `If-Match` required |
| `POST` | `/v1/practices/{practiceId}/taxpayers/{taxpayerId}/access-grants/{uid}:revoke` | Regional | `taxpayerAccess.manage` | `If-Match` + idempotency key |

## `GET /v1/auth/providers`

Returns the safe authentication-method catalogue for the caller's platform and app version. Optional query fields are `platform`, `appVersion` and `invitationToken`. The invitation token may narrow enterprise-provider choices but must not reveal practice membership or provider configuration secrets.

```json
{
  "data": {
    "providers": [
      {
        "providerId": "password",
        "kind": "email_password",
        "displayNameKey": "auth.provider.emailPassword",
        "availability": "available",
        "enabledPlatforms": ["android", "ios", "web"],
        "supportsLinking": true,
        "sortOrder": 10
      },
      {
        "providerId": "google.com",
        "kind": "federated",
        "displayNameKey": "auth.provider.google",
        "availability": "coming_soon",
        "enabledPlatforms": ["android", "ios", "web"],
        "supportsLinking": true,
        "sortOrder": 20
      }
    ]
  },
  "meta": {
    "apiVersion": "v1",
    "requestId": "req_opaque",
    "correlationId": "cor_opaque"
  }
}
```

The client shows a provider only when it has a compiled adapter and the provider supports the current platform. `coming_soon` is a visible but non-interactive product stub: it must not begin an SDK, redirect or popup flow. `unavailable` is normally omitted from the interface unless explaining a temporary method outage is useful. The response never contains client secrets, signing certificates, unrestricted redirect URIs or internal tenant configuration.

**Response:** `200 OK`.

**Errors:** `400 unsupported_platform`, `426 client_upgrade_required`.

## `GET /v1/session`

Returns the caller's identity and minimal authorised-practice directory. Suspended references may be returned so the interface can explain that access exists but is unavailable; removed or revoked references are omitted.

**Response:** `200 OK` with `Session`.

**Errors:** `401 authentication_required`, `403 app_check_required`.

## `POST /v1/practices`

Creates a practice and makes the caller its first owner. This is how a practice
comes into existence, and therefore how `practiceRefs` in `GET /v1/session`
stops being empty.

No capability is required: the actor creates a practice they will own, touching
no existing practice and no other person's access. The tier is Standard, and a
verified email is deliberately not required — that requirement belongs to
joining someone else's practice as staff, which is a different act.

```http
POST /v1/practices
Authorization: Bearer <firebase id token>
X-Firebase-AppCheck: <app check token>
Idempotency-Key: <client-generated opaque key>
Content-Type: application/json

{ "displayName": "Mokoena Media Tax" }
```

`displayName` is the only accepted field. The request body carries **no
region**: `homeRegionKey` is assigned by the server from its own configuration,
because a client-supplied region is untrusted input and honouring one would let
a caller place a practice in a jurisdiction they were never granted. An unknown
body field is refused with `400 validation_error` rather than silently dropped,
so a client learns immediately that a field it believes it is sending has no
effect.

**Response:** `201 Created` with the caller's new `PracticeRef`, the same shape
`GET /v1/session` lists. Returning the projection rather than a bare identifier
lets a client navigate straight into the new practice without a second round
trip.

```json
{
  "data": {
    "practiceId": "prc_opaque",
    "displayLabel": "Mokoena Media Tax",
    "homeRegionKey": "za1",
    "routeVersion": 1,
    "accessStatus": "active"
  },
  "meta": {
    "apiVersion": "v1",
    "requestId": "req_opaque",
    "correlationId": "cor_opaque"
  }
}
```

A repeated `Idempotency-Key` from the same caller answers `200 OK` with the
original projection, so a client can tell a replay from a creation. Keys are
scoped per user, so one caller's key can never collide with another's or reveal
that another's exists. Two calls with *different* keys create two practices,
deliberately: a user may own several, which the session's list and the
`selecting_practice` state already anticipate.

The practice, its founding owner membership, the routing projection and the
audit event are written in one transaction. A practice without an owner or
without a routing entry cannot exist.

**Errors:**

| Condition | Status | Code |
|---|---|---|
| Missing or unparseable body | 400 | `invalid_json` |
| `displayName` absent, empty, longer than 120 characters, or an unknown field present | 400 | `validation_error` |
| Missing `Idempotency-Key` | 400 | `validation_error` |
| No ID token | 401 | `authentication_required` |
| Bad ID token | 401 | `token_invalid` |
| Missing or bad App Check token | 403 | `app_check_required` |
| Anything else | 500 | `internal_error` |

No error detail echoes a submitted value.

## `GET /v1/onboarding`

Returns the caller's own setup progress and the concurrency token the next
save must echo. A user who has answered nothing receives a not-started shape
with empty answers and no `version`; nothing is written.

`nextStep` is derived per request from which answers are present, never
stored. That is what lets the sign-up wizard change shape without migrating
in-flight records. It is absent once `status` is `complete`.

**Response:** `200 OK` with `Onboarding`.

**Errors:** `401 authentication_required`, `401 token_invalid`,
`403 app_check_required`.

## `PATCH /v1/onboarding`

```http
PATCH /v1/onboarding
If-Match: "<version>"
Content-Type: application/json

{ "answers": { "practiceName": "Mokoena Media Tax", "practiceSize": "solo" } }
```

Every answer is optional and merges into the stored set, so the wizard's back
button and a changed mind need no separate path. Unknown fields are refused
rather than dropped. Each value is validated against its enumeration;
client-supplied values are untrusted.

`If-Match` is omitted only on the first write, when no record exists. A write
that finds a record already present and carries no version is a lost update
and answers `428`.

**Response:** `200 OK` with `Onboarding` and a fresh `version`.

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

## `POST /v1/onboarding:complete`

```http
POST /v1/onboarding:complete
Idempotency-Key: <client-generated opaque key>
```

No body. Every input is already stored; accepting them again here would create
two sources of truth and a way to finish with answers that were never saved.

Creates the practice, the founding owner membership, the routing projection,
the founding-answers record and the audit event, and marks onboarding
complete — all in one transaction. A practice whose onboarding still says it is
outstanding therefore cannot exist.

**Response:** `201 Created` with the new `PracticeRef`, or `200 OK` for a
replayed key or an onboarding that was already complete.

**Errors:**

| Condition | Status | Code |
|---|---|---|
| Missing `Idempotency-Key` | 400 | `validation_error` |
| No ID token | 401 | `authentication_required` |
| Bad ID token | 401 | `token_invalid` |
| Missing or bad App Check token | 403 | `app_check_required` |
| A required answer is missing | 409 | `onboarding_incomplete` |
| Anything else | 500 | `internal_error` |

`onboarding_incomplete` names each missing answer through the problem's
`errors[].pointer`. No error detail ever echoes a submitted value.

`version_mismatch` and `version_required` are the concurrency mechanism
section 7 of the [API design README](README.md) describes. The onboarding
record is the first resource in Molo a client updates, so this is their first
use.

## `POST /v1/session:resolve-practice`

This is a non-mutating route resolution, so it does not require an idempotency key.

```json
{
  "practiceId": "prc_opaque",
  "knownRouteVersion": 4
}
```

**Response:** `200 OK` with `PracticeRoute`. The returned API URL must come from trusted region configuration, use HTTPS, and have a short cache lifetime. Database and bucket identifiers are not exposed because Flutter does not access them directly.

**Errors:**

- `403 practice_access_suspended` — caller has a reference but cannot enter;
- `404 resource_not_found` — no visible practice reference exists;
- `409 practice_migrating` — route is temporarily frozen during an audited migration.

## `POST /v1/practices/{practiceId}/invitations`

```json
{
  "email": "person@example.com",
  "role": "practitioner",
  "capabilityOverrides": {},
  "expiresInHours": 72,
  "message": "Optional human invitation message"
}
```

The server normalises the email, prevents inviting an active member twice, checks that the inviter may grant the requested role/capabilities, and sends an opaque single-use token. The raw token is never returned to list endpoints or audit logs.

**Response:** `201 Created` with invitation ID, masked email, role, status and expiry.

**Events:** `member.invited.v1`.

**Errors:** `409 member_already_active`, `422 role_not_grantable`, `422 invalid_expiry`.

## `POST /v1/invitations:accept`

```json
{
  "token": "single_use_secret",
  "displayName": "Naledi Mokoena"
}
```

The global edge resolves the opaque token to its regional cell without persisting practice data globally, then executes acceptance regionally. Acceptance binds the invitation to the authenticated user's verified email rules; email mismatch behaviour must not reveal the invited address.

**Response:** `200 OK` with the new `PracticeMember` and a fresh `PracticeRoute`.

**Events:** `member.joined.v1`.

**Errors:** `409 invitation_used`, `410 invitation_expired`, `422 invitation_identity_mismatch`.

## `PATCH /v1/practices/{practiceId}/members/{uid}`

Allowed fields:

```json
{
  "role": "reviewer",
  "status": "active",
  "capabilityOverrides": {
    "documents.review": true
  },
  "reason": "Moved into the review team"
}
```

Owner transfer is not permitted through this endpoint. A caller cannot grant capabilities they do not hold. Suspending or removing the last active owner is rejected.

**Response:** `200 OK` with updated `PracticeMember` and `ETag`.

**Events:** `member.access_changed.v1`.

**Errors:** `409 last_owner_required`, `422 capability_not_grantable`, `422 owner_transfer_requires_dedicated_flow`.

## Taxpayer access grants

Creation request:

```json
{
  "email": "representative@example.com",
  "role": "representative",
  "scopes": ["taxpayer.read", "workItems.read", "documentRequests.read", "documents.upload", "requests.respond"],
  "validFrom": "2026-08-19T00:00:00Z",
  "validTo": "2027-08-19T00:00:00Z",
  "authorityEvidenceDocumentIds": ["doc_opaque"]
}
```

Updating a grant may change role, scopes, dates or status. Revocation is a dedicated action because it immediately ends portal access and must capture a reason. A grant never expands to related taxpayers or portfolio members.

**Creation response:** `201 Created` with `TaxpayerAccessGrant`.

**Revocation request:** `{ "reason": "Representation ended" }`.

**Events:** `taxpayer_access.invited.v1`, `taxpayer_access.changed.v1`, `taxpayer_access.revoked.v1`.

**Errors:** `409 grant_already_active`, `422 invalid_scope_for_role`, `422 invalid_validity_period`, `422 evidence_required`.

## Security and audit rules

- Member email is masked in normal responses; full email access requires a separately authorised view.
- Membership and grants are resolved from the regional database on every consequential command. The capability catalogue, default role bundles, resource scopes and delegation limits are defined in the [Identity and Access Data Design](../data_design/identity_access.md).
- Invitations, role changes, capability overrides, suspension and revocation always create audit events.
- Authentication-factor setup, password reset and provider linking remain Firebase Authentication flows and are not reimplemented by this API.

## Contract tests

1. A user cannot resolve a practice absent from their session directory.
2. A valid user sent to a stale regional route receives `421`, then succeeds after route resolution.
3. Replaying an invitation creation with the same key and payload creates one invitation.
4. A manager cannot grant an owner-only capability.
5. Revoking access to Taxpayer A does not affect a separate grant for Taxpayer B.
