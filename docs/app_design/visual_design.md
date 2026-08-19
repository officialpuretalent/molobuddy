# Molo Product Visual System

- **Status:** Accepted foundation v1.0
- **Applies to:** Flutter Web, Android and iOS
- **First implemented journey:** Authentication
- **Last updated:** 19 August 2026

## 1. Statement

Molo should feel like serious professional power without the visual weight of traditional tax software. The product uses a calm, precise neutral foundation and one clear signal of energy. It is spacious, fast to understand and warm at the moments where people need confidence.

The reference lesson observed in products such as [Revolut](https://www.revolut.com/) is restraint: confident type, generous space, excellent contrast and vivid colour used with purpose. Molo does not copy another company's mark, layouts, typography or signature visual assets. Its own expression is **clear energy**.

## 2. Foundation palette

### Brand primitives

| Token | Value | Purpose |
|---|---:|---|
| `moloBlue` | `#3155F5` | Primary action, active navigation, focus emphasis and key brand moments |
| `moloBlueTint` | `#EEF2FF` | Selected and supportive backgrounds |
| `deepInk` | `#0B1020` | Primary text, dark hero surfaces and authority |
| `canvas` | `#FBFCFE` | Main light canvas |
| `softCloud` | `#F4F6FA` | Secondary surfaces and quiet structure |
| `white` | `#FFFFFF` | Cards and content surfaces |
| `slate` | `#667085` | Secondary text; `4.97:1` against white |
| `cloudLine` | `#D8DEE9` | Borders and dividers |
| `helloCoral` | `#FF6E67` | Small expressive details, illustrations and highlights |
| `aloe` | `#0E9F6E` | Confirmed success |
| `amber` | `#D97706` | Warnings and attention |
| `error` | `#D92D20` | Errors and destructive actions |

`moloBlue` with white text has a WCAG contrast ratio of approximately `5.60:1`. `deepInk` on white is approximately `18.93:1`. These measured pairs are the default for primary controls and body content.

Hello Coral, Aloe and Amber do not carry readable status alone on a light surface. Pair them with an icon, a label and a sufficiently dark text colour. Hello Coral is not a primary button colour and is never used for body text on white.

### Semantic light scheme

| Semantic role | Token |
|---|---|
| Background | `canvas` |
| Surface | `white` |
| Surface muted | `softCloud` |
| Primary | `moloBlue` |
| On primary | `white` |
| Text primary | `deepInk` |
| Text secondary | `slate` |
| Border | `cloudLine` |
| Focus ring | `moloBlue` with a visible outer tint |
| Success | `aloe` plus explicit text/icon |
| Warning | `amber` plus explicit text/icon |
| Error | `error` plus explicit text/icon |

Dark mode is not enabled by simply inverting the light palette. It requires a dedicated, contrast-tested semantic scheme and visual-regression matrix before release. Until then, the application declares the accepted light scheme consistently across targets.

## 3. Typography

Molo uses bundled Geist Sans Regular (400) and Medium (500), registered through the Flutter design system. This avoids platform-dependent rendering and web font loading shift across Web, Android and iOS. Geist is licensed under the SIL Open Font License 1.1; its required notice is included at [`assets/fonts/Geist-OFL-1.1.txt`](../../src/molobuddy_app/assets/fonts/Geist-OFL-1.1.txt). The source font files are identical copies of the accepted TaxBuddy design-system assets and are not modified.

- Use Medium, compact display headings with comfortable line height. Do not request weights above 500 until a matching licensed font file has been admitted.
- Use sentence case everywhere.
- Prefer short, plain labels over tax or software terminology.
- Avoid em dashes in product copy. Use full stops, commas, colons or shorter sentences instead.
- Use tabular figures for dense financial values when that feature arrives.
- Maintain readable measure: authentication copy should not exceed roughly 44–52 characters per line on wide screens.
- Text must remain usable at `200%` scaling without clipping or hidden actions.

## 4. Shape, spacing and elevation

- Use an `8`-point spacing rhythm with `4`-point adjustments for compact internals.
- Primary controls are at least `48` logical pixels high; touch targets are at least `48 × 48`.
- Input and button corners use a confident `14–16` logical-pixel radius.
- Cards use `24–28` logical-pixel radii on large canvases and smaller radii only where space demands it.
- Prefer borders and surface contrast over heavy shadows. Elevation should explain hierarchy, not decorate it.
- Keep the main form narrow even on wide displays; use the extra space for brand storytelling rather than stretching inputs.

## 5. Authentication composition

### Compact windows

The sign-in journey is one scroll-safe column. Brand mark, welcome statement, credentials and actions appear in that order. The primary action remains reachable with an on-screen keyboard and all content remains usable in landscape or split-screen windows.

### Expanded windows

Use a two-part composition:

1. a calm Molo Blue/Deep Ink brand panel that communicates control, momentum and trust;
2. a focused white sign-in surface with no unnecessary navigation or product clutter.

The form keeps the same reading order and interaction model as compact mode. Responsive changes rearrange composition; they do not create a separate feature implementation.

### Authentication controls

- Email and password are the available first method.
- Google appears as a disabled, clearly labelled **Coming soon** option in this slice.
- A disabled provider never starts an SDK flow and remains understandable to screen readers.
- Loading preserves labels where possible and prevents duplicate submission.
- Validation is close to the field, explains how to recover and never exposes raw Firebase or server errors.
- Password visibility is a labelled toggle with a stable touch target.

## 6. Motion

Use motion to clarify arrival, focus and successful progress. Keep transitions short, interruptible and reduced-motion aware. Do not animate credential values, validation errors aggressively or any security warning playfully.

## 7. Accessibility and international quality gate

Every product surface must pass:

1. WCAG AA contrast for text and meaningful controls;
2. keyboard-only navigation in logical reading order on Web;
3. visible focus independent of hover;
4. screen-reader names, roles, state and error relationships;
5. `200%` text scaling and long translated strings;
6. compact, medium and expanded widths;
7. light-theme screenshots on Web, Android and iOS without platform-specific breakage;
8. status communication that remains clear without colour.

## 8. Ownership

Views consume semantic Molo theme tokens; they do not introduce raw colours ad hoc. Brand primitives are centralised in `app/design_system/colour`, while components consume `ColorScheme` and semantic theme extensions. A new colour requires a named role, accessibility evidence and a cross-platform use case.
