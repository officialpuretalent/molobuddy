# MoloBuddy Engineering Instructions

These instructions apply to the whole repository. Read the relevant design documents before changing architecture, dependencies or public contracts.

## Sources of truth

- Product vocabulary: `docs/product/glossary.md`
- Brand: `docs/product/brand_platform.md`
- System architecture: `docs/product/system_architecture.md`
- Flutter application: `docs/app_design/README.md`
- Backend: `docs/backend_design/README.md`
- API contracts: `docs/api_design/README.md`
- Data design: `docs/data_design/README.md`
- Running locally against Firebase: `docs/local_development.md`

If implementation conflicts with an accepted design or the glossary, update the design deliberately or treat the implementation as incorrect.

## Application boundaries

- `src/molobuddy_server` is the Node.js/TypeScript server. Domain-driven design applies to the server only.
- `src/molobuddy_app` is the Flutter application for Web, Android and iOS. It uses feature-first MVVM with views, view models, repositories and services; do not reproduce server bounded contexts or DDD layers in Flutter.
- Server and client share generated wire contracts, never source-language business models.

## Flutter rules

- Use Riverpod 3 as the only application state-management and dependency-composition system. Use generated providers, `Notifier`/`AsyncNotifier` and immutable state. Do not introduce GetIt, Injectable, BLoC, GetX, Provider/ChangeNotifier state, or another competing state system.
- Keep animation controllers, focus nodes, text-editing controllers and other disposable widget-only state local to the widget. Riverpod owns shared, asynchronous, session, repository and view-model state.
- A view observes its view model. View models depend on repository interfaces. Repositories are sources of truth and depend on stateless services. Add a use case only for complex orchestration reused by multiple view models.
- All screens must work on Web, Android and iOS from their first implementation. Branch on available layout space and capabilities, not device labels or orientation.
- Use the Molo design system and Flutter SDK primitives for responsiveness. Do not add a responsive-layout package without an accepted exception.
- Routes are typed, URL-addressable and refresh-safe. Do not put secrets or sensitive personal/tax data in a URL.
- Use the versioned HTTP API for operational business data. Do not add direct `cloud_firestore` or `firebase_storage` feature access without a new accepted architecture decision.
- All user-facing text is localised. Layouts must support long text, text scaling, keyboard navigation, pointer input and screen readers.
- No feature may import Firebase Auth or access raw identity tokens outside the approved authentication data layer.

## Dependency policy

- Before adding or upgrading a library, verify its current stable release, publisher, maintenance status, licence, platform support, changelog, known defects, security advisories and transitive dependencies. For Flutter runtime packages, verify Web, Android and iOS support.
- Default to the latest stable version compatible with the repository's current stable Flutter/Dart or Node.js toolchain. Do not copy an old version from a tutorial or memory.
- A lower version is allowed only for a documented incompatibility, regression, security issue or platform defect. Record the selected version, evidence, impact, exit condition and review date in the relevant design or ADR.
- Do not use prerelease, discontinued, deprecated or unmaintained packages in production foundations. Do not use `any`, unpinned Git dependencies or `dependency_overrides` without a time-bounded accepted exception.
- Prefer the language/framework SDK, an official verified publisher, or a Flutter Favorite before adding a third-party dependency. A package still requires a suitability review; popularity alone is not approval.
- Commit application lockfiles. Treat lockfile changes as source changes and review unexpected transitive updates.
- Never introduce a deprecated API into new code. Deprecation diagnostics are CI failures. Migrate existing deprecated use when touching the surrounding code.
- Run the relevant outdated and advisory checks during dependency work. An advisory may be ignored only with documented proof that it is not reachable or applicable, plus a review date.
- Add dependencies at an adapter boundary. Feature views and view models must not depend directly on vendor SDKs.

The complete admission and upgrade process is in `docs/app_design/dependency_governance.md` and applies by analogy to the server ecosystem.

## Verification

- Keep formatting, static analysis and tests clean.
- Test architectural components separately: services, repositories, view models and views.
- Flutter changes require proportional checks on all affected targets and layout classes, not only the developer's current device.
- Generated files must be reproducible and must never be edited manually.
- Preserve unrelated user changes in the working tree.
