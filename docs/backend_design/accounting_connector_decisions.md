# Accounting Connector Decisions

- **Status:** Accepted for initial implementation
- **Owner:** Engineering
- **Decision date:** 22 August 2026
- **Scope:** Molo's read-only accounting connectors at South African launch

These are deliberate product and architecture decisions, not open questions. They apply to the Connector bounded context, the current provider foundation and all future connection/sync work. Each external premise is linked to primary vendor or public-authority documentation checked on the decision date.

## 1. Native adapter kernel, not an accounting aggregator

**Decision:** Molo will implement and operate native provider adapters behind its connector kernel. It will not introduce a third-party accounting aggregation platform at launch.

**Why:** Molo's purpose is a trusted practice operating system with region-bound data, audit evidence and controlled domain actions. A native adapter gives Molo direct control of source identity, consent, retention, rate limits, provider-specific recovery and evidence. An aggregator would add another financial-data processor, commercial dependency and failure domain while still not removing the need to understand provider differences. This follows the existing system rule that every external system enters through the governed Connector plane and may not write uncontrolled data into Molo work. [Molo system architecture](../product/system_architecture.md)

**Consequence:** Provider DTOs remain private adapters; the shared kernel contains only lifecycle, credential, sync, receipt and normalised-envelope contracts. A later aggregator can be admitted only as another adapter after a documented privacy, residency, commercial and exit-plan review.

## 2. Sage product: Sage Business Cloud Accounting v3.1

**Decision:** The initial Sage connector is **Sage Business Cloud Accounting v3.1**. Sage Intacct, Sage X3, Sage Pastel and other Sage products are out of scope and must each receive a separate connector definition and architecture decision.

**Why:** Molo launches with South African accounting and tax practices, while the Sage Accounting API provides an OAuth 2.0 v3.1 API with one cross-country base URL and explicit multi-business selection. Sage Intacct has a materially different API and requires a Web Services developer licence, sender ID/password, application registration and company authorisation. Treating them as one provider would create misleading consent, unsafe adapters and support ambiguity. [Molo launch market](../product/system_architecture.md) · [Sage Accounting v3.1 migration and multi-business API](https://developer.sage.com/accounting/docs/v1.0.0/guides/learning/migrating/migrating-from-v3-to-v31) · [Sage Intacct OAuth prerequisites](https://developer.sage.com/intacct/docs/1/sage-intacct-rest-api/tutorials/your-first-api-requests/php-oauth2-example)

**Consequence:** The `sage_business_cloud_accounting` adapter selects a business explicitly using `X-Business`; it must not rely on Sage's mutable lead-business default. The catalogue label remains exactly “Sage Business Cloud Accounting”.

## 3. Launch scope: read-only evidence, not accounting automation

**Decision:** Launch with read-only ingestion of selected data sources: organisation/company profile, contacts, chart of accounts, tax rates, sales invoices, purchase bills, credit notes and payments. Do not post, amend, reconcile, pay, create bank feeds, create journals or write back to any provider.

**Why:** Molo's first job is to help a practice understand and evidence taxpayer work, not become the accounting system of record. Read-only access limits the consent surface and eliminates the risk that a failed saga changes a client's ledger. It also honours the existing architecture rule that external data is ingested, normalised and matched before a validated Molo domain action. The APIs make different object and tax semantics available: for example, Zoho tax objects are organisation/country-specific and Xero journals require an Advanced tier and certification. [Molo connector boundary](../product/system_architecture.md) · [Zoho tax API](https://www.zoho.com/books/api/v3/taxes/) · [Xero pricing and journal entitlement](https://developer.xero.com/pricing)

**Consequence:** `bank_transactions.read` remains a documented future capability in the private catalogue but is not enabled in a launch connection. Reports are retained as provider-named evidence snapshots only when a later approved use case needs them; Molo will not fabricate a universal profit-and-loss or tax-report model.

## 4. Connection topology: many selected data sources per practice

**Decision:** A Molo connection may expose several data sources, and a practice may select more than one source across one or more providers. Every source requires explicit selection and is syncable independently.

**Why:** A provider account need not equal a Molo Practice. Xero supports multiple tenants and its app-partner feature supports bulk connections; Zoho treats every organisation as independent; Sage Accounting v3.1 lists businesses and requires an optional `X-Business` header to select one. Mapping a connection to a single implicit “default company” would import the wrong client data as provider defaults change. [Xero app-partner features](https://developer.xero.com/documentation/xero-app-store/app-partner-guides/app-partner-features) · [Zoho organisations and IDs](https://www.zoho.com/books/api/v3/introduction/) · [Sage multi-business behaviour](https://developer.sage.com/accounting/docs/v1.0.0/guides/learning/migrating/migrating-from-v3-to-v31)

**Consequence:** `(providerKey, dataSourceId, recordKind, providerRecordId)` is the external-record identity. No matching rule may use invoice number, provider record ID, display name or email outside that source scope.

## 5. Consent and token custody: server-only and least-privilege

**Decision:** Molo uses server-side OAuth authorisation-code flows. The Flutter client never receives a provider token, client secret, webhook secret or raw provider payload. A connection requests only the capability-derived read scopes enabled for that connection; incremental consent/re-authorisation is required to add a capability.

**Why:** Xero requires `offline_access` for refresh tokens and makes scopes additive; reducing scopes requires revocation/reconnection. Zoho access tokens are short-lived and refresh tokens should remain confidential; QuickBooks scopes determine the accounting data an app can access and Intuit recommends incremental scopes. [Xero scopes](https://developer.xero.com/documentation/guides/oauth2/scopes/) · [Zoho OAuth](https://www.zoho.com/books/api/v3/oauth/) · [Intuit scopes](https://developer.intuit.com/app/developer/qbpayments/docs/learn/scopes)

**Consequence:** Credentials reside only in the practice's regional Secret Manager through `ProviderCredentialVault`; Firestore contains only a secret reference and credential generation. Refresh-token rotation is serialised per connection. Provider callbacks bind signed, single-use state to the Molo connection and allowlisted return URI.

## 6. Regional transfer policy: provider domain is explicit consent information

**Decision:** Molo stores the provider API domain/data-centre with every selected data source and permits connection only when the provider domain is approved for that practice's home-region transfer policy. The connection screen must state the provider and source location when known. An unapproved domain results in `connector_unavailable_in_region`; it is not silently routed elsewhere.

**Why:** Molo's regional-cell design requires practice records, secrets, queues and processing to stay in the home cell by default. Zoho operates eight API data-centre domains and requires the relevant domain for each organisation; provider account location is therefore a material processing fact. [Molo regional-cell rules](../product/system_architecture.md) · [Zoho data-centre domains](https://www.zoho.com/books/api/v3/introduction/)

**Consequence:** The launch policy permits the provider's documented API domain only after the practice grants the connector consent. No global proxy, shared secrets or cross-region queue is permitted. Legal review is required before enabling a new provider domain or country-specific edition; this is a product privacy gate, not a runtime fallback.

## 7. Sync policy: bounded history, predictable freshness and reconciliation

**Decision:** The default initial backfill is **18 months** for the launch records. It runs in durable pages. The normal schedule is **every six hours per selected source**, with a daily reconciliation pass and webhook-triggered targeted refresh where supported. A longer backfill is an explicit practice request and requires quota estimation/approval; it is capped at five years.

**Why:** Eighteen months covers a full annual cycle plus comparative work without automatically harvesting an account's full history. Six-hour polling is appropriate for a work-management product and keeps a predictable budget below provider quotas; it is not a promise of ledger real-time data. Zoho limits organisations to 100 requests/minute, plan-dependent daily limits and a small concurrent-call limit. Xero also applies per-organisation daily limits. Webhooks cannot be the only reconciliation mechanism: Intuit notes that its webhooks and Change Data Capture do not cover the Tax Code entity. [Zoho limits](https://www.zoho.com/books/api/v3/introduction/) · [Xero limits](https://developer.xero.com/pricing) · [Intuit tax-code limitation](https://static.developer.intuit.com/resources/Simpler_BAS_partner_FAQ.pdf)

**Consequence:** Every source/entity checkpoint has a lease, opaque cursor/high-water mark and overlap window. `429` and retryable faults persist `notBefore` for later work; workers never wait in process. Product wording says “last synchronised”, never “live”.

## 8. Retention: preserve reviewed tax evidence, minimise source copies

**Decision:** Retain encrypted raw provider payloads for **30 days** for retry/debug evidence. Retain normalised external records that have no confirmed Molo mapping/proposal for **90 days** after disconnect. Retain an external-record version referenced by an accepted Molo action or audit event for **five years after the associated work item closes**, unless a legal hold or a stricter approved jurisdiction policy applies.

**Why:** Molo should not become an uncontrolled duplicate accounting archive, but a tax practice needs durable evidence for reviewed work. SARS states that supporting records must be kept for five years from a tax return's filing date. The five-year Molo evidence rule is a conservative operational default; it does not replace a taxpayer's statutory recordkeeping obligation or legal advice. [SARS record-keeping guidance](https://www.sars.gov.za/wp-content/uploads/Docs/SmallBusiness/Small-business-leaflet-English-2026_updated-2-April-2026.pdf)

**Consequence:** Disconnect transitions the connection to `revoked`, revokes future access immediately and does not rewrite historical audit evidence. Purge jobs are regional, auditable and hold-aware. Raw quarantine access is restricted to authorised operational support and never exposed through public APIs.

## 9. Delivery sequence and production gates

**Decision:** Build and pilot in this order: **Xero → Sage Business Cloud Accounting → QuickBooks Online → Zoho Books**. All four remain `private` in the catalogue until their provider-specific production gate is passed.

**Why:** Xero is the reference implementation because it validates OAuth rotation, tenant selection, granular scopes and a mature app-partner lifecycle. Sage is second because it is the selected South African launch Sage product. QuickBooks then validates a distinct `realmId` and token model; Zoho then validates multi-data-centre routing and organisation-specific quotas. Xero OAuth apps are limited to 25 customers before the relevant certification/partner path, and production Intuit apps require approval. [Xero getting started](https://developer.xero.com/documentation/getting-started-guide/) · [Xero certification checkpoints](https://developer.xero.com/documentation/xero-app-store/app-partner-guides/certification-checkpoints) · [Intuit production approval](https://static.developer.intuit.com/resources/Intuit_App_Partner_Program_Guide.pdf)

**Consequence:** No provider advances to public status until a sandbox/fixture suite proves authorisation, source selection, token rotation, backfill resume, rate limiting, deletion/revision, disconnect/revocation and duplicate/out-of-order webhook handling. Molo does not claim partner/certified status until the provider has granted it.

## 10. API exposure and execution gate

**Decision:** `GET /v1/connectors` remains public but returns only safe, private connector metadata. All practice-scoped connection, sync, callback and webhook endpoints remain unimplemented/unroutable until the regional API, authorisation-state store, Secret Manager adapter, connection/data-source repositories, job ledger and audit integration exist.

**Why:** Public availability metadata has no practice or credential data. By contrast, an OAuth callback or a provider webhook is a security boundary: the existing API design requires signed single-use state, regional resolution, credential storage, signature verification, idempotent receipts and asynchronous processing. Publishing those routes before their storage/audit controls would create an unauthorised data-ingress surface. [Connector API contract](../api_design/connectors.md)

**Consequence:** The current adapter code remains no-I/O by construction. The next implementation slice is the regional connection lifecycle and its tests—not provider SDK installation or live API calls.
