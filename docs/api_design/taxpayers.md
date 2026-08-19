# Taxpayers API

- **Status:** Draft v0.1
- **Base contract:** [API Design](README.md)
- **Domain owner:** Taxpayers

This domain owns taxpayer identity and structure. A taxpayer is one natural person or independently responsible organisation. A client relationship describes the practice's service relationship with that taxpayer; portfolios and relationships never merge legal responsibility or access.

## Core representations

```ts
type Taxpayer = {
  taxpayerId: string;
  kind: 'natural_person' | 'registered_organisation' | 'trust' | 'other';
  displayName: string;
  legalName?: string;
  tradingNames: string[];
  status: 'active' | 'inactive' | 'archived';
  primaryContactId?: string;
  verificationStatus: 'unverified' | 'partially_verified' | 'verified';
  source: { type: 'manual' | 'csv' | 'connector'; ref?: string };
  createdAt: string;
  updatedAt: string;
  version: string;
};

type ClientRelationship = {
  clientRelationshipId: string;
  taxpayerId: string;
  serviceStatus: 'prospect' | 'onboarding' | 'active' | 'paused' | 'terminated' | 'archived';
  relationshipOwnerUid?: string;
  billingReference?: string;
  serviceTags: string[];
  riskFlags?: string[];
  openWorkItemCount: number;
  overdueCount: number;
  nextDueAt?: string;
  version: string;
};

type TaxRegistration = {
  registrationId: string;
  taxpayerId: string;
  tradingActivityId?: string;
  jurisdictionCode: string;
  authorityCode: string;
  taxTypeCode: string;
  jurisdictionPackVersionRef: string;
  maskedReference?: string;
  status: 'unconfirmed' | 'active' | 'inactive' | 'deregistered';
  effectiveFrom?: string;
  effectiveTo?: string;
  filingFrequencyCode?: string;
  version: string;
};
```

Relationship, trading-activity and portfolio response fields follow the canonical model in the [system architecture](../product/system_architecture.md). Every representation includes `version` even where abbreviated below.

## Endpoint summary

| Method | Path | Capability | Concurrency |
|---|---|---|---|
| `GET` | `/v1/practices/{practiceId}/taxpayers` | `taxpayers.read` | — |
| `POST` | `/v1/practices/{practiceId}/taxpayers` | `taxpayers.manage` | Idempotency key |
| `GET` | `/v1/practices/{practiceId}/taxpayers/{taxpayerId}` | `taxpayers.read` or access grant | — |
| `PATCH` | `/v1/practices/{practiceId}/taxpayers/{taxpayerId}` | `taxpayers.manage` | `If-Match` required |
| `GET` | `/v1/practices/{practiceId}/taxpayers/{taxpayerId}/client-relationships` | `clients.read` | — |
| `POST` | `/v1/practices/{practiceId}/taxpayers/{taxpayerId}/client-relationships` | `clients.manage` | Idempotency key |
| `PATCH` | `/v1/practices/{practiceId}/client-relationships/{clientRelationshipId}` | `clients.manage` | `If-Match` required |
| `GET` | `/v1/practices/{practiceId}/taxpayer-relationships` | `taxpayerRelationships.read` | — |
| `POST` | `/v1/practices/{practiceId}/taxpayer-relationships` | `taxpayerRelationships.manage` | Idempotency key |
| `PATCH` | `/v1/practices/{practiceId}/taxpayer-relationships/{relationshipId}` | `taxpayerRelationships.manage` | `If-Match` required |
| `POST` | `/v1/practices/{practiceId}/taxpayer-relationships/{relationshipId}:end` | `taxpayerRelationships.manage` | `If-Match` + idempotency key |
| `GET` | `/v1/practices/{practiceId}/taxpayers/{taxpayerId}/trading-activities` | `tradingActivities.read` | — |
| `POST` | `/v1/practices/{practiceId}/taxpayers/{taxpayerId}/trading-activities` | `tradingActivities.manage` | Idempotency key |
| `PATCH` | `/v1/practices/{practiceId}/trading-activities/{tradingActivityId}` | `tradingActivities.manage` | `If-Match` required |
| `POST` | `/v1/practices/{practiceId}/trading-activities/{tradingActivityId}:incorporate` | `tradingActivities.manage` | `If-Match` + idempotency key |
| `GET` | `/v1/practices/{practiceId}/taxpayers/{taxpayerId}/tax-registrations` | `taxRegistrations.read` | — |
| `POST` | `/v1/practices/{practiceId}/taxpayers/{taxpayerId}/tax-registrations` | `taxRegistrations.manage` | Idempotency key |
| `PATCH` | `/v1/practices/{practiceId}/tax-registrations/{registrationId}` | `taxRegistrations.manage` | `If-Match` required |
| `GET` | `/v1/practices/{practiceId}/portfolios` | `portfolios.read` | — |
| `POST` | `/v1/practices/{practiceId}/portfolios` | `portfolios.manage` | Idempotency key |
| `GET` | `/v1/practices/{practiceId}/portfolios/{portfolioId}` | `portfolios.read` | — |
| `PATCH` | `/v1/practices/{practiceId}/portfolios/{portfolioId}` | `portfolios.manage` | `If-Match` required |
| `POST` | `/v1/practices/{practiceId}/portfolios/{portfolioId}:add-member` | `portfolios.manage` | `If-Match` + idempotency key |
| `POST` | `/v1/practices/{practiceId}/portfolios/{portfolioId}:remove-member` | `portfolios.manage` | `If-Match` + idempotency key |
| `POST` | `/v1/practices/{practiceId}/taxpayers/{taxpayerId}/identifiers` | `taxpayerIdentifiers.manage` | Idempotency key |
| `POST` | `/v1/practices/{practiceId}/taxpayer-identifiers/{identifierId}:reveal` | `taxpayerIdentifiers.reveal` | — |

All endpoints are regional.

## Taxpayer collection

Supported taxpayer-list filters: `status`, `kind`, `verificationStatus`, `clientServiceStatus`, `portfolioId`, `updatedAfter`, and prefix `query`. Supported sorts: `displayName`, `-updatedAt`, `nextDueAt`.

Relationship, registration, activity and portfolio collection endpoints follow the shared cursor contract. Relationship filters are `fromTaxpayerId`, `toTaxpayerId`, `role` and `status`; portfolio filters are `status`, `memberTaxpayerId` and prefix `query`.

Creation request:

```json
{
  "kind": "registered_organisation",
  "displayName": "Mokoena Media",
  "legalName": "Mokoena Media (Pty) Ltd",
  "tradingNames": ["Mokoena Studio"],
  "primaryContact": {
    "displayName": "Thando Mokoena",
    "email": "thando@example.com",
    "phoneE164": "+27821234567"
  },
  "source": { "type": "manual" }
}
```

**Response:** `201 Created` with `Taxpayer`. Creating a taxpayer does not automatically create a client relationship, tax registration, portal access or portfolio membership.

**Events:** `taxpayer.created.v1`.

**Errors:** `409 possible_duplicate_taxpayer` with safe candidate IDs visible to the caller; `422 taxpayer_kind_invalid`; `422 name_required`.

Allowed patch fields are `displayName`, `legalName`, `tradingNames`, `status`, `primaryContactId` and verification evidence references. `kind` can change only through a dedicated correction command in a future contract because it affects downstream obligations.

## Client relationships

Creation request:

```json
{
  "serviceStatus": "onboarding",
  "relationshipOwnerUid": "uid_opaque",
  "billingReference": "CLIENT-1042",
  "serviceTags": ["monthly", "priority"]
}
```

Only one non-archived client relationship may exist for the same practice and taxpayer. `riskFlags` are never returned to portal users.

**Response:** `201 Created` with `ClientRelationship`.

**Events:** `client_relationship.created.v1`, `client_relationship.changed.v1`.

**Errors:** `409 client_relationship_exists`, `422 relationship_owner_invalid`.

## Taxpayer relationships

Creation request:

```json
{
  "fromTaxpayerId": "txp_person",
  "toTaxpayerId": "txp_company",
  "role": "director",
  "ownershipPercentageBps": 5000,
  "validFrom": "2025-03-01",
  "evidenceDocumentIds": ["doc_opaque"]
}
```

Relationships are directed, dated and evidenced. `ownershipPercentageBps` is accepted only for applicable roles and never inferred. Ending a relationship sets `validTo` and `status = ended`; it does not delete history or revoke access unless a separate access command is issued.

**Events:** `taxpayer_relationship.created.v1`, `taxpayer_relationship.ended.v1`.

**Errors:** `409 relationship_duplicate`, `422 relationship_cycle_invalid`, `422 ownership_percentage_invalid`.

## Trading activities and incorporation

Creation request:

```json
{
  "name": "Thando Creates",
  "kind": "creator",
  "registrationStatus": "unincorporated",
  "startedAt": "2024-06-01"
}
```

Incorporation request:

```json
{
  "successorTaxpayer": {
    "kind": "registered_organisation",
    "displayName": "Thando Creates",
    "legalName": "Thando Creates (Pty) Ltd"
  },
  "incorporatedAt": "2026-08-01",
  "relationshipRole": "owner"
}
```

The incorporation command atomically creates or links the successor taxpayer, sets `successorTaxpayerId`, changes the activity to `incorporated`, and records the relationship. Historical work, registrations and documents stay with their original responsible taxpayer unless separately migrated through an explicit professional workflow.

**Events:** `trading_activity.created.v1`, `trading_activity.incorporated.v1`, and `taxpayer.created.v1` when a successor is created.

**Errors:** `409 activity_already_incorporated`, `422 successor_must_be_organisation`.

## Tax registrations

Creation request:

```json
{
  "tradingActivityId": "act_optional",
  "jurisdictionCode": "ZA",
  "authorityCode": "SARS",
  "taxTypeCode": "vat",
  "referenceValue": "protected input",
  "status": "active",
  "effectiveFrom": "2025-03-01",
  "filingFrequencyCode": "monthly"
}
```

The server selects the active jurisdiction-pack version and returns only `maskedReference`. A caller cannot submit `jurisdictionPackVersionRef`. Duplicate active registrations are rejected unless the jurisdiction pack explicitly permits them.

Allowed patch fields are status, effective dates, filing frequency and a new protected reference. Jurisdiction, authority, tax type and responsible taxpayer are immutable; correcting them requires replacement with preserved history.

**Events:** `tax_registration.created.v1`, `tax_registration.changed.v1`.

**Errors:** `409 tax_registration_exists`, `422 tax_type_not_supported`, `422 authority_not_supported`, `422 activity_taxpayer_mismatch`.

## Portfolios

Creation request:

```json
{
  "name": "Mokoena Portfolio",
  "primaryTaxpayerId": "txp_person",
  "memberTaxpayerIds": ["txp_person", "txp_company"]
}
```

Membership actions accept `{ "taxpayerId": "txp_opaque" }`. Portfolios are navigation views only: membership creates no tax, ownership, document-sharing or access relationship.

**Events:** `portfolio.created.v1`, `portfolio.member_added.v1`, `portfolio.member_removed.v1`.

**Errors:** `409 portfolio_member_exists`, `404 taxpayer_not_found`.

## Protected identifiers

Identifier creation accepts `jurisdictionCode`, `authorityCode`, `identifierTypeCode` and `value`. The response contains `identifierId`, metadata, masked value and verification status—never the full value. Reveal requires a fresh privileged reason:

```json
{
  "reason": "Confirming the reference during an authorised client call"
}
```

The reveal response sets `Cache-Control: no-store`, is excluded from normal telemetry, and produces a dedicated audit event. Step-up authentication may be required by policy.

## Contract tests

1. Creating a taxpayer does not silently create access or a client relationship.
2. A portfolio member cannot read another member without its own grant.
3. A registration with `locale = en-ZA` is impossible because locale is not a registration field.
4. Incorporation preserves historical work under the original taxpayer.
5. Full identifier values never appear in list, search, event or audit payloads.
