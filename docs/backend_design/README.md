# Molo Backend Design

- **Status:** Draft v0.1
- **Owner:** Engineering
- **Last updated:** 19 August 2026

This directory is the source of truth for Molo's server architecture and its trust boundary with the Flutter application. Domain-driven design applies to the server only. The Flutter client has an independent [application design](../app_design/README.md) based on feature-first MVVM and Riverpod.

## Design documents

| Design | Document | Purpose |
|---|---|---|
| Runtime and platform | [`runtime_platform.md`](runtime_platform.md) | Production runtime, HTTP stack, deployment units, performance and security |
| Domain-driven design | [`domain_driven_design.md`](domain_driven_design.md) | Bounded contexts, layers, dependencies, transactions and events |
| Authentication | [`authentication.md`](authentication.md) | Client-first auth, provider federation and server trust boundary |
| Repository structure | [`repository_structure.md`](repository_structure.md) | Canonical source tree and ownership rules |

## Locked decisions

| Concern | Decision |
|---|---|
| Backend source root | `src/molobuddy_server` |
| Flutter source root | `src/molobuddy_app` |
| Architecture | Domain-driven modular monolith |
| Primary server runtime | Node.js 24 LTS on Cloud Run |
| Language | TypeScript with strictest practical compiler options; ESM output |
| HTTP adapter | Fastify 5 with compiled JSON Schema validation and response serialization |
| Public contract | Existing versioned JSON/HTTPS API design; later promoted to OpenAPI |
| Persistence | Firestore through domain-owned repository ports; no Firestore SDK in domain/application code |
| Async model | Transactional outbox/job ledger, region-constrained Pub/Sub and Eventarc to Cloud Run receivers |
| Authentication | Client-first Flutter experience using Firebase Authentication with Identity Platform |
| Backend identity authority | Verified Firebase ID token plus App Check; server-owned membership and capability resolution |
| Deployment shape | One codebase, multiple regional entrypoints; not microservices per domain |

## Architectural statement

> Molo is one domain-driven server with hard internal boundaries, deployed through a small number of purpose-built entrypoints.

The modular monolith is deliberate. Domain boundaries are enforced in code and tests without paying the operational, latency and consistency cost of a service per domain. A bounded context can move into a separate service later only when measured scale, risk, isolation or team ownership justifies it.

## Relationship to other designs

- [API design](../api_design/README.md) owns observable endpoint behaviour.
- [Flutter app design](../app_design/README.md) owns client architecture, state, responsiveness and packages.
- [Data design](../data_design/README.md) will own durable records, indexes, retention and migrations.
- [System architecture](../product/system_architecture.md) owns regional cells and Google Cloud placement.
- [Product glossary](../product/glossary.md) owns canonical product and model language.

If backend code conflicts with an API contract or the glossary, the code is wrong until the design is deliberately revised.

## Open decisions

1. Exact server package manager and workspace tooling at initial scaffold.
2. OpenAPI generation toolchain after the Markdown endpoint contracts are approved.
3. Initial Cloud Run CPU, memory, concurrency and minimum-instance settings from load tests.
4. First launch authentication methods beyond email and Google.
5. Step-up authentication method that works consistently across Flutter targets.
