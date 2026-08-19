# Flutter Technology Foundation

- **Status:** Accepted foundation
- **Research snapshot:** 19 August 2026
- **Last updated:** 19 August 2026

Package versions below record the stable versions verified during architecture research. They are not permission to scaffold with stale versions later: the scaffold must resolve the latest compatible stable releases again under the [dependency policy](dependency_governance.md).

## 1. Toolchain baseline

| Tool | Verified stable baseline | Policy |
|---|---|---|
| Flutter | 3.44.7 | Pin the exact current stable patch in CI; re-verify before scaffold |
| Dart | 3.12.2, supplied by Flutter | Use Flutter's bundled Dart; do not independently mix SDK versions |
| Android | API 24 minimum under this Flutter baseline | Recheck supported/CI-tested range on every Flutter upgrade |
| iOS | iOS 13 minimum under this Flutter baseline | Recheck supported/CI-tested range on every Flutter upgrade |
| Web | JavaScript across supported browsers | Keep Wasm compatibility; promote Wasm only after matrix evidence |

Flutter's stable release schedule targets three major stable releases a year. Molo uses the stable channel, exact CI pinning and deliberate upgrades—not beta/dev toolchains in production. [Flutter SDK archive](https://docs.flutter.dev/install/archive) · [Flutter supported platforms](https://docs.flutter.dev/reference/supported-platforms)

## 2. Foundational package decisions

| Capability | Approved package/family | Verified stable | Reason |
|---|---|---:|---|
| State + dependency composition | `flutter_riverpod` | 3.4.2 | Async state, lifecycle, caching, overrides, testability and no `BuildContext` dependency |
| Provider generation | `riverpod_annotation` / `riverpod_generator` | 4.0.6 / 4.0.8 | Consistent generated providers, parameters, hot reload and static scoping support |
| Riverpod analysis | `riverpod_lint` | 3.1.8 | Detects invalid provider lifecycles/scopes and common architectural mistakes |
| Navigation | `go_router` | 17.5.0 | Flutter-published, URL-based, deep-link and nested navigation support |
| Typed navigation generation | `go_router_builder` | 4.4.0 | Compile-time route parameters and generated location helpers |
| HTTP transport | `dio` | 5.11.0 | Cancellation, upload/download progress, interceptors, timeouts and Web/mobile adapters |
| Immutable unions/state | `freezed_annotation` / `freezed` | 3.1.0 / 3.2.5 | Stable immutable values, sealed outcomes and copy semantics |
| JSON mapping | `json_annotation` / `json_serializable` | 4.12.0 / 6.14.1 | Generated checked mapping instead of reflective/runtime mapping |
| Code generation | `build_runner` | 2.16.0 | Standard Dart generation pipeline used by approved builders |
| Firebase foundation | `firebase_core` | 4.13.0 | Official FlutterFire project initialisation |
| Identity | `firebase_auth` | 6.5.7 | Official cross-platform Firebase Authentication client |
| App attestation | `firebase_app_check` | 0.4.6 | Official App Check client for Web, Android and iOS |
| Localisation/formatting | Flutter `gen-l10n` + `intl` | SDK / 0.20.3 | Source-generated localisations and locale-aware formatting |
| Non-sensitive preferences | `shared_preferences` | 2.5.5 | Official cross-platform simple preferences; use `SharedPreferencesAsync`, not the legacy API |
| File selection | `file_selector` | 1.1.0 | Flutter-published Web/mobile file-selection boundary |
| External links | `url_launcher` | 6.3.2 | Flutter-published URL launch boundary across targets |
| Browser interop, only when needed | `web` | 1.1.1 | Dart's Wasm-compatible replacement for `dart:html` |
| Base lint set | `flutter_lints` | 6.0.0 | Flutter's maintained recommended analyzer rules, strengthened by project rules |

Primary package evidence: [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) · [go_router](https://pub.dev/packages/go_router) · [Dio](https://pub.dev/packages/dio) · [Freezed](https://pub.dev/packages/freezed) · [json_serializable](https://pub.dev/packages/json_serializable) · [FlutterFire](https://firebase.google.com/docs/flutter/setup)

These are approved capabilities, not an instruction to import packages everywhere. Every vendor package is hidden behind the layer that owns it.

### First scaffold compatibility record

The authentication scaffold was resolved on 19 August 2026 with the locally installed stable Flutter `3.44.0` / Dart `3.12.0`. The following lower selections are deliberate compatibility holds, not stale copied versions:

| Dependency | Latest stable checked | Selected | Reason and evidence | Exit condition | Review by |
|---|---:|---:|---|---|---|
| `flutter_riverpod` | 3.4.2 | 3.3.2 | 3.4.2 requires a newer Dart/Flutter SDK than the stable scaffold toolchain | Move to the latest Riverpod 3 family after the next compatible stable Flutter upgrade passes the full target matrix | 19 November 2026 |
| `riverpod_annotation` / `riverpod_generator` | 4.0.6 / 4.0.8 | 4.0.3 / 4.0.4 | Newer generators require analyzer 13 and a newer Flutter SDK; the selected family resolves together on Flutter 3.44.0 | Upgrade the annotation, generator, runtime and lint family together after the stable SDK upgrade | 19 November 2026 |
| `riverpod_lint` | 3.1.8 | 3.1.4 | 3.1.4 matches analyzer 12 and the selected generator; newer lint releases follow the newer analyzer line | Same Riverpod-family upgrade gate | 19 November 2026 |
| `build_runner` | 2.16.0 | 2.15.1 | Flutter 3.44.0 pins `meta` 1.18.0 while build_runner 2.15.2 and later require `meta` 1.18.3 or later | Upgrade when the stable Flutter SDK no longer pins the incompatible `meta` version | 19 November 2026 |
| `intl` | 0.20.3 | 0.20.2 | Flutter 3.44.0's official `flutter_localizations` package pins 0.20.2 | Follow the version supplied by the next stable Flutter SDK | 19 November 2026 |

These holds affect build compatibility, not architecture. They use stable, maintained APIs and no dependency override. The lockfile is the source of truth for the exact resolved graph.

## 3. State and dependency decision

Riverpod is selected over the main alternatives:

| Option | Assessment |
|---|---|
| Riverpod 3 | Selected: one solution for reactive state, async lifecycles, scoped composition, cache invalidation and test overrides |
| Provider + ChangeNotifier | Suitable for smaller apps and used in Flutter examples, but more widget-context coupling and manual async/error lifecycle for Molo's scale |
| BLoC/Cubit | Mature and testable, but adds event/state ceremony and still needs a separate composition convention |
| GetX | Rejected: combines state, routing and global dependency lookup in ways that weaken the explicit architecture |
| Signals | Promising fine-grained reactivity, but does not provide the same complete, established composition/testing foundation for this project |

Riverpod is not used for disposable widget mechanics. Mixing a second global state library is forbidden because two ownership models produce inconsistent lifecycles, testing and debugging.

## 4. Networking and contracts

The path is:

```text
ViewModel → Repository → generated API service → MoloApiTransport (Dio)
```

The v1 Flutter app does not import `cloud_firestore` or `firebase_storage` for operational business data. The versioned API is the single read/command contract, and document transfer uses server-authorised upload/download sessions. A future realtime transport requires an explicit architecture decision and performance evidence.

The transport owns:

- environment-specific API origins from build-time public configuration;
- ID-token and App Check injection through brokers;
- correlation/request IDs;
- connect, send and receive timeouts;
- cancellation on disposal, sign-out and practice switch;
- safe, bounded retry for idempotent requests only;
- Problem Details decoding;
- upload/download progress without buffering large documents unnecessarily;
- redacted diagnostics.

Rules:

- No feature creates its own Dio client.
- Never retry non-idempotent commands unless the API contract supplies an idempotency key and the repository owns it.
- A connectivity plugin is not treated as proof that the internet or API is reachable; actual request results are authoritative.
- Local MIME/size checks improve UX only. Server scanning and validation remain authoritative.
- Generated clients/DTOs come from the language-neutral API contract and are reproducible in CI.

## 5. Models and code generation

Molo has three distinct client model categories:

1. **Wire DTOs:** generated from API contracts and used by services.
2. **Repository models:** stable client representation and source-of-truth data.
3. **View state:** immutable data shaped for exactly one view.

Do not reuse a DTO as view state merely because its fields currently match. Map at the repository/view-model boundaries.

Use generation where it creates compile-time safety:

- typed Riverpod providers;
- typed routes;
- JSON parsing;
- immutable unions and state;
- generated API DTOs/clients;
- localisations.

Generated outputs are committed only if the selected generator/tooling requires it for deterministic application builds; either way CI regenerates and detects drift. They are never hand-edited.

## 6. Storage and offline posture

- Firebase SDK owns its authentication persistence. Molo never copies ID or refresh tokens into preferences.
- `SharedPreferencesAsync` stores allowlisted, non-critical preferences such as theme or last non-sensitive UI choice. It never stores tax data, raw API responses, credentials or authority.
- Repositories may keep bounded in-memory session caches and must clear practice-scoped data during sign-out/switch.
- V1 has no offline queue for consequential business writes. A lost connection produces a recoverable pending/error state and a deliberate retry.
- Adding a local database requires a separate data/security design covering encryption, Web support, migrations, retention, account/practice isolation, remote invalidation and conflict semantics.
- Riverpod's experimental offline persistence is not approved for production data.

## 7. Routing

- Use typed `go_router` routes and generated helpers.
- The URL is a product contract on Web: lowercase stable paths, opaque resource IDs and localisable labels outside the path.
- Nested navigation uses stateful shells only where separate branch histories are a real product need.
- Auth redirects derive from the session provider and retain one validated return destination.
- Routes never receive full model objects through transient `extra` when refresh/deep linking must work; load by opaque ID.
- Unknown, unauthorised and wrong-region routes have distinct safe outcomes.

`go_router` is published by the Flutter team and is feature-complete, with ongoing stability fixes. [go_router package](https://pub.dev/packages/go_router)

## 8. Security foundation

- No secret can be protected inside a mobile or Web application bundle. Only public configuration is compiled into the app.
- Firebase Auth/App Check SDK use is isolated behind services and token brokers.
- Raw tokens, document contents, taxpayer identifiers and personal details are redacted from logs, analytics, crash reports and provider observations.
- Web browser storage is treated as user-accessible. No sensitive application cache is approved there.
- HTTPS is mandatory; certificate pinning is not a cross-platform default and requires a separate rotation/availability design if proposed.
- External URLs are parsed as `Uri`, restricted to approved schemes/hosts where appropriate, and opened through one service.
- File selection and browser APIs live behind platform services and capability policy.
- The backend independently validates every request; client state never grants authority.

## 9. Localisation, design and accessibility

- Use Material 3 as the accessible component foundation, expressed through Molo design tokens and components rather than default-looking screens.
- Do not add a second UI framework or theme engine.
- Use Flutter's source-generated `gen-l10n` output and never the removed synthetic `package:flutter_gen` import path. [Flutter localisation migration](https://docs.flutter.dev/release/breaking-changes/flutter-generate-i10n-source)
- Never concatenate translated fragments. Supply placeholder context, plurals and translator descriptions in ARB.
- Locale-aware presentation is separate from jurisdiction/business rules.
- Automated contrast, target-size, label and semantics tests are CI gates.

## 10. Observability and configuration

The foundation defines Molo-owned `AppLogger`, `ErrorReporter`, `Analytics` and `PerformanceTracer` interfaces. The final telemetry vendor is not selected until its privacy, residency, retention, cost and Web/mobile support are approved.

Until then:

- debug logging uses structured, redacted events;
- release code does not use `print`;
- errors carry correlation IDs that can be matched to backend traces;
- analytics event names are versioned and never include arbitrary user text;
- environment selection is build-time and validated during bootstrap;
- the app fails safely if Firebase/public endpoint configuration is invalid.

This is an intentional vendor decision gate, not permission for features to add their own telemetry SDK.

## 11. Static analysis and tests

`analysis_options.yaml` starts from `flutter_lints` and treats warnings/deprecations as failures. It enables project rules for:

- strict casts, inference and raw types;
- discarded futures;
- deprecated member use, including same-package use;
- immutable state and public API documentation where appropriate;
- Riverpod lifecycle/scope linting;
- banned vendor imports by layer through an architecture test.

Use Flutter SDK `flutter_test` and `integration_test` first. Prefer handwritten fakes at repository/service boundaries. Add a mocking or native-automation package only when an evidence-backed test need cannot be met by the SDK.

Required CI lanes:

1. format and generated-code drift;
2. static analysis and architecture rules;
3. unit and widget tests;
4. Web release build and browser journey tests;
5. Android build/integration smoke;
6. iOS build/integration smoke;
7. dependency outdated/advisory/licence checks;
8. accessibility and responsive matrix tests;
9. performance-size baseline comparison for release builds.

## 12. Deferred choices with explicit gates

These are deliberately not package selections yet:

| Capability | Gate before selection |
|---|---|
| Crash/error vendor | Privacy, residency, retention, source-map and all-target review |
| Product analytics | Event governance, consent and regional/privacy review |
| Local database/offline sync | Data model, encryption, retention, conflict and Web support design |
| Biometric local unlock | Threat model and clear distinction from server reauthentication |
| Push notifications | Notification design, permission UX and provider/data residency review |
| Camera/document scanner | Quality, permissions, file size and all-target fallback review |
| Wasm as primary Web build | Browser/auth/files/observability compatibility and performance evidence |

No feature may privately decide one of these gates.
