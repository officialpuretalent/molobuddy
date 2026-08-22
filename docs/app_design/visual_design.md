# Molo Product Visual System

- **Status:** Accepted foundation v1.1
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
| `moloPlum` | `#241529` | Primary actions, dark brand surfaces, text and professional authority |
| `warmCanvas` | `#FFF9F7` | Main light canvas with quiet warmth |
| `surface` | `#FFFFFF` | Cards and content surfaces |
| `softBlush` | `#F8ECEE` | Secondary surfaces and quiet structure |
| `moloPulse` | `#F25775` | The recognisable Molo signal for momentum, progress and selected moments |
| `pulseTint` | `#FDECEF` | Selected and supportive backgrounds |
| `pulseText` | `#9B263B` | Accessible links, focus and compact accents on light surfaces |
| `secondaryText` | `#685E68` | Secondary text; `6.20:1` against white |
| `controlBorder` | `#9A858D` | Meaningful control boundaries; `3.43:1` against white |
| `border` | `#E4D5D8` | Non-essential dividers and surface separation |
| `success` | `#087A55` | Confirmed success |
| `warning` | `#A85D00` | Warnings and attention |
| `error` | `#C2382B` | Errors and destructive actions |
| `information` | `#3459D4` | Informational states only, not general brand decoration |

Measured contrast pairs include Molo Plum on white at approximately `17.29:1`, Molo Pulse on Molo Plum at `5.27:1`, Pulse Text on white at `7.68:1` and Control Border on white at `3.43:1`.

Molo Pulse is a signature, not a flood colour. Primary actions normally use Molo Plum. Pulse marks progress, meaningful selection and a small number of brand moments. It never replaces semantic success, warning or error colour, and it is not used as body text on white.

### Semantic light scheme

| Semantic role | Token |
|---|---|
| Background | `warmCanvas` |
| Surface | `surface` |
| Surface muted | `softBlush` |
| Primary action | `moloPlum` |
| On primary | `surface` |
| Signature accent | `moloPulse` |
| Text primary | `moloPlum` |
| Text secondary | `secondaryText` |
| Control boundary | `controlBorder` |
| Quiet divider | `border` |
| Focus ring and links | `pulseText` |
| Success | `success` plus explicit text/icon |
| Warning | `warning` plus explicit text/icon |
| Error | `error` plus explicit text/icon |
| Information | `information` plus explicit text/icon |

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

### Panels that float over a surface

A menu, popover or modal traced from the design draws its own shape: fill,
radius, border and shadow. Host it in something that supplies no surface of its
own, or the two fight and the host wins.

Material's menu and dialog widgets are not neutral hosts. `MenuAnchor`,
`PopupMenuButton`, `Dialog` and `Card` each wrap what you give them in their own
`Material` — with a shape, an elevation and `clipBehavior: Clip.hardEdge` — and
a menu adds padding, a scroll view that also clips, and a scrollbar that is
always on while the menu is open. A panel drawing its own shadow inside that
gets the shadow **clipped to its own bounding box**, so it survives only where
the corner radius leaves the box: a hard grey wedge in each rounded corner and
no shadow anywhere else. It reads as a second rectangle sitting behind the
panel, which is how this was first reported.

The rule:

- A panel that owns its surface is hosted by `RawMenuAnchor` and its
  `overlayBuilder`, which keeps dismissal, focus and the anchor rect while
  supplying no `Material`, no padding, no scroll view and no scrollbar.
- Position it from the anchor rect rather than relying on a menu to flip itself:
  `bottom: overlaySize.height - anchorRect.top + gap` puts a panel above its
  anchor outright.
- Never two shadows. If the host draws one, the panel must not, and the reverse.
  Check for `elevation`, `shadowColor`, `boxShadow`, `PhysicalModel` and
  `PhysicalShape` on both sides.
- Wrap the panel in a `TapRegion` carrying the overlay's `tapRegionGroupId` so a
  tap outside closes it.

Two conversions worth writing down, because both look like a wrong number
otherwise:

- CSS states a blur *radius*, which is twice the Gaussian deviation, while
  Flutter converts a radius with `radius * 0.57735 + 0.5`. A design's
  `40px` blur is a deviation of `20`, which is a Flutter `blurRadius` of about
  `33.8`. Passing `40` straight through spreads it half again as far.
- A CSS border sits inside the box it measures. A Flutter `Border` paints over
  the box without reserving room, so a bordered panel needs a `Container`, which
  adds the border's dimensions to its padding, rather than a `DecoratedBox`.

Do not judge a shadow from a widget test. `flutter_test` sets
`debugDisableShadows`, so shadows paint as solid unblurred shapes and every
shadow looks like a hard offset rectangle. Assert the `BoxShadow` values
directly, and confirm the appearance in a browser.

## 5. Authentication and onboarding composition

Both halves are traced from the design baseline, and this section describes what
ships.

### Sign-in, compact windows

One scroll-safe column. The brand lockup and the offer to create an account
share the top row, then the time-of-day kicker, the welcome statement, the
credentials, the session choice, the actions and the legal footer, in that
order. The primary action remains reachable with an on-screen keyboard and all
content remains usable in landscape or split-screen windows.

The row that holds the lockup and the action is flexible in both directions:
under text scaling the lockup gives ground first and the action's label
truncates second, so the two never paint over each other.

### Sign-in, expanded windows

A two-part composition:

1. a photographic hero pane at 44% of the window, on a Molo Plum ground, under
   a vertical scrim that carries the text's contrast rather than merely
   darkening the image. The lockup sits at the top, the brand promise and one
   supporting line at the bottom, in a column about thirty characters wide;
2. a focused sign-in surface, 384 wide and vertically centred, with no
   navigation or product clutter.

The plum panel with two orbs and three story points is retired, and so are the
brand-story strings that fed it. The photograph ships re-encoded inside a
300 KB budget: a sign-in page is not a place to spend two megabytes.

The form keeps the same reading order and interaction model as compact mode.
Responsive changes rearrange composition; they do not create a separate feature
implementation.

### Authentication controls

- Email and password are the available first method. The field label sits above
  the field rather than floating inside its outline, which leaves the label row
  free to carry an action such as password recovery.
- Microsoft and Google are both drawn and both disabled, each behind its own
  brand mark. A 46-high grid cell has no room for a **Coming soon** pill, so
  the reason is the control's accessible name instead.
- A third-party brand mark is not a Molo glyph and does not live with them. Molo
  glyphs are a single stroked outline that takes its colour from its context; a
  brand mark is several filled shapes in colours its owner fixes. They are held
  in separate types so a mark can never be handed to the glyph painter and
  quietly re-coloured, and the mark's painter takes no colour parameter at all.
- A disabled provider keeps its mark in full colour. The disabled state is
  carried by the muted label and outline, because a greyed logo reads as the
  wrong provider rather than as one that is not ready yet.
- A disabled provider never starts an SDK flow and remains understandable to
  screen readers.
- "Keep me signed in on this device" appears only where the platform can honour
  it. Web can: the session is held in local storage or dropped with the tab.
  Android and iOS always persist, so the row is absent there rather than
  disabled — a control that cannot do anything is worse than no control.
- Loading preserves labels where possible and prevents duplicate submission.
- Validation is close to the field, explains how to recover and never exposes
  raw Firebase or server errors.
- Password visibility is a labelled toggle. The design draws one eye for both
  states and changes only the control's name, so the drawn box is 36 while the
  reachable one stays 48.

### Where sign-in departs from the baseline

Traced values are reproduced exactly, except where the baseline falls short of
section 7's gate. Each of these carries its reason in the code:

- **12px text is not painted `#9A858D`.** That colour is 3.30:1 on the warm
  canvas, and the time-of-day kicker, the "or" divider label and the legal
  footer are ordinary text at 12px, where WCAG 1.4.3 asks for 4.5:1. They take
  Secondary Text at 5.94:1.
- **Field and checkbox outlines are not painted `#E4D5D8`.** At 1.42:1 the
  outline that identifies a control would fail WCAG 1.4.11's 3:1. They take
  Control Border at 3.43:1.
- **The switch pill keeps Control Border in its hovered state too.** Its fill is
  invisible against the pane it sits on, so the outline is the only thing
  identifying it, in every state it has.
- **The two provider buttons do keep the quiet border.** They are permanently
  disabled, and 1.4.11 exempts an inactive control.

### The signup wizard

Four stages, spanning two routes. The account step is at `/sign-up`; the rest
are at `/onboarding`, where every answer is saved before the wizard advances, so
an interrupted signup resumes rather than stranding an account.

1. **Your account:** name, work email, password and terms acceptance.
2. **Shape your workspace:** practice name, team size and primary tax region,
   with the benefit of each default made clear.
3. **Choose your first win:** the outcomes the user wants Molo to improve first.
4. **Make it useful:** import clients, add a first client or explore a sample
   workspace.

There is no completion screen. Founding the practice enters the workspace, which
is the thing the wizard was for.

### The wizard rail

Expanded windows pair the form with a dark rail at 38% of the window, capped at
460 — narrower than sign-in's photographic hero, because a list of four steps
earns less width than a photograph.

The rail names **all four** steps, not only the current one, and marks each as
behind, on screen or ahead: a finished step's chip carries a tick rather than its
number, the current one is filled warm canvas, and one still ahead is quiet.
Someone three steps in can see what is left rather than only how far a bar has
travelled. Below the steps sit a workspace card, which shows the practice name as
it is being typed, and the readiness figure with its bar.

The rail is decoration. Nothing in it is focusable and nothing in it acts: the
step on screen is announced by the form's own heading, and four
unreachable-looking tab stops in front of the first field would cost more than
they explain. It scrolls rather than clipping when the window is short.

The rail names steps from outside them ("Your practice") while the form names
tasks ("Shape your workspace"), which is how it avoids repeating the active form
back at the reader. The one exception is step one, which the baseline calls "Your
account" in both places.

Below 900 the rail goes and the header gains the brand lockup it was carrying,
which is exactly what the baseline does. Nothing stands in the rail's place: no
progress bar, no step count, no practice chip. An earlier pass added all three on
the argument that someone four steps into signup on a phone has no sense of
position; the baseline disagrees, and the step's own eyebrow already names where
the reader is.

The 900 is the baseline's own threshold rather than one of the app's window
classes, which turn at 840. Following the classes drew a rail between 840 and 900
that the design does not draw, so sign-in and the wizard keep the design's number
and every other screen keeps the classes.

### Choice cards

Every option is one card: a traced glyph, a title, a line of explanation, and a
mark. The mark's **shape** says how many answers are allowed before anything is
chosen — round where choosing one unchooses its siblings, square where it does
not. There is exactly one control per answer; an earlier version hung a Material
checkbox beside the card's own mark, which meant two controls painting one state.

Selection and keyboard focus share the strong outline; hover only firms the quiet
one. What tells a focused card from a chosen one is the mark, which is where the
state actually lives.

### Where the wizard departs from the baseline

- **A step's footnote and the password hint are not painted `#9A858D`.** At 12px
  both are ordinary text, and that colour is 3.30:1 on the warm canvas where
  WCAG 1.4.3 asks for 4.5:1. They take Secondary Text at 5.94:1. The satisfied
  password hint reuses the existing Success token at 5.35:1 rather than admitting
  the baseline's own near-identical green.
- **A step's primary action looks incomplete but stays pressable.** The baseline
  disables it. Pressing is how a pointer user learns what is missing — it is what
  puts the inline messages on the fields — so the control keeps the quiet
  appearance, gains a spoken reason naming what is outstanding, and still acts.
- **The unselected choice mark's outline is Control Border**, not the baseline's
  1.49:1: it is the only thing that says a control is there.
- **The rail's own alphas are kept exactly.** Every piece of text it draws on
  plum was measured and clears 4.5:1, the lowest being the step note at 5.02:1.
  Its readiness figure takes a lighter pink than the bar it labels, so the number
  separates itself from the fill rather than competing with it.

The signup wizard and onboarding use the same supporting-pane width at every expanded breakpoint. The shared edge must remain fixed as those two routes fade into each other, so navigation never reveals a geometry jump. Sign-in is not part of that edge: it is a different pane, and the baseline deliberately draws the photographic hero wider than the wizard's rail.

The preview follows the accepted production boundaries: Firebase Authentication will own account creation, and the Molo API will provision the practice, owner membership, home region and defaults. Primary tax region, locale, currency and data residency remain separate concepts even when the first available choice is South Africa.

## 6. Motion

Use motion to clarify arrival, focus and successful progress. Keep transitions short, interruptible and reduced-motion aware. Do not animate credential values, validation errors aggressively or any security warning playfully.

- Web startup uses a lightweight HTML Molo handoff instead of Flutter's generic progress treatment. It shares the warm canvas, plum wordmark and Pulse accent, then fades only after Flutter has started the app.
- Route arrival uses a restrained `180ms` opacity transition. Reverse navigation uses `140ms`. Pages do not slide.
- Onboarding step changes use a `170ms` opacity transition so the relationship between stages remains clear without spatial movement.
- Motion uses Flutter SDK primitives and browser CSS. No animation dependency is admitted for this foundation.
- `MediaQuery.disableAnimationsOf` and `prefers-reduced-motion` reduce these transitions to an immediate state change.

Checkboxes use a six-pixel rounded rectangle, a plum selected fill and state-aware Pulse focus and hover treatment. The full control retains the platform-standard touch target even though the visible mark remains compact. In legal consent rows, only the checkbox changes consent. Legal document names are separate, visibly underlined links; the surrounding sentence is never one large tap target.

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
