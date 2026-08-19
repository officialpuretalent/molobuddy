# Molo Product Glossary and Shared Vocabulary

- **Status:** Approved v1.1
- **Owner:** Product and engineering
- **Approved by:** Project owner
- **Approved on:** 19 August 2026
- **Last updated:** 19 August 2026
- **Applies to:** Product copy, design, engineering, support, documentation and data modelling

---

## 1. Purpose

MoloBuddy needs one shared language. The same concept must not be called a party in code, an entity in a design, a client in support and a taxpayer in product copy without a deliberate distinction.

This document is the vocabulary source of truth for the project. It defines:

- the canonical term for each product concept;
- what the term means and does not mean;
- the words used in the interface;
- the names used in the domain model and APIs;
- terms that should be avoided because they are ambiguous or misleading.

When another project document conflicts with this glossary, the glossary takes precedence.

## 2. Vocabulary principles

1. **Use words tax professionals naturally understand.** Validate the base vocabulary with South African launch practices and validate regional labels again for every new jurisdiction.
2. **Give each concept one canonical name.** Synonyms may be used in explanatory prose, but not as competing labels in the product or model.
3. **Separate a login identity from a taxpayer, contact and team member.** One human may occupy several of these roles.
4. **Separate the practice's client relationship from legal tax responsibility.** A person can represent several independently responsible taxpayers.
5. **Name a record by what it is, not by the screen where it appears.** A work item remains a work item in a list, board, notification or report.
6. **Reserve specialised terms for their real meaning.** An assessment is an outcome from a tax authority; it is not a generic name for all tax work.
7. **Use singular names for types and plural names for collections.** For example, `WorkItem` and `workItems`.
8. **Use international English with British spelling as the base product language.** For example, organisation, authorised and categorise. Localised copy follows the approved locale pack for its market.
9. **Keep region, jurisdiction and locale separate.** Data location, tax law and display language are different concepts and must never share one field.

## 3. Core vocabulary decisions

These are the most important terms in MoloBuddy.

| Canonical term | Product meaning | Model name | Do not use as a synonym |
|---|---|---|---|
| **Practice** | The accounting or tax practice using MoloBuddy, including a solo practitioner | `Practice` | Tenant, workspace, firm account |
| **Taxpayer** | A natural person or independently responsible organisation for whom tax obligations and work are recorded | `Taxpayer` | Party, tax subject, entity, account |
| **Client relationship** | The practice's service relationship with one taxpayer | `ClientRelationship` | Client account, taxpayer account |
| **Taxpayer relationship** | A verified relationship between two taxpayers, such as director, shareholder, trustee or representative | `TaxpayerRelationship` | Party relationship, group membership |
| **Trading activity** | An unincorporated trade, side hustle, rental activity or brand operated by a taxpayer | `TradingActivity` | Party, company, entity, taxpayer |
| **Portfolio** | A convenient view of related taxpayers and trading activities | `Portfolio` | Client group, legal group, account |
| **Tax registration** | A taxpayer's registration or recognised obligation for a tax type | `TaxRegistration` | Taxpayer, tax work, profile |
| **Work item** | One trackable unit of professional work for one responsible taxpayer | `WorkItem` | Tax matter, case, task, assessment |
| **Task** | One action required to progress a work item | `Task` | Work item, reminder, deadline |
| **Deadline** | A statutory, internal or client-document due date that must be monitored | `Deadline` | Task, reminder |
| **Document request** | A request to a taxpayer or authorised portal user for specified documents | `DocumentRequest` | Upload, checklist, work item |
| **Connector** | A reusable integration between MoloBuddy and an external provider | `ConnectorDefinition` | Connection, data source |
| **Connection** | One practice's authorised use of a connector | `ConnectorConnection` | Connector, installation in UI copy |

### 3.1 Replacing `Party` with `Taxpayer`

`Party` will not be part of MoloBuddy's canonical vocabulary. Although it is common in legal and enterprise data models, it is impersonal, ambiguous and unnatural in day-to-day product language.

The canonical term is **Taxpayer**.

A taxpayer is the person or independently responsible organisation that owns the relevant tax registration, obligation, documents, deadlines and work. Supported taxpayer kinds can include:

- individual;
- company;
- close corporation;
- trust;
- non-profit organisation;
- other independently recognised organisation.

The deciding question is:

> Who is legally responsible for this tax obligation or work?

The answer identifies the taxpayer record.

`Client` and `Taxpayer` are related but not interchangeable:

- **Taxpayer** identifies legal or operational tax responsibility.
- **Client** describes the practice's relationship with that taxpayer.
- A director or representative may log in for several taxpayer clients.
- A trading activity is not a separate taxpayer unless it becomes independently registered or incorporated.

The main navigation may use **Clients** because that is natural practice language. Each client record must still identify one responsible taxpayer.

### 3.2 Replacing `TaxMatter` with `WorkItem`

`Tax Matter` will not be the generic name for work in MoloBuddy. It sounds legalistic and may suggest a dispute, investigation or exceptional issue.

The canonical record is **Work Item**. The collective product area may be labelled **Work** or **Tax Work** in navigation.

A work item is one trackable unit of professional work for one taxpayer, normally with a tax type, period, workflow, assignee and deadlines.

Examples:

- Mokoena Media (Pty) Ltd — VAT return — July 2026
- Thando Mokoena — provisional tax — 2027 first period
- Mokoena Family Trust — income tax return — 2026
- Mokoena Media (Pty) Ltd — SARS verification — reference 12345
- Thando Mokoena — tax registration — VAT

A work item is a container for tasks, document requests, deadlines, comments and status history. A task is only one action inside that container.

## 4. People, access and practice terms

| Term | Definition | Example or boundary |
|---|---|---|
| **User** | A global login identity authenticated by MoloBuddy | One user may be a practice member and a portal user |
| **Practice member** | A user who works inside a practice | Owner, administrator, practitioner, reviewer or assistant |
| **Solo practitioner** | The sole owner/member of a practice | Uses the same practice model as a team |
| **Contact** | A person whose contact details are stored against a taxpayer | A contact does not automatically have login access |
| **Portal user** | A user allowed to access the client portal | May act for one or more taxpayers |
| **Authorised representative** | A person with recorded authority to act for a taxpayer | Director, trustee or tax representative |
| **Access grant** | Explicit permission for a portal user to access one taxpayer | Access to Company A does not grant access to Company B |
| **Role** | A named bundle describing a user's broad responsibility | Practice owner or portal uploader |
| **Capability** | A specific action that a user is permitted to perform | `workItems.assign` or `documents.review` |
| **Invitation** | A time-bound invitation to join a practice or portal | Not the same as an active membership or grant |

### Usage rule: person

Use **person** only when referring to a human being. Do not use person as a synonym for user, contact, taxpayer or representative because one human may have all four records for different reasons.

## 5. Taxpayer and client structure

| Term | Definition | Example or boundary |
|---|---|---|
| **Individual taxpayer** | A natural person who is independently responsible for tax | Thando Mokoena |
| **Organisation taxpayer** | A company, close corporation, trust, NPO or other independently responsible organisation | Mokoena Media (Pty) Ltd |
| **Client** | A taxpayer with whom the practice has or had a service relationship | Used naturally in navigation and communication |
| **Client relationship** | The record of that service relationship | Status, relationship owner, service tags and risk flags |
| **Taxpayer relationship** | A dated, evidenced relationship between taxpayers | Thando is a director of Mokoena Media |
| **Trading activity** | A trade or brand operated by a taxpayer without creating a separate legal taxpayer | Thando's Catering or a creator brand |
| **Portfolio** | A practice-defined view of related taxpayers and activities | Mokoena Portfolio |
| **Trading name** | A name under which a taxpayer or activity operates | It does not prove separate legal status |
| **Tax identifier** | A protected identifier issued to or used for a taxpayer | Income tax or VAT reference number |
| **Verification status** | Whether the taxpayer's identity or classification has been checked | Unverified, partially verified or verified |

### Portfolio boundary

A portfolio is for navigation and relationship management. It never:

- transfers legal responsibility;
- merges registrations, work, deadlines or documents;
- proves ownership or representation;
- grants portal access;
- allows one taxpayer's document request to complete another's.

## 6. Tax and work terms

| Term | Definition | Example or boundary |
|---|---|---|
| **Tax type** | A recognised category of tax or tax administration | Personal income tax, corporate income tax, VAT, PAYE, provisional tax |
| **Tax registration** | The record connecting a taxpayer to a tax type and reference | Mokoena Media's VAT registration |
| **Tax period** | The period covered by a work item, return or submission | July 2026 or 2026 year of assessment |
| **Work** | The collective area containing the practice's work items | Suitable as a navigation label |
| **Work item** | A discrete, trackable unit of professional work | VAT return for July 2026 |
| **Workflow** | The ordered stages and rules used to complete a kind of work item | VAT preparation workflow |
| **Workflow template** | A reusable, versioned definition used to create work items | Contains tasks, review gates and default deadlines |
| **Task** | A specific action within a work item | Review uploaded bank statement |
| **Checklist item** | A small confirmation step within a task or request | Confirm all pages are present |
| **Assignee** | The practice member currently responsible for an item | May apply to a work item or task |
| **Reviewer** | The practice member responsible for a review gate | Not necessarily the assignee |
| **Priority** | The operational importance assigned by the practice | Low, normal, high or urgent |
| **Blocker** | A condition preventing progress | Waiting for documents or client approval |
| **Internal status** | The detailed status visible to the practice | Quality review required |
| **Client status** | The simplified progress status visible to the client | In progress |
| **Submission** | A recorded delivery of a return, response or application to an authority | Not every work item results in a submission |
| **Assessment** | An assessment or outcome issued by the relevant tax authority | Never a synonym for work item or status |
| **Dispute** | Work challenging or responding to a tax decision | A category of work item, not the default name for all work |

### Work item ownership rule

Every work item has exactly one responsible taxpayer. It may also reference:

- one tax registration;
- one tax type;
- one tax period;
- one or more trading activities for context;
- one portfolio for navigation;
- many tasks, documents, requests and deadlines.

Related taxpayers require separate work items even when the practice sends one combined communication.

## 7. Deadlines, reminders and notifications

| Term | Definition | Example or boundary |
|---|---|---|
| **Statutory due date** | A deadline imposed by law or the relevant authority | VAT return due date |
| **Internal due date** | The practice's target date, normally earlier than the statutory date | Review complete three days before filing |
| **Document due date** | The date by which the client should provide requested information | Not represented as the statutory due date |
| **Deadline** | A monitored due-date record | Can produce reminders and tasks |
| **Reminder** | A scheduled prompt about a future or overdue action | Does not itself represent the obligation |
| **Notification** | A message generated for a user | In-app, email, push or WhatsApp |
| **Delivery** | One attempt to send a notification through a channel | Tracks sent, delivered, failed or bounced |

## 8. Documents and intelligence

| Term | Definition | Example or boundary |
|---|---|---|
| **Document request** | A request for a defined set of documents from one taxpayer | Personal bank statements for a provisional-tax work item |
| **Request item** | One requested document or document category | IRP5 certificate |
| **Combined request** | One communication that presents separate taxpayer-scoped document requests together | Replaces `RequestBundle` in product language |
| **Upload** | The act or transfer through which a file enters MoloBuddy | Not yet a reviewed document |
| **Document** | The stable logical record for an uploaded or imported document | Bank statement |
| **Document version** | One immutable file version of a document | Original upload or client replacement |
| **Document link** | An explicit association between a document and another record | Links one document to two work items without copying it |
| **OCR** | Machine reading that turns document images into text and layout data | It does not approve or interpret tax treatment |
| **Extraction** | Structured values proposed from a document | Amount, date, taxpayer name or period |
| **Confidence** | The system's stated certainty about a proposed result | Must not be presented as professional approval |
| **Review** | A human decision to confirm, correct or reject a proposed result | Records the reviewer and time |
| **Classification** | A proposed or confirmed document type | Bank statement, invoice or certificate |

## 9. Connector vocabulary

| Term | Definition | Example or boundary |
|---|---|---|
| **Connector** | The reusable MoloBuddy integration for an external provider | Google Drive connector |
| **Connection** | One practice's authorised connection through a connector | DevHouse Tax's Google Drive connection |
| **Data source** | A selected provider resource available through a connection | One Drive folder or accounting organisation |
| **Capability** | A type of data or action supported by a connector | Read documents or create calendar events |
| **Sync** | The controlled process of reconciling external data with MoloBuddy | May be scheduled or manually started |
| **Sync run** | One bounded sync attempt with a recorded outcome | Has start time, cursor and status |
| **External record** | A provider-owned object tracked by external identity and version | Drive file or accounting contact |
| **Mapping** | A confirmed association between an external record and a MoloBuddy record | Drive folder mapped to a taxpayer |
| **Import** | A controlled operation that creates or proposes MoloBuddy data from a source | CSV taxpayer import |

Use **installation** only in infrastructure or deployment documentation. The product interface should say **connection**.

## 10. Regions, jurisdictions and localisation

| Term | Definition | Example or boundary |
|---|---|---|
| **Market** | A commercial go-to-market country or territory | South Africa is Molo's launch market |
| **Region** | A Molo operational and data-placement boundary | `za1`, `eu1` or `us1`; not a tax jurisdiction |
| **Regional cell** | A complete regional deployment of Firestore, Storage, compute, queues and secrets | The `za1` cell runs in Johannesburg |
| **Home region** | The regional cell to which a practice's operational data is assigned | Stored as `homeRegionKey`; changed only through a controlled migration |
| **Cloud location** | The provider-specific region or multi-region used by a resource | `africa-south1`, `eur3` or `nam5` |
| **Tax jurisdiction** | The legal tax system governing a registration, work item or deadline | South Africa (`ZA`) or the United Kingdom (`GB`) |
| **Jurisdiction pack** | A versioned set of tax types, deadline rules, workflows, labels and authority metadata for one tax jurisdiction | South Africa jurisdiction pack v1 |
| **Locale** | The language and formatting convention used to display content | `en-ZA`, `en-GB` or `fr-CA` |
| **Time zone** | The IANA time-zone context used to interpret and display a date or deadline | `Africa/Johannesburg` |
| **Data residency** | Contractual or legal constraints on where data may be stored or processed | Does not determine tax jurisdiction or interface language |

### Separation rule

A practice may:

- operate in one home region;
- serve taxpayers in one or more tax jurisdictions;
- have users working in several time zones;
- display Molo in more than one locale.

Those facts must be configured independently. For example, a London-based practice could use the EU regional cell, support United Kingdom and South African tax work, and have an `en-GB` interface. No single “country” field can represent all three concerns.

Use **multi-region** for Molo's ability to operate multiple regional cells. Use **Firestore multi-region location** only when referring to Google's specific replicated database-location type.

## 11. Terms to avoid or restrict

| Avoid or restrict | Reason | Use instead |
|---|---|---|
| Party | Legal/data-modelling jargon that feels impersonal and ambiguous | Taxpayer |
| Tax subject | Accurate but institutional and unnatural in product copy | Taxpayer |
| Entity as a generic noun | Often excludes or confuses natural persons | Taxpayer, organisation or record |
| Client account | Confused with login, billing or accounting accounts | Client relationship |
| Tax matter | Sounds legalistic or dispute-specific | Work item |
| Case as a generic noun | Suggests an exception, dispute or support ticket | Work item |
| Job | Can describe employment, a queue job or professional work | Work item or background job, as applicable |
| Assessment as a generic noun | Has a specific tax-authority meaning | Work item, progress or tax assessment |
| Task for the whole unit of work | Makes tasks and their container indistinguishable | Work item |
| Business for every organisation | Trusts and NPOs may not be businesses | Organisation taxpayer |
| Brand as proof of legal status | A brand may only be a trading activity | Trading activity or trading name |
| Profile as a core record | Too broad and often means a screen or settings page | Taxpayer, registration or client relationship |
| Connector installation in product copy | Technical and unnatural | Connection |
| AI approved | Misstates the authority of automation | AI proposed; practitioner reviewed |

## 12. Model rename map

The architecture and implementation must use the following names consistently.

| Existing architecture name | Canonical model name |
|---|---|
| `Party` | `Taxpayer` |
| `partyId` | `taxpayerId` |
| `subjectPartyId` | `taxpayerId` |
| `subjectName` | `taxpayerName` |
| `fromPartyId` | `fromTaxpayerId` |
| `toPartyId` | `toTaxpayerId` |
| `liablePartyId` | `taxpayerId` |
| `successorPartyId` | `successorTaxpayerId` |
| `primaryPartyId` | `primaryTaxpayerId` |
| `parties` | `taxpayers` |
| `PartyRelationship` | `TaxpayerRelationship` |
| `partyRelationships` | `taxpayerRelationships` |
| `BusinessActivity` | `TradingActivity` |
| `activityId` | `tradingActivityId` |
| `businessActivityId` | `tradingActivityId` |
| `businessActivityIds` | `tradingActivityIds` |
| `businessActivities` | `tradingActivities` |
| `ClientAccount` | `ClientRelationship` |
| `clientAccountId` | `clientRelationshipId` |
| `clientAccounts` | `clientRelationships` |
| `ClientGroup` | `Portfolio` |
| `groupId` | `portfolioId` |
| `clientGroupId` | `portfolioId` |
| `clientGroupIds` | `portfolioIds` |
| `clientGroups` | `portfolios` |
| `PartyPortalGrant` | `TaxpayerAccessGrant` |
| `portalUsers` | `accessGrants` |
| `TaxMatter` | `WorkItem` |
| `matterId` | `workItemId` |
| `matters` | `workItems` |
| `openMatterCount` | `openWorkItemCount` |
| `RequestBundle` | `CombinedRequest` |
| `requestBundleId` | `combinedRequestId` |
| `ConnectorInstallation` | `ConnectorConnection` |
| `connectorInstallations` | `connectorConnections` |
| `installationId` | `connectionId` |
| `installedByUid` | `connectedByUid` |
| `installConnector` | `connectConnector` |
| `ConnectorManifest` | `ConnectorDefinition` |
| `ExternalObjectEnvelope` | `ExternalRecordEnvelope` |
| `externalObjects` | `externalRecords` |
| `externalObjectId` | `externalRecordId` |
| `objectType` | `recordType` |
| `objectTypes` | `recordTypes` |
| `rawObjectRef` | `rawRecordRef` |
| Target type `matter` | `work_item` |
| Target type `business_activity` | `trading_activity` |

No persisted production data exists yet, so these approved names have been applied to the architecture before implementation rather than carried forward as aliases.

## 13. Example using the shared vocabulary

```text
Portfolio: Mokoena Portfolio
├── Taxpayer: Thando Mokoena (individual)
│   ├── Tax registration: Personal income tax
│   ├── Tax registration: Provisional tax
│   ├── Trading activity: Thando's Catering
│   ├── Trading activity: Thando Creates
│   └── Work item: Provisional tax — 2027 first period
├── Taxpayer: Mokoena Foods (Pty) Ltd (organisation)
│   ├── Tax registration: Corporate income tax
│   ├── Tax registration: VAT
│   └── Work item: VAT return — July 2026
└── Taxpayer: Mokoena Media (Pty) Ltd (organisation)
    ├── Tax registration: Corporate income tax
    └── Work item: Annual income tax return — 2026
```

Thando may be the contact, authorised representative and portal user for all three taxpayers. That does not merge their registrations, work items, documents, deadlines or access grants.

## 14. Sentence tests

New product copy and technical documentation should sound natural in these sentences:

- Create a taxpayer for each independently responsible person or organisation.
- Add Thando's Catering as a trading activity under Thando Mokoena.
- Add Mokoena Media and Thando Mokoena to the Mokoena Portfolio.
- Create a VAT work item for Mokoena Media for July 2026.
- Assign the work item to Lerato and the review task to Naledi.
- Request bank statements from the taxpayer's authorised representative.
- The client can see that the work is in progress; the practice can see that it is in internal review.
- Connect Google Drive and map a folder to the correct taxpayer.

If a proposed term makes these sentences confusing, it should not become canonical vocabulary.

## 15. Approval and change process

The following core vocabulary decisions were approved on 19 August 2026:

| Decision | Canonical term | Status |
|---|---|---|
| Real-world person or independently responsible organisation | Taxpayer | Approved |
| Practice's service relationship with a taxpayer | Client relationship | Approved |
| Unincorporated trade, side hustle or brand | Trading activity | Approved |
| Related-taxpayer navigation view | Portfolio | Approved |
| Discrete unit of professional tax work | Work item | Approved |
| Operational and data-placement boundary | Region | Approved |
| Legal tax system | Tax jurisdiction | Approved |
| Versioned regional tax configuration | Jurisdiction pack | Approved |
| Language and display-format convention | Locale | Approved |

Approval actions:

1. the decision status and approval date are recorded in this document;
2. the architecture and model names are updated in one controlled rename;
3. approved terms are used in designs, tickets, code and support material;
4. new terms are added here before competing vocabulary is introduced elsewhere.

Changes to an approved core term require a short decision note covering the reason, migration impact and affected product copy. Minor clarifications and examples may be added without reopening the decision.
