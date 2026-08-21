# Authentication and Onboarding Design Fidelity

- **Status:** Draft v0.1, awaiting review
- **Owner:** Product and engineering
- **Last updated:** 21 August 2026
- **Design baseline:** `docs/product/Design baseline and scope clarification/Molo workbench.dc.html`, `isSignIn` (lines 217-300), `isSignUp` (lines 38-216) and `signupVals()` (line 5259)
- **Related contracts:** [visual system](../app_design/visual_design.md), [founding onboarding design](2026-08-20-founding-onboarding-design.md), [responsive and multiplatform](../app_design/responsive_multiplatform.md), [architecture](../app_design/architecture.md)

## 1. Decision

Sign-in, the account step and the onboarding wizard are re-traced from the
design baseline, as the workspace sidebar and top bar already were.

**No data changes.** Every answer the baseline collects is already collected
today, under the same names. The design's three practice sizes, four goals and
three starting points match `OnboardingAnswers` and its wire values word for
word, and most of the copy already sits in `app_en.arb`. Nothing moves on the
wire, no server call changes, and the persisted onboarding record is untouched.

Two behaviours are new: session persistence on Web behind the baseline's
"Keep me signed in on this device", and a second federated provider button.

## 2. Scope

In scope:

1. Sign-in re-traced, including the photographic hero and the remember-me row.
2. `MoloWizardShell` re-traced, its progress panel becoming the baseline's
   four-step rail.
3. The account step and the three onboarding steps re-traced.
4. The option-card glyphs traced from the baseline, replacing Material icons.
5. Web session persistence, chosen by the user at sign-in.
6. Section 5 of the visual system rewritten to describe what now ships.

Out of scope:

- Any change to the onboarding record, its wire contract or the practice
  founding call.
- Making Microsoft or Google sign-in actually work. Both stay disabled.
- Forgot-password. The link keeps today's "coming soon" message.
- The workbench screens behind sign-in, which are already traced.

## 3. Route structure

The baseline draws one four-step wizard. The application keeps two routes, and
must:

- `/sign-up` owns step 1. Creating the account creates the Firebase user, which
  is the moment after which answers can be persisted per user.
- `/onboarding` owns steps 2 to 4, resuming from the step the server derived.

Merging them into one route with an internal pager was rejected: it would
discard the resumability that [founding onboarding](2026-08-20-founding-onboarding-design.md)
section 1 exists to provide, for a purely visual gain the shared shell already
delivers. Giving each route its own rail was rejected because the visual system
requires the supporting-pane edge to stay fixed across authentication
navigation, so a route fade never reveals a geometry jump.

`MoloWizardShell` therefore stays the single owner of the chrome. Its input
grows from a step number, a readiness figure and a practice name to also carry
the four step descriptors, so the rail can mark steps done, current and
pending without knowing which route it is decorating.

## 4. Sign-in

### 4.1 Composition

Expanded windows are a two-part row: a `44%` hero pane and the form.

| Element | Value |
|---|---|
| Hero pane | `flex 0 0 44%`, plum ground, `signin-portrait.png` at `cover`, position `62% 50%`, padding 40 |
| Hero scrim | vertical gradient, plum at `0.72` → `0.28` at 42% → `0.86` at 100% |
| Hero promise | 30px, line height 1.2, tracking `-0.02em`, max 30ch |
| Hero body | 14px, line height 1.6, surface at `0.72` alpha |
| Form column | 384 max width, vertically centred, group gap 26 |
| Pane padding | 28 top, 32 sides, 40 bottom |

The plum panel with two orbs and three story points is retired, along with
`brandStoryTitle`, `brandStoryBody` and `brandStoryPointOne` to `Three`. The
promise reuses the existing `brandPromise` string; the hero body is new copy.

### 4.2 Order and controls

1. Header row, right aligned: "New to Molo?" and an outlined pill,
   "Create an account". This moves from the bottom of the form to the top of
   the pane. On compact windows the wordmark takes the left of the same row and
   the "New to Molo?" label drops, leaving the pill, which is the only part
   that acts.
2. Heading group: a 12px uppercase time-of-day kicker, "Welcome back" at 34px,
   then the sign-in blurb. The baseline names a workspace in the blurb; the
   application cannot know one before sign-in, so `signInSubtitle` stands.

   The kicker follows the baseline's rule: morning before 12:00, afternoon
   before 17:00, evening after. This needs three new strings. The home screen's
   greeting is a fixed "Good morning." today; making it follow the clock is
   that screen's own work and is out of scope here.
3. Work email, then password. The password label row carries "Forgot password?"
   on its right, replacing the link below the field.
4. "Keep me signed in on this device", checked by default.
5. Primary "Sign in", 52 high, radius 15.
6. An "or" divider, then a two-column grid of Microsoft and Google, 46 high,
   radius 14, both disabled.
7. Left-aligned legal footer, which gains the baseline's sentence that Molo
   never signs in to eFiling on the user's behalf.

### 4.3 Session persistence

The remember-me row is Web-only. Firebase always persists a session on Android
and iOS, so a control that claimed otherwise there would be a lie; the row is
absent rather than inert.

`AuthService.signInWithEmailAndPassword` gains a `persistSession` argument.
`FirebaseAuthService` sets `Persistence.LOCAL` or `Persistence.SESSION` before
signing in, and only on Web. Preview and unavailable implementations accept the
argument and ignore it. No Firebase type crosses the auth data layer boundary.

### 4.4 Provider buttons

Both buttons are declared by the view and both are disabled, as decided during
design. Labels are the baseline's bare product names. The 46-high grid cell
has no room for the "Coming soon" pill, so the reason moves into each button's
accessible name, which keeps the visual system's rule that a disabled provider
never starts an SDK flow and stays understandable to a screen reader.

This deliberately does not read `AuthMethodDescriptor` from the catalogue.
Wiring these buttons to real federated sign-in will need the catalogue again,
and that work owns re-connecting them.

## 5. The wizard rail

Replaces the current workspace preview panel. Dark aside, `flex 0 0 38%` capped
at 460, padding 40 sides and top, 36 bottom, group gap 40.

| Element | Value |
|---|---|
| Header | wordmark left, "Step n of 4" right at 13px, surface at `0.6` |
| Step row | gap 14, padding 12 vertical |
| Step chip | 28 square, fully round, 13px medium |
| Chip, done | pulse fill, plum mark, `✓` |
| Chip, current | warm canvas fill, plum number |
| Chip, pending | white at `0.1`, surface at `0.6` number |
| Step title | 15px medium; surface when current, `0.72` otherwise |
| Step note | 13px, line height 1.5, surface at `0.5` |
| Workspace card | padding 20, radius 18, white at `0.06` |
| Card eyebrow | 12px uppercase, tracking `0.08em`, surface at `0.55` |
| Card practice name | 24px medium, tracking `-0.02em` |
| Card body | 13px, line height 1.6, surface at `0.66` |
| Readiness label | 13px, surface at `0.72` |
| Readiness figure | 13px, tabular figures, `pulseOnDark` |
| Readiness track | 4 high, fully round, white at `0.16` |
| Readiness fill | pulse, width animated over 320ms |

Readiness stays 12, 32, 58 and 82 per step, which the current implementation
already uses.

The rail's four titles and notes are its own, distinct from the step eyebrows
shown in the form:

| Step | Rail title | Rail note |
|---|---|---|
| 1 | Your account | Name, email and a password |
| 2 | Your practice | Practice, team size and region |
| 3 | Your first win | What you want to fix first |
| 4 | Your starting point | Real data or a sample |

The unused `progressAccount`, `progressPractice` and `progressPriorities`
strings and their bodies are retired in favour of these.

### 5.1 Compact windows

The baseline hides the rail and puts nothing in its place. This design keeps
today's slim progress bar and practice summary chip, because someone four steps
into signup on a phone otherwise has no sense of position, and section 5 of the
visual system already requires progress in one scroll-safe column. This is a
deliberate departure from the baseline, recorded here so it is not read as an
oversight.

## 6. Wizard content pane

Content column 452 max, pane padding 28 top, 32 sides, 48 bottom, 56 above the
first element. Header row right aligned: "Already have an account?" and the
outlined pill "Sign in".

Order: back link, eyebrow, title, blurb, the step's controls, primary button,
footnote.

| Element | Value |
|---|---|
| Back link | 14px `pulseText`, traced 16px arrow, gap 8, plum on hover |
| Eyebrow | 13px medium `pulseText` |
| Title | 34px medium, tracking `-0.025em`, line height 1.12 |
| Blurb | 15px `secondaryText`, line height 1.6 |
| Primary | 52 high, radius 15 |
| Footnote | 12px `controlBorder`, line height 1.6 |

The four footnotes are new copy, taken from the baseline, one per step.

### 6.1 Choice cards

| Element | Value |
|---|---|
| Card | radius 16, padding 16 vertical 18 horizontal, gap 14 |
| Card, resting | surface fill, `border` outline |
| Card, selected | `pulseTint` fill, `pulseText` outline plus a 1px inset ring |
| Card, hovered | `controlBorder` outline |
| Icon | 19px traced glyph; `controlBorder`, `pulseText` when selected |
| Title | 15px medium plum |
| Description | 13px `secondaryText`, line height 1.5 |
| Single-choice mark | 21 round; `pulseText` fill and white tick when selected |
| Multi-choice mark | 21 square, radius 7; plum fill and white tick when selected |

The trailing Material `Checkbox` on the goals step is replaced by the
multi-choice mark, so one control paints one state.

### 6.2 Step 1, the account

Full name, work email, then password with a visibility toggle and a hint line
below it. The hint reads "Use at least 8 characters." in `controlBorder` and
"Long enough." in `success` once the password is long enough. The baseline's
own green is `#2C7A62` at `5.17:1` on white; the existing `success` token is
`#087A55` at `5.35:1`, so this reuses the token rather than admitting a
near-duplicate colour.

The terms row is a 21 square check, radius 7, with the sentence beside it. Only
the check changes consent; the two document names stay separate underlined
links, as the visual system requires.

### 6.3 Steps 2 to 4

Unchanged in substance. Practice name, the three-way team size, and the
single-option tax region select; then the four goals as multi-choice; then the
three starting points as single-choice. Only their presentation moves to the
values above.

### 6.4 The primary button when a step is incomplete

The baseline disables it: `border` fill, `controlBorder` label. That pairing is
about `1.9:1`, which WCAG exempts for a disabled control, and the current
implementation instead keeps the button live and reveals what is missing on
press.

This design takes the baseline's appearance and adds an accessible hint naming
what is still outstanding, so a keyboard or screen-reader user is told why the
button will not act rather than meeting a dead control. Inline field hints stay.

## 7. Design system changes

### 7.1 Glyphs

Ten option glyphs, plus a back arrow, an eye and a tick, traced from the
baseline's paths into `MoloGlyphs` under the existing 18-unit convention. These
replace `Icons.person_outline_rounded`, `Icons.event_available_outlined` and
the rest of the Material set now used by the wizard steps.

### 7.2 Fields

Fields adopt the baseline's geometry: 50 high, radius 14, 16 horizontal
padding, 15px value text, with a 13px medium label above rather than a floating
Material label.

They do **not** adopt the baseline's resting border. `#E4D5D8` is `1.42:1` on
white, and a text field's outline is the visual information that identifies the
control, which WCAG 1.4.11 requires at `3:1`. Resting borders therefore stay
`controlBorder` at `3.43:1`. The baseline moves a focused field's border from
`#E4D5D8` to `#9A858D`, which is unavailable once resting is already that
colour, so focus keeps today's 2px `pulseText` border. The same reasoning keeps
`controlBorder` on the unselected choice
marks and the unchecked terms box, where the baseline draws `#D8C6CB` at
`1.49:1`. Decorative card outlines, whose component identity comes from the
text inside them, keep the quiet `border`.

Changing the input theme globally is safe: these three views hold every
`TextField` in the application, and `MoloSearchField` draws its own chrome.

### 7.3 Radii

The baseline uses 12 for the small pill, 14 for fields and secondary buttons,
15 for a primary button, 16 for a choice card and 18 for the rail's workspace
card. These join the existing 14 and 24 as named values rather than appearing
as literals.

### 7.4 New colours

| Token | Value | Role | Evidence |
|---|---|---|---|
| `pulseOnDark` | `#F98FA4` | The readiness figure in the wizard rail | `7.93:1` on `moloPlum` |
| `pulseBorder` | `#E9B9C4` | Hover outline for a pill on a tinted surface | Hover decoration only; the resting outline carries identity |
| `moloPlumHover` | `#3A2440` | Hover fill for a plum primary action | Fill only; the surface label stays above `15:1` |

Each has a named role and a cross-platform use, as section 8 of the visual
system requires.

### 7.5 The switch pill

Both screens offer the other one through the same control, so it is one
component rather than a style repeated twice: 13px medium plum label, 9
vertical and 16 horizontal padding, radius 12, surface fill, `border` outline,
turning `pulseTint` with a `pulseBorder` outline on hover. It replaces the
`TextButton` used for this today, which read as a link where the baseline draws
a button.

### 7.6 The hero asset

`signin-portrait.png` is 1.85 MB at 1024x1536, which is not shippable on a
sign-in page. It is re-encoded under 300 KB and committed to
`assets/brand/`, registered in `pubspec.yaml`, and shown only in expanded
windows. `signin-team.png` is unused by the baseline and is not adopted.

## 8. Accessibility and platform quality

Unchanged gates, restated where this design touches them:

1. Every traced value is checked against WCAG AA, and the three places where
   the baseline falls short are resolved in sections 6.4 and 7.2.
2. Keyboard order follows the visual order on both screens, and the focus ring
   stays independent of hover.
3. The rail is decoration: it is not in the tab order, and the step it marks is
   announced by the form's own heading.
4. Both screens are verified at compact, medium and expanded widths and at
   200% text scale. The hero, the rail and the provider grid all collapse.
5. The remember-me row's absence on Android and iOS is a platform capability
   difference, not a layout branch on device labels.

## 9. Verification

1. Fidelity tests measuring the traced values, in the manner of
   `molo_sidebar_fidelity_test.dart`: pane split, rail metrics, step chip
   states, field and button geometry, choice-card and mark treatment.
2. Widget tests for the new behaviour: the remember-me row present on Web and
   absent elsewhere, persistence passed through on sign-in, both provider
   buttons disabled and named, and the primary button's hint naming what is
   outstanding.
3. The existing signup journey, onboarding gate, sign-in and onboarding view
   tests keep passing unchanged in intent; only selectors move.
4. Analyser and formatter clean, and the app run in a real browser at all
   three layout classes.

## 10. Documentation

Section 5 of the visual system is rewritten to describe this composition. It
currently accepts the plum brand panel with controlled pulse moments and
describes a completion screen that no longer exists, so leaving it would put an
accepted document in conflict with the code.
