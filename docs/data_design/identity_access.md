# Identity and Access Data Design

- **Status:** Draft v0.1
- **Owner:** Product and engineering
- **Last updated:** 20 August 2026
- **Related contracts:** [system architecture](../product/system_architecture.md), [authentication design](../backend_design/authentication.md), [Identity and Access API](../api_design/identity_access.md)

## 1. Decision

Molo uses server-enforced, capability-based authorisation. A role is a named
bundle of capabilities, not an authority check in its own right. Every access
decision also evaluates the actor's current membership or taxpayer access
grant, the requested practice and the target resource's taxpayer scope.

This is deliberately not a Firebase custom-claims design. Firebase proves a
person's identity; the regional Molo service decides what that person may do
now. A role, capability, practice, taxpayer, region or acting-user ID supplied
by a client is untrusted input.

The model has two independent grant types:

| Grant | Holder | Scope | Purpose |
|---|---|---|---|
| `PracticeMember` | Practice staff | The practice, narrowed by work assignment/share where the capability is scoped | Internal practice work |
| `TaxpayerAccessGrant` | Portal user | Exactly one taxpayer | Client/representative portal access |

A portfolio, taxpayer relationship, contact record, invitation, email address
or connector connection never grants access. An invitation is not a grant
until it has been accepted; a suspended, removed, expired or revoked record
never grants access.

## 2. Authorisation decision

The regional API evaluates a request in this order:

1. Verify the Firebase ID token and App Check token, then build immutable
   `ActorContext` from verified claims.
2. Resolve the practice's trusted home region and reject a request sent to the
   wrong regional API.
3. Load the current active `PracticeMember` and any active,
   time-valid `TaxpayerAccessGrant` for the actor from that regional database.
4. Identify the target resource and its owning `practiceId` and `taxpayerId`
   before returning any business fields.
5. Evaluate a server-owned policy for the endpoint: capability, resource
   scope, relationship constraints, verification tier and state-machine rule.
6. Execute the command only after the policy allows it; write the mandatory
   audit event in the same transaction for consequential or sensitive actions.

The result is deny-by-default. There is no cached client assertion and no
long-lived role claim that can survive a suspension or revocation. Membership
and grant changes take effect on the next regional request.

```text
verified actor + current grant + target resource + endpoint policy
                              │
                              ├─ active PracticeMember → role capabilities → staff scope
                              │
                              └─ active TaxpayerAccessGrant → portal scopes → one taxpayer
                                                           │
                                                           └─ allow only if every condition holds
```

If the same user has both kinds of grant, each is evaluated independently. A
request can be allowed by either one, but the response uses the least revealing
projection for the grant that authorised that request. A portal grant never
turns internal fields into portal-visible fields, and a staff membership never
widens a taxpayer grant to another taxpayer.

## 3. Canonical records and regional placement

The authoritative records are regional, below the practice they govern:

```text
/practices/{practiceId}/members/{uid}
/practices/{practiceId}/taxpayers/{taxpayerId}/accessGrants/{uid}
/practices/{practiceId}/invitations/{invitationId}
```

The global control-plane `users/{uid}/practiceRefs/{practiceId}` record is a
minimal routing/navigation projection. It contains no capability and never
authorises a regional operation.

### 3.1 Practice membership

```ts
type PracticeMember = {
  practiceId: string;
  uid: string;
  role: 'owner' | 'admin' | 'manager' | 'practitioner' | 'reviewer' | 'assistant';
  capabilityOverrides?: Record<CapabilityCode, boolean>;
  status: 'invited' | 'active' | 'suspended' | 'removed';
  displayName: string;
  emailLower: string;
  workloadCapacity?: number;
  joinedAt?: Timestamp;
  updatedAt: Timestamp;
  version: string;
};
```

`role` and `status` are required. The optional overrides are tightly governed
exceptions, not a custom-role editor; section 6 defines their limits.

### 3.2 Taxpayer access grant

```ts
type TaxpayerAccessGrant = {
  practiceId: string;
  taxpayerId: string;
  uid: string;
  role: 'self' | 'director' | 'trustee' | 'representative' | 'viewer' | 'uploader';
  scopes: PortalScope[];
  status: 'invited' | 'active' | 'suspended' | 'expired' | 'revoked';
  validFrom?: Timestamp;
  validTo?: Timestamp;
  authorityEvidenceDocumentIds?: string[];
  grantedByUid: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  version: string;
};

type PortalScope =
  | 'taxpayer.read'
  | 'workItems.read'
  | 'documentRequests.read'
  | 'documents.read'
  | 'documents.upload'
  | 'requests.respond';
```

The server treats a missing `validFrom` as immediately valid and a missing
`validTo` as open-ended. It transitions a time-limited active grant to
`expired` as part of evaluation or scheduled maintenance; it never relies on a
background job for denial. A grant may only name one taxpayer and its evidence
must be stored as protected document references, never copied into the grant.

## 4. Capability catalogue and default role bundles

Capability codes are stable, namespaced server constants. An endpoint declares
one of these codes (or an explicitly named own-inbox rule); it must not compare
role strings. New capabilities are additive and require a documented default
role decision, API contract update and policy tests.

| Capability family | Capability codes |
|---|---|
| Practice and access | `practice.read`, `practice.manage`, `practice.close`, `members.read`, `members.invite`, `members.manage`, `taxpayerAccess.manage` |
| Taxpayer data | `taxpayers.read`, `taxpayers.manage`, `clients.read`, `clients.manage`, `taxpayerRelationships.read`, `taxpayerRelationships.manage`, `tradingActivities.read`, `tradingActivities.manage`, `taxRegistrations.read`, `taxRegistrations.manage`, `portfolios.read`, `portfolios.manage`, `taxpayerIdentifiers.manage`, `taxpayerIdentifiers.reveal` |
| Work | `workItems.read`, `workItems.create`, `workItems.manage`, `workItems.transition`, `workItems.assign`, `tasks.read`, `tasks.create`, `tasks.manage`, `tasks.complete` |
| Documents and client requests | `documentRequests.read`, `documentRequests.create`, `documentRequests.manage`, `documentRequests.send`, `documents.read`, `documents.upload`, `documents.review`, `documents.link` |
| Workflow and deadlines | `workflows.read`, `workflows.manage`, `workflows.publish`, `deadlines.read`, `deadlines.manage`, `deadlines.recalculate`, `deadlines.overrideStatutory`, `reminders.read`, `reminders.manage` |
| Intelligence | `intelligence.run`, `intelligence.read`, `intelligence.manage`, `intelligence.review` |
| Connectors and evidence | `connectors.read`, `connectors.manage`, `connectors.sync`, `audit.read`, `audit.export` |

The following matrix is the v1 default bundle. A tick means the role receives
the capability family subject to section 5's resource scope and section 7's
separation-of-duty checks. It is intentionally conservative for identifiers,
membership, integrations and audit evidence.

| Capability family | Owner | Admin | Manager | Practitioner | Reviewer | Assistant |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| Practice settings | manage/close | manage | — | — | — | — |
| Members and portal grants | manage | manage* | — | — | — | — |
| Taxpayers, clients, relationships, activities, registrations, portfolios | manage | manage | manage | read | read | read |
| Protected identifiers | manage/reveal | manage/reveal | — | — | — | — |
| Work items and tasks | all | all | all | read/manage/transition; tasks all | read/transition-review; tasks read/complete | read; tasks read/complete |
| Document requests | all | all | all | read | read | read |
| Documents | read/upload/review/link | read/upload/review/link | read/upload/link | read/upload/link | read/review | read/upload |
| Workflow templates, deadlines, reminders | all | all except statutory override | read; internal/client deadlines manage | read deadlines | read deadlines | read deadlines |
| Intelligence | all | all | run/read | run/read | read/review | — |
| Connectors | all | all | read | — | — | — |
| Audit | read/export | read/export | — | — | — | — |

`*` An admin cannot alter an owner, transfer ownership, remove/suspend the last
active owner, create an owner invitation, grant owner-only capabilities, or
grant a role/capability outside their own grant ceiling. Only a dedicated,
step-up-protected owner-transfer command may change ownership.

In the matrix, “all” means all capabilities in that family, not an authority to
bypass resource scope, evidence, state transitions or verification tiers.
“transition-review” means only a workflow transition whose current reviewer is
the actor and whose definition permits the actor's capabilities.

## 5. Resource scope

Capability alone is insufficient. Each policy has one of these scopes:

| Scope | Applies to | Rule |
|---|---|---|
| `practice` | Settings, membership, templates, connectors, audit | The active practice membership must carry the capability. Portal grants never satisfy it. |
| `taxpayer` | Taxpayer, registration, document, request and work reads | The resource must belong to the practice and be within the staff member's assigned/shared scope, or exactly match an active portal grant. |
| `work-item` | Work and task changes | Staff must have the capability and be the assignee, reviewer where allowed, or an explicit collaborator; manager/admin/owner bypass the assignment restriction. Portal users only receive client-safe reads and `requests.respond`. |
| `own` | Inbox and notification preferences | The recipient UID must equal the actor UID; no general capability grants access to another user's inbox. |
| `protected` | Identifier reveal, audit export, closure, ownership transfer | Requires the named capability, section 8's privileged verification tier, a reason and a dedicated audit event. |

The staff scope for `practitioner`, `reviewer` and `assistant` is a server-owned
projection of assignments and explicit sharing. It is not inferred from a
portfolio, a taxpayer relationship, a previously opened record or a client
filter. Before a feature exposes shared work, it must persist an auditable,
revocable share/assignment reference and use it in both list and item policies.

All list and search queries must apply this scope in the datastore query or
candidate projection before pagination. Filtering a broader result after it is
read is prohibited because totals, ordering and cursor behaviour can leak data.

## 6. Roles, overrides and delegation

Roles are system-owned v1 bundles. Enterprise custom roles are deferred until
there is a tenant-admin design for role lifecycle, delegation, audit and
migration; they must not be simulated with arbitrary capability strings.

`capabilityOverrides` may grant or remove only capabilities marked delegable by
the server registry. The registry excludes, at minimum:

- `practice.close` and ownership transfer;
- all member-management and portal-grant-management capabilities;
- `taxpayerIdentifiers.reveal`;
- statutory-deadline override;
- connector management and sync;
- audit read and export; and
- any capability that would allow the recipient to change roles, grants or the
  policy itself.

An override is valid only when all conditions hold:

1. the capability is recognised and delegable;
2. the actor holds that capability and may grant the recipient's target role;
3. the override does not exceed the actor's grant ceiling or create an
   equivalent of an owner/admin role;
4. a mandatory reason is supplied; and
5. the member remains active.

The server stores each mutation's before/after effective capability set in the
audit event. Policy code rejects unknown override keys. A `false` override can
remove a delegable operational capability, but cannot remove baseline safety
controls or create a role with no auditable responsibility.

## 7. Portal grants and safeguards

Portal roles bound the scopes that can be requested; selected scopes are the
actual authority. They are not practice capabilities and cannot be used for
internal features.

| Portal role | Permitted scopes | Evidence rule |
|---|---|---|
| `self` | All portal scopes for the individual's own taxpayer | Identity-to-taxpayer verification required by policy |
| `director`, `trustee`, `representative` | All portal scopes | Current recorded authority and evidence are required; expiry must be set where authority is time-limited |
| `viewer` | `taxpayer.read`, `workItems.read`, `documentRequests.read`, `documents.read` | Inviter records a business reason |
| `uploader` | `documentRequests.read`, `documents.upload`, `requests.respond` | Inviter records a business reason; no broad document read |

Portal response projections contain only fields marked client-visible. They
never include internal work status, blocking notes, risk flags, reviewer or
assignee identity, staff comments, connector details, tax identifiers, audit
events or intelligence proposals. Upload sessions inherit their taxpayer and
request scope at creation and reject completion if the grant has since ended.

## 8. Verification tiers and separation of duties

The authentication policy defines standard, sensitive and privileged request
tiers. This data design assigns the minimum tier:

| Action | Minimum tier | Additional rule |
|---|---|---|
| Read/update ordinary scoped work | Standard | Current grant and capability |
| Invite/change member or portal access; connector authorisation; audit export | Sensitive | Verified email, token-revocation check, recent authentication and reason where applicable |
| Reveal protected identifier; statutory deadline override; practice closure; owner transfer | Privileged | Explicit step-up/fresh authentication, reason and dedicated immutable audit event |

Workflow and review policies can impose more conditions than the capability
catalogue. At minimum, a reviewer cannot approve their own work where the
materialised workflow requires separation; an assignee cannot appoint
themselves as the required independent reviewer; and an actor cannot approve
an extraction proposal that their role is not permitted to review. Neither an
override nor owner status bypasses a legally or workflow-mandated second-person
control without a separately documented exception and evidence.

## 9. API and application behaviour

Regional endpoint specifications must declare their required capability and
scope in the endpoint summary. A missing declaration is a design failure. The
authorisation library accepts a typed policy such as:

```ts
authorise(actor, {
  capability: 'documents.review',
  scope: 'taxpayer',
  taxpayerId,
  verificationTier: 'standard',
});
```

Handlers call the library before repositories return a resource and pass the
resulting immutable authorisation context to the application handler. Domain
aggregates still enforce their own transition and separation invariants.

For resources the actor is not entitled even to discover, the API returns the
normal `404 resource_not_found`. For a known practice action that lacks a
capability, it returns `403 capability_required`. Authentication, expired
tokens, suspended practice access and wrong-region routes retain their existing
distinct problem codes. Error details never name a taxpayer or capability that
would reveal hidden information.

The Flutter app may receive a short-lived, server-computed capability summary
after entering a practice to shape navigation and disable unavailable actions.
That summary is a usability hint only: it must be cleared on user/practice
change and the API remains authoritative. The app must handle a later `403` or
`404` by removing stale affordances, refreshing session/access state and using
localised, non-revealing copy. It must never hide data purely through client
filters or trust a role/capability value from local storage.

## 10. Audit, retention and observability

Audit events are mandatory for invitations, acceptance, role/capability
changes, suspension/removal, portal-grant changes/revocation, privileged
actions, connector-consent changes and denied privileged attempts. Each event
records actor UID, target type/opaque ID, practice, action, before/after safe
authorisation state, reason where required, correlation ID and authentication
assurance—never raw tokens, unmasked identifiers, credentials or document
contents.

Authorisation logs use opaque IDs and decision codes. They support incident
investigation and access review without turning observability systems into an
alternative copy of taxpayer data. Retention follows the audit and regional
retention policy; revocation never deletes historical evidence.

## 11. Migration and compatibility

The existing role names remain stable. Existing portal grants without
`documentRequests.read` retain their historical scope and do not gain access
silently. A deliberate migration must either add that scope with recorded
authority or continue serving only the endpoints their scopes authorise.

Capability codes and portal scopes are append-only within API v1. Renaming,
changing their meaning or broadening a default role requires a new API version
or a separately versioned endpoint, a migration plan, audit review and product
approval.

## 12. Acceptance tests

1. An authenticated user without an active regional membership or matching
   taxpayer grant cannot read any practice resource.
2. Suspending a membership or revoking a grant denies the next regional
   request, without waiting for ID-token expiry.
3. A portal grant for Taxpayer A cannot list, open, download or upload against
   Taxpayer B, including when both are in the same portfolio.
4. A practitioner can only list and open work in their server-owned assigned or
   shared scope; a manager can assign eligible staff only.
5. A reviewer cannot satisfy a required independent review for work they
   prepared.
6. An admin cannot change an owner or grant an owner-only/non-delegable
   capability, and no command can remove the last active owner.
7. A capability override with an unknown, non-delegable or over-ceiling code is
   rejected and produces no membership change.
8. Identifier reveal, closure and owner-transfer fail without fresh step-up,
   reason and a dedicated audit event.
9. Portal projections omit every internal-only field even if the actor also has
   a different grant for another taxpayer.
10. Scoped list pagination, counts and cursors never disclose out-of-scope
    resource existence.
