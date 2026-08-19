# Audit API

- **Status:** Draft v0.1
- **Base contract:** [API Design](README.md)
- **Domain owner:** Audit

This domain exposes authorised, read-only access to immutable audit evidence and creates controlled export jobs. No public API can update or delete an audit event.

## Representations

```ts
type AuditEvent = {
  auditEventId: string;
  regionKey: string;
  jurisdictionCode?: string;
  practiceId: string;
  occurredAt: string;
  actor: {
    type: 'user' | 'system' | 'connector';
    actorId: string;
    actingContext?: string;
  };
  action: string;
  target: { type: string; id: string };
  correlationId: string;
  causationId?: string;
  idempotencyKeyHash?: string;
  changedFields?: string[];
  reason?: string;
  sourceReference?: string;
};

type AuditExport = {
  auditExportId: string;
  status: 'queued' | 'running' | 'complete' | 'failed' | 'expired';
  filters: object;
  format: 'jsonl' | 'csv';
  requestedByUid: string;
  requestedAt: string;
  completedAt?: string;
  expiresAt?: string;
  recordCount?: number;
};
```

Audit events contain safe metadata and field names, not full document content, OCR text, access tokens, unmasked tax identifiers or raw provider payloads.

## Endpoint summary

| Method | Path | Capability | Concurrency |
|---|---|---|---|
| `GET` | `/v1/practices/{practiceId}/audit-events` | `audit.read` | — |
| `GET` | `/v1/practices/{practiceId}/audit-events/{auditEventId}` | `audit.read` | — |
| `POST` | `/v1/practices/{practiceId}/audit-exports` | `audit.export` | Idempotency key |
| `GET` | `/v1/practices/{practiceId}/audit-exports/{auditExportId}` | `audit.export` | — |
| `POST` | `/v1/practices/{practiceId}/audit-exports/{auditExportId}:create-download` | `audit.export` | — |

All endpoints are regional.

## Audit-event list

Supported filters:

- `occurredFrom`, `occurredTo`;
- `actorId`, `actorType`;
- `action` or documented action prefix;
- `targetType`, `targetId`;
- `correlationId`;
- `jurisdictionCode`;
- `sourceReference` where visible.

Sort is fixed to `-occurredAt`, with `auditEventId` as tie-breaker. The maximum time range is 90 days unless the caller uses an export. Sensitive privileged-access events may require `audit.privileged.read` in addition to `audit.read`.

**Response:** `200 OK` with redacted `AuditEvent` records.

**Errors:** `400 audit_range_too_large`, `403 privileged_audit_required`.

## Get audit event

Returns one immutable event plus safe links to visible target resources. Target links always perform their own current authorisation. A deleted or inaccessible target does not make the audit event disappear.

The response includes `Cache-Control: private, no-store` for privileged events.

## Create export

```json
{
  "occurredFrom": "2026-07-01T00:00:00Z",
  "occurredTo": "2026-08-01T00:00:00Z",
  "actions": ["document.reviewed", "work_item.status_changed"],
  "targetTypes": ["document", "work_item"],
  "format": "jsonl",
  "purpose": "Quarterly internal control review"
}
```

The purpose is mandatory and audited. The export is generated inside the regional cell, encrypted at rest, filtered to the caller's capability and retained only for a short configured period.

**Response:** `202 Accepted` with `AuditExport`.

**Events:** `audit.export_requested.v1`, `audit.export_completed.v1`.

**Errors:** `422 export_range_invalid`, `422 export_purpose_required`, `429 export_quota_exceeded`.

## Create download

This action returns a single-use, short-lived regional signed URL only when the export is complete:

```json
{
  "reason": "Downloading for the approved quarterly review"
}
```

The response sets `Cache-Control: no-store`. The URL is not written to audit logs; creation and redemption references are audited separately. An expired export must be regenerated.

**Errors:** `409 export_not_complete`, `410 export_expired`.

## Immutability and correction

If an audit event contains incorrect safe metadata, a correction endpoint is not provided. The owning domain emits a new corrective business event, and audit records a new event referencing the original. Historical evidence remains unchanged.

## Contract tests

1. No method can update or delete an audit event.
2. A caller without privileged-audit capability sees a `404` or redacted event according to policy.
3. An export never contains unmasked protected identifiers or raw documents.
4. A signed download URL expires and cannot be reused beyond policy.
5. Corrections append evidence and never mutate the original event.
