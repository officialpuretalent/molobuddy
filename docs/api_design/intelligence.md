# Intelligence API

- **Status:** Draft v0.1
- **Base contract:** [API Design](README.md)
- **Domain owner:** Intelligence

This domain requests OCR, classification and structured extraction, then records human review. Intelligence produces evidence-linked proposals; it never silently becomes professional approval or changes final tax outcomes.

## Representations

```ts
type IntelligenceRun = {
  runId: string;
  documentId: string;
  documentVersionId: string;
  regionKey: string;
  jurisdictionCode?: string;
  purpose: 'ocr' | 'classification' | 'extraction' | 'summary' | 'matching';
  status: 'queued' | 'running' | 'needs_review' | 'complete' | 'failed' | 'cancelled';
  providerFamily: string;
  modelVersionRef: string;
  schemaVersionRef?: string;
  processingLocation: string;
  inputFingerprint: string;
  confidenceSummary?: { minimum: number; mean: number };
  startedAt?: string;
  completedAt?: string;
  version: string;
};

type ExtractionProposal = {
  proposalId: string;
  runId: string;
  schemaVersionRef: string;
  fields: Array<{
    key: string;
    proposedValue: unknown;
    confidence: number;
    evidence: Array<{ page: number; boundingBox?: number[]; textHash?: string }>;
    reviewStatus: 'unreviewed' | 'accepted' | 'corrected' | 'rejected';
  }>;
  reviewStatus: 'unreviewed' | 'partial' | 'reviewed';
  version: string;
};
```

Raw OCR text, images and provider payloads are stored as protected regional artifacts and are not returned by list endpoints or logs.

## Endpoint summary

| Method | Path | Capability | Concurrency |
|---|---|---|---|
| `POST` | `/v1/practices/{practiceId}/documents/{documentId}/intelligence-runs` | `intelligence.run` | Idempotency key |
| `GET` | `/v1/practices/{practiceId}/intelligence-runs/{runId}` | `intelligence.read` | — |
| `POST` | `/v1/practices/{practiceId}/intelligence-runs/{runId}:cancel` | `intelligence.manage` | `If-Match` + idempotency key |
| `GET` | `/v1/practices/{practiceId}/intelligence-runs/{runId}/proposal` | `intelligence.review` | — |
| `POST` | `/v1/practices/{practiceId}/intelligence-runs/{runId}/proposal:review` | `intelligence.review` | `If-Match` + idempotency key |

All endpoints are regional. Provider callbacks are internal, authenticated worker contracts and are not public API endpoints.

## Create intelligence run

```json
{
  "documentVersionId": "ver_opaque",
  "purpose": "extraction",
  "schemaKey": "za_vat_invoice",
  "jurisdictionCode": "ZA",
  "requestedOutputs": ["classification", "fields", "summary"]
}
```

The server requires a clean malware scan, resolves the actual document/taxpayer jurisdiction, selects an allowed provider and processing location under the practice's residency policy, and pins provider/model/schema versions. The caller cannot name a provider or processing region in the public contract.

The same input fingerprint, purpose and version set may reuse an existing completed run when policy permits; reuse is explicit in response metadata.

**Response:** `202 Accepted` with `IntelligenceRun`.

**Events:** `intelligence.run_requested.v1`, followed by run status events.

**Errors:** `409 document_scan_incomplete`, `409 run_already_active`, `422 schema_not_applicable`, `422 processing_location_not_permitted`, `429 intelligence_quota_exceeded`.

## Get run and proposal

Run retrieval exposes safe status, versions, processing location, confidence summary and failure code. It never returns provider credentials, prompts, hidden reasoning, raw payloads or stack traces.

Proposal retrieval returns fields and page-level evidence only to authorised reviewers. Portal users do not receive internal extraction proposals merely because they uploaded the document.

## Review proposal

```json
{
  "fieldDecisions": [
    {
      "key": "invoiceTotal",
      "decision": "correct",
      "correctedValue": { "amountMinor": "125000", "currency": "ZAR" },
      "note": "OCR missed the final zero"
    },
    {
      "key": "invoiceDate",
      "decision": "accept"
    }
  ],
  "overallDecision": "approve_for_workflow",
  "reason": "Compared with the source pages"
}
```

Field decision is `accept`, `correct` or `reject`. `approve_for_workflow` means the reviewed values may be offered to a separate domain command; it does not itself change a tax registration, work item, deadline or filing. Corrections retain the proposed value, reviewer, time and evidence.

**Response:** `200 OK` with reviewed `ExtractionProposal` and a safe reviewed-values reference.

**Events:** `intelligence.proposal_reviewed.v1`. A subsequent domain mutation emits its own event and references the reviewed-values ID as causation evidence.

**Errors:** `409 run_not_reviewable`, `409 proposal_already_superseded`, `422 corrected_value_invalid`, `422 evidence_required`, `422 reviewer_separation_required`.

## Cancel run

Cancellation accepts `{ "reason": "Wrong document version selected" }`. It is best-effort for an active external provider request, prevents future results from being applied, and preserves evidence already received under retention policy.

## Safety rules

- No intelligence endpoint calculates or represents a final tax liability unless a future, separately approved professional workflow defines it.
- Low confidence cannot be hidden by averaging; field confidence and missing evidence remain visible.
- Provider/model changes create new versions and never rewrite historical runs.
- Processing region is recorded for every run.
- AI summaries are labelled as generated and linked to source evidence.

## Contract tests

1. A blocked or unscanned version cannot start a run.
2. A provider chosen outside the residency policy is rejected before document transfer.
3. Reviewing a proposal does not mutate tax-work records.
4. Two reviewers using the same stale proposal version produce one success and one `412`.
5. Historical run records retain their model, schema and processing-location references.
