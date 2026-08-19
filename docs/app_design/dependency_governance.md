# Dependency and Upgrade Governance

- **Status:** Accepted project policy
- **Applies to:** Flutter foundation; same principles apply to server dependencies
- **Last updated:** 19 August 2026

## 1. Policy

Molo favours the latest **stable, compatible and supportable** release of a framework, package or library.

“Latest” is not a substitute for evaluation. We stay current to receive security fixes, platform compatibility and maintained APIs, while refusing releases with a known regression, vulnerability or incompatibility relevant to Molo.

This policy is summarised for all coding agents in the repository's [`AGENTS.md`](../../AGENTS.md).

## 2. Package admission checklist

Before a new runtime dependency is accepted, record and verify:

1. the capability cannot be met cleanly by Flutter/Dart SDK or an already approved package;
2. current stable version and release date are checked from the authoritative registry/repository;
3. package is not deprecated, discontinued, prerelease-only or abandoned;
4. publisher identity, source repository and release tag/provenance are credible;
5. licence is compatible with commercial distribution;
6. Web, Android and iOS support is explicit and the required platform floors match Molo;
7. current Flutter/Dart stable and Web JavaScript build work;
8. Wasm compatibility is known or the dependency is isolated behind an adapter;
9. changelog and migration notes show no relevant unresolved regression;
10. open high-severity issues and security advisories are reviewed;
11. transitive dependency count, native SDKs, binary size and permissions are reasonable;
12. package does not force a second architecture/state/navigation/networking system;
13. vendor types can be contained behind a Molo-owned interface;
14. unit, widget and platform integration testing strategy is clear;
15. removal/replacement cost is understood.

Prefer, in order:

1. Flutter/Dart SDK capability;
2. package published by `flutter.dev`, `dart.dev`, `firebase.google.com` or another relevant official vendor;
3. a current Flutter Favorite or verified publisher;
4. a well-maintained third-party package with a documented justification;
5. a small Molo-owned adapter/implementation when external dependency risk is greater.

Flutter Favorites are a strong first-review signal based on publisher, licence, usability, runtime behaviour and dependency quality, but Flutter explicitly says the designation is not a suitability guarantee. [Flutter Favorite criteria](https://docs.flutter.dev/packages-and-plugins/favorites)

## 3. Version rules

- Use stable releases only for production foundation packages.
- Set an intentional minimum Flutter/Dart SDK constraint and use versions compatible with the exact CI-pinned Flutter stable patch.
- Direct dependency constraints must never be `any`.
- Do not add Git/path dependencies for published third-party runtime packages.
- Do not use `dependency_overrides` to force a production resolution without a written, expiring exception.
- Commit `pubspec.lock` for the Flutter application so development and deployment use the same resolved graph. Dart recommends committing an application lockfile. [Dart lockfile guidance](https://dart.dev/tools/pub/packages)
- Review the complete lockfile diff; a one-line direct upgrade can replace many transitive packages.
- Keep related vendor families, such as FlutterFire or Riverpod packages, on compatible current releases together.

## 4. Upgrade process

For every Flutter/Dart or dependency upgrade:

1. read upstream release notes, breaking changes and migration guidance;
2. check `flutter pub outdated` including transitive packages;
3. resolve the latest stable compatible versions without overrides;
4. inspect advisories surfaced by Pub and the resulting dependency graph;
5. regenerate code and review generated diffs;
6. run formatting, analysis, unit, widget and architecture tests;
7. build Web, Android and iOS release artefacts;
8. run affected auth, routing, file, deep-link and platform integration smoke tests;
9. compare app size, startup and key interaction measurements to the baseline;
10. record any deliberate holdback with its exit condition.

`flutter pub outdated` distinguishes current, upgradable, resolvable and latest releases. Molo normally moves to the latest **resolvable stable** version, then investigates any gap to latest. [Dart pub outdated](https://dart.dev/tools/pub/cmd/pub-outdated)

## 5. Security advisories

Pub surfaces GitHub Advisory Database findings during dependency resolution. An advisory requires triage; it is not dismissed because the affected package is transitive. [Dart Pub security advisories](https://dart.dev/tools/pub/security-advisories)

An advisory can be ignored only when a committed exception records:

- advisory identifier and affected package/version;
- why the vulnerable path is not present or reachable in Molo;
- evidence/source for the assessment;
- compensating controls;
- owner, expiry/review date and removal condition.

Security fixes can bypass the normal upgrade cadence but not cross-platform verification. A critical reachable issue blocks release.

## 6. Deprecations

- New code cannot use a deprecated API.
- Analyzer deprecation diagnostics are errors in CI.
- When an upgrade introduces deprecations, migrate in the upgrade change unless upstream gives no supported replacement.
- A temporary upstream exception must identify the tracking issue, containment adapter and review date.
- Do not adopt APIs documented as experimental as foundational contracts. Experimental use must be isolated and replaceable.

This is why the foundation uses Riverpod `Notifier`/`AsyncNotifier`, `SharedPreferencesAsync`, `package:web` and source-generated localisations instead of their legacy predecessors.

## 7. Exception record

Use this minimum shape in the relevant ADR/design:

```text
Dependency:
Capability:
Latest stable checked:
Selected version:
Date checked:
Reason for exception:
Evidence / upstream issue / advisory:
Affected targets:
Containment or compensating control:
Exit condition:
Owner:
Review/expiry date:
```

An exception without an exit condition is a permanent architecture decision and requires full architecture review.

## 8. Removal triggers

An approved dependency is re-evaluated when:

- its publisher marks it discontinued/deprecated;
- it misses two relevant stable platform/toolchain cycles without compatibility;
- an unpatched reachable vulnerability exists;
- its licence or data-handling behaviour changes;
- it blocks a required Web, Android or iOS capability;
- its API pushes vendor types across Molo layer boundaries;
- the SDK or an existing approved dependency makes it redundant;
- measured size, startup, memory or reliability cost exceeds its value.

## 9. Acceptance criteria

1. Every direct runtime package maps to one approved capability and adapter boundary.
2. The lockfile contains no unreviewed advisory, Git dependency or forced override.
3. CI rejects deprecated API use and generated-code drift.
4. Upgrade evidence covers Web, Android and iOS for affected runtime packages.
5. Any non-latest selection has a current, evidence-backed exception and exit condition.
6. No feature adds a foundational dependency without updating this catalogue or an accepted design.
