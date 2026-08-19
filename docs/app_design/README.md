# Molo Flutter Application Design

- **Status:** Foundation decision v1.0
- **Targets:** Web, Android and iOS
- **Owner:** Product and engineering
- **Last updated:** 19 August 2026

This directory is the source of truth for the Molo Flutter application. The client has its own architecture and does not follow the server's domain-driven design.

## Design documents

| Design | Document | Purpose |
|---|---|---|
| Application architecture | [`architecture.md`](architecture.md) | Feature boundaries, MVVM layers, Riverpod state and dependency rules |
| Responsive multiplatform | [`responsive_multiplatform.md`](responsive_multiplatform.md) | Web/mobile layouts, navigation, capabilities, accessibility and test matrix |
| Product visual system | [`visual_design.md`](visual_design.md) | Colour tokens, typography, surfaces, motion and sign-in composition |
| Technology foundation | [`technology_foundation.md`](technology_foundation.md) | Flutter baseline, approved foundational libraries, networking, security and quality |
| Dependency governance | [`dependency_governance.md`](dependency_governance.md) | Latest-stable policy, package admission, upgrades, exceptions and deprecation rules |

## Locked decisions

| Concern | Decision |
|---|---|
| Source root | `src/molobuddy_app` |
| Platforms | One Flutter product for Web, Android and iOS |
| Architecture | Feature-first MVVM: View + ViewModel + Repository + Service |
| Optional logic layer | Small use cases only for complex orchestration shared by multiple view models |
| State management | Riverpod 3 with generated providers and immutable state |
| Dependency composition | Riverpod; no second service locator or dependency-injection container |
| Navigation | Typed `go_router` routes with browser/deep-link semantics |
| Networking | Generated contracts over a Molo transport built on Dio |
| Business-data access | Versioned HTTP API and server-authorised upload/download flows; no direct Firestore/Storage client in v1 |
| Models | Separate wire DTOs, repository models and immutable view state; Freezed and `json_serializable` where generation adds value |
| Authentication | Client-first auth module; Firebase identity behind repository/service interfaces; backend remains the authority |
| Responsive UI | Constraint-driven Molo design system using Flutter SDK layout primitives |
| Visual foundation | Deep Ink and Soft Cloud neutrals with accessible Molo Blue actions and sparse Hello Coral energy |
| Localisation | Flutter `gen-l10n`, ARB source and `intl`; international English fallback with regional locale packs |
| Persistence | Firebase owns auth persistence; only non-sensitive preferences initially; no offline business-write queue in v1 |
| Web output | JavaScript-compatible production baseline; maintain Wasm-compatible source and promote Wasm only after the release matrix passes |
| Package posture | Latest compatible stable versions, official/verified packages first, no deprecated foundations |

## Architectural statement

> Molo is one adaptive Flutter product whose views are a function of immutable state, whose repositories are the client sources of truth, and whose services isolate every external system.

Riverpod carries state and composes dependencies throughout the app, but it does not erase architectural responsibilities. A provider can construct or expose a view model, repository or service; it does not turn those components into one layer.

## Explicit non-goals

- Reproducing backend aggregates, bounded contexts or domain events in Dart.
- Creating separate Android, iOS and Web feature implementations when adaptive composition is sufficient.
- Choosing a third-party package for ordinary responsive layout.
- Storing Firebase ID tokens or tax data in general-purpose preferences.
- Enabling offline consequential writes before conflict, encryption, retention and audit semantics are designed.
- Adopting experimental Riverpod mutation or persistence APIs as production foundations.

## Relationship to other designs

- [Backend design](../backend_design/README.md) owns server architecture and authorisation.
- [Authentication design](../backend_design/authentication.md) owns the end-to-end identity trust boundary.
- [API design](../api_design/README.md) owns observable endpoint behaviour.
- [System architecture](../product/system_architecture.md) owns regional routing and deployment.
- [Product glossary](../product/glossary.md) owns canonical product language.
- [Brand platform](../product/brand_platform.md) owns Molo's visual and verbal direction.

## Foundation gate

Feature implementation starts only when the scaffold enforces these decisions through structure, analysis, tests and CI. A feature is not complete merely because it renders on one phone.
