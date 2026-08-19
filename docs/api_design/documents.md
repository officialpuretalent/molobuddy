# Documents API

- **Status:** Draft v0.1
- **Base contract:** [API Design](README.md)
- **Domain owner:** Documents

This domain owns document requests, secure upload sessions, logical documents, immutable versions and explicit links. It does not own OCR/extraction proposals, which belong to [Intelligence](intelligence.md).

## Representations

```ts
type DocumentRequest = {
  requestId: string;
  combinedRequestId?: string;
  taxpayerId: string;
  clientRelationshipId: string;
  tradingActivityIds?: string[];
  workItemId?: string;
  title: string;
  status: 'draft' | 'sent' | 'opened' | 'partial' | 'submitted' | 'reviewing' | 'more_info' | 'complete' | 'cancelled';
  recipientUserIds: string[];
  dueAt?: string;
  totalItems: number;
  acceptedItems: number;
  outstandingItems: number;
  sentAt?: string;
  completedAt?: string;
  version: string;
};

type Document = {
  documentId: string;
  taxpayerId: string;
  tradingActivityId?: string;
  workItemId?: string;
  requestId?: string;
  requestItemId?: string;
  kindCode: string;
  displayName: string;
  currentVersionId: string;
  status: 'processing' | 'needs_review' | 'accepted' | 'rejected' | 'superseded';
  uploadedByUid: string;
  createdAt: string;
  updatedAt: string;
  version: string;
};

type DocumentVersion = {
  versionId: string;
  sha256: string;
  byteSize: number;
  contentType: string;
  malwareScan: 'pending' | 'clean' | 'blocked' | 'failed';
  ocrStatus: 'not_requested' | 'queued' | 'processing' | 'complete' | 'failed';
  pageCount?: number;
  source: 'portal' | 'staff' | 'connector' | 'email';
  uploadedAt: string;
};
```

Storage paths, provider payloads and signed URLs are never part of durable document representations.

## Endpoint summary

| Method | Path | Capability | Concurrency |
|---|---|---|---|
| `GET` | `/v1/practices/{practiceId}/document-requests` | `documentRequests.read` or scoped grant | — |
| `POST` | `/v1/practices/{practiceId}/document-requests` | `documentRequests.create` | Idempotency key |
| `GET` | `/v1/practices/{practiceId}/document-requests/{requestId}` | `documentRequests.read` or scoped grant | — |
| `PATCH` | `/v1/practices/{practiceId}/document-requests/{requestId}` | `documentRequests.manage` | `If-Match` required |
| `POST` | `/v1/practices/{practiceId}/document-requests/{requestId}:send` | `documentRequests.send` | `If-Match` + idempotency key |
| `POST` | `/v1/practices/{practiceId}/document-requests/{requestId}:submit` | `requests.respond` grant | `If-Match` + idempotency key |
| `POST` | `/v1/practices/{practiceId}/document-requests/{requestId}:cancel` | `documentRequests.manage` | `If-Match` + idempotency key |
| `POST` | `/v1/practices/{practiceId}/upload-sessions` | `documents.upload` | Idempotency key |
| `POST` | `/v1/practices/{practiceId}/upload-sessions/{uploadSessionId}:complete` | Upload-session owner | Idempotency key |
| `GET` | `/v1/practices/{practiceId}/documents` | `documents.read` or scoped grant | — |
| `GET` | `/v1/practices/{practiceId}/documents/{documentId}` | `documents.read` or scoped grant | — |
| `POST` | `/v1/practices/{practiceId}/documents/{documentId}/versions` | `documents.upload` | Idempotency key |
| `POST` | `/v1/practices/{practiceId}/documents/{documentId}:create-download` | `documents.read` or scoped grant | — |
| `POST` | `/v1/practices/{practiceId}/documents/{documentId}:review` | `documents.review` | `If-Match` + idempotency key |
| `POST` | `/v1/practices/{practiceId}/document-links` | `documents.link` | Idempotency key |
| `POST` | `/v1/practices/{practiceId}/document-links/{linkId}:remove` | `documents.link` | Idempotency key |

All endpoints are regional. File bytes travel directly to the returned regional Storage upload target, not through the command API.

## Document requests

Creation request:

```json
{
  "taxpayerId": "txp_opaque",
  "clientRelationshipId": "clr_opaque",
  "workItemId": "wrk_optional",
  "tradingActivityIds": ["act_optional"],
  "title": "Documents needed for July VAT",
  "dueAt": "2026-08-15T15:00:00Z",
  "reminderPolicyId": "rmp_opaque",
  "items": [
    {
      "itemKey": "bank_statements",
      "label": "Business bank statements",
      "documentKindCodes": ["bank_statement"],
      "minimumCount": 1,
      "instructions": "Upload every page for July."
    }
  ]
}
```

The server snapshots reminder policy and item definitions. The request remains `draft`; creation does not notify anyone. A patch may alter draft title, due date, policy and items. After sending, only due date, reminder controls and user-safe instructions may change; taxpayer and work ownership are immutable.

**Response:** `201 Created` with `DocumentRequest` and request items.

**Events:** `document_request.created.v1`.

**Errors:** `422 taxpayer_context_mismatch`, `422 request_item_invalid`, `422 reminder_policy_invalid`.

## Send, submit and cancel

Send request:

```json
{
  "recipientUserIds": ["uid_representative"],
  "channels": ["email", "in_app"],
  "message": "Please send the listed documents by 15 August."
}
```

Every recipient must hold an applicable taxpayer access grant. The server creates notification intents and records the exact rendered template/content versions. It never treats provider delivery as proof the request was opened.

Submit request:

```json
{
  "itemConfirmations": [
    { "requestItemId": "rqi_opaque", "documentIds": ["doc_opaque"] }
  ],
  "note": "All July statements are included."
}
```

Submission moves the request into review only when every required item meets its minimum upload rule. Staff acceptance still occurs per document/item.

Cancellation request: `{ "reason": "Created for the wrong tax period" }`.

**Events:** `request.sent.v1`, `request.submitted.v1`, `request.cancelled.v1`.

**Errors:** `409 request_not_draft`, `409 required_items_missing`, `422 recipient_not_authorised`, `422 document_taxpayer_mismatch`.

## Upload session

Creation request:

```json
{
  "taxpayerId": "txp_opaque",
  "requestId": "req_optional",
  "requestItemId": "rqi_optional",
  "workItemId": "wrk_optional",
  "file": {
    "displayName": "July bank statement.pdf",
    "contentType": "application/pdf",
    "byteSize": 842190,
    "sha256": "hex_digest"
  }
}
```

**Response:** `201 Created`:

```json
{
  "data": {
    "uploadSessionId": "upl_opaque",
    "method": "PUT",
    "uploadUrl": "short_lived_signed_url",
    "requiredHeaders": {
      "Content-Type": "application/pdf",
      "x-goog-meta-upload-session": "upl_opaque"
    },
    "maximumByteSize": 10485760,
    "expiresAt": "2026-08-19T14:20:00Z"
  },
  "meta": {
    "apiVersion": "v1",
    "requestId": "req_opaque",
    "correlationId": "cor_opaque"
  }
}
```

The target path is fixed server-side from the authenticated practice, taxpayer and session. The caller cannot provide a bucket or object path.

Completion request:

```json
{
  "observedSha256": "hex_digest",
  "observedByteSize": 842190
}
```

Completion verifies the object, seals the session, creates an immutable document version and starts scanning. It returns `202 Accepted` with `Document.status = processing`. A failed or missing object never creates an accepted document.

**Events:** `document.uploaded.v1`; later scan events.

**Errors:** `409 upload_already_completed`, `410 upload_session_expired`, `422 upload_checksum_mismatch`, `422 file_type_not_allowed`, `413 file_too_large`.

## New document versions

`POST /documents/{documentId}/versions` creates an upload session bound to an existing logical document. It accepts the same file contract plus a replacement reason. The new version becomes current only after upload validation and policy checks; prior versions remain immutable.

## Document list and download

Supported document filters: `taxpayerId`, `workItemId`, `requestId`, `requestItemId`, `kindCode`, `status`, `uploadedByUid`, and `updatedAfter`. Portal users are always restricted to granted taxpayers and client-visible document states.

Create-download request:

```json
{
  "versionId": "ver_current_or_historical",
  "purpose": "Reviewing evidence for the assigned work item"
}
```

The API re-checks current access, malware status and version visibility, records the purpose, then returns a single-use or short-lived regional signed URL with `Cache-Control: no-store`. The URL is never placed in an idempotency or audit record.

**Errors:** `409 scan_incomplete`, `410 document_version_expired`, `422 download_purpose_required`.

## Document review

```json
{
  "decision": "accept",
  "confirmedKindCode": "bank_statement",
  "reasonCode": "matches_request",
  "note": "All pages are present."
}
```

`decision` is `accept`, `reject` or `request_replacement`. Blocked malware can never be accepted. A reviewer sees only clean versions. Rejection and replacement requests require a reason and do not delete evidence.

**Response:** `200 OK` with updated `Document` and affected request-item counts.

**Events:** `document.reviewed.v1`; `request.more_info_requested.v1` when applicable.

**Errors:** `409 scan_incomplete`, `409 document_already_superseded`, `422 blocked_file`, `422 review_reason_required`.

## Document links

Creation request:

```json
{
  "documentId": "doc_opaque",
  "targetType": "work_item",
  "targetId": "wrk_opaque",
  "reason": "Supports both provisional-tax calculations"
}
```

Normal links require the document and target to share one taxpayer. Cross-taxpayer links are rejected by default and require a future dedicated privileged command with explicit legal basis; portfolio membership is insufficient.

## Contract tests

1. A signed URL cannot upload outside its fixed regional practice/taxpayer path.
2. Completing the same upload session twice creates one version.
3. A portal user cannot attach Taxpayer A's document to Taxpayer B's request.
4. A blocked file never becomes readable or reviewable.
5. Replacing a file preserves the original version and review history.
