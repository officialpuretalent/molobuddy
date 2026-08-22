# Connectors Data Design

- **Status:** Draft v0.1
- **Owner:** Product and engineering
- **Last updated:** 22 August 2026

This document defines the durable truth owned by the Connectors context. It complements the [Connectors API contract](../api_design/connectors.md) and the [accounting connector research](../research/accounting_connector_platform.md). It does not authorise provider API calls.

## 1. Ownership and placement

All records are practice-scoped and live in the practice's home regional cell. Connector credentials are secrets, not Firestore records: Firestore retains only an opaque regional Secret Manager reference and a credential generation. Provider raw payloads are stored in restricted quarantine storage and are not returned by an API.

Connector records never give the client direct Firestore access and never write into another bounded context's collections. A confirmed mapping/proposal invokes a public target-context command and stores the resulting Molo resource reference as evidence.

## 2. Canonical records

### `ConnectorConnection`

One practice's consented relationship with one provider identity. It contains provider key/version, connection status, consent evidence, granted Molo capabilities/provider scopes, creator, non-secret health state and resource version.

Connection transitions:

```text
authorising → awaiting_source_selection → active ⇄ paused
active/paused → attention_required → authorising | revoked
active/paused/attention_required → revoked
```

Only `active` sources may schedule syncs. Disconnect transitions the connection to `revoked`, prevents new work, removes the credential secret reference and retains accepted Molo outcomes according to policy.

### `ConnectorDataSource`

An explicitly selected external tenant, organisation, company or equivalent below a connection. Its natural key is `(connectionId, providerDataSourceId)`. It carries display name, provider API domain/region where relevant, selection time and independent sync health/checkpoints.

Do not equate a data source with a Molo practice, taxpayer or client. One connection may have multiple data sources; one practice may have many connections.

### `SyncRun` and `SyncCheckpoint`

`SyncRun` is an immutable attempt record with mode, reason, actor/system origin, counters, lifecycle, timing, rate-limit/retry metadata and correlation ID. A source/entity `SyncCheckpoint` holds opaque provider cursor/watermark plus a lease. Only the worker that holds the active lease may advance it, and it advances only in the transaction that persists the corresponding record page and receipts.

### `ExternalRecord`

A source-versioned integration projection. Its identity is:

```text
providerKey + providerDataSourceId + recordKind + providerRecordId
```

Every version stores provider version/update timestamp when available, retrieval timestamp, deletion/tombstone status, canonical envelope, checksum, raw-payload quarantine reference and mapping/proposal evidence. Provider display names, invoice numbers and emails are not identifiers.

### `WebhookReceipt`

A durable receipt of a verified provider notification: provider key, connection/data-source resolution, provider event key or checksum, receipt timestamp, payload quarantine reference and follow-up job reference. The unique key `(connectionId, providerEventKey)` prevents duplicate enqueueing. Invalid webhook bodies are not persisted.

## 3. Sensitive fields and retention

| Data                                         | Classification                       | Storage/handling                                                                     |
| -------------------------------------------- | ------------------------------------ | ------------------------------------------------------------------------------------ |
| OAuth access/refresh tokens, webhook secrets | Secret                               | Regional Secret Manager only; never logs, events or Firestore.                       |
| Provider raw payload                         | Restricted financial/personal data   | Encrypted quarantine storage; restricted diagnostic access; defined short retention. |
| Canonical external envelope                  | Sensitive operational/financial data | Regional Firestore; exposed only through a future authorised API projection.         |
| Connection/sync health                       | Operational metadata                 | Regional Firestore; API-safe only after response projection/redaction.               |
| Audit evidence                               | Immutable sensitive evidence         | Regional audit store under audit retention policy.                                   |

Raw payload retention, canonical record retention and final deletion/export behaviour must be set by the approved practice closure and data-retention policy before public release. Disconnect revokes future access; it does not silently destroy previous professional evidence.

## 4. Index and query requirements

Required query shapes:

- connections by practice, provider and status;
- selected sources by connection and source health;
- sync runs by connection/source, newest first, with status filter;
- active lease/checkpoint by source and record kind;
- external records by source/kind/provider ID and by changed/retrieved time;
- webhook receipts by connection and provider event key.

The initial deployed index is `connectorSyncRuns(connectionId ASC, updatedAt DESC)`.
It supports the practice-local sync history query without a cross-practice
collection-group query. Add further indexes only alongside the concrete,
authorised query that needs them.

Indexes must follow actual Firestore query shapes; no generic global external-record search index is permitted. Any cross-practice operational search uses anonymised metrics, not tenant records.

## 5. Compatibility and acceptance

- Connector definitions are version-pinned at connection creation; adapter upgrades must read old connection records or include an explicit migration.
- Provider DTO changes do not alter the canonical envelope without a versioned mapper migration and fixture evidence.
- At-least-once delivery is assumed. Receipt, record version and domain-command idempotency keys each protect a distinct boundary.
- A connector cannot bypass Taxpayers, Tax Work or Documents command APIs.
- A provider response, webhook body, secret reference or raw payload is never serialised in public API responses or event payloads.
