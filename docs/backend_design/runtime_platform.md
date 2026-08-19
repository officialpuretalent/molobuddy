# Backend Runtime and Platform

- **Status:** Draft v0.1
- **Decision:** Node.js 24 LTS on Cloud Run
- **Last reviewed:** 19 August 2026

## 1. Decision

Use **Node.js 24 LTS**, strict TypeScript and ESM for `src/molobuddy_server`. Deploy the primary API, event receivers and workers as regional Cloud Run services from one codebase.

Use **Fastify 5** only at the transport edge. Domain and application code must not depend on Fastify, Firebase or Google Cloud types.

Node.js 24 is GA in Cloud Run and has a longer support runway than Node.js 22. Cloud Functions for Firebase currently documents Node.js 20 and 22, so Molo should not make Firebase CLI deployment the runtime ceiling for the entire server. Eventarc can route named Firestore database events directly to Cloud Run by filtering the database ID. [Cloud Run Node.js runtimes](https://cloud.google.com/run/docs/runtimes/nodejs) · [Firebase Functions runtimes](https://firebase.google.com/docs/functions/manage-functions#set_nodejs_version) · [Firestore events to Cloud Run](https://cloud.google.com/eventarc/standard/docs/run/route-trigger-cloud-firestore)

## 2. Why this suite

| Option | Decision | Reason |
|---|---|---|
| Node.js 24 + Cloud Run | **Choose** | Long support runway, excellent I/O concurrency, mature Firebase/Google SDKs, one TypeScript ecosystem and full container/runtime control |
| Node.js 22 + Firebase Functions | Thin compatibility adapter only | Strong convenience but shorter runway and currently constrains the whole application to the Firebase-supported runtime list |
| Bun or Deno | Do not choose for production core | Runtime speed alone does not outweigh the less direct Google/Firebase deployment path and operational uncertainty for this system |
| Go | Revisit for isolated CPU-heavy workers | Excellent efficiency, but a second domain language would increase contract, staffing and maintenance cost before Molo has evidence it needs it |
| NestJS | Do not choose for the core | Its decorators, reflection and framework container add indirection and cold-start work that Molo does not need to implement DDD |
| Express | Do not choose for the new API | Mature, but Fastify gives stronger schema-first validation/serialization and a cleaner plugin boundary for this contract-heavy API |

This is not a claim that Node.js wins every microbenchmark. Molo's expected workload is primarily authenticated JSON commands, Firestore access, object storage, provider APIs and event orchestration—an I/O-heavy profile well suited to asynchronous Node.js.

## 3. Runtime stack

| Layer | Choice | Rule |
|---|---|---|
| Runtime | Node.js 24 LTS | Pin exact major in development, CI and container base |
| Language | TypeScript | Compile before production; do not run a TypeScript transpiler in the request process |
| Modules | ESM | No mixed CommonJS/ESM application graph |
| HTTP | Fastify 5 | Adapter only; route handlers call application use cases |
| Validation | JSON Schema/Ajv through Fastify | Validate body, path, query and headers before application code |
| Serialization | Response JSON Schemas | Allowlist output fields to prevent accidental sensitive-field leakage |
| API definition | OpenAPI + JSON Schema after contract approval | Generate wire types; do not hand-maintain competing DTO definitions |
| Logging | Structured JSON through Fastify/Pino adapter | No `console.log` in production paths; mandatory correlation context |
| Identity | Firebase Admin SDK | Verify ID/App Check tokens; never expose Admin SDK to domain code |
| Google services | Official Google Cloud clients | Wrapped behind infrastructure adapters |
| Testing | Domain unit, application, contract, adapter and regional end-to-end suites | Architecture tests enforce dependency rules |

Fastify recommends JSON Schema for validation and response serialization; it compiles schemas and response serializers. Response schemas also reduce accidental leakage because only declared fields are serialized. Schemas are trusted application artifacts—never accept runtime schemas from users or connectors. [Fastify validation and serialization](https://fastify.dev/docs/latest/Reference/Validation-and-Serialization/)

## 4. TypeScript baseline

The production compiler configuration must enable at least:

```json
{
  "compilerOptions": {
    "target": "ES2023",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitOverride": true,
    "noFallthroughCasesInSwitch": true,
    "useUnknownInCatchVariables": true,
    "verbatimModuleSyntax": true,
    "isolatedModules": true
  }
}
```

Domain identifiers use branded string types or value objects so `TaxpayerId`, `PracticeId` and `WorkItemId` cannot be interchanged accidentally. Money, dates, jurisdiction codes and resource versions are value objects with explicit parsing at the boundary.

## 5. Deployment units

Build one server artifact with separate composition roots:

```text
control-api       Global identity bootstrap and authorised region routing only
regional-api      Versioned practice-scoped HTTP API in each cell
event-receiver    Authenticated CloudEvents receiver for Firestore/Storage/Eventarc
worker            Pub/Sub/job-ledger consumers for workflow, documents and connectors
coordinator       Payload-free scheduled wake-up target for due regional jobs
```

These are deployment entrypoints, not separate domain codebases. They import only the bounded contexts they need and share the same application contracts.

The default is Cloud Run services rather than one deployed function per endpoint. This reduces deployment sprawl, centralises middleware and makes concurrency/resource tuning observable. Direct Firestore/Storage events enter through Eventarc and an IAM-authenticated event receiver. Public provider webhooks enter through a dedicated route group with connector-specific signature verification.

## 6. Performance rules

- Keep route handlers asynchronous and non-blocking.
- Move OCR, malware scanning, PDF work and other CPU-heavy processing to workers; never block the regional API event loop.
- Initialise Firebase Admin, schema compilers and Google clients once per instance in the composition root.
- Reuse outbound HTTP connections and set explicit connect/request timeouts.
- Bound every collection, upload, provider request and concurrent batch.
- Start Cloud Run concurrency conservatively, such as 8–16, then tune from p95 latency, event-loop delay, CPU and memory evidence. Google recommends beginning lower when application behaviour under concurrency is not yet known. [Cloud Run concurrency](https://cloud.google.com/run/docs/about-concurrency)
- Use minimum instances only for latency-critical APIs after measuring cold-start impact.
- Use response schemas on every route and avoid serialising unrestricted domain objects.
- Profile before extracting a Go worker or adding caching.

## 7. Security rules

- Run as a non-root user on a minimal supported Node.js 24 base image.
- Use one least-privilege service account per deployment entrypoint and regional cell.
- Make Cloud Run services private by default; expose only the regional API and verified webhook edge through the approved ingress.
- Require IAM-authenticated Eventarc/Pub/Sub delivery for internal receivers.
- Verify Firebase ID tokens and App Check before loading practice data.
- Validate all inputs and explicitly serialize all outputs.
- Never build executable validation schemas from tenant/provider input.
- Keep secrets in regional Secret Manager and pass references, not values, through application code.
- Pin dependencies with a lockfile, scan the built image and fail CI on critical reachable vulnerabilities.
- Set request size, header size, timeout and rate limits at both ingress and application layers.
- Redact tokens, signed URLs, identifiers, raw payloads and document content from logs.
- Terminate gracefully on `SIGTERM`, stop accepting work, finish bounded in-flight requests and release leases.

## 8. Runtime upgrade policy

- Pin one Node major across local development, CI and Cloud Run.
- Review Node and Cloud Run lifecycle dates quarterly.
- Test the next LTS in CI before the current runtime enters maintenance/deprecation.
- Do not use preview runtimes in production.
- A Firebase-specific Node.js 22 adapter, if ever required, must contain transport translation only and no domain logic.

## 9. Acceptance criteria

1. Domain/application packages compile without Fastify, Firebase or Google Cloud imports.
2. The same use case can be invoked from HTTP, Eventarc and a test without rewriting domain logic.
3. Response schemas prevent an injected undeclared secret field from reaching JSON.
4. Named-database Firestore events reach the correct regional receiver and are idempotent.
5. Load tests establish safe concurrency and memory settings before production.
6. An unavailable external provider cannot exhaust the API event loop or instance pool.
