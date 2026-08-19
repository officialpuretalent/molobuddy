# Tax Work API

- **Status:** Draft v0.1
- **Base contract:** [API Design](README.md)
- **Domain owner:** Tax work

This domain owns work items and tasks. A work item is one trackable unit of professional work for exactly one responsible taxpayer. Deadlines and reusable workflow definitions belong to [Workflows](workflows.md).

## Representations

```ts
type WorkItem = {
  workItemId: string;
  taxpayerId: string;
  clientRelationshipId: string;
  taxpayerName: string;
  portfolioIds?: string[];
  taxRegistrationId?: string;
  tradingActivityIds?: string[];
  jurisdictionCode: string;
  authorityCode?: string;
  jurisdictionPackVersionRef: string;
  workTypeCode: string;
  taxTypeCode: string;
  title: string;
  period: { label: string; startDate?: string; endDate?: string };
  internalStatus: string;
  clientStatus: string;
  priority: 'low' | 'normal' | 'high' | 'urgent';
  assignedToUid?: string;
  reviewerUid?: string;
  statutoryDueAt?: string;
  internalDueAt?: string;
  clientDocumentDueAt?: string;
  blockingReasonCode?: string;
  outstandingDocumentCount: number;
  incompleteTaskCount: number;
  workflowTemplateVersionRef?: string;
  createdAt: string;
  updatedAt: string;
  completedAt?: string;
  version: string;
};

type Task = {
  taskId: string;
  workItemId: string;
  title: string;
  status: 'open' | 'in_progress' | 'blocked' | 'complete' | 'cancelled';
  assignedToUid?: string;
  reviewerUid?: string;
  dueAt?: string;
  visibility: 'internal' | 'client';
  completedAt?: string;
  version: string;
};
```

## Endpoint summary

| Method | Path | Capability | Concurrency |
|---|---|---|---|
| `GET` | `/v1/practices/{practiceId}/work-items` | `workItems.read` | — |
| `POST` | `/v1/practices/{practiceId}/work-items` | `workItems.create` | Idempotency key |
| `GET` | `/v1/practices/{practiceId}/work-items/{workItemId}` | `workItems.read` or scoped grant | — |
| `PATCH` | `/v1/practices/{practiceId}/work-items/{workItemId}` | `workItems.manage` | `If-Match` required |
| `POST` | `/v1/practices/{practiceId}/work-items/{workItemId}:transition` | `workItems.transition` | `If-Match` + idempotency key |
| `POST` | `/v1/practices/{practiceId}/work-items/{workItemId}:assign` | `workItems.assign` | `If-Match` + idempotency key |
| `GET` | `/v1/practices/{practiceId}/work-items/{workItemId}/tasks` | `tasks.read` | — |
| `POST` | `/v1/practices/{practiceId}/work-items/{workItemId}/tasks` | `tasks.create` | Idempotency key |
| `PATCH` | `/v1/practices/{practiceId}/work-items/{workItemId}/tasks/{taskId}` | `tasks.manage` | `If-Match` required |
| `POST` | `/v1/practices/{practiceId}/work-items/{workItemId}/tasks/{taskId}:complete` | `tasks.complete` | `If-Match` + idempotency key |

All endpoints are regional.

## Work-item list

Supported filters: `taxpayerId`, `portfolioId`, `taxRegistrationId`, `jurisdictionCode`, `taxTypeCode`, `workTypeCode`, `internalStatus`, `clientStatus`, `assignedToUid`, `reviewerUid`, `priority`, `dueBefore`, `updatedAfter`, and `blocked`. Supported sorts: `effectiveDueAt`, `-updatedAt`, `priority`, `taxpayerName`.

Portal access always applies a server-owned taxpayer scope and returns only client-visible fields. Supplying another `taxpayerId` cannot widen that scope.

## `POST /v1/practices/{practiceId}/work-items`

```json
{
  "taxpayerId": "txp_opaque",
  "clientRelationshipId": "clr_opaque",
  "taxRegistrationId": "reg_optional",
  "tradingActivityIds": ["act_optional"],
  "jurisdictionCode": "ZA",
  "workTypeCode": "return_preparation",
  "taxTypeCode": "vat",
  "title": "VAT return — July 2026",
  "period": {
    "label": "July 2026",
    "startDate": "2026-07-01",
    "endDate": "2026-07-31"
  },
  "priority": "normal",
  "assignedToUid": "uid_optional",
  "workflowTemplateId": "wft_optional"
}
```

The server validates that every related record belongs to the same practice and responsible taxpayer. It selects the active jurisdiction-pack and workflow-template versions, materialises their tasks/deadlines, and stores those exact version references. A client cannot supply version references or initial status values.

**Response:** `201 Created` with `WorkItem` and links to materialised tasks/deadlines.

**Events:** `work_item.created.v1` plus materialisation events.

**Errors:** `409 duplicate_work_item`, `422 taxpayer_context_mismatch`, `422 tax_type_not_supported`, `422 workflow_not_applicable`, `422 period_invalid`.

## `PATCH /v1/practices/{practiceId}/work-items/{workItemId}`

Allowed general fields:

```json
{
  "title": "Updated display title",
  "priority": "high",
  "internalDueAt": "2026-08-20T15:00:00Z",
  "clientDocumentDueAt": "2026-08-15T15:00:00Z",
  "blockingReasonCode": "waiting_for_client"
}
```

The general patch cannot change responsible taxpayer, jurisdiction, tax type, registration, materialised workflow version, internal status or client status. Those changes need explicit domain actions or replacement work.

**Events:** `work_item.details_changed.v1`.

## Transition action

```json
{
  "transitionCode": "submit_for_review",
  "reason": "Preparation and evidence checks complete",
  "clientStatusOverrideCode": null
}
```

The server evaluates the materialised workflow state machine, required tasks, document reviews and reviewer separation rules. The transition determines both internal and client statuses; the client does not set either directly. `clientStatusOverrideCode` is owner/admin-only and requires a reason when allowed by policy.

**Response:** `200 OK` with updated `WorkItem`, `ETag` and any newly created tasks.

**Events:** `work_item.status_changed.v1`; `work_item.completed.v1` when terminal.

**Errors:** `409 transition_not_allowed`, `409 required_tasks_incomplete`, `409 documents_need_review`, `422 transition_unknown`, `422 reviewer_separation_required`.

## Assignment action

```json
{
  "assignedToUid": "uid_practitioner",
  "reviewerUid": "uid_reviewer",
  "reason": "Monthly allocation"
}
```

The assignee and reviewer must be active members with appropriate capabilities. Workflow policy may prohibit the same user occupying both roles.

**Events:** `work_item.assignment_changed.v1`.

**Errors:** `422 assignee_not_eligible`, `422 reviewer_not_eligible`, `422 reviewer_separation_required`.

## Tasks

Creation request:

```json
{
  "title": "Confirm all VAT invoices are present",
  "assignedToUid": "uid_opaque",
  "reviewerUid": "uid_optional",
  "dueAt": "2026-08-18T15:00:00Z",
  "visibility": "internal"
}
```

The general task patch may update title, assignment, reviewer, due date, visibility and blocking code. Status changes to `complete` use the completion action:

```json
{
  "completionNote": "Checked against the source folder",
  "evidenceDocumentIds": ["doc_optional"]
}
```

Completion rejects missing required evidence and is idempotent. Reopening or cancelling a task requires an allowed workflow transition and reason through the general patch or a future dedicated action.

**Events:** `task.created.v1`, `task.changed.v1`, `task.completed.v1`.

**Errors:** `409 task_already_complete`, `422 task_evidence_required`, `422 task_visibility_invalid`.

## Contract tests

1. A work item cannot reference activities owned by another taxpayer.
2. A portal user never receives internal status, blocking notes or reviewer identity.
3. Two concurrent transitions with the same `ETag` result in one success and one `412`.
4. Replaying a completed task does not increment completion counts twice.
5. A jurisdiction-pack update does not silently change an existing work item's materialised version.
