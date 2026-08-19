# Repository and Source Structure

- **Status:** Draft v0.1
- **Last updated:** 19 August 2026

## 1. Canonical roots

```text
src/molobuddy_server   Node.js 24 + TypeScript backend
src/molobuddy_app      Flutter application
```

The roots are siblings because they are separate deployable products with different toolchains. They share generated wire contracts, not source-language domain models.

## 2. Repository tree

```text
docs/
  api_design/
  app_design/
  backend_design/
  data_design/

src/
  molobuddy_server/
    package.json
    tsconfig.json
    tsconfig.build.json
    eslint.config.js
    Dockerfile
    src/
      entrypoints/
        control_api.ts
        regional_api.ts
        event_receiver.ts
        worker.ts
        coordinator.ts
      bootstrap/
        config.ts
        container.ts
        lifecycle.ts
      kernel/
        ids/
        values/
        result/
        events/
        time/
      contracts/
        generated/
        cloud_events/
      contexts/
        identity_access/
          domain/
          application/
          adapters/
            inbound/
            outbound/
          index.ts
        practices/
        taxpayers/
        tax_work/
        documents/
        workflows/
        notifications/
        connectors/
        intelligence/
        audit/
      platform/
        auth/
        app_check/
        firestore/
        storage/
        messaging/
        secrets/
        observability/
        http/
    test/
      architecture/
      contract/
      integration/
      fixtures/

  molobuddy_app/
    pubspec.yaml
    analysis_options.yaml
    build.yaml
    l10n.yaml
    lib/
      bootstrap/
        app_bootstrap.dart
        app_environment.dart
        provider_observer.dart
      app/
        molo_app.dart
        router/
          routes/
        design_system/
          colour/
          typography/
          spacing/
          components/
        adaptive/
          window_class.dart
          adaptive_shell.dart
          capabilities.dart
          policies.dart
        localisation/
      core/
        auth/
          data/
            models/
            repositories/
            services/
            federation/
          ui/
            view_models/
            views/
            widgets/
          auth_providers.dart
          auth.dart
        networking/
        result/
        storage/
        observability/
        platform/
        contracts/
          generated/
      features/
        practice_home/
        clients/
        tax_work/
        document_requests/
        documents/
        notifications/
        settings/
        account_security/
    test/
      unit/
      widget/
      architecture/
      integration/

contracts/
  openapi/
  json_schema/
  events/

jurisdictions/
  za/

locales/
  en/
  en-ZA/

firebase/
  control/
  regional/

infra/
  environments/
  regions/
  eventarc/
  monitoring/
```

The architectural shape is locked. Package manifests and application scaffolds are created in the implementation step after re-verifying the current stable Flutter/Dart release and approved package catalogue in [`../app_design/`](../app_design/README.md).

## 3. Server context template

Every server context uses the same shape:

```text
contexts/{context}/
  domain/
    aggregates/
    entities/
    value_objects/
    services/
    events/
    errors/
  application/
    commands/
    queries/
    handlers/
    policies/
    ports/
    process_managers/
  adapters/
    inbound/
      http/
      events/
      jobs/
    outbound/
      persistence/
      messaging/
      providers/
  index.ts
```

Omit empty folders until the context needs them. Consistency is useful; ceremonial empty layers are not.

`index.ts` is the only import surface for another context. It must not re-export aggregates, repositories or provider types.

## 4. What belongs in `platform`

`platform` owns runtime-specific cross-cutting adapters:

- Firebase ID-token verification;
- App Check verification;
- Firestore client/database selection and transaction primitives;
- Storage signed URL and object metadata helpers;
- Eventarc/Pub/Sub envelope verification;
- Secret Manager client construction;
- structured logging, tracing and metrics;
- Fastify plugins for request context, limits and Problem Details.

Platform code does not own business decisions. For example, it verifies an ID token, but `identity_access` decides whether that user may assign a work item.

## 5. Generated contracts

The language-neutral source lives in top-level `contracts/`. Generation produces:

```text
src/molobuddy_server/src/contracts/generated  TypeScript wire DTOs and schemas
src/molobuddy_app/lib/core/contracts/generated Dart wire DTOs and clients
```

Generated files are never edited manually. Domain objects do not reuse generated wire DTOs directly; inbound adapters map them into value objects and commands.

## 6. Configuration

Configuration is validated once at startup and passed through composition roots. Contexts cannot read `process.env` directly.

Configuration categories:

- deployment identity and region;
- Firestore database and Storage bucket IDs;
- API limits and feature rollout;
- non-secret provider configuration;
- secret references, never secret values in committed configuration.

Do not create a generic global config singleton accessible from domain code.

## 7. Naming rules

- Directories and filenames: `snake_case` to match the established project paths.
- TypeScript types/classes: `PascalCase`.
- Functions/variables: `camelCase`.
- Domain commands: imperative (`CreateTaxpayer`, `TransitionWorkItem`).
- Events: past tense in code (`WorkItemTransitioned`) and versioned snake-case on the wire (`work_item.status_changed.v1`).
- Ports: capability names (`WorkItemRepository`, `DomainEventOutbox`), not infrastructure names (`FirestoreWorkItemService`).
- Adapter implementations may name infrastructure (`FirestoreWorkItemRepository`).

## 8. Dependency rules

Allowed:

```text
entrypoint → bootstrap → context public APIs + platform
inbound adapter → application → domain → kernel
outbound adapter → application ports + domain + platform client wrapper
```

Forbidden:

```text
domain → application/adapters/platform
application → Fastify/Firebase/Google Cloud
context A internals → context B internals
Flutter → server source packages
server domain → generated API DTO as entity
Flutter view → repository/service/vendor SDK/generated DTO
Flutter view model → Flutter widgets/BuildContext/vendor SDK
Flutter feature internals → another feature's internals
```

The Flutter-specific allowed flow is:

```text
view → view model → repository interface → service → external system
Riverpod providers → construct/scope view models, repositories and services
```

Flutter uses feature-first MVVM, not the server's DDD layers. Full rules are in the [Flutter application architecture](../app_design/architecture.md).

## 9. Acceptance criteria

1. Both source roots can be built and tested independently.
2. A static architecture test enforces the server dependency rules.
3. No Flutter view or feature imports Firebase Auth directly outside `core/auth/data` adapters.
4. No server domain/application file imports `firebase-admin`, Fastify or Google Cloud SDK packages.
5. Generated contracts can be replaced from OpenAPI without editing domain logic.
6. Flutter static checks enforce View → ViewModel → Repository → Service dependencies.
7. Riverpod is the only application state and dependency-composition mechanism.
8. Web, Android and iOS builds use the same feature sources and pass the required responsive test matrix.
9. Flutter operational business data flows through the versioned API; features do not import Firestore or Storage clients.
