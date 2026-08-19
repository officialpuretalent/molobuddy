# MoloBuddy Server

Node.js 24, strict TypeScript and Fastify 5 backend for MoloBuddy.

The first vertical slice exposes:

- `GET /health` — public service health;
- `GET /v1/auth/providers` — email/password availability plus the deliberate Google coming-soon stub;
- `GET /v1/session` — a verified Firebase identity and an empty practice directory until membership persistence lands.

Password and provider credentials are never checked by this server. Firebase Authentication owns credential verification and identity issuance; the server verifies the resulting Firebase ID token and App Check token.

## Local feedback loop

1. Use Node.js 24 and run `npm install`.
2. Copy `.env.example` to `.env.local`. The committed example contains development-only tokens; replace them if the machine is shared.
3. Run `npm run dev`.
4. Point Flutter at `http://localhost:8080` and run Flutter Web on `http://localhost:3000`.

The provider and health endpoints are public. The local session endpoint requires both headers:

```http
Authorization: Bearer molo-local-id-token
X-Firebase-AppCheck: molo-local-app-check-token
```

The local verifier is accepted only when `NODE_ENV` is `development` or `test` and `AUTH_VERIFIER=local`. Production rejects that combination during startup. Production uses Application Default Credentials and requires `AUTH_VERIFIER=firebase` plus `FIREBASE_PROJECT_ID`.

`CORS_ALLOWED_ORIGINS` is an explicit comma-separated origin allowlist. Wildcards, paths and origins containing credentials are rejected. CORS credentials are disabled.

## Commands

```text
npm run dev          Start the control API with reload
npm run build        Compile production JavaScript
npm run typecheck    Check strict TypeScript types
npm run lint         Run ESLint with zero warnings
npm run format:check Check formatting
npm test             Build and run all tests
npm run test:unit
npm run test:contract
npm run test:integration
npm run check        Run formatting, lint, types, build and tests
npm run audit:production
```

## Dependency security note

The production audit excludes development and optional packages because the production image installs neither. On 19 August 2026, the complete development-tree audit reported `GHSA-w5hq-g745-h8pq` through Firebase Admin's optional Cloud Storage dependency (`@google-cloud/storage → gaxios/teeny-request → uuid`). Molo's auth slice imports only the modular Firebase app, auth and App Check entrypoints, and the production image uses `npm ci --omit=dev --omit=optional`, so that optional Storage chain is absent from the deployed runtime. `npm run audit:production` reports zero vulnerabilities. Review this exception by 19 November 2026, or sooner when Firebase Admin refreshes the optional Storage chain. Do not add a Storage import without resolving or reassessing the advisory first.

Architecture and public contracts remain governed by the repository-level design documents linked from the root `AGENTS.md`.
