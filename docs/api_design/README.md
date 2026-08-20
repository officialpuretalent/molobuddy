# Molo API Design

- **Status:** Draft v0.1
- **Contract version:** `v1`
- **Owner:** Product and engineering
- **Last updated:** 19 August 2026

This directory is the source of truth for Molo endpoint behaviour. It specifies observable contracts independently of whether an endpoint is hosted by Cloud Functions, Cloud Run or a future compatible runtime.

The [product glossary](../product/glossary.md) controls names. The [system architecture](../product/system_architecture.md) controls regional placement, tenancy, security and event-processing boundaries.

## Domain contracts

| Domain | Contract | Primary resources |
|---|---|---|
| Identity and access | [`identity_access.md`](identity_access.md) | Session, regional route, members, invitations and access grants |
| Practices | [`practices.md`](practices.md) | Practice and practice settings |
| Taxpayers | [`taxpayers.md`](taxpayers.md) | Taxpayers, client relationships, relationships, activities, registrations and portfolios |
| Tax work | [`tax_work.md`](tax_work.md) | Work items and tasks |
| Documents | [`documents.md`](documents.md) | Requests, uploads, documents, versions and links |
| Workflows | [`workflows.md`](workflows.md) | Workflow templates, deadlines and reminder policies |
| Notifications | [`notifications.md`](notifications.md) | Notification inbox, preferences and inbound email |
| Connectors | [`connectors.md`](connectors.md) | Connector definitions, connections, OAuth, webhooks and sync runs |
| Intelligence | [`intelligence.md`](intelligence.md) | Intelligence runs, extraction proposals and human reviews |
| Audit | [`audit.md`](audit.md) | Audit-event queries and evidence exports |

## 1. Contract style

Molo uses versioned JSON over HTTPS:

- resource-oriented paths for creation, retrieval and allowed field updates;
- explicit action endpoints for state transitions, approvals, sending, revocation and other consequential commands;
- plural, lower-kebab-case path segments;
- `camelCase` JSON fields and `snake_case` enum values;
- opaque string identifiers; callers must not infer type, region or creation time from an ID;
- `/v1` path versioning; additive fields do not require a new major version.

The canonical v1 client contract is HTTP. Molo does not add a parallel Firebase callable surface; Web, Android and iOS use the same generated API contract.

## 2. API planes and regional routing

Molo exposes two logical planes:

| Plane | Purpose | Data boundary |
|---|---|---|
| Global control API | Session bootstrap and authorised practice-route resolution | Identity and minimal routing metadata only |
| Regional API | All practice, taxpayer, tax-work, document and connector operations | The selected practice's home-region cell |

Conceptual bases:

```text
https://control.api.molo.example/v1
https://{regionKey}.api.molo.example/v1
```

`.example` is a documentation placeholder, not a DNS decision.

The client first calls `GET /v1/session`, then resolves the selected practice through `POST /v1/session:resolve-practice`. It must use only the returned regional base URL. Regional endpoints independently resolve `practiceId → homeRegionKey` and return `421 Misdirected Request` with code `region_route_mismatch` if the route is stale or wrong. The caller then re-runs route resolution; the error does not disclose another practice's route.

`homeRegionKey` is never accepted as an operational request field. Practice relocation is a separate audited migration, not an endpoint update.

## 3. Authentication and standard headers

Unless an endpoint is explicitly public, requests require:

```http
Authorization: Bearer <Firebase ID token>
X-Firebase-AppCheck: <App Check token>
Accept: application/json, application/problem+json
Content-Type: application/json
Accept-Language: en-ZA
X-Correlation-Id: <optional caller-generated opaque ID>
```

Mutation requests also use:

```http
Idempotency-Key: <required opaque key for POST commands>
If-Match: "<resourceVersion>"  # required where a contract marks it required
```

The backend verifies Firebase ID tokens and App Check tokens; identity is never accepted from a JSON field. `Accept-Language` affects human-readable messages only, never stable codes or business rules. [Firebase ID-token verification](https://firebase.google.com/docs/auth/admin/verify-id-tokens) · [Firebase App Check for custom backends](https://firebase.google.com/docs/app-check/web/custom-resource)

## 4. Success contract

Every JSON success uses:

```json
{
  "data": {},
  "meta": {
    "apiVersion": "v1",
    "requestId": "req_opaque",
    "correlationId": "cor_opaque"
  }
}
```

Creation returns `201 Created` and a `Location` header. Accepted asynchronous work returns `202 Accepted` with a status resource. Updates return a strong `ETag` containing the new opaque resource version. Commands may return `200 OK` when the updated representation is useful or `204 No Content` when it is not.

## 5. Collection contract

Collection endpoints accept only documented filters and sorts:

```text
?limit=50&cursor=<opaque>&sort=-updatedAt&status=active
```

- default `limit`: 50;
- maximum `limit`: 100;
- `cursor`: opaque and bound to the original filter, sort, actor and practice;
- stable ordering always includes the resource ID as a final tie-breaker;
- unknown filter or sort fields return `400 invalid_query`.

Collection metadata:

```json
{
  "data": [],
  "meta": {
    "apiVersion": "v1",
    "requestId": "req_opaque",
    "correlationId": "cor_opaque",
    "nextCursor": "cur_opaque",
    "hasMore": true
  }
}
```

## 6. Error contract

Errors use `application/problem+json` following RFC 9457:

```json
{
  "type": "https://api.molo.example/problems/validation-error",
  "title": "The request is not valid.",
  "status": 422,
  "detail": "Correct the highlighted fields and try again.",
  "instance": "/v1/problems/prb_opaque",
  "code": "validation_error",
  "correlationId": "cor_opaque",
  "errors": [
    {
      "pointer": "/taxpayerId",
      "code": "required",
      "message": "Choose a taxpayer."
    }
  ]
}
```

Clients branch on `code` and field-error `code`, never on `title`, `detail` or `message`. Problem details never expose stack traces, provider secrets, document contents, tax identifiers or whether an inaccessible resource exists. [RFC 9457](https://www.rfc-editor.org/rfc/rfc9457.html)

### Standard status mapping

| Status | Stable code examples | Meaning |
|---|---|---|
| `400` | `invalid_json`, `invalid_query` | Request cannot be parsed or query shape is unsupported |
| `401` | `authentication_required`, `token_invalid` | Identity is missing or invalid |
| `403` | `capability_required`, `app_check_required` | Authenticated caller lacks authority or app attestation |
| `404` | `resource_not_found` | Resource is absent or deliberately hidden from this caller |
| `409` | `state_conflict`, `idempotency_conflict` | Current domain state conflicts with the command |
| `410` | `resource_expired` | A time-bound invitation, session or export is no longer usable |
| `412` | `version_mismatch` | `If-Match` does not match the current resource version |
| `413` | `payload_too_large` | Request or file exceeds its documented maximum size |
| `421` | `region_route_mismatch` | Request reached the wrong regional API |
| `422` | `validation_error`, `jurisdiction_rule_violation` | Parsed request violates field or domain rules |
| `426` | `client_upgrade_required` | The installed client cannot safely support the requested contract/provider |
| `428` | `version_required` | Required `If-Match` header is missing |
| `429` | `rate_limited`, `quota_exceeded` | Caller must slow down or has exceeded a plan limit |
| `500` | `internal_error` | Unexpected safe failure |
| `503` | `dependency_unavailable` | Temporary regional or provider dependency failure |

## 7. Idempotency, concurrency and retries

- Every create or action `POST` marks whether `Idempotency-Key` is required; it is required by default.
- The key is scoped to actor, practice, method and canonical path.
- Replaying the same key with the same canonical payload returns the original status and response.
- Reusing a key with a different payload returns `409 idempotency_conflict`.
- Idempotency records never persist raw secrets, access tokens or signed URLs. For a response containing a short-lived URL, a replay returns the same underlying resource/session and may mint a fresh equivalent URL without repeating the business effect.
- Keys are retained for at least 24 hours; longer-running or financial/legal commands may define a longer period.
- A caller may retry `GET`, `HEAD` and an idempotent mutation after a network failure.
- `PATCH` and state-changing actions marked `If-Match: required` use strong entity tags to prevent lost updates. A mismatch returns `412` without applying the command. [RFC 9110: If-Match](https://www.rfc-editor.org/rfc/rfc9110.html#name-if-match)
- The `version` field carried by every resource representation **is** that entity tag: the opaque optimistic-concurrency token an `ETag` returns and `If-Match` is compared against. It is not a document schema stamp, which is `schemaVersion`. A server regenerates `version` on every write. A constant value would make every `If-Match` comparison succeed and silently remove the protection this section describes, so a resource that is never updated by a caller carries no `version` at all rather than a placeholder.

## 8. Dates, localisation and protected values

- Instant: RFC 3339 UTC string, for example `2026-08-19T14:05:00Z`.
- Calendar date without time: `YYYY-MM-DD`.
- Time zone: IANA identifier, for example `Africa/Johannesburg`.
- Locale: BCP 47 tag, for example `en-ZA`.
- Currency: ISO 4217 code.
- Money: `{ "amountMinor": "12500", "currency": "ZAR" }`; `amountMinor` is a signed base-10 integer string, never a floating-point amount.
- Jurisdiction: explicit `jurisdictionCode`; never inferred from locale, route or currency.
- Protected identifiers: masked by default and returned in full only from an explicitly authorised reveal flow that is separately audited.

All names are Unicode. APIs must not require Western first-name/last-name structures. Postal addresses and telephone numbers use the data-design contract for their country-aware structure.

## 9. Authorisation and audit

Every regional request derives the actor from the verified token and resolves authoritative membership or taxpayer access inside the selected regional database. A supplied `practiceId`, `uid`, `regionKey`, role or capability is never trusted as authority.

Every meaningful mutation records:

- actor and acting context;
- practice and regional cell;
- command and target;
- correlation and idempotency keys;
- jurisdiction code where relevant;
- safe before/after field names;
- reason for privileged actions.

## 10. Compatibility rules

Within `v1`, the API may add optional response fields, enum values documented as open, new endpoints and optional request fields with defaults. It must not rename or remove fields, change field meaning, make an optional input required, reuse an enum value, or change authorisation semantics without a new major version or an explicitly versioned endpoint.

Consumers must ignore unknown response fields. They must handle unknown enum values using an `unknown` fallback unless the domain contract marks an enum as closed for safety.

## 11. Health endpoint

`GET /health` is public and regional. It returns only service status, release identifier and region key—never dependency names, tenant counts or secrets.

```json
{
  "status": "ok",
  "regionKey": "za1",
  "release": "2026.08.19.1"
}
```

## 12. Contract completion rule

An endpoint is ready for implementation only when its domain file defines:

1. method and path;
2. authentication and capability;
3. idempotency and concurrency behaviour;
4. request fields and validation;
5. success status and response fields;
6. domain-specific errors;
7. emitted events and audit effect;
8. regional and data-residency behaviour;
9. automated contract-test examples.

## 13. Open design decisions

These decisions remain intentionally unresolved in draft v0.1:

1. production API hostnames and certificate/DNS ownership;
2. which screens, if any, require a server-owned realtime subscription transport beyond v1 HTTP reads;
3. default and plan-specific upload limits by document type;
4. exact idempotency retention periods beyond the 24-hour minimum;
5. step-up authentication policy for identifier reveal, exports and other privileged actions;
6. the production problem-type URI base;
7. promotion of the approved Markdown contracts into OpenAPI and generated TypeScript/Dart clients.

Resolving one item must not weaken the regional, authorisation, vocabulary or audit rules already fixed by this contract.
