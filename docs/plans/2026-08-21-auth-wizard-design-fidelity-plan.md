# Signup Wizard and Onboarding Design Fidelity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Re-trace the four-step signup wizard — the account step at `/sign-up` and the three onboarding steps at `/onboarding` — from the design baseline, collecting exactly the answers it collects today.

**Architecture:** `MoloWizardShell` stays the single owner of the chrome across both routes. Its progress contract grows from a step number and a readiness figure to also carry the four step descriptors, so the new dark rail can mark steps done, current and pending without knowing which route it is decorating. The rail moves into its own file, and `MoloChoiceCard` moves out of the shell into the design system, where it is re-traced with the option glyphs and the two selection marks. Nothing moves on the wire.

**Tech Stack:** Flutter Web/Android/iOS, Riverpod 3 (generated providers), `go_router` typed routes, `flutter_test`.

**Spec:** [docs/plans/2026-08-21-auth-onboarding-design-fidelity-design.md](2026-08-21-auth-onboarding-design-fidelity-design.md) — sections 3, 5, 6, and the parts of 7 and 8 the wizard consumes. Sections 4 and the sign-in half are already shipped by [the sign-in plan](2026-08-21-auth-sign-in-design-fidelity-plan.md); read it for the components this plan reuses.

## Global Constraints

- Riverpod 3 only. Generated providers, `Notifier`/`AsyncNotifier`, immutable state. No other state system.
- Controllers, focus nodes and animation controllers stay local to the widget; Riverpod owns shared and asynchronous state.
- **No change to the onboarding record, its wire contract, or the practice-founding call.** `OnboardingAnswers`, its three enums and every wire value stay exactly as they are. If a step's save changes shape, the change is wrong.
- Every user-facing string is localised, in **both** `lib/app/localisation/l10n/app_en.arb` and `app_en_ZA.arb`. `l10n.yaml` sets `use-escaping: true`, so a straight apostrophe is doubled (`Let''s`); a curly `’` is written as-is. Before committing an ARB change, check for a duplicate key — JSON keeps both and the last wins:
  ```bash
  python3 -c "import re,collections,io;[print(p,{k:c for k,c in collections.Counter(re.findall(r'^  \"(@?[A-Za-z0-9_]+)\":',io.open(p).read(),re.M)).items() if c>1} or 'clean') for p in ['lib/app/localisation/l10n/app_en.arb','lib/app/localisation/l10n/app_en_ZA.arb']]"
  ```
- Localisations are generated, never hand-edited: after an ARB change run `flutter gen-l10n`.
- Riverpod and router code is generated, never hand-edited: after a provider change run `dart run build_runner build --delete-conflicting-outputs`.
- Branch on available layout space and platform capability, never device labels or orientation.
- Every screen works on Web, Android and iOS, at compact, medium and expanded widths and at 200% text scale.
- Deprecated APIs are CI failures. In particular `SemanticsNode.hasFlag` and `containsSemantics` are both deprecated: assert semantics with **`isSemantics`**.
- All work happens in `src/molobuddy_app`; every `flutter`/`dart` command runs from there.
- Commands: `flutter analyze`, `dart format .`, `flutter test`.

## What the sign-in half already built, and this plan reuses

Do not rebuild any of these:

| Component | Use it for |
|---|---|
| `MoloTextField({label, controller, fieldKey, trailing, hintText, errorText, enabled, obscureText, suffix, autofillHints, keyboardType, textInputAction, focusNode, onSubmitted, autocorrect})` | Every field, in all four steps |
| `MoloCheckRow({label, semanticLabel, value, onChanged, enabled, boxSize})`, with `MoloCheckRow.boxKey` | The terms row on step 1 |
| `MoloPillButton({label, onPressed})` | The "Sign in" pill in the pane header |
| `MoloBrandLockup({onDark, compact, labelled, markKey})` | The rail's header and the compact pane header |
| `MoloGlyphs.eye`, `MoloGlyphs.tick`, `MoloIcon(glyph, size:, color:)` | The password toggle, and the tick inside every selection mark |
| `MoloSpacing.pillRadius/controlRadius/primaryActionRadius/choiceCardRadius/railCardRadius` | 12 / 14 / 15 / 16 / 18 |
| `MoloColours.pulseBorder`, `MoloColours.moloPlumHover` | Already defined; the primary's hover is already in the theme |
| Theme: fields 50 high at radius 14 with 15px text; `FilledButton` 52 high at radius 15 | Nothing to set per call site |

## Deviations from the baseline this plan settles

1. **The step footnote is not painted `controlBorder`.** Spec section 6 gives it `#9A858D`, which is **3.30:1** on the warm canvas. At 12px it is ordinary text and WCAG 1.4.3 wants 4.5:1, so it takes `secondaryText` (5.94:1) — the same resolution the sign-in half applied to its kicker, divider label and legal footer.
2. **The rail's own alphas are kept exactly.** Every piece of text the rail draws on plum was measured and clears 4.5:1: the current step title at 16.59:1, an inactive one at 9.03:1, the step label and pending chip number at 6.65:1, the step note at 5.02:1, the card eyebrow at 5.76:1, the card body at 7.76:1, the readiness label at 9.03:1 and its figure at 7.82:1. The pending chip's fill, the readiness track and the card's fill are decorative surfaces, not control identifiers — the chip's *number* is what carries its state.
3. **The primary action looks incomplete but stays pressable.** Spec section 6.4 takes the baseline's disabled appearance and adds a spoken reason. It does not take the baseline's disabled *behaviour*: pressing is what reveals the inline field errors, and section 6.4 keeps those. A control that looked incomplete and did nothing would remove the only way a pointer user learns what is missing.
4. **Compact windows keep the progress bar and practice chip.** Spec section 5.1, already recorded there as a deliberate departure. `_CompactProgress` and `_CompactWorkspaceSummary` stay.

## File Structure

**Created**

| File | Responsibility |
|---|---|
| `lib/app/adaptive/molo_wizard_rail.dart` | The dark rail: header, four step rows, workspace card, readiness |
| `lib/app/design_system/components/molo_choice_card.dart` | The option card and its two selection marks |
| `lib/app/design_system/components/molo_field_label.dart` | The 13px label above a field, shared by `MoloTextField` and the region select |
| `test/widget/app/molo_choice_card_test.dart` | Card geometry, states, marks, semantics |
| `test/widget/app/molo_wizard_rail_fidelity_test.dart` | Rail metrics and the three chip states |
| `test/widget/core/onboarding/wizard_pane_fidelity_test.dart` | Pane geometry, heading group, back link, primary and footnote |

**Modified**

| File | Change |
|---|---|
| `lib/app/design_system/icons/molo_glyphs.dart` | Eleven traced glyphs: ten options and a back arrow |
| `lib/app/design_system/colour/molo_colours.dart` | `pulseOnDark` |
| `lib/app/adaptive/auth_shell_layout.dart` | `wizardRailWidth` |
| `lib/app/adaptive/molo_wizard_shell.dart` | `WizardProgress` grows step descriptors; the rail replaces the preview panel; pane geometry; header pill; the step widgets |
| `lib/app/design_system/components/molo_text_field.dart` | Its label becomes the shared `MoloFieldLabel` |
| `lib/core/auth/ui/views/registration/registration_view.dart` | Step 1 re-traced |
| `lib/core/onboarding/ui/views/onboarding_view.dart` | Steps 2 to 4 re-traced |
| `lib/app/localisation/l10n/app_en.arb`, `app_en_ZA.arb` | Rail titles and notes, four footnotes, the password-ok hint; thirteen dead strings retired |
| `test/widget/core/auth/registration_view_test.dart`, `test/widget/core/onboarding/onboarding_view_test.dart`, `test/widget/app/signup_journey_test.dart` | Selectors move |
| `docs/app_design/visual_design.md` | Section 5's wizard and onboarding paragraphs |

---

### Task 1: The eleven wizard glyphs

**Files:**
- Modify: `lib/app/design_system/icons/molo_glyphs.dart`
- Test: `test/widget/app/molo_glyph_test.dart` (append)

**Interfaces:**
- Consumes: `MoloGlyph`, `MoloGlyphs.viewBox`, `MoloIcon` — all existing.
- Produces, all `MoloGlyph`: `practiceSolo`, `practiceSmallTeam`, `practiceGrowing`, `goalDeadlines`, `goalDocuments`, `goalTeamwork`, `goalVisibility`, `startImport`, `startFirstClient`, `startSample` (18-unit box each), and `backArrow` (16-unit box).

Every path below was mechanically converted from the baseline's own `d` attributes in `whoDefs`, `goalDefs`, `beginDefs` and the back button — SVG's `a` maps one-to-one onto `Path.arcToPoint`, so the arcs are the baseline's arcs and not an approximation of them. Each is stroked at `stroke-width: 1.5`, `linecap: round`, `linejoin: round`, which is what `cap`/`join` below say.

- [ ] **Step 1: Write the failing test**

Append to `test/widget/app/molo_glyph_test.dart`, inside `main()`:

```dart
  group('wizard option glyphs', () {
    final options = <String, MoloGlyph>{
      'practiceSolo': MoloGlyphs.practiceSolo,
      'practiceSmallTeam': MoloGlyphs.practiceSmallTeam,
      'practiceGrowing': MoloGlyphs.practiceGrowing,
      'goalDeadlines': MoloGlyphs.goalDeadlines,
      'goalDocuments': MoloGlyphs.goalDocuments,
      'goalTeamwork': MoloGlyphs.goalTeamwork,
      'goalVisibility': MoloGlyphs.goalVisibility,
      'startImport': MoloGlyphs.startImport,
      'startFirstClient': MoloGlyphs.startFirstClient,
      'startSample': MoloGlyphs.startSample,
    };

    test('all ten are drawn in the design 18-unit box, round-capped', () {
      expect(options, hasLength(10));
      for (final entry in options.entries) {
        expect(entry.value.viewBox, 18.0, reason: entry.key);
        expect(entry.value.cap, StrokeCap.round, reason: entry.key);
        expect(entry.value.join, StrokeJoin.round, reason: entry.key);
      }
    });

    test('every glyph stays inside its box', () {
      for (final entry in options.entries) {
        final bounds = entry.value.buildPath().getBounds();
        expect(bounds.left, greaterThanOrEqualTo(0), reason: entry.key);
        expect(bounds.top, greaterThanOrEqualTo(0), reason: entry.key);
        expect(bounds.right, lessThanOrEqualTo(18), reason: entry.key);
        expect(bounds.bottom, lessThanOrEqualTo(18), reason: entry.key);
      }
    });

    test('every glyph fills enough of its box to read at 19px', () {
      // A dropped subpath or a mis-parsed arc shows up as a glyph that
      // occupies a fraction of its box, which is invisible in a screenshot
      // beside nine that look right.
      for (final entry in options.entries) {
        final bounds = entry.value.buildPath().getBounds();
        expect(bounds.width, greaterThan(8), reason: entry.key);
        expect(bounds.height, greaterThan(8), reason: entry.key);
      }
    });

    test('no two option glyphs are the same shape', () {
      // Copy-paste between ten similar entries is the likely error, and it
      // would ship two cards wearing one icon.
      final seen = <String, String>{};
      for (final entry in options.entries) {
        final key = entry.value.buildPath().getBounds().toString();
        expect(
          seen.containsKey(key),
          isFalse,
          reason: '${entry.key} has the same bounds as ${seen[key]}',
        );
        seen[key] = entry.key;
      }
    });
  });

  test('the back arrow is drawn in the 16-unit box the baseline uses', () {
    expect(MoloGlyphs.backArrow.viewBox, 16.0);
    expect(MoloGlyphs.backArrow.cap, StrokeCap.round);
    final bounds = MoloGlyphs.backArrow.buildPath().getBounds();
    expect(bounds.left, closeTo(5.2, 0.1));
    expect(bounds.right, closeTo(11.6, 0.1));
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/app/molo_glyph_test.dart`
Expected: FAIL — none of the eleven names exist on `MoloGlyphs`.

- [ ] **Step 3: Write the implementation**

Add to `lib/app/design_system/icons/molo_glyphs.dart`, before the closing brace of `MoloGlyphs`:

```dart
  // The signup wizard's ten option glyphs, traced from the baseline's own path
  // data. The `arcToPoint` calls are its `a` commands: SVG's arc parameters and
  // Flutter's are the same five, so these are the baseline's arcs rather than
  // circles fitted by eye.

  /// A solo practitioner.
  static final practiceSolo = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    buildPath: () => Path()
      ..moveTo(9, 9.4)
      ..arcToPoint(
        const Offset(9, 4.2),
        radius: const Radius.circular(2.6),
        largeArc: true,
        clockwise: false,
      )
      ..arcToPoint(
        const Offset(9, 9.4),
        radius: const Radius.circular(2.6),
        clockwise: false,
      )
      ..close()
      ..moveTo(3.6, 15)
      ..cubicTo(4.2, 12.6, 6.3, 11.3, 9, 11.3)
      ..cubicTo(11.7, 11.3, 13.8, 12.6, 14.4, 15),
  );

  /// A team of two to ten.
  static final practiceSmallTeam = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    buildPath: () => Path()
      ..moveTo(6.6, 8.6)
      ..arcToPoint(
        const Offset(6.6, 4),
        radius: const Radius.circular(2.3),
        largeArc: true,
        clockwise: false,
      )
      ..arcToPoint(
        const Offset(6.6, 8.6),
        radius: const Radius.circular(2.3),
        clockwise: false,
      )
      ..close()
      ..moveTo(12.4, 9)
      ..arcToPoint(
        const Offset(12.4, 5),
        radius: const Radius.circular(2),
        largeArc: true,
        clockwise: false,
      )
      ..arcToPoint(
        const Offset(12.4, 9),
        radius: const Radius.circular(2),
        clockwise: false,
      )
      ..close()
      ..moveTo(2.4, 14.6)
      ..cubicTo(2.9, 12.5, 4.5, 11.4, 6.6, 11.4)
      ..cubicTo(8.7, 11.4, 10.3, 12.5, 10.8, 14.6)
      ..moveTo(12, 11.6)
      ..cubicTo(13.9, 11.7, 15.1, 12.7, 15.6, 14.6),
  );

  /// A team of eleven or more.
  static final practiceGrowing = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    buildPath: () => Path()
      ..moveTo(3.4, 15)
      ..lineTo(3.4, 4.2)
      ..lineTo(8.8, 4.2)
      ..lineTo(8.8, 15)
      ..moveTo(8.8, 7.4)
      ..lineTo(14.6, 7.4)
      ..lineTo(14.6, 15)
      ..moveTo(2.2, 15)
      ..lineTo(15.8, 15)
      ..moveTo(5.4, 6.6)
      ..lineTo(6.8, 6.6)
      ..moveTo(5.4, 9.2)
      ..lineTo(6.8, 9.2)
      ..moveTo(5.4, 11.8)
      ..lineTo(6.8, 11.8)
      ..moveTo(11, 10)
      ..lineTo(12.6, 10)
      ..moveTo(11, 12.6)
      ..lineTo(12.6, 12.6),
  );

  /// Staying ahead of deadlines.
  static final goalDeadlines = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    buildPath: () => Path()
      ..moveTo(3, 5.4)
      ..lineTo(15, 5.4)
      ..lineTo(15, 15)
      ..lineTo(3, 15)
      ..close()
      ..moveTo(6, 3)
      ..lineTo(6, 5.6)
      ..moveTo(12, 3)
      ..lineTo(12, 5.6)
      ..moveTo(3, 8.4)
      ..lineTo(15, 8.4)
      ..moveTo(8.2, 11.6)
      ..lineTo(9.4, 12.8)
      ..lineTo(11.8, 10.4),
  );

  /// Keeping documents moving.
  static final goalDocuments = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    buildPath: () => Path()
      ..moveTo(2.6, 5.4)
      ..lineTo(6.8, 5.4)
      ..lineTo(8.2, 7.1)
      ..lineTo(15.4, 7.1)
      ..lineTo(15.4, 15)
      ..lineTo(2.6, 15)
      ..close(),
  );

  /// Running work with a team.
  static final goalTeamwork = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    buildPath: () => Path()
      ..moveTo(9, 5.2)
      ..arcToPoint(
        const Offset(9, 2.2),
        radius: const Radius.circular(1.5),
        largeArc: true,
        clockwise: false,
      )
      ..arcToPoint(
        const Offset(9, 5.2),
        radius: const Radius.circular(1.5),
        clockwise: false,
      )
      ..close()
      ..moveTo(4.4, 14.6)
      ..arcToPoint(
        const Offset(4.4, 11.6),
        radius: const Radius.circular(1.5),
        largeArc: true,
        clockwise: false,
      )
      ..arcToPoint(
        const Offset(4.4, 14.6),
        radius: const Radius.circular(1.5),
        clockwise: false,
      )
      ..close()
      ..moveTo(13.6, 14.6)
      ..arcToPoint(
        const Offset(13.6, 11.6),
        radius: const Radius.circular(1.5),
        largeArc: true,
        clockwise: false,
      )
      ..arcToPoint(
        const Offset(13.6, 14.6),
        radius: const Radius.circular(1.5),
        clockwise: false,
      )
      ..close()
      ..moveTo(8.2, 6.4)
      ..lineTo(5.2, 11.4)
      ..moveTo(9.8, 6.4)
      ..lineTo(12.8, 11.4),
  );

  /// Seeing the whole practice clearly.
  static final goalVisibility = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    buildPath: () => Path()
      ..moveTo(8.2, 2.6)
      ..lineTo(9.5, 6.1)
      ..lineTo(13, 7.4)
      ..lineTo(9.5, 8.7)
      ..lineTo(8.2, 12.2)
      ..lineTo(6.9, 8.7)
      ..lineTo(3.4, 7.4)
      ..lineTo(6.9, 6.1)
      ..close()
      ..moveTo(13, 11.4)
      ..lineTo(13.7, 13.2)
      ..lineTo(15.5, 13.9)
      ..lineTo(13.7, 14.6)
      ..lineTo(13, 16.4)
      ..lineTo(12.3, 14.6)
      ..lineTo(10.5, 13.9)
      ..lineTo(12.3, 13.2)
      ..close(),
  );

  /// Importing a client list.
  static final startImport = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    buildPath: () => Path()
      ..moveTo(4.4, 2.6)
      ..lineTo(9.6, 2.6)
      ..lineTo(13.4, 6.4)
      ..lineTo(13.4, 15.4)
      ..lineTo(4.4, 15.4)
      ..close()
      ..moveTo(9.4, 2.6)
      ..lineTo(9.4, 6.5)
      ..lineTo(13.3, 6.5)
      ..moveTo(9, 9)
      ..lineTo(9, 13)
      ..moveTo(7.4, 10.6)
      ..lineTo(9, 9)
      ..lineTo(10.6, 10.6),
  );

  /// Adding the first client.
  static final startFirstClient = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    buildPath: () => Path()
      ..moveTo(7.4, 9.2)
      ..arcToPoint(
        const Offset(7.4, 4),
        radius: const Radius.circular(2.6),
        largeArc: true,
        clockwise: false,
      )
      ..arcToPoint(
        const Offset(7.4, 9.2),
        radius: const Radius.circular(2.6),
        clockwise: false,
      )
      ..close()
      ..moveTo(2.6, 15)
      ..cubicTo(3.1, 12.7, 5, 11.4, 7.4, 11.4)
      ..moveTo(12.6, 8.6)
      ..lineTo(12.6, 12.8)
      ..moveTo(10.5, 10.7)
      ..lineTo(14.7, 10.7),
  );

  /// Exploring a sample workspace.
  static final startSample = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    buildPath: () => Path()
      ..moveTo(9, 15.4)
      ..arcToPoint(
        const Offset(9, 2.6),
        radius: const Radius.circular(6.4),
        largeArc: true,
        clockwise: false,
      )
      ..arcToPoint(
        const Offset(9, 15.4),
        radius: const Radius.circular(6.4),
        clockwise: false,
      )
      ..close()
      ..moveTo(11.6, 6.4)
      ..lineTo(7.9, 7.9)
      ..lineTo(6.4, 11.6)
      ..lineTo(10.1, 10.1)
      ..close(),
  );

  /// The wizard's back link, drawn in a 16-unit box like the search glyph.
  static final backArrow = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    viewBox: 16,
    buildPath: () => Path()
      ..moveTo(9.6, 3.6)
      ..lineTo(5.2, 8)
      ..lineTo(9.6, 12.4)
      ..moveTo(5.4, 8)
      ..lineTo(11.6, 8),
  );
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget/app/molo_glyph_test.dart`
Expected: PASS, 9 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/app/design_system/icons/molo_glyphs.dart test/widget/app/molo_glyph_test.dart
git commit -m "feat: trace the wizard's ten option glyphs and its back arrow"
```

---

### Task 2: The option card

**Files:**
- Create: `lib/app/design_system/components/molo_choice_card.dart`
- Modify: `lib/app/adaptive/molo_wizard_shell.dart` (delete `MoloChoiceCard` and `_SingleChoiceMark` from it)
- Test: `test/widget/app/molo_choice_card_test.dart`

**Interfaces:**
- Consumes: `MoloIcon`, `MoloGlyph`, `MoloGlyphs.tick`, `MoloSpacing.choiceCardRadius`, `MoloColours`.
- Produces:
  ```dart
  enum MoloChoiceKind { single, multiple }

  class MoloChoiceCard extends StatefulWidget {
    const MoloChoiceCard({
      required this.glyph,
      required this.title,
      required this.description,
      required this.selected,
      required this.onTap,
      this.kind = MoloChoiceKind.single,
      super.key,
    });
    final MoloGlyph glyph;
    final String title;
    final String description;
    final bool selected;
    final VoidCallback onTap;
    final MoloChoiceKind kind;
    static const markKey = Key('molo_choice_card_mark');
  }
  ```

`MoloChoiceCard` moves out of `molo_wizard_shell.dart` and into the design system. Its old API took an `IconData` and an optional `trailing` widget; both are gone. The `trailing` slot existed only so the goals step could hang a Material `Checkbox` beside the card's own mark — two controls painting one state. `kind` replaces it.

Traced values:

| Element | Value |
|---|---|
| Card | radius 16, padding 16 vertical and 18 horizontal, gap 14 |
| Resting | `surface` fill, 1px `border` outline |
| Selected | `pulseTint` fill, 2px `pulseText` outline |
| Hovered | 1px `controlBorder` outline |
| Focused | 2px `pulseText` outline |
| Glyph | 19px; `controlBorder`, `pulseText` when selected |
| Title | 15px medium plum |
| Description | 13px `secondaryText`, height 1.5, 3 below the title |
| Single mark | 21 round; `surface` with a `controlBorder` outline, `pulseText` filled with an 11px `warmCanvas` tick when selected |
| Multiple mark | 21 square at radius 7; `moloPlum` filled when selected |

The baseline draws the selected edge as a 1px border plus a 1px inset ring of the same colour, which is a 2px edge; that is what the outline above is. The unselected mark's outline is `controlBorder` rather than the baseline's `#D8C6CB` (1.49:1), per spec section 7.2 — it is the only thing that says a control is there. Focus and hover stay distinguishable, and a focused-but-unselected card is told apart from a selected one by its mark, which is the state's real carrier.

- [ ] **Step 1: Write the failing test**

Create `test/widget/app/molo_choice_card_test.dart`:

```dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_choice_card.dart';
import 'package:molobuddy_app/app/design_system/icons/molo_glyphs.dart';
import 'package:molobuddy_app/app/design_system/molo_theme.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';

void main() {
  late int taps;

  Future<void> pump(
    WidgetTester tester, {
    bool selected = false,
    MoloChoiceKind kind = MoloChoiceKind.single,
  }) async {
    taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: MoloTheme.light(),
        home: Scaffold(
          backgroundColor: MoloColours.warmCanvas,
          body: Center(
            child: SizedBox(
              width: 452,
              child: MoloChoiceCard(
                glyph: MoloGlyphs.practiceSolo,
                title: 'Just me',
                description: 'A focused workspace for a solo practitioner.',
                selected: selected,
                kind: kind,
                onTap: () => taps++,
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration cardDecoration(WidgetTester tester) {
    return tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(MoloChoiceCard),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;
  }

  BoxDecoration markDecoration(WidgetTester tester) {
    return tester
            .widget<Container>(find.byKey(MoloChoiceCard.markKey))
            .decoration!
        as BoxDecoration;
  }

  testWidgets('resting, the card is white inside a quiet outline', (
    tester,
  ) async {
    await pump(tester);
    final decoration = cardDecoration(tester);
    expect(decoration.color, MoloColours.surface);
    expect(decoration.border?.top.color, MoloColours.border);
    expect(decoration.border?.top.width, 1);
    expect(
      decoration.borderRadius,
      BorderRadius.circular(MoloSpacing.choiceCardRadius),
    );
  });

  testWidgets('selected, it tints and takes the design two-pixel edge', (
    tester,
  ) async {
    await pump(tester, selected: true);
    final decoration = cardDecoration(tester);
    expect(decoration.color, MoloColours.pulseTint);
    expect(decoration.border?.top.color, MoloColours.pulseText);
    expect(decoration.border?.top.width, 2);
  });

  testWidgets('hovering firms the outline without tinting the card', (
    tester,
  ) async {
    await pump(tester);
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.byType(MoloChoiceCard)));
    await tester.pumpAndSettle();

    final decoration = cardDecoration(tester);
    expect(decoration.border?.top.color, MoloColours.controlBorder);
    expect(decoration.color, MoloColours.surface);
  });

  testWidgets('the glyph is 19px and follows the selection', (tester) async {
    await pump(tester);
    expect(
      tester.widget<MoloIcon>(find.byType(MoloIcon).first).color,
      MoloColours.controlBorder,
    );
    expect(tester.getSize(find.byType(MoloIcon).first), const Size(19, 19));

    await pump(tester, selected: true);
    expect(
      tester.widget<MoloIcon>(find.byType(MoloIcon).first).color,
      MoloColours.pulseText,
    );
  });

  testWidgets('the title and description take the design sizes', (
    tester,
  ) async {
    await pump(tester);
    final title = tester.widget<Text>(find.text('Just me'));
    expect(title.style?.fontSize, 15);
    expect(title.style?.fontWeight, FontWeight.w500);
    expect(title.style?.color, MoloColours.moloPlum);

    final description = tester.widget<Text>(
      find.text('A focused workspace for a solo practitioner.'),
    );
    expect(description.style?.fontSize, 13);
    expect(description.style?.height, 1.5);
    expect(description.style?.color, MoloColours.secondaryText);
  });

  group('the mark', () {
    testWidgets('a single choice is round, 21 across', (tester) async {
      await pump(tester);
      expect(
        tester.getSize(find.byKey(MoloChoiceCard.markKey)),
        const Size(21, 21),
      );
      expect(markDecoration(tester).shape, BoxShape.circle);
      expect(markDecoration(tester).color, MoloColours.surface);
      expect(
        markDecoration(tester).border?.top.color,
        MoloColours.controlBorder,
      );
    });

    testWidgets('a chosen single choice fills pulseText', (tester) async {
      await pump(tester, selected: true);
      expect(markDecoration(tester).color, MoloColours.pulseText);
    });

    testWidgets('a multiple choice is square at radius 7', (tester) async {
      await pump(tester, kind: MoloChoiceKind.multiple);
      expect(
        tester.getSize(find.byKey(MoloChoiceCard.markKey)),
        const Size(21, 21),
      );
      expect(markDecoration(tester).borderRadius, BorderRadius.circular(7));
    });

    testWidgets('a chosen multiple choice fills plum', (tester) async {
      await pump(
        tester,
        kind: MoloChoiceKind.multiple,
        selected: true,
      );
      expect(markDecoration(tester).color, MoloColours.moloPlum);
    });

    testWidgets('the card carries one mark, never two', (tester) async {
      // The goals step used to hang a Material Checkbox beside this, so two
      // controls painted one state.
      await pump(tester, kind: MoloChoiceKind.multiple);
      expect(find.byKey(MoloChoiceCard.markKey), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
    });
  });

  testWidgets('the whole card is the control', (tester) async {
    await pump(tester);
    await tester.tap(
      find.text('A focused workspace for a solo practitioner.'),
    );
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('a single choice announces as one of a set', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, selected: true);
    expect(
      tester.getSemantics(find.byType(MoloChoiceCard)),
      isSemantics(
        hasCheckedState: true,
        isChecked: true,
        isInMutuallyExclusiveGroup: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('a multiple choice announces as an independent check', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, kind: MoloChoiceKind.multiple);
    expect(
      tester.getSemantics(find.byType(MoloChoiceCard)),
      isSemantics(
        hasCheckedState: true,
        isChecked: false,
        isInMutuallyExclusiveGroup: false,
      ),
    );
    semantics.dispose();
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/app/molo_choice_card_test.dart`
Expected: FAIL — `molo_choice_card.dart` does not exist.

- [ ] **Step 3: Write the component**

Create `lib/app/design_system/components/molo_choice_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/icons/molo_glyphs.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';
import 'package:molobuddy_app/app/design_system/typography/molo_typography.dart';

/// Whether choosing this card unchooses its siblings.
enum MoloChoiceKind { single, multiple }

/// One selectable option in the signup wizard: a glyph, a title, a line of
/// explanation, and a mark saying whether it is chosen.
///
/// The card is the whole control. There is no separate checkbox: the previous
/// version accepted a trailing widget so the goals step could hang a Material
/// `Checkbox` beside the card's own mark, which meant two controls painting one
/// state and two tap targets for one answer.
class MoloChoiceCard extends StatefulWidget {
  const MoloChoiceCard({
    required this.glyph,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
    this.kind = MoloChoiceKind.single,
    super.key,
  });

  final MoloGlyph glyph;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  final MoloChoiceKind kind;

  /// The selection mark, so a measurement can find it.
  static const markKey = Key('molo_choice_card_mark');

  @override
  State<MoloChoiceCard> createState() => _MoloChoiceCardState();
}

class _MoloChoiceCardState extends State<MoloChoiceCard> {
  bool _focused = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final radius = BorderRadius.circular(MoloSpacing.choiceCardRadius);
    // Selection and focus share the strong edge; hover only firms the quiet
    // one. What tells a focused card from a chosen one is the mark, which is
    // where the state actually lives.
    final strongEdge = selected || _focused;
    return Semantics(
      container: true,
      checked: selected,
      inMutuallyExclusiveGroup: widget.kind == MoloChoiceKind.single,
      child: Material(
        color: selected ? MoloColours.pulseTint : MoloColours.surface,
        borderRadius: radius,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: radius,
          // Focus paints its own outline below, so the default fill would
          // otherwise linger and read as a second chosen card.
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          onFocusChange: (value) => setState(() => _focused = value),
          onHover: (value) => setState(() => _hovered = value),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected ? MoloColours.pulseTint : MoloColours.surface,
              borderRadius: radius,
              border: Border.all(
                color: strongEdge
                    ? MoloColours.pulseText
                    : _hovered
                    ? MoloColours.controlBorder
                    : MoloColours.border,
                width: strongEdge ? 2 : 1,
              ),
            ),
            child: Padding(
              // The design pads 16 down the sides of the row and 18 across it,
              // and the two-pixel selected edge is drawn inside that.
              padding: EdgeInsets.symmetric(
                vertical: strongEdge ? 15 : 16,
                horizontal: strongEdge ? 17 : 18,
              ),
              child: Row(
                children: [
                  MoloIcon(
                    widget.glyph,
                    size: 19,
                    color: selected
                        ? MoloColours.pulseText
                        : MoloColours.controlBorder,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0,
                            height: MoloTypography.normalLineHeight,
                            color: MoloColours.moloPlum,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.description,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            letterSpacing: 0,
                            color: MoloColours.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  _ChoiceMark(selected: selected, kind: widget.kind),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Round for a choice that excludes its siblings, square for one that does not,
/// so the shape says how many answers are allowed before anything is chosen.
class _ChoiceMark extends StatelessWidget {
  const _ChoiceMark({required this.selected, required this.kind});

  final bool selected;
  final MoloChoiceKind kind;

  @override
  Widget build(BuildContext context) {
    final single = kind == MoloChoiceKind.single;
    final fill = single ? MoloColours.pulseText : MoloColours.moloPlum;
    return Container(
      key: MoloChoiceCard.markKey,
      width: 21,
      height: 21,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? fill : MoloColours.surface,
        shape: single ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: single ? null : BorderRadius.circular(7),
        border: selected
            ? null
            : Border.all(color: MoloColours.controlBorder),
      ),
      // The tick stays in the tree and fades, as the baseline does, so the mark
      // never reflows as it is chosen.
      child: Opacity(
        opacity: selected ? 1 : 0,
        child: MoloIcon(
          MoloGlyphs.tick,
          size: 11,
          color: MoloColours.warmCanvas,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Delete the old card from the shell**

In `lib/app/adaptive/molo_wizard_shell.dart`, delete the `MoloChoiceCard` class and the `_SingleChoiceMark` class beneath it. Leave `MoloStepEyebrow`, `MoloStepHeading` and `MoloWizardBackButton` where they are; Task 5 rewrites those.

`flutter analyze` will now report `registration_view.dart` and `onboarding_view.dart` as broken. That is expected: Tasks 8 and 9 rewrite them, and this task's gate is the card's own test plus the design system suite.

- [ ] **Step 5: Run the card's tests**

Run: `flutter test test/widget/app/molo_choice_card_test.dart test/widget/app/molo_glyph_test.dart`
Expected: PASS, 14 card tests plus Task 1's 9.

- [ ] **Step 6: Commit**

```bash
git add lib/app/design_system/components/molo_choice_card.dart lib/app/adaptive/molo_wizard_shell.dart test/widget/app/molo_choice_card_test.dart
git commit -m "feat: re-trace the option card and give it one selection mark"
```

The tree does not compile after this commit until Task 9 lands. If every commit must build, hold Tasks 2 and 5 to 9 back and land them together.

---

### Task 3: The progress contract, the rail width, and pulseOnDark

**Files:**
- Modify: `lib/app/adaptive/molo_wizard_shell.dart:19-33` (the `WizardProgress` class)
- Modify: `lib/app/adaptive/auth_shell_layout.dart`
- Modify: `lib/app/design_system/colour/molo_colours.dart`
- Test: `test/unit/app/wizard_progress_test.dart`
- Test: `test/unit/app/molo_tokens_test.dart` (append)

**Interfaces:**
- Consumes: nothing.
- Produces:
  ```dart
  enum WizardStepState { done, current, pending }

  final class WizardStepDescriptor {
    const WizardStepDescriptor({required this.title, required this.note});
    final String title;
    final String note;
  }

  final class WizardProgress {
    const WizardProgress({
      required this.stepNumber,
      required this.readinessPercent,
      required this.steps,
      this.practiceName = '',
    });
    final int stepNumber;          // one-based
    final int readinessPercent;
    final List<WizardStepDescriptor> steps;   // exactly totalSteps, in order
    final String practiceName;    // empty until named
    static const totalSteps = 4;
    WizardStepState stateOf(int oneBasedStep);
  }

  /// Built from localisations by whichever route is on screen.
  List<WizardStepDescriptor> moloWizardSteps(AppLocalizations localisations);

  // auth_shell_layout.dart
  static double wizardRailWidth(double availableWidth);   // 38%, capped at 460

  // molo_colours.dart
  static const pulseOnDark = Color(0xFFF98FA4);
  ```

- [ ] **Step 1: Write the failing test**

Create `test/unit/app/wizard_progress_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/adaptive/auth_shell_layout.dart';
import 'package:molobuddy_app/app/adaptive/molo_wizard_shell.dart';

void main() {
  WizardProgress at(int step) => WizardProgress(
    stepNumber: step,
    readinessPercent: const [12, 32, 58, 82][0],
    steps: const [
      WizardStepDescriptor(title: 'Your account', note: 'Name, email and a password'),
      WizardStepDescriptor(title: 'Your practice', note: 'Practice, team size and region'),
      WizardStepDescriptor(title: 'Your first win', note: 'What you want to fix first'),
      WizardStepDescriptor(title: 'Your starting point', note: 'Real data or a sample'),
    ],
  );

  test('a step before the current one is done', () {
    expect(at(3).stateOf(1), WizardStepState.done);
    expect(at(3).stateOf(2), WizardStepState.done);
  });

  test('the step on screen is current', () {
    expect(at(3).stateOf(3), WizardStepState.current);
  });

  test('a step after it is pending', () {
    expect(at(3).stateOf(4), WizardStepState.pending);
  });

  test('the first step has nothing behind it', () {
    expect(at(1).stateOf(1), WizardStepState.current);
    expect(at(1).stateOf(2), WizardStepState.pending);
  });

  test('the last step has nothing ahead of it', () {
    expect(at(4).stateOf(3), WizardStepState.done);
    expect(at(4).stateOf(4), WizardStepState.current);
  });

  test('the rail carries one descriptor per step', () {
    expect(at(1).steps, hasLength(WizardProgress.totalSteps));
  });

  group('rail width', () {
    test('is 38% of the window', () {
      expect(MoloAuthShellLayout.wizardRailWidth(1000), closeTo(380, 0.01));
    });

    test('stops growing at 460', () {
      expect(MoloAuthShellLayout.wizardRailWidth(1600), 460);
      expect(MoloAuthShellLayout.wizardRailWidth(2400), 460);
    });

    test('is narrower than the sign-in hero, as the baseline draws them', () {
      // Sign-in gets 44% and the rail 38%. Asserting it means a later change
      // that quietly unifies the two has to argue with a test.
      expect(
        MoloAuthShellLayout.wizardRailWidth(1200),
        lessThan(MoloAuthShellLayout.signInHeroWidth(1200)),
      );
    });
  });
}
```

Append to `test/unit/app/molo_tokens_test.dart`, inside the `new colours` group:

```dart
    test('the readiness figure is readable on the rail', () {
      expect(
        _contrast(MoloColours.pulseOnDark, MoloColours.moloPlum),
        greaterThan(4.5),
      );
    });

    test('pulse itself would not have been', () {
      // Which is why the rail needs its own pink: moloPulse is the fill of the
      // bar, where contrast does not apply, but the figure beside it is text.
      expect(
        _contrast(MoloColours.moloPulse, MoloColours.moloPlum),
        lessThan(4.5),
      );
      expect(MoloColours.pulseOnDark, const Color(0xFFF98FA4));
    });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/unit/app/wizard_progress_test.dart test/unit/app/molo_tokens_test.dart`
Expected: FAIL — `WizardStepDescriptor`, `stateOf`, `wizardRailWidth` and `pulseOnDark` do not exist.

- [ ] **Step 3: Grow the progress contract**

In `lib/app/adaptive/molo_wizard_shell.dart`, replace the `WizardProgress` class with:

```dart
/// Where one step of the wizard stands relative to the step on screen.
enum WizardStepState { done, current, pending }

/// What the rail says about one step.
///
/// Distinct from the eyebrow shown in the form: the rail names the step from
/// outside it ("Your practice") while the form names the task ("Shape your
/// workspace"), and the design writes both.
final class WizardStepDescriptor {
  const WizardStepDescriptor({required this.title, required this.note});

  final String title;
  final String note;
}

/// What the signup chrome needs to know, whichever half of the wizard is on
/// screen.
///
/// Signup spans two routes — the account step at `/sign-up` and the rest at
/// `/onboarding` — and each keeps its own state. This is the small shape they
/// both reduce to, so the rail does not need to know which half it is
/// decorating.
final class WizardProgress {
  const WizardProgress({
    required this.stepNumber,
    required this.readinessPercent,
    required this.steps,
    this.practiceName = '',
  });

  /// One-based, out of [totalSteps].
  final int stepNumber;

  final int readinessPercent;

  /// One descriptor per step, in order. The rail marks them from
  /// [stepNumber] rather than being told each one's state, so the two can never
  /// disagree.
  final List<WizardStepDescriptor> steps;

  /// Empty until the user has named their practice.
  final String practiceName;

  static const totalSteps = 4;

  WizardStepState stateOf(int oneBasedStep) {
    if (oneBasedStep < stepNumber) {
      return WizardStepState.done;
    }
    if (oneBasedStep == stepNumber) {
      return WizardStepState.current;
    }
    return WizardStepState.pending;
  }
}

/// The rail's four descriptors, in order.
///
/// One definition, because both routes render the same rail and a second copy
/// would drift on whichever step the other route does not own.
List<WizardStepDescriptor> moloWizardSteps(AppLocalizations localisations) {
  return [
    WizardStepDescriptor(
      title: localisations.wizardStepAccountTitle,
      note: localisations.wizardStepAccountNote,
    ),
    WizardStepDescriptor(
      title: localisations.wizardStepPracticeTitle,
      note: localisations.wizardStepPracticeNote,
    ),
    WizardStepDescriptor(
      title: localisations.wizardStepGoalsTitle,
      note: localisations.wizardStepGoalsNote,
    ),
    WizardStepDescriptor(
      title: localisations.wizardStepStartTitle,
      note: localisations.wizardStepStartNote,
    ),
  ];
}
```

Those eight localisation getters arrive in Task 7. Until then this file does not compile, which is why Task 7 is a prerequisite for Task 4's test run rather than for this task's.

- [ ] **Step 4: Add the rail width**

In `lib/app/adaptive/auth_shell_layout.dart`, add:

```dart
  /// The signup wizard's rail, which the design draws at 38% of the window and
  /// stops at 460.
  ///
  /// Narrower than [signInHeroWidth] on purpose: a photograph earns width that
  /// a list of four steps does not.
  static double wizardRailWidth(double availableWidth) {
    return (availableWidth * 0.38).clamp(0, 460).toDouble();
  }
```

- [ ] **Step 5: Add the token**

In `lib/app/design_system/colour/molo_colours.dart`, after `moloPlumHover`:

```dart
  /// The readiness figure in the signup wizard's rail.
  ///
  /// 7.82:1 on [moloPlum]. [moloPulse] is 3.5:1 there, which is fine for the
  /// bar it fills but not for the number beside it.
  static const pulseOnDark = Color(0xFFF98FA4);
```

- [ ] **Step 6: Run the tests that can run**

Run: `flutter test test/unit/app/molo_tokens_test.dart`
Expected: PASS, 6 tests. `wizard_progress_test.dart` cannot run until Task 7 supplies the strings `moloWizardSteps` reads; run it at the end of Task 7.

- [ ] **Step 7: Commit**

```bash
git add lib/app/adaptive/molo_wizard_shell.dart lib/app/adaptive/auth_shell_layout.dart lib/app/design_system/colour/molo_colours.dart test/unit/app/wizard_progress_test.dart test/unit/app/molo_tokens_test.dart
git commit -m "feat: let the wizard's progress describe all four of its steps"
```

---

### Task 4: The wizard rail

**Files:**
- Create: `lib/app/adaptive/molo_wizard_rail.dart`
- Modify: `lib/app/adaptive/molo_wizard_shell.dart` (delete `_WorkspacePreviewPanel`; point the expanded branch at the rail)
- Test: `test/widget/app/molo_wizard_rail_fidelity_test.dart`

**Interfaces:**
- Consumes: `WizardProgress`, `WizardStepState`, `WizardStepDescriptor`, `MoloBrandLockup`, `MoloColours.pulseOnDark`, `MoloSpacing.railCardRadius`, `MoloAuthShellLayout.wizardRailWidth`.
- Produces:
  ```dart
  class MoloWizardRail extends StatelessWidget {
    const MoloWizardRail({required this.progress, super.key});
    final WizardProgress progress;
    static const railKey = Key('registration_progress_panel');   // kept
    static Key chipKey(int oneBasedStep);                        // Key('wizard_step_chip_$n')
    static const practiceNameKey = Key('workspace_preview_practice_name');  // kept
    static const readinessBarKey = Key('wizard_readiness_bar');
  }
  ```
  `railKey` and `practiceNameKey` keep the values the old panel used, so existing tests and the sign-in half's pane-edge test go on pointing at the same things.

Traced values:

| Element | Value |
|---|---|
| Aside | 38% capped at 460, `moloPlum` ground |
| Padding | 40 sides and top, 36 bottom |
| Group gap | 40 |
| Header | lockup left, "Step n of 4" right, 13px, `warmCanvas` at 0.6 |
| Step rows | 2 apart; each row gap 14, padding 12 vertical |
| Step chip | 28 square, fully round, 13px medium |
| Chip, done | `moloPulse` fill, `moloPlum` tick |
| Chip, current | `warmCanvas` fill, `moloPlum` number |
| Chip, pending | `surface` at 0.1, `warmCanvas` at 0.6 number |
| Step title | 15px medium; `warmCanvas` when current, at 0.72 otherwise |
| Step note | 13px, height 1.5, `warmCanvas` at 0.5, 3 below the title |
| Workspace card | padding 20, radius 18, `surface` at 0.06, group gap 10 |
| Card eyebrow | 12px uppercase, tracking 0.08em, `warmCanvas` at 0.55 |
| Card practice name | 24px medium, tracking -0.02em, `warmCanvas` |
| Card body | 13px, height 1.6, `warmCanvas` at 0.66 |
| Readiness | group gap 10; label 13px `warmCanvas` at 0.72; figure 13px tabular `pulseOnDark` |
| Readiness track | 4 high, fully round, `surface` at 0.16 |
| Readiness fill | `moloPulse`, animated over 320ms |

The done chip carries a tick rather than its number, so `MoloGlyphs.tick` is used at 13 in `moloPlum`. Every alpha above was measured against `moloPlum`: the lowest is the step note at 5.02:1, so all of them clear 4.5:1 and none is changed.

- [ ] **Step 1: Write the failing test**

Create `test/widget/app/molo_wizard_rail_fidelity_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/adaptive/molo_wizard_rail.dart';
import 'package:molobuddy_app/app/adaptive/molo_wizard_shell.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/molo_theme.dart';
import 'package:molobuddy_app/app/localisation/generated/app_localizations.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';

void main() {
  const steps = [
    WizardStepDescriptor(
      title: 'Your account',
      note: 'Name, email and a password',
    ),
    WizardStepDescriptor(
      title: 'Your practice',
      note: 'Practice, team size and region',
    ),
    WizardStepDescriptor(
      title: 'Your first win',
      note: 'What you want to fix first',
    ),
    WizardStepDescriptor(
      title: 'Your starting point',
      note: 'Real data or a sample',
    ),
  ];

  Future<void> pump(
    WidgetTester tester, {
    int step = 2,
    int readiness = 32,
    String practiceName = '',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MoloTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: 460,
                height: 900,
                child: MoloWizardRail(
                  progress: WizardProgress(
                    stepNumber: step,
                    readinessPercent: readiness,
                    steps: steps,
                    practiceName: practiceName,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  BoxDecoration chipDecoration(WidgetTester tester, int step) {
    return tester
            .widget<Container>(find.byKey(MoloWizardRail.chipKey(step)))
            .decoration!
        as BoxDecoration;
  }

  testWidgets('the rail is plum and says where you are', (tester) async {
    await pump(tester);
    expect(find.byKey(MoloWizardRail.railKey), findsOneWidget);
    expect(find.text('Step 2 of 4'), findsOneWidget);
    expect(find.text('molo'), findsOneWidget);
  });

  testWidgets('all four steps are listed, with their notes', (tester) async {
    await pump(tester);
    for (final step in steps) {
      expect(find.text(step.title), findsOneWidget);
      expect(find.text(step.note), findsOneWidget);
    }
  });

  testWidgets('every chip is 28 square and fully round', (tester) async {
    await pump(tester);
    for (var step = 1; step <= 4; step++) {
      expect(
        tester.getSize(find.byKey(MoloWizardRail.chipKey(step))),
        const Size(28, 28),
      );
      expect(chipDecoration(tester, step).shape, BoxShape.circle);
    }
  });

  testWidgets('a finished step fills pulse and shows a tick, not a number', (
    tester,
  ) async {
    await pump(tester, step: 3);
    expect(chipDecoration(tester, 1).color, MoloColours.moloPulse);
    expect(
      find.descendant(
        of: find.byKey(MoloWizardRail.chipKey(1)),
        matching: find.text('1'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(MoloWizardRail.chipKey(1)),
        matching: find.byType(MoloIcon),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the step on screen fills warm canvas and keeps its number', (
    tester,
  ) async {
    await pump(tester, step: 3);
    expect(chipDecoration(tester, 3).color, MoloColours.warmCanvas);
    expect(
      find.descendant(
        of: find.byKey(MoloWizardRail.chipKey(3)),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a step still ahead is quiet but numbered', (tester) async {
    await pump(tester, step: 3);
    expect(
      chipDecoration(tester, 4).color,
      MoloColours.surface.withValues(alpha: 0.1),
    );
    expect(
      find.descendant(
        of: find.byKey(MoloWizardRail.chipKey(4)),
        matching: find.text('4'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the current title is brighter than the others', (tester) async {
    await pump(tester, step: 2);
    expect(
      tester.widget<Text>(find.text('Your practice')).style?.color,
      MoloColours.warmCanvas,
    );
    expect(
      tester.widget<Text>(find.text('Your first win')).style?.color,
      MoloColours.warmCanvas.withValues(alpha: 0.72),
    );
  });

  group('workspace card', () {
    testWidgets('is padded 20 at the design radius', (tester) async {
      await pump(tester);
      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find.ancestor(
                      of: find.text('Your workspace'),
                      matching: find.byType(DecoratedBox),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      expect(
        decoration.borderRadius,
        BorderRadius.circular(MoloSpacing.railCardRadius),
      );
      expect(decoration.color, MoloColours.surface.withValues(alpha: 0.06));
    });

    testWidgets('names the practice once it has a name', (tester) async {
      await pump(tester, practiceName: 'Mokoena Tax Studio');
      expect(
        tester.widget<Text>(find.byKey(MoloWizardRail.practiceNameKey)).data,
        'Mokoena Tax Studio',
      );
      expect(
        tester
            .widget<Text>(find.byKey(MoloWizardRail.practiceNameKey))
            .style
            ?.fontSize,
        24,
      );
    });

    testWidgets('stands in for it until then', (tester) async {
      await pump(tester);
      expect(
        tester.widget<Text>(find.byKey(MoloWizardRail.practiceNameKey)).data,
        'Your practice',
      );
    });
  });

  group('readiness', () {
    testWidgets('states the figure twice, in words and as a number', (
      tester,
    ) async {
      await pump(tester, readiness: 58);
      expect(find.text('Workspace 58% ready'), findsOneWidget);
      expect(find.text('58%'), findsOneWidget);
    });

    testWidgets('the figure takes the colour that is readable on plum', (
      tester,
    ) async {
      await pump(tester, readiness: 58);
      expect(
        tester.widget<Text>(find.text('58%')).style?.color,
        MoloColours.pulseOnDark,
      );
    });

    testWidgets('the track is 4 high and the fill follows the figure', (
      tester,
    ) async {
      await pump(tester, readiness: 58);
      expect(
        tester.getSize(find.byKey(MoloWizardRail.readinessBarKey)).height,
        4,
      );
      final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(MoloWizardRail.readinessBarKey),
      );
      expect(bar.value, closeTo(0.58, 0.001));
      expect(bar.color, MoloColours.moloPulse);
    });
  });

  testWidgets('the rail is decoration, not a place to tab into', (
    tester,
  ) async {
    await pump(tester);
    // The form's own heading announces the step. A tab stop here would put
    // four unreachable-looking rows in front of the first field.
    expect(find.byType(InkWell), findsNothing);
    expect(find.byType(TextButton), findsNothing);
  });
}
```

Add `import 'package:molobuddy_app/app/design_system/icons/molo_glyphs.dart';` for `MoloIcon`.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/app/molo_wizard_rail_fidelity_test.dart`
Expected: FAIL — `molo_wizard_rail.dart` does not exist.

- [ ] **Step 3: Write the rail**

Create `lib/app/adaptive/molo_wizard_rail.dart`:

```dart
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:molobuddy_app/app/adaptive/molo_wizard_shell.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_brand_lockup.dart';
import 'package:molobuddy_app/app/design_system/icons/molo_glyphs.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';
import 'package:molobuddy_app/app/design_system/typography/molo_typography.dart';
import 'package:molobuddy_app/app/localisation/generated/app_localizations.dart';

/// The dark aside beside the signup wizard.
///
/// Replaces the single-panel workspace preview: the design names all four steps
/// and marks which are behind, on screen and ahead, so someone three steps in
/// can see what is left rather than only how far along a bar has travelled.
///
/// Decoration, deliberately. Nothing here is focusable and nothing here acts:
/// the step on screen is announced by the form's own heading, and four
/// unreachable-looking tab stops in front of the first field would cost more
/// than they explain.
class MoloWizardRail extends StatelessWidget {
  const MoloWizardRail({required this.progress, super.key});

  final WizardProgress progress;

  /// Kept from the panel this replaces, so the shell's own measurements and the
  /// sign-in half's pane-edge test go on pointing at the same pane.
  static const railKey = Key('registration_progress_panel');

  static const practiceNameKey = Key('workspace_preview_practice_name');
  static const readinessBarKey = Key('wizard_readiness_bar');

  static Key chipKey(int oneBasedStep) => Key('wizard_step_chip_$oneBasedStep');

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    return ColoredBox(
      key: railKey,
      color: MoloColours.moloPlum,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 40, 40, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const MoloBrandLockup(onDark: true),
                const Spacer(),
                Text(
                  localisations.registrationProgress(
                    progress.stepNumber,
                    WizardProgress.totalSteps,
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    letterSpacing: 0,
                    height: MoloTypography.normalLineHeight,
                    color: MoloColours.warmCanvas.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            for (var step = 1; step <= WizardProgress.totalSteps; step++) ...[
              if (step > 1) const SizedBox(height: 2),
              _StepRow(
                number: step,
                descriptor: progress.steps[step - 1],
                state: progress.stateOf(step),
              ),
            ],
            const Spacer(),
            const SizedBox(height: 40),
            _WorkspaceCard(practiceName: progress.practiceName),
            const SizedBox(height: 40),
            _Readiness(percent: progress.readinessPercent),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.descriptor,
    required this.state,
  });

  final int number;
  final WizardStepDescriptor descriptor;
  final WizardStepState state;

  @override
  Widget build(BuildContext context) {
    final current = state == WizardStepState.current;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepChip(number: number, state: state),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  descriptor.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                    height: MoloTypography.normalLineHeight,
                    color: current
                        ? MoloColours.warmCanvas
                        : MoloColours.warmCanvas.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  descriptor.note,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    letterSpacing: 0,
                    color: MoloColours.warmCanvas.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({required this.number, required this.state});

  final int number;
  final WizardStepState state;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (state) {
      WizardStepState.done => (MoloColours.moloPulse, MoloColours.moloPlum),
      WizardStepState.current => (
        MoloColours.warmCanvas,
        MoloColours.moloPlum,
      ),
      WizardStepState.pending => (
        MoloColours.surface.withValues(alpha: 0.1),
        MoloColours.warmCanvas.withValues(alpha: 0.6),
      ),
    };
    return Container(
      key: MoloWizardRail.chipKey(number),
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      // A finished step shows a tick instead of its number, which is what says
      // it is behind you rather than merely a different colour.
      child: state == WizardStepState.done
          ? MoloIcon(MoloGlyphs.tick, size: 13, color: foreground)
          : Text(
              '$number',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
                height: MoloTypography.normalLineHeight,
                color: foreground,
              ),
            ),
    );
  }
}

class _WorkspaceCard extends StatelessWidget {
  const _WorkspaceCard({required this.practiceName});

  final String practiceName;

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: MoloColours.surface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(MoloSpacing.railCardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localisations.workspacePreviewTitle.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                letterSpacing: MoloTypography.trackingEm(0.08, 12),
                height: MoloTypography.normalLineHeight,
                color: MoloColours.warmCanvas.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              key: MoloWizardRail.practiceNameKey,
              practiceName.isEmpty
                  ? localisations.workspacePreviewPlaceholder
                  : practiceName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                letterSpacing: MoloTypography.display(24),
                height: MoloTypography.normalLineHeight,
                color: MoloColours.warmCanvas,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              localisations.workspacePreviewBody,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                letterSpacing: 0,
                color: MoloColours.warmCanvas.withValues(alpha: 0.66),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Readiness extends StatelessWidget {
  const _Readiness({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                localisations.workspaceReadiness(percent),
                style: TextStyle(
                  fontSize: 13,
                  letterSpacing: 0,
                  height: MoloTypography.normalLineHeight,
                  color: MoloColours.warmCanvas.withValues(alpha: 0.72),
                ),
              ),
            ),
            Text(
              '$percent%',
              style: const TextStyle(
                fontSize: 13,
                letterSpacing: 0,
                height: MoloTypography.normalLineHeight,
                // Tabular, so the figure does not shuffle sideways as it
                // climbs from 12 to 82.
                fontFeatures: [FontFeature.tabularFigures()],
                color: MoloColours.pulseOnDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder(
            tween: Tween<double>(end: percent / 100),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOut,
            builder: (context, value, _) => LinearProgressIndicator(
              key: MoloWizardRail.readinessBarKey,
              minHeight: 4,
              value: value,
              color: MoloColours.moloPulse,
              backgroundColor: MoloColours.surface.withValues(alpha: 0.16),
            ),
          ),
        ),
      ],
    );
  }
}
```

`TweenAnimationBuilder` is spelt `TweenAnimationBuilder<double>` in Dart; if the analyser asks for the type argument, add it. If it reports the class as undefined, the correct name is `TweenAnimationBuilder` from `package:flutter/widgets.dart` — already imported through `material.dart`.

- [ ] **Step 4: Point the shell at the rail**

In `lib/app/adaptive/molo_wizard_shell.dart`: delete `_WorkspacePreviewPanel` entirely, add `import 'package:molobuddy_app/app/adaptive/molo_wizard_rail.dart';`, and change the expanded branch:

```dart
              if (showPanel && panelProgress != null) {
                return Row(
                  children: [
                    SizedBox(
                      width: MoloAuthShellLayout.wizardRailWidth(
                        constraints.maxWidth,
                      ),
                      child: MoloWizardRail(progress: panelProgress),
                    ),
                    Expanded(child: _Pane(shell: this)),
                  ],
                );
              }
```

- [ ] **Step 5: Run the rail's tests**

Run: `flutter test test/widget/app/molo_wizard_rail_fidelity_test.dart test/unit/app/wizard_progress_test.dart`
Expected: PASS, 15 rail tests plus 9 progress tests. Both need Task 7's strings, so run this step after Task 7 if you are working in order; the rail's own code does not depend on it.

- [ ] **Step 6: Commit**

```bash
git add lib/app/adaptive/molo_wizard_rail.dart lib/app/adaptive/molo_wizard_shell.dart test/widget/app/molo_wizard_rail_fidelity_test.dart
git commit -m "feat: replace the workspace preview with the design's four-step rail"
```

---

### Task 5: The pane, its header, and the step widgets

**Files:**
- Create: `lib/app/design_system/components/molo_field_label.dart`
- Modify: `lib/app/design_system/components/molo_text_field.dart` (its label row becomes the shared one)
- Modify: `lib/app/adaptive/molo_wizard_shell.dart` (`_Pane`, and the exported step widgets)
- Test: `test/widget/core/onboarding/wizard_pane_fidelity_test.dart`

**Interfaces:**
- Consumes: `MoloPillButton`, `MoloBrandLockup`, `MoloGlyphs.backArrow`, `MoloIcon`, `MoloTypography`.
- Produces:
  ```dart
  class MoloFieldLabel extends StatelessWidget {
    const MoloFieldLabel({required this.label, this.trailing, super.key});
    final String label;
    final Widget? trailing;
    static const gap = 7.0;   // between the label and the control below it
  }

  // exported from molo_wizard_shell.dart
  class MoloWizardHeadingGroup extends StatelessWidget {
    const MoloWizardHeadingGroup({
      required this.eyebrow,
      required this.title,
      required this.blurb,
      this.onBack,
      super.key,
    });
  }
  class MoloStepFootnote extends StatelessWidget {
    const MoloStepFootnote({required this.label, super.key});
  }
  class MoloWizardBackButton extends StatefulWidget {   // was stateless
    const MoloWizardBackButton({required this.onPressed, super.key});
  }
  ```
  `MoloStepEyebrow`, `MoloStepHeading` and `MoloWizardBackButton` keep their names and their single `label`/`onPressed` argument, so Tasks 8 and 9 change only what they wrap them in. `MoloStepHeading`'s `textAlign` argument is dropped — nothing passes it.

Traced values:

| Element | Value |
|---|---|
| Pane padding | 28 top, 32 sides, 48 bottom |
| Above the first element | 56, and the column is top-aligned, not centred |
| Content column | 452 max |
| Header row | right aligned: "Already have an account?" 13px `secondaryText`, gap 10, then the pill |
| Heading group | gap 12 throughout |
| Back link | 14px `pulseText`, 16px `backArrow`, gap 8, `moloPlum` on hover |
| Eyebrow | 13px medium `pulseText` |
| Title | 34px medium, tracking -0.025em, height 1.12 |
| Blurb | 15px `secondaryText`, height 1.6 |
| Footnote | 12px, height 1.6 |

The footnote takes `secondaryText`, not the spec's `controlBorder`: 12px is ordinary text and `controlBorder` is 3.30:1 on this ground. This plan's deviation 1.

- [ ] **Step 1: Write the failing test**

Create `test/widget/core/onboarding/wizard_pane_fidelity_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/adaptive/molo_wizard_shell.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_pill_button.dart';
import 'package:molobuddy_app/app/design_system/molo_theme.dart';
import 'package:molobuddy_app/app/localisation/generated/app_localizations.dart';

void main() {
  const steps = [
    WizardStepDescriptor(title: 'Your account', note: 'Name, email and a password'),
    WizardStepDescriptor(title: 'Your practice', note: 'Practice, team size and region'),
    WizardStepDescriptor(title: 'Your first win', note: 'What you want to fix first'),
    WizardStepDescriptor(title: 'Your starting point', note: 'Real data or a sample'),
  ];

  Future<void> pump(
    WidgetTester tester,
    Size size, {
    bool withBack = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        theme: MoloTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MoloWizardShell(
          pageTitle: 'Create your account | Molo',
          progress: const WizardProgress(
            stepNumber: 2,
            readinessPercent: 32,
            steps: steps,
          ),
          showSignInLink: true,
          child: Column(
            key: const Key('a_step'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MoloWizardHeadingGroup(
                eyebrow: 'Shape your workspace',
                title: 'Tell us about your practice',
                blurb: 'These details shape your workspace.',
                onBack: withBack ? () {} : null,
              ),
              const SizedBox(height: 28),
              const MoloStepFootnote(
                label: 'You can change these settings later.',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the content column is capped at 452', (tester) async {
    await pump(tester, const Size(1440, 950));
    expect(tester.getSize(find.byKey(const Key('a_step'))).width, 452);
  });

  testWidgets('the column is top aligned, 56 below the header', (tester) async {
    await pump(tester, const Size(1440, 950));
    final header = tester.getRect(find.text('Already have an account?'));
    final firstElement = tester.getRect(find.text('Shape your workspace'));
    // 56 of padding, plus the header's own bottom padding within the pane.
    expect(firstElement.top - header.bottom, greaterThan(50));
    // Top aligned rather than centred: on a tall window the heading stays put.
    expect(firstElement.top, lessThan(300));
  });

  testWidgets('the offer to sign in is a pill, not a link', (tester) async {
    await pump(tester, const Size(1440, 950));
    expect(find.byType(MoloPillButton), findsOneWidget);
    expect(find.text('Already have an account?'), findsOneWidget);
    expect(find.byKey(const Key('registration_sign_in_link')), findsOneWidget);
  });

  testWidgets('on compact the lockup appears and the label drops', (
    tester,
  ) async {
    await pump(tester, const Size(390, 900));
    expect(find.text('molo'), findsOneWidget);
    expect(find.text('Already have an account?'), findsNothing);
    expect(find.byKey(const Key('registration_sign_in_link')), findsOneWidget);
  });

  group('the heading group', () {
    testWidgets('the eyebrow is 13px medium pulseText', (tester) async {
      await pump(tester, const Size(1440, 950));
      final eyebrow = tester.widget<Text>(find.text('Shape your workspace'));
      expect(eyebrow.style?.fontSize, 13);
      expect(eyebrow.style?.fontWeight, FontWeight.w500);
      expect(eyebrow.style?.color, MoloColours.pulseText);
    });

    testWidgets('the title is 34px at the design tracking', (tester) async {
      await pump(tester, const Size(1440, 950));
      final title = tester.widget<Text>(
        find.text('Tell us about your practice'),
      );
      expect(title.style?.fontSize, 34);
      expect(title.style?.height, 1.12);
      expect(title.style?.letterSpacing, closeTo(-0.85, 0.001));
    });

    testWidgets('the blurb is 15px secondaryText', (tester) async {
      await pump(tester, const Size(1440, 950));
      final blurb = tester.widget<Text>(
        find.text('These details shape your workspace.'),
      );
      expect(blurb.style?.fontSize, 15);
      expect(blurb.style?.height, 1.6);
      expect(blurb.style?.color, MoloColours.secondaryText);
    });

    testWidgets('the title is announced as a heading', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, const Size(1440, 950));
      expect(
        tester.getSemantics(find.text('Tell us about your practice')),
        isSemantics(label: 'Tell us about your practice', isHeader: true),
      );
      semantics.dispose();
    });

    testWidgets('the group is 12 apart throughout', (tester) async {
      await pump(tester, const Size(1440, 950));
      final eyebrow = tester.getRect(find.text('Shape your workspace'));
      final title = tester.getRect(find.text('Tell us about your practice'));
      expect(title.top - eyebrow.bottom, closeTo(12, 2));
    });

    testWidgets('back appears only where there is somewhere to go', (
      tester,
    ) async {
      await pump(tester, const Size(1440, 950));
      expect(find.byType(MoloWizardBackButton), findsNothing);

      await pump(tester, const Size(1440, 950), withBack: true);
      expect(find.byType(MoloWizardBackButton), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      // Above the eyebrow, so it reads before the step it leaves.
      expect(
        tester.getRect(find.text('Back')).top,
        lessThan(tester.getRect(find.text('Shape your workspace')).top),
      );
    });
  });

  testWidgets('the footnote is 12px in a colour that clears 4.5:1', (
    tester,
  ) async {
    await pump(tester, const Size(1440, 950));
    final footnote = tester.widget<Text>(
      find.text('You can change these settings later.'),
    );
    expect(footnote.style?.fontSize, 12);
    expect(footnote.style?.height, 1.6);
    // Not the spec's controlBorder: 3.30:1 on the warm canvas, and this is
    // ordinary text at 12px.
    expect(footnote.style?.color, MoloColours.secondaryText);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/core/onboarding/wizard_pane_fidelity_test.dart`
Expected: FAIL — `MoloWizardHeadingGroup` and `MoloStepFootnote` do not exist, and the pane is 560 wide with `MoloSpacing.lg` padding.

- [ ] **Step 3: Extract the field label**

Create `lib/app/design_system/components/molo_field_label.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/typography/molo_typography.dart';

/// The label above a field, and anything the design puts at the right of that
/// same row.
///
/// One definition because two controls need it — a text field and the region
/// select — and a label that drifted between them would be visible on the one
/// step that shows both.
///
/// Excluded from semantics: the control below re-states it as its own
/// accessible name, so leaving this visible to a screen reader would say it
/// twice.
class MoloFieldLabel extends StatelessWidget {
  const MoloFieldLabel({required this.label, this.trailing, super.key});

  final String label;

  /// An action at the right of the row, such as "Forgot password?". Outside
  /// this widget's exclusion, because it is a separate control.
  final Widget? trailing;

  /// The design's distance from this label to the control below it.
  static const gap = 7.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: ExcludeSemantics(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
                height: MoloTypography.normalLineHeight,
                color: MoloColours.moloPlum,
              ),
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
```

In `lib/app/design_system/components/molo_text_field.dart`, replace the label `Row` and the `SizedBox(height: 7)` with:

```dart
        MoloFieldLabel(label: label, trailing: trailing),
        const SizedBox(height: MoloFieldLabel.gap),
```

and add the import. The `MoloTypography` import may become unused — check with `grep -n MoloTypography lib/app/design_system/components/molo_text_field.dart` before removing it; the field's 15px value style still uses it, so it stays.

- [ ] **Step 4: Rewrite the pane and the step widgets**

In `lib/app/adaptive/molo_wizard_shell.dart`, replace `_Pane`'s `build` with:

```dart
  @override
  Widget build(BuildContext context) {
    final progress = shell.progress;
    return ColoredBox(
      color: MoloColours.warmCanvas,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
            child: _WizardHeaderRow(
              showWordmark: showCompactHeader,
              showSignInOffer: shell.showSignInLink,
            ),
          ),
          if (showCompactHeader && progress != null)
            _CompactProgress(progress: progress),
          if (showCompactHeader &&
              progress != null &&
              shell.showWorkspaceSummary)
            _CompactWorkspaceSummary(progress: progress),
          Expanded(
            child: SingleChildScrollView(
              // The design tops the column out 56 below the header and leaves
              // 48 under it, and keeps it top aligned: a centred column would
              // move the heading every time a step's controls changed height.
              padding: const EdgeInsets.fromLTRB(32, 56, 32, 48),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 452),
                  child: AnimatedSwitcher(
                    duration: MoloMotion.duration(context, MoloMotion.step),
                    reverseDuration: MoloMotion.duration(
                      context,
                      MoloMotion.routeReverse,
                    ),
                    transitionBuilder: (child, animation) {
                      final arrival = CurvedAnimation(
                        parent: animation,
                        curve: MoloMotion.standard,
                        reverseCurve: MoloMotion.exit,
                      );
                      return FadeTransition(opacity: arrival, child: child);
                    },
                    child: shell.child,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
```

Add, replacing the header `Row` that was inline:

```dart
/// The pane's top row: the wordmark where the rail is absent, then the offer to
/// sign in instead.
class _WizardHeaderRow extends StatelessWidget {
  const _WizardHeaderRow({
    required this.showWordmark,
    required this.showSignInOffer,
  });

  final bool showWordmark;
  final bool showSignInOffer;

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    return Row(
      // No spacer: a spacer is a tight flex child and would take a share of the
      // row the pill then could not have, truncating its label while the row
      // still had room.
      mainAxisAlignment: showWordmark
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.end,
      children: [
        if (showWordmark) const MoloBrandLockup(compact: true),
        if (showSignInOffer) ...[
          if (!showWordmark) ...[
            Flexible(
              child: Text(
                localisations.alreadyHaveAccount,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  letterSpacing: 0,
                  height: MoloTypography.normalLineHeight,
                  color: MoloColours.secondaryText,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: MoloPillButton(
              key: const Key('registration_sign_in_link'),
              label: localisations.signIn,
              onPressed: () => const SignInRoute().go(context),
            ),
          ),
        ],
      ],
    );
  }
}
```

Replace the three exported step widgets and add two more:

```dart
/// The eyebrow, title and blurb the design puts at the head of every step, with
/// the back link above them where there is a step to go back to.
class MoloWizardHeadingGroup extends StatelessWidget {
  const MoloWizardHeadingGroup({
    required this.eyebrow,
    required this.title,
    required this.blurb,
    this.onBack,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String blurb;

  /// Null on the first step, which has nowhere to go back to.
  final VoidCallback? onBack;

  /// The design separates every element of this group by the same 12.
  static const _gap = 12.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onBack != null) ...[
          MoloWizardBackButton(onPressed: onBack!),
          const SizedBox(height: _gap),
        ],
        MoloStepEyebrow(label: eyebrow),
        const SizedBox(height: _gap),
        MoloStepHeading(label: title),
        const SizedBox(height: _gap),
        _StepBlurb(label: blurb),
      ],
    );
  }
}

class MoloStepEyebrow extends StatelessWidget {
  const MoloStepEyebrow({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: MoloTypography.normalLineHeight,
        color: MoloColours.pulseText,
      ),
    );
  }
}

class MoloStepHeading extends StatelessWidget {
  const MoloStepHeading({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w500,
          height: 1.12,
          letterSpacing: MoloTypography.trackingEm(-0.025, 34),
          color: MoloColours.moloPlum,
        ),
      ),
    );
  }
}

class _StepBlurb extends StatelessWidget {
  const _StepBlurb({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        height: 1.6,
        letterSpacing: 0,
        color: MoloColours.secondaryText,
      ),
    );
  }
}

/// The quiet line under a step's primary action.
class MoloStepFootnote extends StatelessWidget {
  const MoloStepFootnote({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        height: 1.6,
        letterSpacing: 0,
        // Not the design's #9A858D, which is 3.30:1 on this ground. At 12px
        // this is ordinary text and 1.4.3 asks for 4.5:1.
        color: MoloColours.secondaryText,
      ),
    );
  }
}

/// The link back to the previous step.
///
/// Stateful only to follow its own hover: the glyph takes a fixed colour, so it
/// cannot read the button's state the way a text style can.
class MoloWizardBackButton extends StatefulWidget {
  const MoloWizardBackButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  State<MoloWizardBackButton> createState() => _MoloWizardBackButtonState();
}

class _MoloWizardBackButtonState extends State<MoloWizardBackButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    final colour = _hovered ? MoloColours.moloPlum : MoloColours.pulseText;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: widget.onPressed,
        onHover: (value) => setState(() => _hovered = value),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.padded,
          foregroundColor: colour,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MoloIcon(MoloGlyphs.backArrow, size: 16, color: colour),
            const SizedBox(width: 8),
            Text(
              localisations.backLabel,
              style: TextStyle(
                fontSize: 14,
                letterSpacing: 0,
                height: MoloTypography.normalLineHeight,
                color: colour,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

Add the imports this brings in: `molo_brand_lockup.dart`, `molo_pill_button.dart`, `molo_glyphs.dart`. `molo_wordmark.dart` becomes unused in this file — remove that import.

- [ ] **Step 5: Run the pane's tests**

Run: `flutter test test/widget/core/onboarding/wizard_pane_fidelity_test.dart`
Expected: PASS, 11 tests. If the 56 assertion fails by a few pixels, print the two rects and adjust the assertion's floor — the padding value is the design's and does not move.

- [ ] **Step 6: Commit**

```bash
git add lib/app/design_system/components/molo_field_label.dart lib/app/design_system/components/molo_text_field.dart lib/app/adaptive/molo_wizard_shell.dart test/widget/core/onboarding/wizard_pane_fidelity_test.dart
git commit -m "feat: re-trace the wizard pane and the widgets every step shares"
```

---

### Task 6: The primary action when a step is incomplete

**Files:**
- Modify: `lib/app/adaptive/molo_wizard_shell.dart` (add the widget)
- Test: `test/widget/core/onboarding/wizard_pane_fidelity_test.dart` (append a group)

**Interfaces:**
- Consumes: the theme's `FilledButton` style, `MoloColours`.
- Produces:
  ```dart
  class MoloWizardPrimaryAction extends StatelessWidget {
    const MoloWizardPrimaryAction({
      required this.label,
      required this.complete,
      required this.outstanding,
      required this.onPressed,
      this.busy = false,
      this.buttonKey,
      super.key,
    });
    final String label;
    final bool complete;      // whether the step's answers are all in
    final String outstanding; // spoken reason, used only when incomplete
    final VoidCallback onPressed;
    final bool busy;
    final Key? buttonKey;
  }
  ```

Per spec section 6.4 and this plan's deviation 3: incomplete takes the baseline's appearance — a `border` fill with a `controlBorder` label — and gains a spoken reason, but **stays pressable**, because pressing is what reveals the inline field errors the same section keeps. `1.9:1` is exempt as a disabled control's contrast, and this control looks disabled without being dead.

- [ ] **Step 1: Write the failing test**

Append to `test/widget/core/onboarding/wizard_pane_fidelity_test.dart`, inside `main()`:

```dart
  group('the primary action', () {
    late int presses;

    Future<void> pumpAction(
      WidgetTester tester, {
      required bool complete,
      bool busy = false,
    }) async {
      presses = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: MoloTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 452,
                child: MoloWizardPrimaryAction(
                  buttonKey: const Key('primary'),
                  label: 'Continue',
                  complete: complete,
                  outstanding: 'Enter your practice name.',
                  busy: busy,
                  onPressed: () => presses++,
                ),
              ),
            ),
          ),
        ),
      );
    }

    ButtonStyle styleOf(WidgetTester tester) =>
        tester.widget<FilledButton>(find.byKey(const Key('primary'))).style!;

    testWidgets('complete, it is the plum primary at 52 high', (tester) async {
      await pumpAction(tester, complete: true);
      expect(tester.getSize(find.byKey(const Key('primary'))).height, 52);
      expect(
        styleOf(tester).backgroundColor?.resolve(const <WidgetState>{}),
        isNull,
        reason: 'a complete step defers to the theme',
      );
    });

    testWidgets('incomplete, it takes the design quiet fill and label', (
      tester,
    ) async {
      await pumpAction(tester, complete: false);
      expect(
        styleOf(tester).backgroundColor?.resolve(const <WidgetState>{}),
        MoloColours.border,
      );
      expect(
        styleOf(tester).foregroundColor?.resolve(const <WidgetState>{}),
        MoloColours.controlBorder,
      );
    });

    testWidgets('incomplete, it still presses, which is what shows the errors', (
      tester,
    ) async {
      await pumpAction(tester, complete: false);
      await tester.tap(find.byKey(const Key('primary')));
      await tester.pump();
      expect(presses, 1);
    });

    testWidgets('incomplete, it says what is outstanding', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpAction(tester, complete: false);
      expect(
        tester.getSemantics(find.byKey(const Key('primary'))),
        isSemantics(
          label: 'Continue',
          hint: 'Enter your practice name.',
          isButton: true,
          isEnabled: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('complete, it has nothing left to explain', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpAction(tester, complete: true);
      expect(
        tester.getSemantics(find.byKey(const Key('primary'))),
        isSemantics(label: 'Continue', hint: '', isButton: true),
      );
      semantics.dispose();
    });

    testWidgets('busy, it shows a spinner and refuses a second press', (
      tester,
    ) async {
      await pumpAction(tester, complete: true, busy: true);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byKey(const Key('primary')), warnIfMissed: false);
      await tester.pump();
      expect(presses, 0);
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/core/onboarding/wizard_pane_fidelity_test.dart`
Expected: FAIL — `MoloWizardPrimaryAction` does not exist.

- [ ] **Step 3: Write the widget**

Add to `lib/app/adaptive/molo_wizard_shell.dart`:

```dart
/// A step's primary action.
///
/// When the step's answers are not all in, this takes the design's quiet
/// appearance — a `border` fill under a `controlBorder` label — but stays
/// pressable. Pressing is how a pointer user learns what is missing: it is what
/// puts the inline messages on the fields. A control that looked like this and
/// did nothing would leave them with no way to find out.
///
/// The reason is also spoken, so somebody who cannot see the quiet fill is told
/// what is outstanding rather than pressing into silence.
class MoloWizardPrimaryAction extends StatelessWidget {
  const MoloWizardPrimaryAction({
    required this.label,
    required this.complete,
    required this.outstanding,
    required this.onPressed,
    this.busy = false,
    this.buttonKey,
    super.key,
  });

  final String label;

  /// Whether every answer this step needs has been given.
  final bool complete;

  /// What is still missing, spoken when [complete] is false.
  final String outstanding;

  final VoidCallback onPressed;
  final bool busy;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        hint: complete ? null : outstanding,
        child: FilledButton(
          key: buttonKey,
          onPressed: busy ? null : onPressed,
          style: complete
              ? null
              : FilledButton.styleFrom(
                  backgroundColor: MoloColours.border,
                  foregroundColor: MoloColours.controlBorder,
                ),
          child: busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: MoloColours.surface,
                  ),
                )
              : Text(label),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget/core/onboarding/wizard_pane_fidelity_test.dart`
Expected: PASS, 17 tests. If the `hint` does not appear on the merged node, the cause is `MergeSemantics` sitting outside `Semantics` rather than inside; swap them so `Semantics` is the outer widget and `MergeSemantics` wraps the button.

- [ ] **Step 5: Commit**

```bash
git add lib/app/adaptive/molo_wizard_shell.dart test/widget/core/onboarding/wizard_pane_fidelity_test.dart
git commit -m "feat: say what is outstanding rather than only looking incomplete"
```

---

### Task 7: The copy

**Files:**
- Modify: `lib/app/localisation/l10n/app_en.arb`
- Modify: `lib/app/localisation/l10n/app_en_ZA.arb`
- Modify: `lib/app/design_system/components/molo_check_row.dart` (a box radius, so the terms row can be the design's 7)

**Interfaces:**
- Consumes: nothing.
- Produces on `AppLocalizations`: `wizardStepAccountTitle`, `wizardStepAccountNote`, `wizardStepPracticeTitle`, `wizardStepPracticeNote`, `wizardStepGoalsTitle`, `wizardStepGoalsNote`, `wizardStepStartTitle`, `wizardStepStartNote`, `wizardFootnoteAccount`, `wizardFootnotePractice`, `wizardFootnoteGoals`, `wizardFootnoteStart`, `fullNameHint`, `passwordLongEnough`, `wizardAccountOutstanding`. And on `MoloCheckRow`: `boxRadius`, defaulting to 6.

Every eyebrow, title, blurb, option label and option description the wizard needs is **already** in the ARB, word for word from the baseline. What is new is the rail's own titles and notes, the four footnotes, the password-satisfied hint, and one spoken reason. The other three spoken reasons reuse the inline messages that already exist — `practiceNameRequired`, `choosePriorityRequired` and `chooseStartingPointRequired` — because the button's hint and the field's message should not be two different sentences about one problem.

- [ ] **Step 1: Add the new strings**

In `lib/app/localisation/l10n/app_en.arb`, add after `"alreadyHaveAccount"`:

```json
  "wizardStepAccountTitle": "Your account",
  "wizardStepAccountNote": "Name, email and a password",
  "wizardStepPracticeTitle": "Your practice",
  "wizardStepPracticeNote": "Practice, team size and region",
  "wizardStepGoalsTitle": "Your first win",
  "wizardStepGoalsNote": "What you want to fix first",
  "wizardStepStartTitle": "Your starting point",
  "wizardStepStartNote": "Real data or a sample",
  "wizardFootnoteAccount": "Molo never signs in to eFiling, submits returns or makes payments on your behalf.",
  "wizardFootnotePractice": "You can rename the practice and change these settings later.",
  "wizardFootnoteGoals": "This only changes what Molo puts in front of you first. Nothing is hidden.",
  "wizardFootnoteStart": "Sample data is clearly marked and can be removed in one step.",
  "fullNameHint": "Ngcebo Qwabe",
  "passwordLongEnough": "Long enough.",
  "wizardAccountOutstanding": "Add your name, a work email, a password of at least 8 characters, and agree to the terms.",
```

- [ ] **Step 2: Retire what nothing reads**

The retired completion screen and the old three-item progress panel left fourteen strings behind. Confirm each is unread, then delete it and any `@`-metadata block that follows it:

```bash
for k in registrationCompleteTitle registrationCompleteBody registrationCompleteSummary \
         continueToSignIn noRegistrationDataSaved registrationHeroTitle registrationHeroBody \
         progressAccount progressAccountBody progressPractice progressPracticeBody \
         progressPriorities progressPrioritiesBody finishSetup; do
  printf '%-32s %s\n' "$k" "$(grep -rl "localisations\.$k\b" lib test | wc -l | tr -d ' ')"
done
```

Expected: every count is 0. Delete only the keys that report 0; if one reports a use, leave it and say so in the commit message.

- [ ] **Step 3: Mirror both changes into the South African file**

Apply steps 1 and 2 identically to `lib/app/localisation/l10n/app_en_ZA.arb`. Same keys, same values — this locale exists for spelling and format, and none of these strings differ.

- [ ] **Step 4: Check for duplicates, then regenerate**

```bash
python3 -c "import re,collections,io;[print(p,{k:c for k,c in collections.Counter(re.findall(r'^  \"(@?[A-Za-z0-9_]+)\":',io.open(p).read(),re.M)).items() if c>1} or 'clean') for p in ['lib/app/localisation/l10n/app_en.arb','lib/app/localisation/l10n/app_en_ZA.arb']]"
flutter gen-l10n
```

Expected: both files report `clean`, and generation succeeds. A duplicate key is not an error in JSON — the last one silently wins — so this check is the only thing that catches it.

- [ ] **Step 5: Let the check row take the design's other radius**

The sign-in row draws its box at radius 6; the terms row draws the same 21-square box at radius 7, matching the multiple-choice mark. In `lib/app/design_system/components/molo_check_row.dart`, add the parameter:

```dart
    this.boxSize = 19,
    this.boxRadius = 6,
```

with the field and doc:

```dart
  /// The design draws 19 at sign-in and 21 on the terms row.
  final double boxSize;

  /// 6 at sign-in, 7 on the terms row, where the box matches the shape of a
  /// multiple-choice mark.
  final double boxRadius;
```

and replace both `BorderRadius.circular(6)` uses in that file with `BorderRadius.circular(boxRadius)`.

- [ ] **Step 6: Run the tests that the strings unblock**

Run: `flutter test test/unit/app/wizard_progress_test.dart test/widget/app/molo_wizard_rail_fidelity_test.dart test/widget/app/molo_check_row_test.dart test/widget/core/onboarding/wizard_pane_fidelity_test.dart`
Expected: PASS. These are the tests from Tasks 3 to 6 that needed `moloWizardSteps` to compile.

- [ ] **Step 7: Commit**

```bash
git add lib/app/localisation lib/app/design_system/components/molo_check_row.dart
git commit -m "feat: give the rail its own titles and every step its footnote"
```

---

### Task 8: Step one, the account

**Files:**
- Modify: `lib/core/auth/ui/views/registration/registration_view.dart`
- Test: `test/widget/core/auth/registration_view_test.dart` (append a fidelity group)

**Interfaces:**
- Consumes: `MoloWizardShell`, `WizardProgress`, `moloWizardSteps`, `MoloWizardHeadingGroup`, `MoloStepFootnote`, `MoloWizardPrimaryAction`, `MoloTextField`, `MoloCheckRow`, `MoloIcon`, `MoloGlyphs.eye`.
- Produces: no new API. **Keys that must survive**, because other tests depend on them: `Key('registration_account_step')`, `Key('registration_name_field')`, `Key('registration_email_field')`, `Key('registration_password_field')`, `Key('registration_terms_checkbox')`, `Key('registration_account_continue')`, `Key('registration_failure_notice')`.

Traced values: fields group gap 18; the password hint sits under its field; the terms row is a 21 square at radius 7; primary and footnote 12 apart; the whole step's groups 28 apart.

The password hint reads `passwordHelper` ("Use at least 8 characters.") until the password is long enough and `passwordLongEnough` ("Long enough.") after. The satisfied colour is the existing `success` token, not the baseline's `#2C7A62`, per spec section 6.2. The unsatisfied colour is `secondaryText`, not the baseline's `#9A858D` — this plan's deviation 1 again, at 12px.

- [ ] **Step 1: Write the failing test**

Append to `test/widget/core/auth/registration_view_test.dart`, inside `main()`. That file already has the helpers this needs: `_setViewport(tester, size)`, `_pumpPreviewApp(tester)` and `_openRegistration(tester)`, which taps through from sign-in. Add one wrapper beside them so each test reads as one line:

```dart
/// Sign-in, then through to the account step, at a stated size.
Future<void> _pumpRegistration(WidgetTester tester) async {
  await _pumpPreviewApp(tester);
  await _openRegistration(tester);
}
```

```dart
  group('step one fidelity', () {
    testWidgets('the rail names all four steps and marks this one', (
      tester,
    ) async {
      await _setViewport(tester, const Size(1440, 950));
      await _pumpRegistration(tester);

      expect(find.text('Your account'), findsOneWidget);
      expect(find.text('Your practice'), findsOneWidget);
      expect(find.text('Your first win'), findsOneWidget);
      expect(find.text('Your starting point'), findsOneWidget);
      expect(find.text('Step 1 of 4'), findsOneWidget);
    });

    testWidgets('there is no way back from the first step', (tester) async {
      await _setViewport(tester, const Size(1440, 950));
      await _pumpRegistration(tester);
      expect(find.byType(MoloWizardBackButton), findsNothing);
    });

    testWidgets('the password hint changes once it is long enough', (
      tester,
    ) async {
      await _setViewport(tester, const Size(1440, 950));
      await _pumpRegistration(tester);

      expect(find.text('Use at least 8 characters.'), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.text('Use at least 8 characters.'))
            .style
            ?.color,
        MoloColours.secondaryText,
      );

      await tester.enterText(
        find.byKey(const Key('registration_password_field')),
        'long-enough-password',
      );
      await tester.pump();

      expect(find.text('Use at least 8 characters.'), findsNothing);
      expect(find.text('Long enough.'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Long enough.')).style?.color,
        MoloColours.success,
      );
    });

    testWidgets('the terms row is the design box, not a Material checkbox', (
      tester,
    ) async {
      await _setViewport(tester, const Size(1440, 950));
      await _pumpRegistration(tester);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.byKey(const Key('registration_terms_checkbox')), findsOneWidget);
      expect(
        tester.getSize(find.byKey(MoloCheckRow.boxKey)),
        const Size(21, 21),
      );
    });

    testWidgets('the two documents stay separate links', (tester) async {
      await _setViewport(tester, const Size(1440, 950));
      await _pumpRegistration(tester);
      // Consent belongs to the box; reading a document must not grant it.
      expect(
        find.textContaining('Terms of Service', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Privacy Policy', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('the action is quiet until every answer is in', (tester) async {
      await _setViewport(tester, const Size(1440, 950));
      await _pumpRegistration(tester);
      final button = find.byKey(const Key('registration_account_continue'));

      expect(
        tester.widget<FilledButton>(button).style
            ?.backgroundColor
            ?.resolve(const <WidgetState>{}),
        MoloColours.border,
      );

      await tester.enterText(
        find.byKey(const Key('registration_name_field')),
        'Ngcebo Qwabe',
      );
      await tester.enterText(
        find.byKey(const Key('registration_email_field')),
        'ngcebo@practice.co.za',
      );
      await tester.enterText(
        find.byKey(const Key('registration_password_field')),
        'long-enough-password',
      );
      await tester.tap(find.byKey(const Key('registration_terms_checkbox')));
      await tester.pumpAndSettle();

      expect(
        tester.widget<FilledButton>(button).style?.backgroundColor,
        isNull,
        reason: 'a complete step defers to the theme',
      );
    });

    testWidgets('the footnote says what Molo will not do', (tester) async {
      await _setViewport(tester, const Size(1440, 950));
      await _pumpRegistration(tester);
      expect(
        find.textContaining('never signs in to eFiling'),
        findsOneWidget,
      );
    });
  });
```

Add whatever imports these need: `molo_wizard_shell.dart`, `molo_check_row.dart`, `molo_colours.dart`.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/core/auth/registration_view_test.dart`
Expected: FAIL — the rail's titles are absent, the hint never changes, and the terms row is still a Material `Checkbox`.

- [ ] **Step 3: Rewrite the view**

In `lib/core/auth/ui/views/registration/registration_view.dart`:

Keep `_RegistrationViewState`'s three controllers, `_obscurePassword`, `_acceptedTerms` and `dispose`. Its `build` becomes:

```dart
  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    final state = ref.watch(registrationViewModelProvider);
    return MoloWizardShell(
      pageTitle: localisations.signUpPageTitle,
      progress: WizardProgress(
        stepNumber: 1,
        readinessPercent: 12,
        steps: moloWizardSteps(localisations),
      ),
      showSignInLink: true,
      child: _AccountStep(
        key: const ValueKey('account'),
        state: state,
        nameController: _nameController,
        emailController: _emailController,
        passwordController: _passwordController,
        obscurePassword: _obscurePassword,
        acceptedTerms: _acceptedTerms,
        onTogglePassword: () =>
            setState(() => _obscurePassword = !_obscurePassword),
        onAcceptedTermsChanged: (value) =>
            setState(() => _acceptedTerms = value),
      ),
    );
  }
```

Note `onAcceptedTermsChanged` becomes `ValueChanged<bool>`, not `ValueChanged<bool?>`: `MoloCheckRow` never reports null, and the old signature existed only to satisfy Material's tristate `Checkbox`.

`_AccountStep`'s `build` becomes:

```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localisations = AppLocalizations.of(context);
    return AutofillGroup(
      child: Column(
        key: const Key('registration_account_step'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MoloWizardHeadingGroup(
            eyebrow: localisations.registrationStepAccount,
            title: localisations.createYourAccount,
            blurb: localisations.createAccountSubtitle,
          ),
          const SizedBox(height: 28),
          MoloTextField(
            label: localisations.fullNameLabel,
            fieldKey: const Key('registration_name_field'),
            controller: nameController,
            hintText: localisations.fullNameHint,
            errorText: state.nameInvalid
                ? localisations.fullNameRequired
                : null,
            autofillHints: const [AutofillHints.name],
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 18),
          MoloTextField(
            label: localisations.workEmailLabel,
            fieldKey: const Key('registration_email_field'),
            controller: emailController,
            hintText: localisations.emailHint,
            errorText: state.emailAlreadyRegistered
                ? localisations.emailAlreadyRegistered
                : state.emailInvalid
                ? localisations.invalidEmail
                : null,
            autofillHints: const [AutofillHints.newUsername],
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
          ),
          const SizedBox(height: 18),
          _PasswordField(
            controller: passwordController,
            obscure: obscurePassword,
            onToggle: onTogglePassword,
            errorText: state.passwordTooShort
                ? localisations.passwordTooShort
                : null,
          ),
          const SizedBox(height: 18),
          MoloCheckRow(
            key: const Key('registration_terms_checkbox'),
            boxSize: 21,
            boxRadius: 7,
            value: acceptedTerms,
            onChanged: onAcceptedTermsChanged,
            semanticLabel: localisations.acceptTermsLabel(
              localisations.termsOfService,
              localisations.privacyPolicy,
            ),
            label: AuthLegalLinksText(
              label: localisations.acceptTermsLabel(
                localisations.termsOfService,
                localisations.privacyPolicy,
              ),
              termsLabel: localisations.termsOfService,
              privacyLabel: localisations.privacyPolicy,
              onTermsPressed: () => showAuthLegalPreviewDialog(
                context,
                title: localisations.termsOfService,
                body: localisations.legalPreviewBody,
                closeLabel: localisations.closeLabel,
              ),
              onPrivacyPressed: () => showAuthLegalPreviewDialog(
                context,
                title: localisations.privacyPolicy,
                body: localisations.legalPreviewBody,
                closeLabel: localisations.closeLabel,
              ),
            ),
          ),
          if (state.termsNotAccepted) ...[
            const SizedBox(height: MoloSpacing.xs),
            Text(
              localisations.acceptTermsRequired,
              style: const TextStyle(fontSize: 12, color: MoloColours.error),
            ),
          ],
          const SizedBox(height: 28),
          if (state.failure != null) ...[
            _AccountFailureNotice(failure: state.failure!),
            const SizedBox(height: MoloSpacing.md),
          ],
          // The action's appearance follows the fields as they are typed, so it
          // needs to rebuild on every keystroke rather than only on submit.
          ListenableBuilder(
            listenable: Listenable.merge([
              nameController,
              emailController,
              passwordController,
            ]),
            builder: (context, _) => MoloWizardPrimaryAction(
              buttonKey: const Key('registration_account_continue'),
              label: localisations.continueLabel,
              complete: _complete,
              outstanding: localisations.wizardAccountOutstanding,
              busy: state.submitting,
              onPressed: () => _submit(context, ref),
            ),
          ),
          const SizedBox(height: 12),
          MoloStepFootnote(label: localisations.wizardFootnoteAccount),
        ],
      ),
    );
  }

  /// The same four conditions the view model checks on submit. Restated here
  /// only to decide the button's appearance; the view model stays the authority
  /// on whether the account is created.
  bool get _complete =>
      nameController.text.trim().isNotEmpty &&
      emailController.text.contains('@') &&
      passwordController.text.length >= 8 &&
      acceptedTerms;
```

Delete `_TermsAgreement` entirely — `MoloCheckRow` plus the message above replaces it.

Add the password field, which is the one field with a hint below it:

```dart
/// The password field and the line under it that says whether it is long
/// enough.
class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
    required this.errorText,
  });

  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final longEnough = controller.text.length >= 8;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MoloTextField(
              label: localisations.createPasswordLabel,
              fieldKey: const Key('registration_password_field'),
              controller: controller,
              obscureText: obscure,
              hintText: localisations.passwordHint,
              errorText: errorText,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              suffix: IconButton(
                tooltip: obscure
                    ? localisations.showPassword
                    : localisations.hidePassword,
                onPressed: onToggle,
                icon: MoloIcon(
                  MoloGlyphs.eye,
                  size: 18,
                  color: MoloColours.secondaryText,
                ),
                style: IconButton.styleFrom(
                  fixedSize: const Size.square(36),
                  padding: EdgeInsets.zero,
                  hoverColor: MoloColours.pulseTint,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: MoloFieldLabel.gap),
            Text(
              longEnough
                  ? localisations.passwordLongEnough
                  : localisations.passwordHelper,
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 0,
                height: MoloTypography.normalLineHeight,
                // The satisfied colour is the existing success token at 5.35:1
                // rather than the baseline's own green at 5.17:1, which would
                // have been a second green for no gain. The unsatisfied one is
                // secondaryText, not the baseline's #9A858D at 3.30:1.
                color: longEnough
                    ? MoloColours.success
                    : MoloColours.secondaryText,
              ),
            ),
          ],
        );
      },
    );
  }
}
```

- [ ] **Step 4: Run the step's tests**

Run: `flutter test test/widget/core/auth/registration_view_test.dart`
Expected: PASS. Any pre-existing test in that file that tapped the Material `Checkbox` now taps `Key('registration_terms_checkbox')` instead; the key is unchanged, so `tester.tap` on it keeps working.

- [ ] **Step 5: Commit**

```bash
git add lib/core/auth/ui/views/registration/registration_view.dart lib/app/localisation test/widget/core/auth/registration_view_test.dart
git commit -m "feat: re-trace the account step, hint and terms row included"
```

---

### Task 9: Steps two, three and four

**Files:**
- Modify: `lib/core/onboarding/ui/views/onboarding_view.dart`
- Test: `test/widget/core/onboarding/onboarding_view_test.dart` (append a fidelity group)

**Interfaces:**
- Consumes: `MoloWizardShell`, `WizardProgress`, `moloWizardSteps`, `MoloWizardHeadingGroup`, `MoloStepFootnote`, `MoloWizardPrimaryAction`, `MoloChoiceCard`, `MoloChoiceKind`, `MoloTextField`, `MoloFieldLabel`, and the ten option glyphs.
- Produces: no new API. **Keys that must survive:** `Key('registration_practice_step')`, `Key('practice_name_field')`, `Key('practice_size_solo')`, `Key('practice_size_small')`, `Key('practice_size_growing')`, `Key('practice_region_field')`, `Key('registration_practice_continue')`, `Key('registration_priorities_step')`, `Key('priority_deadlines')` and its three siblings, `Key('complete_registration_preview')`, `Key('registration_starting_point_step')`, `Key('starting_point_import')`, `Key('starting_point_client')`, `Key('starting_point_sample')`, `Key('finish_registration_preview')`, `Key('onboarding_failure_notice')`, `Key('onboarding_load_failure')`, `Key('onboarding_load_retry')`.

**Nothing about the answers changes.** `OnboardingAnswers`, `PracticeSize`, `OnboardingPriority`, `WorkspaceStartingPoint`, every `saveAnswers` call and `completeOnboarding` stay exactly as they are, including the practice step's rule that a name of two characters or more is enough and the size defaults to `solo`. Only the presentation moves.

Traced values: step 2's groups are 24 apart; the option cards in every step are 10 apart; the label above a group of cards is 10 above the first one; the region select's helper sits below it at 12px.

Glyph assignments, replacing the Material icons:

| Card | Was | Becomes |
|---|---|---|
| Just me | `Icons.person_outline_rounded` | `MoloGlyphs.practiceSolo` |
| A team of 2 to 10 | `Icons.groups_2_outlined` | `MoloGlyphs.practiceSmallTeam` |
| A team of 11 or more | `Icons.apartment_rounded` | `MoloGlyphs.practiceGrowing` |
| Stay ahead of deadlines | `Icons.event_available_outlined` | `MoloGlyphs.goalDeadlines` |
| Keep documents moving | `Icons.folder_copy_outlined` | `MoloGlyphs.goalDocuments` |
| Run work with a team | `Icons.hub_outlined` | `MoloGlyphs.goalTeamwork` |
| See the whole practice clearly | `Icons.auto_graph_rounded` | `MoloGlyphs.goalVisibility` |
| Import a client list | `Icons.upload_file_outlined` | `MoloGlyphs.startImport` |
| Add the first client | `Icons.person_add_alt_1_outlined` | `MoloGlyphs.startFirstClient` |
| Explore a sample workspace | `Icons.explore_outlined` | `MoloGlyphs.startSample` |

- [ ] **Step 1: Write the failing test**

`test/widget/core/onboarding/onboarding_view_test.dart` pumps through `_pump(tester, _FakeOnboarding(snapshot))`, which pins the viewport to 390x900 inside itself. These tests need an expanded window, so give it a size and add three one-line helpers.

Change the signature:

```dart
Future<void> _pump(
  WidgetTester tester,
  _FakeOnboarding service, {
  Size size = const Size(390, 900),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
```

and add beside it:

```dart
/// The three steps, each at a stated size. `_atPractice` and `_atStartingPoint`
/// already exist; `_atPriorities` is the same shape with the practice answered.
const _atPriorities = OnboardingSnapshot(
  complete: false,
  nextStep: OnboardingStep.priorities,
  version: 'v-2',
  answers: OnboardingAnswers(
    practiceName: 'Mokoena Tax Studio',
    practiceSize: PracticeSize.smallTeam,
  ),
);

Future<void> _pumpPracticeStep(WidgetTester tester, Size size) =>
    _pump(tester, _FakeOnboarding(_atPractice), size: size);

Future<void> _pumpPrioritiesStep(WidgetTester tester, Size size) =>
    _pump(tester, _FakeOnboarding(_atPriorities), size: size);

Future<void> _pumpStartingPointStep(WidgetTester tester, Size size) =>
    _pump(tester, _FakeOnboarding(_atStartingPoint), size: size);
```

Then append to `main()`:

```dart
  group('wizard fidelity', () {
    testWidgets('the practice step wears the rail at step two', (tester) async {
      await _pumpPracticeStep(tester, const Size(1440, 950));
      expect(find.text('Step 2 of 4'), findsOneWidget);
      expect(find.text('Your practice'), findsOneWidget);
      // Step one is behind us, so its chip carries a tick, not a number.
      expect(
        find.descendant(
          of: find.byKey(MoloWizardRail.chipKey(1)),
          matching: find.text('1'),
        ),
        findsNothing,
      );
    });

    testWidgets('the practice step offers no way back to account creation', (
      tester,
    ) async {
      // Going back would mean un-creating a Firebase account that already
      // exists, so this step deliberately has no back link.
      await _pumpPracticeStep(tester, const Size(1440, 950));
      expect(find.byType(MoloWizardBackButton), findsNothing);
    });

    testWidgets('the size cards are single-choice, with traced glyphs', (
      tester,
    ) async {
      await _pumpPracticeStep(tester, const Size(1440, 950));
      for (final key in const [
        Key('practice_size_solo'),
        Key('practice_size_small'),
        Key('practice_size_growing'),
      ]) {
        final card = tester.widget<MoloChoiceCard>(find.byKey(key));
        expect(card.kind, MoloChoiceKind.single);
        expect(
          find.descendant(of: find.byKey(key), matching: find.byType(MoloIcon)),
          findsWidgets,
        );
      }
      expect(find.byIcon(Icons.person_outline_rounded), findsNothing);
    });

    testWidgets('choosing one size unchooses the others', (tester) async {
      await _pumpPracticeStep(tester, const Size(1440, 950));
      await tester.tap(find.byKey(const Key('practice_size_small')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MoloChoiceCard>(find.byKey(const Key('practice_size_small')))
            .selected,
        isTrue,
      );
      await tester.tap(find.byKey(const Key('practice_size_growing')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MoloChoiceCard>(find.byKey(const Key('practice_size_small')))
            .selected,
        isFalse,
      );
    });

    testWidgets('the region select keeps its label above and its note below', (
      tester,
    ) async {
      await _pumpPracticeStep(tester, const Size(1440, 950));
      final label = tester.getRect(find.text('Primary tax region'));
      final field = tester.getRect(find.byKey(const Key('practice_region_field')));
      final note = tester.getRect(
        find.text('South Africa is available first. More regions will follow.'),
      );
      expect(label.bottom, lessThan(field.top));
      expect(note.top, greaterThan(field.top));
    });

    testWidgets('the goals are multiple-choice and carry no extra checkbox', (
      tester,
    ) async {
      await _pumpPrioritiesStep(tester, const Size(1440, 950));
      expect(find.byType(Checkbox), findsNothing);
      for (final name in const [
        'deadlines',
        'documents',
        'teamwork',
        'visibility',
      ]) {
        expect(
          tester
              .widget<MoloChoiceCard>(find.byKey(Key('priority_$name')))
              .kind,
          MoloChoiceKind.multiple,
        );
      }
    });

    testWidgets('more than one goal can be chosen at once', (tester) async {
      await _pumpPrioritiesStep(tester, const Size(1440, 950));
      await tester.tap(find.byKey(const Key('priority_deadlines')));
      await tester.tap(find.byKey(const Key('priority_documents')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MoloChoiceCard>(find.byKey(const Key('priority_deadlines')))
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<MoloChoiceCard>(find.byKey(const Key('priority_documents')))
            .selected,
        isTrue,
      );
    });

    testWidgets('the goals step can go back, and says so first', (
      tester,
    ) async {
      await _pumpPrioritiesStep(tester, const Size(1440, 950));
      expect(find.byType(MoloWizardBackButton), findsOneWidget);
      expect(
        tester.getRect(find.text('Back')).top,
        lessThan(tester.getRect(find.text('Choose your first win')).top),
      );
    });

    testWidgets('the starting points are single-choice', (tester) async {
      await _pumpStartingPointStep(tester, const Size(1440, 950));
      for (final key in const [
        Key('starting_point_import'),
        Key('starting_point_client'),
        Key('starting_point_sample'),
      ]) {
        expect(
          tester.widget<MoloChoiceCard>(find.byKey(key)).kind,
          MoloChoiceKind.single,
        );
      }
    });

    testWidgets('the last step asks to build the workspace', (tester) async {
      await _pumpStartingPointStep(tester, const Size(1440, 950));
      expect(find.text('Build my workspace'), findsOneWidget);
      expect(find.text('Step 4 of 4'), findsOneWidget);
      expect(
        find.textContaining('Sample data is clearly marked'),
        findsOneWidget,
      );
    });

    testWidgets('each step is quiet until it has its answer', (tester) async {
      await _pumpPrioritiesStep(tester, const Size(1440, 950));
      final button = find.byKey(const Key('complete_registration_preview'));
      expect(
        tester.widget<FilledButton>(button).style
            ?.backgroundColor
            ?.resolve(const <WidgetState>{}),
        MoloColours.border,
      );

      await tester.tap(find.byKey(const Key('priority_deadlines')));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(button).style?.backgroundColor, isNull);
    });

    testWidgets('the tab order follows the order the step is drawn in', (
      tester,
    ) async {
      // Flutter's default traversal reads top to bottom, so asserting the
      // geometry asserts the order. The back link moved above the eyebrow and
      // the footnote below the action, both of which change where the caret
      // goes next.
      await _pumpPrioritiesStep(tester, const Size(1440, 950));
      final tops = <String, double>{
        'back': tester.getRect(find.text('Back')).top,
        'first goal': tester.getRect(find.byKey(const Key('priority_deadlines'))).top,
        'last goal': tester.getRect(find.byKey(const Key('priority_visibility'))).top,
        'continue': tester
            .getRect(find.byKey(const Key('complete_registration_preview')))
            .top,
      };
      final names = tops.keys.toList();
      for (var i = 1; i < names.length; i++) {
        expect(
          tops[names[i]],
          greaterThan(tops[names[i - 1]]!),
          reason: '${names[i]} must come after ${names[i - 1]}',
        );
      }
    });

    testWidgets('pressing it while incomplete still says what is missing', (
      tester,
    ) async {
      // The button looks quiet but is not dead: pressing is how a pointer user
      // finds out, and the inline message is the answer.
      await _pumpPrioritiesStep(tester, const Size(1440, 950));
      await tester.tap(find.byKey(const Key('complete_registration_preview')));
      await tester.pumpAndSettle();
      expect(find.text('Choose at least one priority.'), findsOneWidget);
    });
  });
```

Imports: `molo_wizard_rail.dart`, `molo_wizard_shell.dart`, `molo_choice_card.dart`, `molo_glyphs.dart`, `molo_colours.dart`.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/core/onboarding/onboarding_view_test.dart`
Expected: FAIL — the cards still take `IconData`, the goals still hang a `Checkbox`, and the file does not compile against the card's new API.

- [ ] **Step 3: Rewrite the shell call and the practice step**

In `lib/core/onboarding/ui/views/onboarding_view.dart`, the `MoloWizardShell` call gains the descriptors:

```dart
    return MoloWizardShell(
      pageTitle: localisations.signUpPageTitle,
      progress: WizardProgress(
        stepNumber: _stepNumber(state.step),
        readinessPercent: _readiness(state.step),
        steps: moloWizardSteps(localisations),
        practiceName:
            state.draftPracticeName ?? state.answers.practiceName ?? '',
      ),
      showWorkspaceSummary: true,
      child: switch (state.step) { /* unchanged */ },
    );
```

`_PracticeStepState.build` becomes:

```dart
  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    final state = widget.state;
    return Column(
      key: const Key('registration_practice_step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // No back link: going back would mean un-creating an account that
        // already exists.
        MoloWizardHeadingGroup(
          eyebrow: localisations.registrationStepPractice,
          title: localisations.tellUsAboutPractice,
          blurb: localisations.practiceSubtitle,
        ),
        const SizedBox(height: 28),
        MoloTextField(
          label: localisations.practiceNameLabel,
          fieldKey: const Key('practice_name_field'),
          controller: _controller,
          hintText: localisations.practiceNameHint,
          errorText: _nameInvalid ? localisations.practiceNameRequired : null,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _continue(),
        ),
        const SizedBox(height: 24),
        MoloFieldLabel(label: localisations.practiceSizeQuestion),
        const SizedBox(height: 10),
        for (final choice in [
          (
            PracticeSize.solo,
            'practice_size_solo',
            MoloGlyphs.practiceSolo,
            localisations.practiceSizeSolo,
            localisations.practiceSizeSoloBody,
          ),
          (
            PracticeSize.smallTeam,
            'practice_size_small',
            MoloGlyphs.practiceSmallTeam,
            localisations.practiceSizeSmall,
            localisations.practiceSizeSmallBody,
          ),
          (
            PracticeSize.growingTeam,
            'practice_size_growing',
            MoloGlyphs.practiceGrowing,
            localisations.practiceSizeGrowing,
            localisations.practiceSizeGrowingBody,
          ),
        ]) ...[
          MoloChoiceCard(
            key: Key(choice.$2),
            glyph: choice.$3,
            title: choice.$4,
            description: choice.$5,
            selected: _size == choice.$1,
            onTap: () => setState(() => _size = choice.$1),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 14),
        MoloFieldLabel(label: localisations.primaryTaxRegionLabel),
        const SizedBox(height: MoloFieldLabel.gap),
        DropdownButtonFormField<String>(
          key: const Key('practice_region_field'),
          initialValue: 'ZA',
          items: [
            DropdownMenuItem(
              value: 'ZA',
              child: Text(localisations.southAfrica),
            ),
          ],
          onChanged: (_) {},
        ),
        const SizedBox(height: MoloFieldLabel.gap),
        Text(
          localisations.primaryTaxRegionHelper,
          style: const TextStyle(
            fontSize: 12,
            letterSpacing: 0,
            height: MoloTypography.normalLineHeight,
            color: MoloColours.secondaryText,
          ),
        ),
        const SizedBox(height: 28),
        if (state.failure != null) ...[
          _OnboardingFailureNotice(failure: state.failure!),
          const SizedBox(height: MoloSpacing.md),
        ],
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => MoloWizardPrimaryAction(
            buttonKey: const Key('registration_practice_continue'),
            label: localisations.continueLabel,
            complete: _controller.text.trim().length >= 2,
            outstanding: localisations.practiceNameRequired,
            busy: state.busy,
            onPressed: _continue,
          ),
        ),
        const SizedBox(height: 12),
        MoloStepFootnote(label: localisations.wizardFootnotePractice),
      ],
    );
  }
```

The `labelText`/`helperText` come off the `DropdownButtonFormField`'s `InputDecoration`, because `MoloFieldLabel` above and the 12px line below are now doing that work; drop the `decoration:` argument entirely so the field takes the theme's.

- [ ] **Step 4: Rewrite the goals step**

Replace the `choices` list's icons with the glyphs, drop the `trailing:` `Checkbox`, and pass `kind`:

```dart
    final choices = [
      (
        OnboardingPriority.deadlines,
        MoloGlyphs.goalDeadlines,
        localisations.priorityDeadlines,
        localisations.priorityDeadlinesBody,
      ),
      (
        OnboardingPriority.documents,
        MoloGlyphs.goalDocuments,
        localisations.priorityDocuments,
        localisations.priorityDocumentsBody,
      ),
      (
        OnboardingPriority.teamwork,
        MoloGlyphs.goalTeamwork,
        localisations.priorityTeamwork,
        localisations.priorityTeamworkBody,
      ),
      (
        OnboardingPriority.visibility,
        MoloGlyphs.goalVisibility,
        localisations.priorityVisibility,
        localisations.priorityVisibilityBody,
      ),
    ];
```

and its column:

```dart
    return Column(
      key: const Key('registration_priorities_step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MoloWizardHeadingGroup(
          eyebrow: localisations.registrationStepPriorities,
          title: localisations.whatShouldMoloHelpWith,
          blurb: localisations.prioritiesSubtitle,
          onBack: ref.read(onboardingViewModelProvider.notifier).goBack,
        ),
        const SizedBox(height: 28),
        for (final choice in choices) ...[
          MoloChoiceCard(
            key: Key('priority_${choice.$1.name}'),
            glyph: choice.$2,
            title: choice.$3,
            description: choice.$4,
            kind: MoloChoiceKind.multiple,
            selected: _chosen.contains(choice.$1),
            onTap: () => _toggle(choice.$1),
          ),
          const SizedBox(height: 10),
        ],
        if (_invalid) ...[
          const SizedBox(height: MoloSpacing.xs),
          Text(
            localisations.choosePriorityRequired,
            style: const TextStyle(fontSize: 12, color: MoloColours.error),
          ),
        ],
        const SizedBox(height: 18),
        if (state.failure != null) ...[
          _OnboardingFailureNotice(failure: state.failure!),
          const SizedBox(height: MoloSpacing.md),
        ],
        MoloWizardPrimaryAction(
          buttonKey: const Key('complete_registration_preview'),
          label: localisations.continueLabel,
          complete: _chosen.isNotEmpty,
          outstanding: localisations.choosePriorityRequired,
          busy: state.busy,
          onPressed: _continue,
        ),
        const SizedBox(height: 12),
        MoloStepFootnote(label: localisations.wizardFootnoteGoals),
      ],
    );
```

- [ ] **Step 5: Rewrite the starting-point step**

```dart
    return Column(
      key: const Key('registration_starting_point_step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MoloWizardHeadingGroup(
          eyebrow: localisations.registrationStepStartingPoint,
          title: localisations.putSomethingUsefulInside,
          blurb: localisations.startingPointSubtitle,
          onBack: ref.read(onboardingViewModelProvider.notifier).goBack,
        ),
        const SizedBox(height: 28),
        for (final choice in [
          (
            WorkspaceStartingPoint.importClients,
            'starting_point_import',
            MoloGlyphs.startImport,
            localisations.startingPointImport,
            localisations.startingPointImportBody,
          ),
          (
            WorkspaceStartingPoint.addFirstClient,
            'starting_point_client',
            MoloGlyphs.startFirstClient,
            localisations.startingPointClient,
            localisations.startingPointClientBody,
          ),
          (
            WorkspaceStartingPoint.sampleWorkspace,
            'starting_point_sample',
            MoloGlyphs.startSample,
            localisations.startingPointSample,
            localisations.startingPointSampleBody,
          ),
        ]) ...[
          MoloChoiceCard(
            key: Key(choice.$2),
            glyph: choice.$3,
            title: choice.$4,
            description: choice.$5,
            selected: _chosen == choice.$1,
            onTap: () => setState(() {
              _chosen = choice.$1;
              _invalid = false;
            }),
          ),
          const SizedBox(height: 10),
        ],
        if (_invalid) ...[
          const SizedBox(height: MoloSpacing.xs),
          Text(
            localisations.chooseStartingPointRequired,
            style: const TextStyle(fontSize: 12, color: MoloColours.error),
          ),
        ],
        const SizedBox(height: 18),
        if (state.failure != null) ...[
          _OnboardingFailureNotice(failure: state.failure!),
          const SizedBox(height: MoloSpacing.md),
        ],
        MoloWizardPrimaryAction(
          buttonKey: const Key('finish_registration_preview'),
          label: localisations.buildMyWorkspace,
          complete: _chosen != null,
          outstanding: localisations.chooseStartingPointRequired,
          busy: state.busy,
          onPressed: () => unawaited(_finish()),
        ),
        const SizedBox(height: 12),
        MoloStepFootnote(label: localisations.wizardFootnoteStart),
      ],
    );
```

`_finish` keeps its body exactly, including saving before founding and skipping the save on a retry from `readyToComplete`.

- [ ] **Step 6: Run the step's tests**

Run: `flutter test test/widget/core/onboarding/onboarding_view_test.dart`
Expected: PASS.

- [ ] **Step 7: Analyse and format**

Run: `flutter analyze && dart format .`
Expected: no issues. The whole tree compiles again from this commit onward.

- [ ] **Step 8: Commit**

```bash
git add lib/core/onboarding/ui/views/onboarding_view.dart test/widget/core/onboarding/onboarding_view_test.dart
git commit -m "feat: re-trace the practice, goals and starting-point steps"
```

---

### Task 10: Move the remaining tests, verify in a browser, finish the visual system

**Files:**
- Modify: `test/widget/app/signup_journey_test.dart`
- Modify: `test/widget/core/auth/sign_in_view_test.dart` (the pane-edge test's expected width)
- Modify: `docs/app_design/visual_design.md` (section 5's wizard and onboarding paragraphs)

**Interfaces:**
- Consumes: everything the previous nine tasks produced.
- Produces: a green suite and a design document that describes what ships.

- [ ] **Step 1: Run the whole suite and read every failure**

Run: `flutter test`

Expected failures, and what each one means:
1. Anything asserting `isSelected` on a choice card — the card now reports `hasCheckedState`/`isChecked`, and `inMutuallyExclusiveGroup` for a single choice. Update the matcher, not the widget.
2. Anything finding a Material `Checkbox` in the wizard — there is exactly one control per answer now. Target `MoloChoiceCard.markKey` or the card's key.
3. Anything finding a Material icon by `Icons.…` in the wizard — the ten glyphs replaced them. Target `MoloIcon`, or the card's key.
4. Anything asserting the supporting pane is 300–360 wide — the rail is 38% capped at 460. At 1280 that is 460, not 360.
5. `sign_in_view_test.dart`'s `the two wizard routes keep a stable supporting pane edge` — still valid in intent; both routes now measure 460 at 1280. It should keep passing. If it fails, the two routes disagree, which is a real bug in Task 4 or 9, not a test to update.

- [ ] **Step 2: Fix each failure at the test, not the widget**

Every expected failure above is a selector or a number that moved by design. If a failure is not on that list, stop and diagnose it: it is a regression.

- [ ] **Step 3: Analyse, format, and confirm no duplicate copy**

```bash
flutter analyze
dart format --set-exit-if-changed .
python3 -c "import re,collections,io;[print(p,{k:c for k,c in collections.Counter(re.findall(r'^  \"(@?[A-Za-z0-9_]+)\":',io.open(p).read(),re.M)).items() if c>1} or 'clean') for p in ['lib/app/localisation/l10n/app_en.arb','lib/app/localisation/l10n/app_en_ZA.arb']]"
```

Expected: clean, no diff, both locales clean.

- [ ] **Step 4: Verify in a real browser**

Restart the dev server rather than reloading the tab — `flutter web-server` does not hot-reload. Use the `molo-app` configuration in `.claude/launch.json` (port 4300). The wizard is behind account creation, so reach it either by creating an account or by signing in with a session whose setup is unfinished.

Check, at each width:
- **1440 x 950:** the rail is 460 wide with all four steps listed; step one's chip carries a tick once you are on step two; the workspace card names the practice as you type it; the readiness bar animates rather than jumping; the content column is 452 and top-aligned 56 below the header.
- **800 x 900:** no rail; the compact progress bar and the practice chip appear in its place.
- **390 x 844:** the same, and every step scrolls without clipping. Check the option cards in particular: three lines of title-plus-description inside a 16-radius card is the tightest thing on this screen.
- **200% text scale at 390:** set `document.documentElement.style.fontSize = '32px'`. Nothing may overlap. The header row and the option cards are where the sign-in half found its two defects, so look there first.

Then walk the whole journey once: create an account, name a practice, choose a size, choose two goals, choose a starting point, and arrive at the workspace. The answers must survive a page reload mid-wizard, which is the point of the two-route split.

- [ ] **Step 5: Screenshot each width and the walked journey**

Attach them to the review, so the fidelity claim is visible rather than asserted.

- [ ] **Step 6: Finish the visual system's section 5**

In `docs/app_design/visual_design.md`, section 5:
- Delete the note added by the sign-in half saying the wizard paragraphs still describe the previous composition. Both halves ship now.
- Replace the **Registration preview** paragraphs: the quiet workspace context panel becomes the four-step rail, and the sentence forbidding it from repeating the form's choices is now satisfied by construction — the rail names steps, the form names tasks, and the two use different words on purpose.
- Delete the sentence about a completion screen stating that no data was saved. There is no completion screen: founding the practice enters the workspace.
- Record the wizard's deviations: the footnote and password-hint colour at 12px, the primary action that looks incomplete but stays pressable, and the compact progress bar the baseline does not draw.
- Keep the paragraph on the fixed supporting-pane edge as the sign-in half rewrote it: the invariant is between `/sign-up` and `/onboarding`, and sign-in is deliberately wider.

- [ ] **Step 7: Commit**

```bash
git add test docs/app_design/visual_design.md
git commit -m "test: move the wizard's tests onto the re-traced steps"
```

- [ ] **Step 8: Open the pull request**

Only if the user has asked for it. Pushing is an outward-facing action; the sign-in half deliberately stopped short of it.

```bash
git push -u origin auth-sign-in-design-fidelity
gh pr create --title "Re-trace sign-in and the signup wizard from the design baseline" --body "$(cat <<'BODY'
## Summary
Sign-in and the four-step signup wizard are re-traced from the design baseline. They collect exactly what they collected before: `OnboardingAnswers`, its three enums and every wire value are untouched. The only new behaviour is the baseline's "Keep me signed in on this device", which chooses Firebase session persistence on Web.

## Deviations from the baseline
- 12px text moves off `#9A858D` (3.30:1) to `secondaryText` (5.94:1) everywhere it appears: the sign-in kicker, the divider label, both legal footers, the step footnotes and the password hint. WCAG 1.4.3.
- Field, checkbox and choice-mark outlines stay `controlBorder`; the switch pill keeps it in its hovered state too.
- The disabled provider buttons keep the quiet border, which 1.4.11 exempts.
- A step's primary action takes the baseline's incomplete appearance but stays pressable, because pressing is what reveals the inline messages.
- Compact windows keep a progress bar and practice chip the baseline does not draw.
- The hero photograph ships as WebP at 63 KB rather than the baseline's 1.85 MB PNG.

## Verification
- `flutter analyze`, `dart format`, `flutter test` all clean.
- Both screens checked in a browser at 390, 800 and 1440 wide, and at 200% text scale.
- The whole signup journey walked end to end, including a reload mid-wizard.

Spec: `docs/plans/2026-08-21-auth-onboarding-design-fidelity-design.md`
Plans: `docs/plans/2026-08-21-auth-sign-in-design-fidelity-plan.md`, `docs/plans/2026-08-21-auth-wizard-design-fidelity-plan.md`

🤖 Generated with [Claude Code](https://claude.com/claude-code)
BODY
)"
```

---

## Order note

Tasks 2 and 5 delete and rewrite things that Tasks 8 and 9 consume, so the tree does not compile between Task 2's commit and Task 9's. Each task's own tests still run, because they exercise the new components directly. If every commit must build, land Tasks 2 to 9 as one commit; otherwise take them in order and treat `flutter analyze` as meaningful again only from Task 9 step 7.
