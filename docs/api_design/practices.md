# Practices API

- **Status:** Draft v0.1
- **Base contract:** [API Design](README.md)
- **Domain owner:** Practices

This domain owns the practice as Molo's tenant, including onboarding defaults, public identity, regional assignment and lifecycle. Membership belongs to [Identity and Access](identity_access.md).

## Resource

```ts
type Practice = {
  practiceId: string;
  name: string;
  slug: string;
  status: 'trial' | 'active' | 'suspended' | 'closing' | 'closed';
  homeRegionKey: string;
  defaultJurisdictionCode: string;
  enabledJurisdictionCodes: string[];
  timezone: string;
  defaultLocale: string;
  defaultCurrency: string;
  dataResidencyPolicyVersion: string;
  branding: {
    logoDocumentId?: string;
    primaryColour?: string;
  };
  plan: { code: string; limitsVersion: number };
  createdAt: string;
  updatedAt: string;
  version: string;
};
```

## Endpoint summary

| Method | Path | Plane | Capability | Concurrency |
|---|---|---|---|---|
| `POST` | `/v1/practices` | Global orchestration | Authenticated user | Idempotency key |
| `GET` | `/v1/practices/{practiceId}` | Regional | `practice.read` | — |
| `PATCH` | `/v1/practices/{practiceId}` | Regional | `practice.manage` | `If-Match` required |
| `POST` | `/v1/practices/{practiceId}:request-closure` | Regional | `practice.close` | `If-Match` + idempotency key |
| `POST` | `/v1/practices/{practiceId}:cancel-closure` | Regional | `practice.close` | `If-Match` + idempotency key |

## `POST /v1/practices`

```json
{
  "name": "Mokoena Tax Studio",
  "requestedHomeRegionKey": "za1",
  "defaultJurisdictionCode": "ZA",
  "enabledJurisdictionCodes": ["ZA"],
  "timezone": "Africa/Johannesburg",
  "defaultLocale": "en-ZA",
  "defaultCurrency": "ZAR",
  "acceptedResidencyPolicyVersion": "za1-2026-08"
}
```

The global orchestrator validates that the region is offered, the jurisdiction pack is active in that region, and the caller accepted the applicable residency terms. It creates the route, regional practice and owner membership as one idempotent provisioning workflow. Success is returned only when all authoritative records are usable; incomplete attempts are repaired or safely rolled back before retry.

`requestedHomeRegionKey` is accepted only during creation and only from the published region catalogue. It is not accepted by any update endpoint.

**Response:** `201 Created` with `Practice`, owner-membership summary and `PracticeRoute`.

**Events:** `practice.created.v1`.

**Errors:** `409 slug_unavailable`, `422 region_not_available`, `422 jurisdiction_not_supported`, `422 residency_policy_not_accepted`.

## `GET /v1/practices/{practiceId}`

Returns the practice representation appropriate to the caller. Plan limits and internal feature flags are visible only to members with settings authority. Portal users do not receive a practice-settings representation.

**Response:** `200 OK` with `Practice` and `ETag`.

## `PATCH /v1/practices/{practiceId}`

Allowed fields:

```json
{
  "name": "Mokoena Global Tax",
  "slug": "mokoena-global-tax",
  "defaultJurisdictionCode": "ZA",
  "enabledJurisdictionCodes": ["ZA", "GB"],
  "timezone": "Africa/Johannesburg",
  "defaultLocale": "en-ZA",
  "defaultCurrency": "ZAR",
  "branding": {
    "logoDocumentId": "doc_opaque",
    "primaryColour": "#2457FF"
  }
}
```

The API rejects `homeRegionKey`, `status`, `plan`, `dataResidencyPolicyVersion` and feature flags in this general patch. Enabling a jurisdiction requires an active jurisdiction pack in the cell. Changing the default locale never changes tax jurisdiction, currency, timezone or deadlines.

**Response:** `200 OK` with updated `Practice` and `ETag`.

**Events:** `practice.settings_changed.v1`; `practice.jurisdiction_enabled.v1` when applicable.

**Errors:** `409 slug_unavailable`, `422 immutable_field`, `422 jurisdiction_not_supported`, `422 locale_not_supported`.

## Closure actions

Request:

```json
{
  "reason": "Practice has ceased trading",
  "requestedClosureDate": "2026-09-30",
  "exportRequired": true
}
```

Requesting closure changes the practice to `closing`, revokes new invitations and connector authorisations according to policy, and creates export/deletion work. It does not immediately delete records. The response includes the closure state and any blocking obligations.

Cancellation is allowed only before irreversible deletion begins:

```json
{
  "reason": "Closure request withdrawn"
}
```

**Responses:** `202 Accepted` with closure operation status.

**Events:** `practice.closure_requested.v1`, `practice.closure_cancelled.v1`.

**Errors:** `409 closure_already_started`, `409 irreversible_deletion_started`, `422 export_destination_required`.

## Invariants

- Every practice has exactly one home region at a time.
- A practice always has at least one active owner until closure reaches its irreversible stage.
- A default jurisdiction must be present in `enabledJurisdictionCodes`.
- Locale, currency, timezone, market and tax jurisdiction remain independent settings.
- Slugs are presentation identifiers, not authorisation boundaries.
- Regional migration is intentionally absent from `v1`; it requires an internal audited runbook and a future dedicated contract.

## Contract tests

1. Replaying practice creation returns the same practice and route.
2. The API rejects a general patch containing `homeRegionKey`.
3. Enabling `GB` fails if its jurisdiction pack is unavailable in the selected cell.
4. Changing `defaultLocale` leaves registrations and calculated deadlines unchanged.
5. Closure cannot remove the audit trail before the applicable retention period.
