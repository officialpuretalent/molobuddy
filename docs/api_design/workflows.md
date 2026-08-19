# Workflows API

- **Status:** Draft v0.1
- **Base contract:** [API Design](README.md)
- **Domain owner:** Workflows

This domain owns versioned workflow templates, deadline records and reminder policies. Jurisdiction packs provide reviewed tax rules; published work-item instances keep immutable references to the exact versions used.

## Representations

```ts
type WorkflowTemplate = {
  workflowTemplateId: string;
  name: string;
  jurisdictionCode: string;
  workTypeCode: string;
  taxTypeCodes: string[];
  status: 'draft' | 'published' | 'deprecated';
  latestPublishedVersionId?: string;
  version: string;
};

type WorkflowTemplateVersion = {
  workflowTemplateVersionId: string;
  workflowTemplateId: string;
  versionNumber: number;
  jurisdictionPackVersionRef: string;
  states: object[];
  transitions: object[];
  taskDefinitions: object[];
  deadlineDefinitions: object[];
  publishedAt: string;
};

type Deadline = {
  deadlineId: string;
  taxpayerId: string;
  clientRelationshipId: string;
  taxRegistrationId?: string;
  tradingActivityId?: string;
  workItemId?: string;
  jurisdictionCode: string;
  taxTypeCode: string;
  kind: 'statutory' | 'internal' | 'client_documents' | 'custom';
  dueAt: string;
  timezone: string;
  source: 'rule' | 'template' | 'manual' | 'connector';
  ruleVersionRef?: string;
  status: 'scheduled' | 'satisfied' | 'missed' | 'cancelled';
  nextReminderAt?: string;
  version: string;
};
```

## Endpoint summary

| Method | Path | Capability | Concurrency |
|---|---|---|---|
| `GET` | `/v1/practices/{practiceId}/workflow-templates` | `workflows.read` | — |
| `POST` | `/v1/practices/{practiceId}/workflow-templates` | `workflows.manage` | Idempotency key |
| `GET` | `/v1/practices/{practiceId}/workflow-templates/{workflowTemplateId}` | `workflows.read` | — |
| `PATCH` | `/v1/practices/{practiceId}/workflow-templates/{workflowTemplateId}` | `workflows.manage` | `If-Match` required |
| `POST` | `/v1/practices/{practiceId}/workflow-templates/{workflowTemplateId}:publish` | `workflows.publish` | `If-Match` + idempotency key |
| `POST` | `/v1/practices/{practiceId}/workflow-templates/{workflowTemplateId}:deprecate` | `workflows.publish` | `If-Match` + idempotency key |
| `GET` | `/v1/practices/{practiceId}/deadlines` | `deadlines.read` or scoped grant | — |
| `POST` | `/v1/practices/{practiceId}/deadlines` | `deadlines.manage` | Idempotency key |
| `PATCH` | `/v1/practices/{practiceId}/deadlines/{deadlineId}` | `deadlines.manage` | `If-Match` required |
| `POST` | `/v1/practices/{practiceId}/deadlines/{deadlineId}:recalculate` | `deadlines.recalculate` | `If-Match` + idempotency key |
| `POST` | `/v1/practices/{practiceId}/deadlines/{deadlineId}:cancel` | `deadlines.manage` | `If-Match` + idempotency key |
| `GET` | `/v1/practices/{practiceId}/reminder-policies` | `reminders.read` | — |
| `POST` | `/v1/practices/{practiceId}/reminder-policies` | `reminders.manage` | Idempotency key |
| `PATCH` | `/v1/practices/{practiceId}/reminder-policies/{reminderPolicyId}` | `reminders.manage` | `If-Match` required |

All endpoints are regional.

## Workflow templates

Creation request:

```json
{
  "name": "Monthly VAT preparation",
  "jurisdictionCode": "ZA",
  "workTypeCode": "return_preparation",
  "taxTypeCodes": ["vat"],
  "definition": {
    "states": [
      { "code": "collecting", "clientStatusCode": "waiting_for_documents" },
      { "code": "preparing", "clientStatusCode": "in_progress" },
      { "code": "review", "clientStatusCode": "in_progress" },
      { "code": "complete", "clientStatusCode": "complete", "terminal": true }
    ],
    "transitions": [],
    "taskDefinitions": [],
    "deadlineDefinitions": []
  }
}
```

Draft templates may be edited. Publish validates unique state codes, reachable terminal states, transition capabilities, client-status mappings, task dependencies, reviewer separation and jurisdiction applicability. Publishing creates an immutable version; existing work items never change automatically.

Publish request:

```json
{
  "changeSummary": "Added second-person review before completion",
  "effectiveFrom": "2026-09-01"
}
```

**Response:** `201 Created` with `WorkflowTemplateVersion`.

**Events:** `workflow_template.created.v1`, `workflow_template.published.v1`, `workflow_template.deprecated.v1`.

**Errors:** `409 draft_required`, `422 workflow_unreachable_state`, `422 transition_capability_missing`, `422 client_status_mapping_required`, `422 jurisdiction_rule_violation`.

## Deadline list and creation

Supported filters: `taxpayerId`, `workItemId`, `jurisdictionCode`, `taxTypeCode`, `kind`, `status`, `dueBefore`, `dueAfter`, `assignedToUid`. Supported sorts: `dueAt`, `-updatedAt`.

Manual deadline creation:

```json
{
  "taxpayerId": "txp_opaque",
  "clientRelationshipId": "clr_opaque",
  "workItemId": "wrk_optional",
  "jurisdictionCode": "ZA",
  "taxTypeCode": "vat",
  "kind": "internal",
  "dueAt": "2026-08-21T15:00:00Z",
  "timezone": "Africa/Johannesburg",
  "assignedToUid": "uid_optional",
  "reminderPolicyId": "rmp_optional",
  "reason": "Internal review target"
}
```

Only `internal`, `client_documents` and `custom` deadlines may be created as manual records. A statutory deadline must be calculated from a reviewed jurisdiction rule or entered through a privileged statutory-override flow with source evidence.

**Response:** `201 Created` with `Deadline`.

**Events:** `deadline.created.v1`.

**Errors:** `422 statutory_rule_required`, `422 taxpayer_context_mismatch`, `422 timezone_invalid`.

## Deadline update and recalculation

General patch allows assignment, applicable reminder policy and non-statutory due date. Changing a statutory due date requires the recalculation action or a privileged manual override with reason and evidence.

Recalculation request:

```json
{
  "calculationInputs": {
    "periodEndDate": "2026-07-31",
    "filingFrequencyCode": "monthly"
  },
  "reason": "Registration frequency was corrected"
}
```

The server selects the applicable active jurisdiction rule, calculates a proposed date, records the rule version and input fingerprint, then applies it only if policy permits. Existing manual overrides are preserved and surfaced as conflicts rather than silently overwritten.

**Response:** `200 OK` with updated `Deadline`, previous due date, calculation evidence and `ETag`.

**Events:** `deadline.recalculated.v1`; `deadline.override_conflict.v1` where applicable.

**Errors:** `409 manual_override_present`, `422 rule_not_found`, `422 calculation_input_invalid`.

Cancellation request: `{ "reason": "Registration was deregistered before the period" }`. Cancellation preserves the record and stops future reminders.

## Reminder policies

Creation request:

```json
{
  "name": "Standard client document reminders",
  "audience": "client",
  "steps": [
    { "offsetMinutes": -10080, "channels": ["email", "in_app"] },
    { "offsetMinutes": -1440, "channels": ["email", "in_app"] },
    { "offsetMinutes": 1440, "channels": ["email"], "overdue": true }
  ],
  "quietHours": {
    "start": "20:00",
    "end": "07:00",
    "timezoneSource": "recipient"
  }
}
```

Offsets are relative to the relevant deadline and use minutes to avoid ambiguous units. Rendering language and local delivery time are resolved at notification time from recipient locale/timezone. Policy updates affect future scheduled intents; already delivered messages remain immutable evidence.

## Contract tests

1. Publishing a template creates an immutable version.
2. A new template version does not alter an existing work item.
3. Locale changes do not change a statutory deadline calculation.
4. Recalculation records the exact jurisdiction rule and inputs used.
5. Cancelling a deadline prevents new reminders but preserves previous deliveries and audit evidence.
