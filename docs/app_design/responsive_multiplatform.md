# Responsive Web, Android and iOS Design

- **Status:** Accepted foundation
- **Targets:** Web, Android and iOS
- **Last updated:** 19 August 2026

## 1. Decision

Molo is one adaptive product, not a stretched phone application and not three unrelated interfaces.

- **Responsive** means the layout fits the available space.
- **Adaptive** means navigation, density, input and composition remain appropriate for that space and platform capability.

Flutter recommends measuring the available window or parent constraints, avoiding device-type/orientation checks, and designing for touch, pointer and keyboard input. [Flutter adaptive design](https://docs.flutter.dev/ui/adaptive-responsive) · [Adaptive best practices](https://docs.flutter.dev/ui/adaptive-responsive/best-practices)

## 2. Molo window classes

Window classes use logical pixels and the space actually granted to the widget:

| Class | Width | Default shell | Content behaviour |
|---|---:|---|---|
| Compact | `< 600` | Bottom `NavigationBar` or focused flow | One pane, full-width forms, stacked actions |
| Medium | `600–839` | `NavigationRail` | One primary pane with optional transient support pane |
| Expanded | `840–1199` | Rail/compact side navigation | List-detail or primary/supporting panes |
| Large | `1200–1599` | Persistent side navigation | Multi-pane with bounded content widths |
| Extra large | `>= 1600` | Persistent side navigation | Multi-pane; whitespace increases before control density |

Breakpoints are central tokens, not scattered numbers. A component may use `LayoutBuilder` and a local constraint when its parent pane is narrower than the window. Use `MediaQuery.sizeOf` only for window-level decisions.

Never branch a layout because a device is named phone, tablet or desktop. Never lock orientation. Multi-window and foldable layouts are first-class cases.

## 3. Adaptive shell

The app shell owns:

- navigation destinations and role/capability visibility;
- selected practice and region state;
- compact, rail and expanded navigation compositions;
- route outlet and browser URL synchronisation;
- app-level banners for offline, session, rollout or maintenance conditions;
- keyboard shortcuts and focus traversal for common work.

Feature views receive constraints from the shell and compose one of these patterns:

- **focused flow:** authentication, onboarding, upload and confirmation;
- **feed/grid:** home, dashboards and work summaries;
- **list-detail:** clients, work items, documents and notifications;
- **supporting pane:** a task/document with contextual actions or activity;
- **bounded form:** one readable column on large displays, not fields stretched edge to edge.

Compact layouts navigate from list to detail. Expanded layouts can show both while keeping the detail route addressable. Browser refresh and back/forward must preserve the same logical destination.

## 4. Responsive component rules

- Build small `const` widgets and share content components across layout compositions.
- Use `SafeArea` where system intrusions can cover controls.
- Set readable maximum widths for forms, paragraphs and dialogs.
- Prefer grids/slivers that respond to minimum card width, not hard-coded column counts.
- Preserve scroll, selection and form state when a window crosses a breakpoint.
- Do not hide required actions solely to make a narrow layout fit; change composition.
- Dialogs may become full-screen flows in compact layouts.
- Tables must define compact alternatives: horizontal scrolling alone is not the default solution for critical workflows.
- Touch targets, hover, focus, keyboard activation and context affordances are designed together.

No third-party responsive package is approved. Flutter's `LayoutBuilder`, specialised `MediaQuery` accessors, `SafeArea`, Flex, Wrap, Grid/Sliver widgets, `NavigationBar`, `NavigationRail` and Molo layout primitives are sufficient and keep the design system under our control.

## 5. Capabilities and policies

Platform differences are exposed as tested Molo-owned interfaces:

```text
AppCapabilities: what this runtime can do
AppPolicies: what Molo should enable here
```

Examples include camera capture, file selection, share support, biometric availability, external-link behaviour, auth-provider availability and browser download support.

Views ask a meaningful question such as `canCaptureDocument` or `shouldUseRedirectAuthentication`; they do not scatter `kIsWeb` and platform checks through features. Flutter recommends this capability/policy separation for scalable adaptive products. [Flutter capabilities and policies](https://docs.flutter.dev/ui/adaptive-responsive/capabilities)

## 6. Web requirements

- Every meaningful screen has a typed, stable, human-readable path.
- Browser refresh, direct entry, back/forward and multi-tab usage are tested.
- Route paths and query strings contain opaque IDs and safe filters only—never tokens, taxpayer identifiers, document names or other sensitive data.
- Use `package:web` and `dart:js_interop` behind adapters when browser APIs are unavoidable; do not introduce `dart:html` or `package:js`.
- The production compatibility baseline is Flutter's JavaScript web output across supported Chrome, Edge, Firefox and Safari.
- Source and dependencies remain Wasm-compatible. A Wasm release becomes primary only after auth redirects/popups, file handling, observability and the full browser matrix pass with the required hosting headers.
- Public SEO/marketing pages are not assumed to be part of the authenticated Flutter application.
- Web builds publish source maps only to the approved symbolication system; source maps are not served publicly.

Flutter documents current Wasm browser limitations and requires compatible dependencies plus specific cross-origin headers for multithreading. Molo therefore treats Wasm as an evidence-gated optimisation, not a launch assumption. [Flutter WebAssembly support](https://docs.flutter.dev/platform-integration/web/wasm)

## 7. Mobile requirements

- Minimum supported platform versions follow the pinned Flutter stable release; the current verified baseline is Android API 24+ and iOS 13+.
- Android back/predictive-back and iOS navigation gestures preserve route semantics.
- Deep links cover sign-in callbacks, invitations and safe product destinations.
- Lifecycle restoration is tested from foreground, background, process death and auth redirect.
- Camera or native file capture is an optional capability; document workflows always offer an accessible file alternative.
- System text scaling, dark/light preference, reduced motion, locale and safe areas are respected.

Flutter 3.44.7 currently supports Android 24–37, iOS 13–26, current mainstream web browsers and JavaScript on all supported web browsers. Target floors must be rechecked whenever Flutter is upgraded. [Flutter supported platforms](https://docs.flutter.dev/reference/supported-platforms)

## 8. Internationalisation and accessibility

- All user-facing strings come from ARB source through Flutter `gen-l10n`; generated localisation source lives inside `lib`, not the removed synthetic `package:flutter_gen` path.
- `en` is the international fallback and `en-ZA` supplies South African launch language and formats.
- Dates, times, currency and numbers are locale-aware; tax jurisdiction never comes from locale alone.
- Layout tests include long translations, Unicode names and right-to-left direction before an RTL locale launches.
- UI remains usable at large text/display scaling without clipping or inaccessible actions.
- Controls have semantic labels, visible focus, keyboard activation and adequate contrast/target size.
- Critical journeys are tested with TalkBack, VoiceOver and browser accessibility tools.

Flutter provides automated accessibility guidelines for tap targets, labels and contrast. These checks are release gates, not late polish. [Flutter accessibility testing](https://docs.flutter.dev/ui/accessibility/accessibility-testing)

## 9. Required test matrix

Every feature is tested at minimum in:

| Target | Required layouts/input |
|---|---|
| Android | Compact portrait and landscape; phone plus resizable/large-screen case; touch and system back |
| iOS | Compact portrait and landscape; phone plus iPad split view; touch, VoiceOver and navigation gesture |
| Web | Compact, medium, expanded and large windows; keyboard, mouse and browser history |

Release browser coverage follows Flutter's supported matrix: latest two Chrome/Edge/Firefox versions and supported Safari versions, with JavaScript output. Wasm builds add their own compatibility lane.

For every class, test loading, empty, error, permission-denied, long-content and large-text states. Golden images may detect visual regression, but semantic/widget assertions remain the source of behavioural truth.

## 10. Acceptance criteria

1. Resizing across every breakpoint retains route, selection, form and scroll state where appropriate.
2. No view decides layout from a device name or orientation alone.
3. Every expanded list-detail view has a coherent compact navigation equivalent.
4. All primary journeys work with touch and keyboard; screen-reader labels are meaningful.
5. Direct web links and browser refresh restore the correct authenticated destination or safe sign-in return path.
6. No sensitive value appears in route paths, query strings, browser history or page titles.
7. Platform-specific APIs are isolated behind capability/service adapters.
8. Each feature's CI evidence covers all three targets and the layout classes it supports.
