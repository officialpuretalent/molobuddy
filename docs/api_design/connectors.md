# Connectors API

- **Status:** Draft v0.1
- **Base contract:** [API Design](README.md)
- **Domain owner:** Connectors

This domain owns the connector catalogue, practice connections, OAuth lifecycle, sync requests, external-record intake and provider webhooks. Connectors never write directly to arbitrary core records; they invoke validated domain commands.

## Representations

```ts
type ConnectorDefinition = {
  key: string;
  version: string;
  name: string;
  auth: 'oauth2' | 'api_key' | 'service_account' | 'none';
  capabilities: string[];
  scopes: Array<{ key: string; description: string; required: boolean }>;
  supportsDeltaSync: boolean;
  supportsWebhooks: boolean;
  status: 'private' | 'beta' | 'public' | 'deprecated';
};

type ConnectorConnection = {
  connectionId: string;
  connectorKey: string;
  connectorVersion: string;
  status: 'authorising' | 'awaiting_source_selection' | 'active' | 'attention_required' | 'paused' | 'revoked';
  externalAccountName?: string;
  grantedCapabilities: string[];
  grantedScopes: string[];
  lastSuccessfulSyncAt?: string;
  nextScheduledSyncAt?: string;
  errorSummary?: { code: string; occurredAt: string };
  connectedByUid: string;
  version: string;
};

type ConnectorDataSource = {
  dataSourceId: string;
  connectionId: string;
  displayName: string;
  selected: boolean;
  providerApiDomain?: string;
};

type SyncRun = {
  syncRunId: string;
  connectionId: string;
  mode: 'delta' | 'full' | 'selected_sources';
  status: 'queued' | 'running' | 'needs_review' | 'complete' | 'failed' | 'cancelled';
  counters: { received: number; matched: number; applied: number; needsReview: number; failed: number };
  startedAt?: string;
  completedAt?: string;
};
```

Credential values, OAuth tokens, webhook secrets and raw provider payloads are never returned by this API.

## Endpoint summary

| Method | Path | Plane/access | Concurrency |
|---|---|---|---|
| `GET` | `/v1/connectors` | Global safe catalogue | — |
| `GET` | `/v1/connectors/{connectorKey}` | Global safe catalogue | — |
| `GET` | `/v1/practices/{practiceId}/connector-connections` | Regional `connectors.read` | — |
| `POST` | `/v1/practices/{practiceId}/connector-connections` | Regional `connectors.manage` | Idempotency key |
| `GET` | `/v1/practices/{practiceId}/connector-connections/{connectionId}` | Regional `connectors.read` | — |
| `POST` | `/v1/practices/{practiceId}/connector-connections/{connectionId}:test` | Regional `connectors.manage` | Idempotency key |
| `POST` | `/v1/practices/{practiceId}/connector-connections/{connectionId}:sync` | Regional `connectors.sync` | Idempotency key |
| `POST` | `/v1/practices/{practiceId}/connector-connections/{connectionId}:pause` | Regional `connectors.manage` | `If-Match` + idempotency key |
| `POST` | `/v1/practices/{practiceId}/connector-connections/{connectionId}:resume` | Regional `connectors.manage` | `If-Match` + idempotency key |
| `POST` | `/v1/practices/{practiceId}/connector-connections/{connectionId}:disconnect` | Regional `connectors.manage` | `If-Match` + idempotency key |
| `GET` | `/v1/practices/{practiceId}/connector-connections/{connectionId}/sync-runs` | Regional `connectors.read` | — |
| `GET` | `/v1/oauth/{connectorKey}/callback` | Public verified OAuth edge | OAuth state |
| `POST` | `/v1/webhooks/{connectorKey}/{publicConnectionKey}` | Public verified provider edge | Provider idempotency |

## Connector catalogue

The global catalogue contains only public product metadata, supported regions/jurisdictions and consent descriptions. A definition may be unavailable in a region because of provider residency, network or contractual rules. Availability is returned explicitly; it is never inferred from marketing status.

Supported filters: `status`, `capability`, `regionKey`, `jurisdictionCode`.

## Create connection

```json
{
  "connectorKey": "google-drive",
  "requestedCapabilities": ["documents.read"],
  "requestedScopes": ["drive.readonly"],
  "authorisationReturnUri": "molo://settings/connectors/callback",
  "historicalBackfill": {
    "enabled": true,
    "earliestDate": "2025-03-01"
  }
}
```

The server pins a connector version, verifies the caller may grant every requested capability, validates the return URI against an allowlist, records consent, creates an `authorising` connection and returns an OAuth authorisation URL where required.

After provider authorisation, a connection enters `awaiting_source_selection`.
It cannot become `active` until the user has explicitly selected at least one
provider data source. The returned `version` is a strong entity tag and every
state-changing operation that declares `If-Match` compares it before committing.

**Response:** `201 Created`:

```json
{
  "data": {
    "connection": {
      "connectionId": "con_opaque",
      "connectorKey": "google-drive",
      "status": "authorising",
      "grantedCapabilities": [],
      "grantedScopes": [],
      "connectedByUid": "uid_opaque",
      "version": "1"
    },
    "authorisation": {
      "url": "https://provider.example/authorise?...",
      "expiresAt": "2026-08-19T15:20:00Z"
    }
  },
  "meta": {
    "apiVersion": "v1",
    "requestId": "req_opaque",
    "correlationId": "cor_opaque"
  }
}
```

**Events:** `connector.connection_started.v1`.

**Errors:** `409 connector_already_connected`, `422 connector_unavailable_in_region`, `422 scope_not_allowed`, `422 return_uri_not_allowed`.

## OAuth callback

The callback verifies signed, single-use state; derives region, practice, connection and return URI from server state; exchanges the code; stores credentials in regional Secret Manager; tests the connection; and redirects to the allowlisted app URI with only a safe status code and connection ID.

It never accepts a caller-supplied `practiceId`, `regionKey`, secret reference or arbitrary redirect URI. Provider errors are translated into stable safe codes; raw provider error details stay in restricted diagnostics.

**Events:** `connector.connected.v1`, `connector.authorisation_failed.v1`.

**Errors:** `400 oauth_state_invalid`, `409 oauth_state_used`, `410 oauth_state_expired`.

## Test and sync

Test has an empty body and returns connection health without exposing credentials.

Sync request:

```json
{
  "mode": "delta",
  "dataSourceIds": [],
  "reason": "Manual refresh before month-end review"
}
```

The command returns `202 Accepted` with `SyncRun`. Only one cursor-mutating sync may run per connection; another compatible request may return the active run instead of creating a duplicate. Full backfills may require explicit approval and quota confirmation.

**Events:** `connector.sync_requested.v1`, followed by completed/failed events.

**Errors:** `409 sync_already_running`, `409 connection_not_active`, `422 delta_sync_not_supported`, `429 connector_rate_limited`, `429 backfill_approval_required`.

## Pause, resume and disconnect

Pause stops new scheduled sync and outbound actions but preserves credentials. Resume tests the connection before returning it to active status. Disconnect requires:

```json
{
  "reason": "Practice no longer uses this provider",
  "revokeAtProvider": true,
  "retainImportedRecords": true
}
```

Disconnect revokes/deletes credentials, disables webhooks and stops new sync. It does not delete core Molo records created through reviewed domain commands. Provider raw data follows the documented retention policy.

**Events:** `connector.paused.v1`, `connector.resumed.v1`, `connector.disconnected.v1`.

## Provider webhooks

The public edge performs, in order:

1. maximum-size and content-type checks;
2. connector-specific signature and timestamp verification;
3. opaque public key resolution to connection and regional cell;
4. provider event ID or checksum idempotency check;
5. durable regional receipt and raw-payload quarantine;
6. `202 Accepted` response;
7. asynchronous normalisation, matching and domain-command execution.

The webhook path is not proof of authority by itself. The endpoint ignores body/query `practiceId`, `regionKey`, `connectionId` and taxpayer mappings.

A valid replay returns the original `202 Accepted` outcome without enqueueing another business effect.

**Errors:** `401 webhook_signature_invalid`, `404 resource_not_found`, `413 payload_too_large`.

## Contract tests

1. OAuth state cannot be replayed or redirect outside the allowlist.
2. A webhook with a valid public key but invalid signature is rejected before persistence.
3. Replaying a provider event produces one business effect.
4. Disconnect removes credential access but preserves accepted Molo records.
5. Connector code cannot bypass the taxpayer/work/document domain APIs.
