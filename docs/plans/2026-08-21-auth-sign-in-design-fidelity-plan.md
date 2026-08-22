# Sign-in Design Fidelity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Re-trace the sign-in screen from the design baseline, collecting exactly the data it collects today, and wire the baseline's "Keep me signed in on this device" to Firebase session persistence on Web.

**Architecture:** The screen becomes a two-part row: a photographic hero pane at 44% and a 384-wide form column. Every reusable piece the baseline draws twice (the brand lockup, the labelled field, the switch pill, the checkbox row) becomes a design-system component rather than a private widget, so the wizard half consumes them instead of repeating them. Session persistence travels as a `persistSession` argument from the view down to `FirebaseAuthService`, which is the only place that knows Firebase exists.

**Tech Stack:** Flutter Web/Android/iOS, Riverpod 3 (generated providers), `go_router` typed routes, `firebase_auth` 6.5.7, `flutter_test`.

**Spec:** [docs/plans/2026-08-21-auth-onboarding-design-fidelity-design.md](2026-08-21-auth-onboarding-design-fidelity-design.md) — sections 1 to 4, 7 and 8. Sections 5, 6 and the parts of 7 that only the wizard consumes (`pulseOnDark`, the ten option glyphs, the choice card) belong to the second half and are **out of scope here**.

## Global Constraints

- Riverpod 3 only. Generated providers, `Notifier`/`AsyncNotifier`, immutable state. No other state system.
- Controllers, focus nodes and animation controllers stay local to the widget; Riverpod owns shared and asynchronous state.
- No feature may import Firebase Auth outside `lib/core/auth/data/services/`. `firebase_auth` appears in `firebase_auth_service.dart` and nowhere else this plan touches.
- Every user-facing string is localised, in **both** `lib/app/localisation/l10n/app_en.arb` and `app_en_ZA.arb`. `l10n.yaml` sets `use-escaping: true`, so a straight apostrophe must be doubled (`Let''s`); a curly `’` is written as-is.
- Localisations are generated, never hand-edited: after an ARB change run `flutter gen-l10n`.
- Riverpod and router code is generated, never hand-edited: after a provider change run `dart run build_runner build --delete-conflicting-outputs`.
- Branch on available layout space and platform capability, never on device labels or orientation. `moloWindowClassFor(constraints.maxWidth)` is the only layout branch.
- Every screen works on Web, Android and iOS from its first implementation, at compact, medium and expanded widths and at 200% text scale.
- Deprecated APIs are CI failures. Never introduce one.
- Design values are traced from the baseline exactly, **except** where this plan states a deviation and its reason. Every deviation carries a code comment naming the gate it satisfies.
- All work happens in `src/molobuddy_app`. Every `flutter`/`dart` command in this plan runs from that directory.
- Commands: `flutter analyze`, `dart format .`, `flutter test`.

## Deviations from the baseline this plan settles

These are decisions, not drift. Each one carries a comment in the code.

1. **12px text at `#9A858D` is replaced by `secondaryText`.** The baseline paints the time-of-day kicker, the "or" divider label and the legal footer in `#9A858D`, which is **3.30:1** on `warmCanvas`. Twelve-pixel text is not large text, so WCAG 1.4.3 requires 4.5:1. `secondaryText` `#685E68` measures **5.94:1** and is already what the application uses for these roles. `controlBorder` keeps its outline role only. *(This is a gate failure the design document did not catch; it is recorded here rather than copied.)*
2. **Field and unchecked-box outlines stay `controlBorder`**, per spec section 7.2: the baseline's `#E4D5D8` is 1.42:1 where 1.4.11 requires 3:1.
3. **The two provider buttons keep the baseline's quiet `border` outline.** Both are permanently disabled, and 1.4.11 exempts an inactive control. Their outline is the only place `border` survives on a control in this screen.
4. **The hero pane is 44% and the wizard rail is not.** The baseline gives sign-in `flex 0 0 44%` and the signup aside `flex 0 0 38%` capped at 460, so the panes genuinely differ. Spec section 3's fixed-edge requirement governs `/sign-up` ↔ `/onboarding`, which share one shell; it does not reach across a change of pane. Task 12 retargets the existing test accordingly.
5. **The hero ships as WebP.** Spec section 7.6 requires under 300 KB. Measured on the source: JPEG q80 is 193 KB, WebP q85 is **63 KB** at full 1024x1536. Flutter decodes WebP on all three platforms.
6. **`moloPlumHover` carries its label at 13.37:1**, not the "above 15:1" the spec estimated. Both are far above AA; the measured figure is what the token comment records.

## File Structure

**Created**

| File | Responsibility |
|---|---|
| `lib/app/design_system/components/molo_brand_lockup.dart` | The mark-plus-wordmark lockup, in the two sizes the design draws |
| `lib/app/design_system/components/molo_text_field.dart` | A field with a 13px label above it and an optional trailing label-row action |
| `lib/app/design_system/components/molo_pill_button.dart` | The small outlined pill each auth screen offers the other one through |
| `lib/app/design_system/components/molo_check_row.dart` | A square checkbox and a label, the whole row being the control |
| `lib/core/auth/ui/views/sign_in/sign_in_greeting.dart` | The baseline's time-of-day rule as a pure function |
| `lib/core/auth/ui/views/sign_in/sign_in_hero_pane.dart` | The photographic hero pane |
| `assets/brand/signin-portrait.webp` | The hero photograph, re-encoded |
| `test/unit/app/molo_tokens_test.dart` | Radii values and the contrast evidence behind each new colour |
| `test/unit/core/auth/sign_in_greeting_test.dart` | The clock rule |
| `test/widget/app/molo_brand_lockup_test.dart` | Lockup geometry |
| `test/widget/app/molo_text_field_test.dart` | Field geometry, label treatment, one accessible name |
| `test/widget/app/molo_pill_button_test.dart` | Pill geometry and states |
| `test/widget/app/molo_check_row_test.dart` | Box geometry, toggle behaviour, accessible name |
| `test/widget/core/auth/sign_in_fidelity_test.dart` | Traced measurements of the whole screen |

**Modified**

| File | Change |
|---|---|
| `lib/app/design_system/spacing/molo_spacing.dart` | Four named radii join the existing two |
| `lib/app/design_system/colour/molo_colours.dart` | `pulseBorder`, `moloPlumHover` |
| `lib/app/design_system/icons/molo_glyphs.dart` | `eye`, `tick` |
| `lib/app/design_system/molo_theme.dart` | Field geometry, primary button 52/15 |
| `lib/app/adaptive/molo_app_shell.dart` | The sidebar's private lockup becomes the shared one |
| `lib/app/adaptive/auth_shell_layout.dart` | A hero width alongside the supporting-pane width |
| `lib/core/auth/data/services/auth_service.dart` and the three implementations | `persistSession` |
| `lib/core/auth/data/repositories/auth_repository.dart`, `default_auth_repository.dart` | `persistSession` |
| `lib/core/auth/ui/view_models/auth_view_model.dart` | `persistSession` |
| `lib/core/auth/auth_providers.dart` | `sessionPersistenceChoosable` |
| `lib/core/auth/ui/views/sign_in/sign_in_view.dart` | Re-traced |
| `lib/app/localisation/l10n/app_en.arb`, `app_en_ZA.arb` | New copy in, retired copy out |
| `pubspec.yaml` | `assets/brand/` registered |
| `test/widget/core/auth/sign_in_view_test.dart` | Selectors move; the pane-edge test retargets |
| `docs/app_design/visual_design.md` | Section 5's sign-in paragraphs |

---

### Task 1: Radii and colour tokens

**Files:**
- Modify: `lib/app/design_system/spacing/molo_spacing.dart`
- Modify: `lib/app/design_system/colour/molo_colours.dart`
- Test: `test/unit/app/molo_tokens_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `MoloSpacing.pillRadius = 12.0`, `MoloSpacing.primaryActionRadius = 15.0`, `MoloSpacing.choiceCardRadius = 16.0`, `MoloSpacing.railCardRadius = 18.0`; `MoloColours.pulseBorder`, `MoloColours.moloPlumHover`.

- [ ] **Step 1: Write the failing test**

Create `test/unit/app/molo_tokens_test.dart`:

```dart
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';

/// Contrast ratio as WCAG defines it, so a colour's evidence is checked rather
/// than asserted in a comment.
double _contrast(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('radii', () {
    test('the design draws six, each named', () {
      expect(MoloSpacing.pillRadius, 12.0);
      expect(MoloSpacing.controlRadius, 14.0);
      expect(MoloSpacing.primaryActionRadius, 15.0);
      expect(MoloSpacing.choiceCardRadius, 16.0);
      expect(MoloSpacing.railCardRadius, 18.0);
      expect(MoloSpacing.cardRadius, 24.0);
    });
  });

  group('new colours', () {
    test('a hovered plum action still carries its label', () {
      expect(
        _contrast(MoloColours.moloPlumHover, MoloColours.warmCanvas),
        greaterThan(4.5),
      );
    });

    test('the hover outline never has to carry identity on its own', () {
      // pulseBorder is 1.72:1 on white, which is why it may only replace an
      // outline that already exists in the resting state. Its resting partner
      // is what has to clear 3:1.
      expect(
        _contrast(MoloColours.controlBorder, MoloColours.surface),
        greaterThan(3.0),
      );
      expect(
        _contrast(MoloColours.pulseBorder, MoloColours.surface),
        lessThan(3.0),
      );
    });

    test('the values are the traced ones', () {
      expect(MoloColours.pulseBorder, const Color(0xFFE9B9C4));
      expect(MoloColours.moloPlumHover, const Color(0xFF3A2440));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/app/molo_tokens_test.dart`
Expected: FAIL — `pillRadius` and `pulseBorder` are not defined on their classes.

- [ ] **Step 3: Write minimal implementation**

Replace the two radius lines at the end of `lib/app/design_system/spacing/molo_spacing.dart` with:

```dart
  // The design draws six corner radii and no others. Naming them keeps a
  // literal from appearing at a call site, where it reads as a choice rather
  // than as the design's number.

  /// The small switch pill each authentication screen offers the other through.
  static const pillRadius = 12.0;

  /// Fields and secondary buttons.
  static const controlRadius = 14.0;

  /// A primary action, which the design draws one unit rounder than a field.
  static const primaryActionRadius = 15.0;

  /// A selectable option card in the signup wizard.
  static const choiceCardRadius = 16.0;

  /// The workspace card inside the wizard rail.
  static const railCardRadius = 18.0;

  /// A surface card in the workspace.
  static const cardRadius = 24.0;
```

Add to `lib/app/design_system/colour/molo_colours.dart`, after `border`:

```dart
  /// Hover outline for a pill on a tinted surface.
  ///
  /// 1.72:1 on white, so it may only ever replace an outline that already
  /// exists: the resting `border` or `controlBorder` is what identifies the
  /// control, and this is the hover decoration over it.
  static const pulseBorder = Color(0xFFE9B9C4);

  /// Hover fill for a plum primary action.
  ///
  /// Fill only. A [warmCanvas] label on it measures 13.37:1, so the hover
  /// state never costs the label its contrast.
  static const moloPlumHover = Color(0xFF3A2440);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/app/molo_tokens_test.dart`
Expected: PASS, 4 tests.

- [ ] **Step 5: Confirm nothing else moved**

Run: `flutter analyze && flutter test`
Expected: no analyser issues, whole suite green. `cardRadius` and `controlRadius` keep their values, so no existing measurement changes.

- [ ] **Step 6: Commit**

```bash
git add lib/app/design_system/spacing/molo_spacing.dart lib/app/design_system/colour/molo_colours.dart test/unit/app/molo_tokens_test.dart
git commit -m "feat: name the design's six radii and add the two hover colours"
```

---

### Task 2: The eye and tick glyphs

**Files:**
- Modify: `lib/app/design_system/icons/molo_glyphs.dart`
- Test: `test/widget/app/molo_glyph_test.dart` (create if absent; append if it exists)

**Interfaces:**
- Consumes: `MoloGlyph`, `MoloGlyphs.viewBox`, `MoloIcon` — all existing.
- Produces: `MoloGlyphs.eye` (18-unit box) and `MoloGlyphs.tick` (14-unit box), both `MoloGlyph`.

The traced sources, from the baseline's sign-in markup:

```
eye:  <svg viewBox="0 0 18 18" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
        <path d="M1.6 9S4.4 4.4 9 4.4 16.4 9 16.4 9 13.6 13.6 9 13.6 1.6 9 1.6 9z" />
        <circle cx="9" cy="9" r="2.1" />
      </svg>
tick: <svg viewBox="0 0 14 14" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M3 7.4 5.6 10 11 4.4" />
      </svg>
```

The eye's `S` commands are smooth cubics whose first control point mirrors the previous curve's second. Written out, the four segments are the ones in the implementation below.

- [ ] **Step 1: Write the failing test**

Create `test/widget/app/molo_glyph_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/icons/molo_glyphs.dart';

void main() {
  test('the eye is drawn in the design 18-unit box', () {
    expect(MoloGlyphs.eye.viewBox, 18.0);
    expect(MoloGlyphs.eye.cap, StrokeCap.round);
    expect(MoloGlyphs.eye.join, StrokeJoin.round);
  });

  test('the eye closes around its own centre', () {
    final bounds = MoloGlyphs.eye.buildPath().getBounds();
    // The lid spans 1.6 to 16.4 and the pupil sits on the centre line, so the
    // path has to reach both edges and stay inside the box.
    expect(bounds.left, closeTo(1.6, 0.2));
    expect(bounds.right, closeTo(16.4, 0.2));
    expect(bounds.center.dy, closeTo(9, 0.2));
  });

  test('the tick is drawn in the 14-unit box the baseline uses for it', () {
    expect(MoloGlyphs.tick.viewBox, 14.0);
    expect(MoloGlyphs.tick.cap, StrokeCap.round);
    final bounds = MoloGlyphs.tick.buildPath().getBounds();
    expect(bounds.left, closeTo(3, 0.1));
    expect(bounds.right, closeTo(11, 0.1));
  });

  testWidgets('a glyph paints at the size it is given', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MoloIcon(
            MoloGlyphs.eye,
            size: 18,
            color: MoloColours.secondaryText,
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(MoloIcon)), const Size(18, 18));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/app/molo_glyph_test.dart`
Expected: FAIL — `eye` and `tick` are not defined on `MoloGlyphs`.

- [ ] **Step 3: Write minimal implementation**

Add to `lib/app/design_system/icons/molo_glyphs.dart`, before the closing brace of `MoloGlyphs`:

```dart
  /// The password field's reveal toggle.
  ///
  /// The baseline draws one eye for both states and changes only the control's
  /// title, so there is no crossed-out variant to trace: what the state is, is
  /// carried by the accessible name.
  static final eye = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    buildPath: () => Path()
      // The lid, as four cubics. The source writes it with smooth-curve
      // shorthand, whose first control point mirrors the previous segment's
      // second; these are those mirrors written out.
      ..moveTo(1.6, 9)
      ..cubicTo(1.6, 9, 4.4, 4.4, 9, 4.4)
      ..cubicTo(13.6, 4.4, 16.4, 9, 16.4, 9)
      ..cubicTo(16.4, 9, 13.6, 13.6, 9, 13.6)
      ..cubicTo(4.4, 13.6, 1.6, 9, 1.6, 9)
      ..close()
      ..addOval(Rect.fromCircle(center: const Offset(9, 9), radius: 2.1)),
  );

  /// The mark inside a checked box, drawn in the 14-unit box the baseline uses
  /// for it rather than the usual 18.
  static final tick = MoloGlyph(
    cap: StrokeCap.round,
    join: StrokeJoin.round,
    viewBox: 14,
    buildPath: () => Path()
      ..moveTo(3, 7.4)
      ..lineTo(5.6, 10)
      ..lineTo(11, 4.4),
  );
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget/app/molo_glyph_test.dart`
Expected: PASS, 4 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/app/design_system/icons/molo_glyphs.dart test/widget/app/molo_glyph_test.dart
git commit -m "feat: trace the eye and tick glyphs from the baseline"
```

---

### Task 3: The shared brand lockup

**Files:**
- Create: `lib/app/design_system/components/molo_brand_lockup.dart`
- Modify: `lib/app/adaptive/molo_app_shell.dart` (replace the body of `_MoloSidebarBrand`)
- Test: `test/widget/app/molo_brand_lockup_test.dart`

**Interfaces:**
- Consumes: `MoloColours`, `MoloTypography.normalLineHeight`.
- Produces:
  ```dart
  class MoloBrandLockup extends StatelessWidget {
    const MoloBrandLockup({
      this.onDark = false,
      this.compact = false,
      this.labelled = true,
      this.markKey,
      super.key,
    });
    final bool onDark;    // surface-coloured wordmark instead of plum
    final bool compact;   // 22/8/9/18 instead of 26/9/10/21
    final bool labelled;  // false paints the mark alone, as the rail does
    final Key? markKey;   // so MoloSidebar.brandMarkKey survives
  }
  ```

The design draws the lockup at two sizes and no others:

| | mark | mark radius | gap | wordmark |
|---|---|---|---|---|
| default | 26 | 9 | 10 | 21px, tracking -0.02em |
| compact | 22 | 8 | 9 | 18px, tracking -0.02em |

- [ ] **Step 1: Write the failing test**

Create `test/widget/app/molo_brand_lockup_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_brand_lockup.dart';

void main() {
  Widget host(Widget child) =>
      MaterialApp(home: Scaffold(body: Row(children: [child])));

  const markKey = Key('mark');

  testWidgets('the full lockup is 26 square beside a 21px wordmark', (
    tester,
  ) async {
    await tester.pumpWidget(host(const MoloBrandLockup(markKey: markKey)));
    expect(tester.getSize(find.byKey(markKey)), const Size(26, 26));
    expect(tester.widget<Text>(find.text('molo')).style?.fontSize, 21);
  });

  testWidgets('the compact lockup is 22 square beside an 18px wordmark', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const MoloBrandLockup(compact: true, markKey: markKey)),
    );
    expect(tester.getSize(find.byKey(markKey)), const Size(22, 22));
    expect(tester.widget<Text>(find.text('molo')).style?.fontSize, 18);
  });

  testWidgets('the wordmark tracks -0.02em at its own size', (tester) async {
    await tester.pumpWidget(host(const MoloBrandLockup()));
    expect(
      tester.widget<Text>(find.text('molo')).style?.letterSpacing,
      closeTo(-0.42, 0.001),
    );
  });

  testWidgets('unlabelled paints the mark alone', (tester) async {
    await tester.pumpWidget(
      host(const MoloBrandLockup(labelled: false, markKey: markKey)),
    );
    expect(find.byKey(markKey), findsOneWidget);
    expect(find.text('molo'), findsNothing);
  });

  testWidgets('on dark the wordmark takes the surface colour', (tester) async {
    await tester.pumpWidget(host(const MoloBrandLockup(onDark: true)));
    expect(
      tester.widget<Text>(find.text('molo')).style?.color,
      MoloColours.surface,
    );
  });

  testWidgets('the lockup announces once, as the brand', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(host(const MoloBrandLockup()));
    expect(find.bySemanticsLabel('Molo'), findsOneWidget);
    semantics.dispose();
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/app/molo_brand_lockup_test.dart`
Expected: FAIL — `molo_brand_lockup.dart` does not exist.

- [ ] **Step 3: Write minimal implementation**

Create `lib/app/design_system/components/molo_brand_lockup.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/typography/molo_typography.dart';

/// The Molo mark, and the wordmark beside it where there is room.
///
/// The design draws this lockup at exactly two sizes: 26/21 in the sidebar and
/// the sign-in hero, 22/18 in a compact header. It is one component because
/// the mark's radius, the gap and the wordmark's size move together, and a
/// caller that only knew one of the three would drift.
class MoloBrandLockup extends StatelessWidget {
  const MoloBrandLockup({
    this.onDark = false,
    this.compact = false,
    this.labelled = true,
    this.markKey,
    super.key,
  });

  /// Paints the wordmark on a dark ground. The mark is pulse either way.
  final bool onDark;

  /// The smaller of the design's two sizes.
  final bool compact;

  /// Whether the wordmark appears. The navigation rail paints the mark alone.
  final bool labelled;

  /// Lets a caller keep a measurement key on the mark itself.
  final Key? markKey;

  double get _markSize => compact ? 22 : 26;
  double get _markRadius => compact ? 8 : 9;
  double get _gap => compact ? 9 : 10;
  double get _wordmarkSize => compact ? 18 : 21;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Molo',
      header: true,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              key: markKey,
              width: _markSize,
              height: _markSize,
              decoration: BoxDecoration(
                color: MoloColours.moloPulse,
                borderRadius: BorderRadius.circular(_markRadius),
              ),
            ),
            if (labelled) ...[
              SizedBox(width: _gap),
              Text(
                'molo',
                style: TextStyle(
                  fontSize: _wordmarkSize,
                  fontWeight: FontWeight.w500,
                  letterSpacing: MoloTypography.display(_wordmarkSize),
                  // Material's body leading makes this line box taller than
                  // the design's, which pushes the mark off centre and shifts
                  // everything beneath the lockup down.
                  height: MoloTypography.normalLineHeight,
                  color: onDark ? MoloColours.surface : MoloColours.moloPlum,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget/app/molo_brand_lockup_test.dart`
Expected: PASS, 6 tests.

- [ ] **Step 5: Point the sidebar at the shared lockup**

In `lib/app/adaptive/molo_app_shell.dart`, replace the whole `Row` inside `_MoloSidebarBrand.build` with the shared component, keeping the padding and the alignment the sidebar owns:

```dart
  @override
  Widget build(BuildContext context) {
    return Padding(
      // The design pads the lockup inside the frame and separates it from the
      // first row by 18.
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 18),
      child: Row(
        mainAxisAlignment:
            labelled ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          MoloBrandLockup(
            onDark: true,
            labelled: labelled,
            markKey: MoloSidebar.brandMarkKey,
          ),
        ],
      ),
    );
  }
```

Add the import `package:molobuddy_app/app/design_system/components/molo_brand_lockup.dart`. Remove the `MoloTypography` import only if nothing else in the file uses it — check with `grep -n MoloTypography lib/app/adaptive/molo_app_shell.dart` before removing.

- [ ] **Step 6: Run the sidebar's own measurements**

Run: `flutter test test/widget/app/molo_sidebar_fidelity_test.dart test/widget/app/molo_sidebar_typography_test.dart test/widget/app/molo_app_shell_test.dart`
Expected: PASS. The 26-square mark, the 21px wordmark and the mark-alone rail are all already asserted there, so this is the safety net for the extraction.

- [ ] **Step 7: Commit**

```bash
git add lib/app/design_system/components/molo_brand_lockup.dart lib/app/adaptive/molo_app_shell.dart test/widget/app/molo_brand_lockup_test.dart
git commit -m "refactor: share the brand lockup between the sidebar and sign-in"
```

---

### Task 4: The hero photograph

**Files:**
- Create: `assets/brand/signin-portrait.webp`
- Modify: `pubspec.yaml`

**Interfaces:**
- Consumes: nothing.
- Produces: the asset path `assets/brand/signin-portrait.webp`, loadable as `AssetImage('assets/brand/signin-portrait.webp')`.

- [ ] **Step 1: Re-encode the source**

The baseline's `signin-portrait.png` is 1.85 MB at 1024x1536, which spec section 7.6 rules out on a sign-in page. Re-encode at full resolution; the pane is at most 44% of an extra-large window, so 1024 wide still leaves headroom on a high-density display.

Run from `src/molobuddy_app`:

```bash
cwebp -q 85 "../../docs/product/Design baseline and scope clarification/assets/signin-portrait.png" -o assets/brand/signin-portrait.webp
```

- [ ] **Step 2: Verify the budget**

Run: `ls -l assets/brand/signin-portrait.webp`
Expected: about 63 KB, comfortably under the 300 KB the spec sets. If `cwebp` is unavailable, the fallback is `sips -s format jpeg -s formatOptions 80 <source> --out assets/brand/signin-portrait.jpg`, which measures 193 KB — still inside budget, and every later reference changes extension to match.

- [ ] **Step 3: Register the asset directory**

In `pubspec.yaml`, add an `assets` entry to the `flutter:` section, above `fonts:`:

```yaml
flutter:
  generate: true
  uses-material-design: true
  assets:
    - assets/brand/
  fonts:
```

- [ ] **Step 4: Verify the bundle resolves**

Run: `flutter test test/widget/app/molo_card_test.dart`
Expected: PASS. Any error in the `assets:` block fails asset-manifest generation before a test can run, so a green unrelated widget test proves the manifest built.

- [ ] **Step 5: Commit**

```bash
git add assets/brand/signin-portrait.webp pubspec.yaml
git commit -m "feat: ship the sign-in hero photograph inside its size budget"
```

Note for the reviewer: `assets/brand/` already holds two unreferenced 1 MB PNGs (`molo-landing-hero-v1.png`, `molo-wordmark-selected.png`). Registering the directory would bundle them. Confirm with the owner whether they are wanted before this task lands; if not, delete them in this commit, and if their status is unknown, register `assets/brand/signin-portrait.webp` as a single file instead of the directory.

---

### Task 5: Session persistence through the auth stack

**Files:**
- Modify: `lib/core/auth/data/services/auth_service.dart`
- Modify: `lib/core/auth/data/services/firebase_auth_service.dart:46-65`
- Modify: `lib/core/auth/data/services/preview_auth_service.dart:32-35`
- Modify: `lib/core/auth/data/services/unavailable_auth_service.dart:12-17`
- Modify: `lib/core/auth/data/repositories/auth_repository.dart:11-14`
- Modify: `lib/core/auth/data/repositories/default_auth_repository.dart:30-38`
- Modify: `lib/core/auth/ui/view_models/auth_view_model.dart:62-94`
- Modify: `lib/core/auth/auth_providers.dart`
- Modify (test fakes, each of which `implements` one of the two interfaces and so must grow the argument): `test/unit/core/auth/default_auth_repository_session_test.dart:43,80`, `test/unit/core/auth/preview_session_service_test.dart:117`, `test/unit/core/auth/auth_view_model_test.dart:53`, `test/unit/core/auth/registration_view_model_test.dart:12`, `test/unit/core/auth/auth_view_model_session_test.dart:364,410`, `test/widget/core/auth/registration_view_test.dart:209`
- Test: `test/unit/core/auth/session_persistence_test.dart`

**Interfaces:**
- Consumes: `AuthResult`, `AuthUser`, `AuthFailure` — all existing.
- Produces:
  ```dart
  // AuthService and AuthRepository, both:
  Future<AuthResult<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
    required bool persistSession,
  });

  // AuthViewModel:
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
    bool persistSession = true,
  });

  // auth_providers.dart, generated as sessionPersistenceChoosableProvider:
  bool sessionPersistenceChoosable(Ref ref);
  ```
  `persistSession` is **required** in the data layer, where being explicit about a session's lifetime matters, and **defaults to true** on the view model, whose contract is "persist unless the person asked otherwise" — which is also what every platform without the control does.

- [ ] **Step 1: Write the failing test**

Create `test/unit/core/auth/session_persistence_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/core/auth/auth_providers.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_user.dart';
import 'package:molobuddy_app/core/auth/data/repositories/default_auth_repository.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_provider_catalogue_service.dart';
import 'package:molobuddy_app/core/auth/data/services/auth_service.dart';
import 'package:molobuddy_app/core/auth/data/services/preview_session_service.dart';

/// Records what the repository asked for, so the argument's journey is checked
/// rather than assumed.
final class _RecordingAuthService implements AuthService {
  bool? lastPersistSession;

  @override
  AuthUser? get currentUser => null;

  @override
  Future<AuthResult<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
    required bool persistSession,
  }) async {
    lastPersistSession = persistSession;
    return const AuthSuccess(
      AuthUser(id: 'u1', email: 'a@b.co', displayName: 'A'),
    );
  }

  @override
  Future<AuthResult<AuthUser>> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) async => const AuthError(AuthFailure(AuthFailureKind.unexpected));

  @override
  Future<AuthResult<void>> signOut() async => const AuthSuccess(null);
}

void main() {
  group('the repository passes the choice down untouched', () {
    late _RecordingAuthService service;
    late DefaultAuthRepository repository;

    setUp(() {
      service = _RecordingAuthService();
      repository = DefaultAuthRepository(
        service,
        const BundledPreviewAuthProviderCatalogueService(),
        PreviewSessionService(service, practices: () => const []),
      );
    });

    test('a person who asked to stay signed in', () async {
      await repository.signInWithEmailAndPassword(
        email: 'a@b.co',
        password: 'password123',
        persistSession: true,
      );
      expect(service.lastPersistSession, isTrue);
    });

    test('a person who did not', () async {
      await repository.signInWithEmailAndPassword(
        email: 'a@b.co',
        password: 'password123',
        persistSession: false,
      );
      expect(service.lastPersistSession, isFalse);
    });
  });

  test('the choice is not offered where the platform ignores it', () {
    // The test host is not the web, and neither is Android or iOS: Firebase
    // always persists there, so there is nothing to choose.
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(sessionPersistenceChoosableProvider), isFalse);
  });

  test('a view can be told the platform does offer it', () {
    final container = ProviderContainer(
      overrides: [sessionPersistenceChoosableProvider.overrideWithValue(true)],
    );
    addTearDown(container.dispose);
    expect(container.read(sessionPersistenceChoosableProvider), isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/core/auth/session_persistence_test.dart`
Expected: FAIL — `persistSession` is not a parameter of `signInWithEmailAndPassword`, and `sessionPersistenceChoosableProvider` does not exist.

- [ ] **Step 3: Add the argument to the two interfaces**

In `lib/core/auth/data/services/auth_service.dart`:

```dart
  /// Signs in with an email address and a password.
  ///
  /// [persistSession] says whether the session should outlive the window. Only
  /// Web can honour it: Android and iOS always persist, and an implementation
  /// there accepts the argument and ignores it rather than pretending to have a
  /// choice.
  Future<AuthResult<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
    required bool persistSession,
  });
```

Make the same signature change in `lib/core/auth/data/repositories/auth_repository.dart`, with the same doc comment.

- [ ] **Step 4: Implement it in the three services and the repository**

`lib/core/auth/data/services/firebase_auth_service.dart` — add `import 'package:flutter/foundation.dart' show kIsWeb;` and replace the method's opening:

```dart
  @override
  Future<AuthResult<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
    required bool persistSession,
  }) async {
    try {
      // Web is the only platform where a session's lifetime is a choice.
      // `setPersistence` is a no-op-or-throw elsewhere, and Android and iOS
      // persist unconditionally, so the guard is a capability check rather
      // than a device check.
      if (kIsWeb) {
        await _auth.setPersistence(
          persistSession
              ? firebase.Persistence.LOCAL
              : firebase.Persistence.SESSION,
        );
      }
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
```

The rest of the method is unchanged.

`lib/core/auth/data/services/preview_auth_service.dart`:

```dart
  @override
  Future<AuthResult<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
    // Preview holds its session in memory for one run, so there is nothing
    // for a lifetime to change.
    required bool persistSession,
  }) async {
```

`lib/core/auth/data/services/unavailable_auth_service.dart`:

```dart
  @override
  Future<AuthResult<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
    required bool persistSession,
  }) async {
    return const AuthError(AuthFailure(AuthFailureKind.configurationMissing));
  }
```

`lib/core/auth/data/repositories/default_auth_repository.dart`:

```dart
  @override
  Future<AuthResult<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
    required bool persistSession,
  }) {
    return _authService.signInWithEmailAndPassword(
      email: email,
      password: password,
      persistSession: persistSession,
    );
  }
```

- [ ] **Step 5: Carry it through the view model**

In `lib/core/auth/ui/view_models/auth_view_model.dart`, change the method's signature and the repository call:

```dart
  /// Signs in, and says whether the session should outlive the window.
  ///
  /// The default is to persist, which is both what someone who was never
  /// offered the choice expects and what Android and iOS do regardless.
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
    bool persistSession = true,
  }) async {
```

and at the repository call (currently line 91):

```dart
    final result = await repository.signInWithEmailAndPassword(
      email: normalisedEmail,
      password: password,
      persistSession: persistSession,
    );
```

- [ ] **Step 6: Add the capability provider**

In `lib/core/auth/auth_providers.dart`, add `import 'package:flutter/foundation.dart';` and, after `authServiceProvider`:

```dart
/// Whether this platform lets someone choose how long a session outlives the
/// window.
///
/// Web does: Firebase can hold the session in local storage or drop it with
/// the tab. Android and iOS always persist, so a control offering the choice
/// there would be a promise the platform does not keep — which is why the
/// sign-in screen omits the row rather than disabling it.
@Riverpod(keepAlive: true)
bool sessionPersistenceChoosable(Ref ref) => kIsWeb;
```

- [ ] **Step 7: Regenerate**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `auth_providers.g.dart` gains `sessionPersistenceChoosableProvider`. Never edit the generated file.

- [ ] **Step 8: Update every fake**

Each class listed under **Files** implements `AuthService` or `AuthRepository` and now fails to satisfy the interface. Add `required bool persistSession,` to each one's `signInWithEmailAndPassword`, and where the fake records its arguments, record this one too. Find them all with:

```bash
grep -rn "signInWithEmailAndPassword" test
```

- [ ] **Step 9: Run the tests**

Run: `flutter test test/unit/core/auth/`
Expected: PASS, including the four new assertions. Then `flutter analyze` clean.

- [ ] **Step 10: Commit**

```bash
git add lib/core/auth lib/core/auth/auth_providers.g.dart test/unit/core/auth test/widget/core/auth/registration_view_test.dart
git commit -m "feat: let someone choose whether a web session outlives the window"
```

---

### Task 6: Field geometry and the labelled field

**Files:**
- Modify: `lib/app/design_system/molo_theme.dart`
- Create: `lib/app/design_system/components/molo_text_field.dart`
- Test: `test/widget/app/molo_text_field_test.dart`
- Test: `test/unit/app/molo_theme_test.dart` (append)

**Interfaces:**
- Consumes: `MoloSpacing.controlRadius`, `MoloSpacing.primaryActionRadius`, `MoloTypography.normalLineHeight`.
- Produces:
  ```dart
  class MoloTextField extends StatelessWidget {
    const MoloTextField({
      required this.label,
      required this.controller,
      this.fieldKey,
      this.trailing,
      this.hintText,
      this.errorText,
      this.enabled = true,
      this.obscureText = false,
      this.suffix,
      this.autofillHints,
      this.keyboardType,
      this.textInputAction,
      this.focusNode,
      this.onSubmitted,
      this.autocorrect = true,
      super.key,
    });
    final String label;              // the visible label, and the accessible name
    final Widget? trailing;          // sits at the right of the label row
    final TextEditingController controller;
    final Key? fieldKey;             // put on the TextField, so existing keys survive
    final String? hintText;
    final String? errorText;
    final bool enabled;
    final bool obscureText;
    final Widget? suffix;            // the reveal toggle
    final List<String>? autofillHints;
    final TextInputType? keyboardType;
    final TextInputAction? textInputAction;
    final FocusNode? focusNode;
    final ValueChanged<String>? onSubmitted;
    final bool autocorrect;
  }
  ```

Traced values: field 50 high, radius 14, 16 horizontal padding, 15px value text; label 13px medium plum, 7 above the field.

Geometry note: 15px text at Geist's 1.3 line box is 19.5 logical pixels, so 15 of vertical padding either side gives 49.5, and a 50 minimum lifts it to exactly 50. The minimum is a **floor, not a fixed height**, so a 200% text scale grows the field instead of clipping it.

- [ ] **Step 1: Write the failing test**

Create `test/widget/app/molo_text_field_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_text_field.dart';
import 'package:molobuddy_app/app/design_system/molo_theme.dart';

void main() {
  const fieldKey = Key('field');

  Future<void> pump(
    WidgetTester tester, {
    Widget? trailing,
    String? errorText,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MoloTheme.light(),
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(textScale),
            ),
            child: Center(
              child: SizedBox(
                width: 384,
                child: MoloTextField(
                  label: 'Work email',
                  fieldKey: fieldKey,
                  controller: TextEditingController(),
                  hintText: 'you@practice.co.za',
                  errorText: errorText,
                  trailing: trailing,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('the field is 50 high, the design height', (tester) async {
    await pump(tester);
    expect(tester.getSize(find.byKey(fieldKey)).height, 50);
  });

  testWidgets('the value text is 15px', (tester) async {
    await pump(tester);
    expect(tester.widget<TextField>(find.byKey(fieldKey)).style?.fontSize, 15);
  });

  testWidgets('the label sits above the field, 13px medium', (tester) async {
    await pump(tester);
    final label = tester.widget<Text>(find.text('Work email'));
    expect(label.style?.fontSize, 13);
    expect(label.style?.fontWeight, FontWeight.w500);
    expect(label.style?.color, MoloColours.moloPlum);

    final labelBottom = tester.getRect(find.text('Work email')).bottom;
    final fieldTop = tester.getRect(find.byKey(fieldKey)).top;
    expect(fieldTop - labelBottom, closeTo(7, 1));
  });

  testWidgets('a trailing action shares the label row', (tester) async {
    await pump(
      tester,
      trailing: TextButton(onPressed: () {}, child: const Text('Forgot?')),
    );
    final labelRow = tester.getRect(find.text('Work email'));
    final trailing = tester.getRect(find.text('Forgot?'));
    expect(trailing.center.dx, greaterThan(labelRow.center.dx));
    expect(trailing.center.dy, closeTo(labelRow.center.dy, 4));
  });

  testWidgets('the field carries exactly one accessible name', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    expect(find.bySemanticsLabel('Work email'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('doubling the text size grows the field instead of clipping', (
    tester,
  ) async {
    await pump(tester, textScale: 2);
    expect(tester.getSize(find.byKey(fieldKey)).height, greaterThan(50));
    expect(tester.takeException(), isNull);
  });

  testWidgets('an error message appears below the field', (tester) async {
    await pump(tester, errorText: 'Enter a valid email address.');
    expect(
      tester.getRect(find.text('Enter a valid email address.')).top,
      greaterThan(tester.getRect(find.byKey(fieldKey)).top),
    );
  });
}
```

Append to `test/unit/app/molo_theme_test.dart`, inside `main()`:

```dart
  group('control geometry', () {
    test('a field is drawn at the design radius', () {
      final theme = MoloTheme.light();
      final border = theme.inputDecorationTheme.enabledBorder;
      expect(border, isA<OutlineInputBorder>());
      expect(
        (border! as OutlineInputBorder).borderRadius,
        BorderRadius.circular(MoloSpacing.controlRadius),
      );
      expect(theme.inputDecorationTheme.constraints?.minHeight, 50);
      expect(
        theme.inputDecorationTheme.contentPadding,
        const EdgeInsets.symmetric(horizontal: MoloSpacing.md, vertical: 15),
      );
    });

    test('a primary action is 52 high at the design radius', () {
      final style = MoloTheme.light().filledButtonTheme.style!;
      expect(
        style.minimumSize?.resolve(const <WidgetState>{}),
        const Size.fromHeight(52),
      );
      expect(
        style.shape?.resolve(const <WidgetState>{}),
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            MoloSpacing.primaryActionRadius,
          ),
        ),
      );
    });

    test('hovering a primary action darkens the fill, not the label', () {
      final style = MoloTheme.light().filledButtonTheme.style!;
      expect(
        style.backgroundColor?.resolve(const <WidgetState>{}),
        MoloColours.moloPlum,
      );
      expect(
        style.backgroundColor?.resolve({WidgetState.hovered}),
        MoloColours.moloPlumHover,
      );
      expect(
        style.foregroundColor?.resolve({WidgetState.hovered}),
        MoloColours.warmCanvas,
      );
    });
  });
```

Add the `MoloSpacing` and `MoloColours` imports to that test file if they are
not already there.

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/widget/app/molo_text_field_test.dart test/unit/app/molo_theme_test.dart`
Expected: FAIL — `molo_text_field.dart` does not exist, and the theme's field is 54-ish with no `constraints` and its primary button is 54 at radius 14.

- [ ] **Step 3: Change the theme**

In `lib/app/design_system/molo_theme.dart`, inside `inputDecorationTheme`, replace `contentPadding` and add `constraints` beside it:

```dart
        // The design draws a 50-high field with 16 of horizontal padding.
        // 15px text at Geist's 1.3 line box is 19.5, so 15 either side lands
        // on 49.5 and the minimum lifts it to exactly 50. A minimum rather
        // than a fixed height, so a doubled text size grows the field.
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MoloSpacing.md,
          vertical: 15,
        ),
        constraints: const BoxConstraints(minHeight: 50),
```

Replace `filledButtonTheme`, and note that `controlShape` stays as it is because the outlined theme still uses it:

```dart
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          // The design draws a primary action one unit rounder and two shorter
          // than a field, which is what separates it from the fields above it.
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                MoloSpacing.primaryActionRadius,
              ),
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return MoloColours.border;
            }
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.pressed)) {
              return MoloColours.moloPlumHover;
            }
            return MoloColours.moloPlum;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return MoloColours.secondaryText;
            }
            return MoloColours.warmCanvas;
          }),
          // The hover fill is the whole hover state, so no overlay lightens it
          // on top and takes the label's contrast with it.
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      ),
```

The hover fill is where `moloPlumHover` earns its place: the design darkens a
pressed primary rather than overlaying it, and a 13.37:1 label on the hovered
fill is what makes that safe.

- [ ] **Step 4: Write the component**

Create `lib/app/design_system/components/molo_text_field.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/typography/molo_typography.dart';

/// A field with its label above it, as the design draws every field.
///
/// Material floats a label into the outline; the design keeps it on its own
/// line, in a row that can also carry an action such as "Forgot password?".
/// The visible label is excluded from semantics and re-stated on the field, so
/// a screen reader hears the name once and hears it attached to the control.
class MoloTextField extends StatelessWidget {
  const MoloTextField({
    required this.label,
    required this.controller,
    this.fieldKey,
    this.trailing,
    this.hintText,
    this.errorText,
    this.enabled = true,
    this.obscureText = false,
    this.suffix,
    this.autofillHints,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
    this.onSubmitted,
    this.autocorrect = true,
    super.key,
  });

  final String label;
  final TextEditingController controller;

  /// Placed on the [TextField] itself, so a caller's existing key keeps
  /// pointing at the control rather than at this wrapper.
  final Key? fieldKey;

  /// An action at the right of the label row. Outside the field's semantics,
  /// because it is a separate control.
  final Widget? trailing;

  final String? hintText;
  final String? errorText;
  final bool enabled;
  final bool obscureText;
  final Widget? suffix;
  final List<String>? autofillHints;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final bool autocorrect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
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
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 7),
        Semantics(
          container: true,
          label: label,
          child: TextField(
            key: fieldKey,
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            obscureText: obscureText,
            autocorrect: autocorrect,
            autofillHints: autofillHints,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            style: const TextStyle(
              fontSize: 15,
              letterSpacing: 0,
              height: MoloTypography.normalLineHeight,
              color: MoloColours.moloPlum,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              errorText: errorText,
              suffixIcon: suffix,
            ),
          ),
        ),
      ],
    );
  }
}
```

If `flutter analyze` reports the `package:flutter/services.dart` import as unused, remove it.

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/widget/app/molo_text_field_test.dart test/unit/app/molo_theme_test.dart`
Expected: PASS. If the 50-high assertion is off by a fraction, adjust the theme's vertical padding — the height is `2 * padding + round(15 * 1.3)` under a 50 floor — and do not change the assertion.

- [ ] **Step 6: See what the taller-button change moved**

Run: `flutter test`
Expected: the suite is green. The primary button dropped from 54 to 52 everywhere, and no test asserts 54; if one fails on a shifted position rather than a height, update that position, because 52 is the design's number.

- [ ] **Step 7: Commit**

```bash
git add lib/app/design_system/molo_theme.dart lib/app/design_system/components/molo_text_field.dart test/widget/app/molo_text_field_test.dart test/unit/app/molo_theme_test.dart
git commit -m "feat: draw fields and primary actions at the design's geometry"
```

---

### Task 7: The switch pill

**Files:**
- Create: `lib/app/design_system/components/molo_pill_button.dart`
- Test: `test/widget/app/molo_pill_button_test.dart`

**Interfaces:**
- Consumes: `MoloSpacing.pillRadius`, `MoloColours`, `MoloTypography.normalLineHeight`.
- Produces:
  ```dart
  class MoloPillButton extends StatelessWidget {
    const MoloPillButton({
      required this.label,
      required this.onPressed,   // null disables
      super.key,
    });
    final String label;
    final VoidCallback? onPressed;
  }
  ```

Traced: 13px medium plum label, padding 9 vertical and 16 horizontal, radius 12, surface fill, `pulseTint` fill on hover.

**Deviation (this plan's number 7):** spec section 7.5 gives the pill a quiet `border` outline resting and `pulseBorder` on hover. Both are under 3:1, and this control has nothing else to identify it — its surface fill is 1.01:1 against the warm canvas pane it sits on, so remove the outline and it reads as the plain label beside it. The outline therefore carries identification in **both** states and stays `controlBorder` (3.43:1) in both, with hover changing the fill only. This is the same reasoning spec section 7.2 applies to fields, applied where the spec did not reach.

- [ ] **Step 1: Write the failing test**

Create `test/widget/app/molo_pill_button_test.dart`:

```dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_pill_button.dart';
import 'package:molobuddy_app/app/design_system/molo_theme.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';

void main() {
  Future<void> pump(WidgetTester tester, {VoidCallback? onPressed}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MoloTheme.light(),
        home: Scaffold(
          backgroundColor: MoloColours.warmCanvas,
          body: Center(
            child: MoloPillButton(
              label: 'Create an account',
              onPressed: onPressed ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  ShapeDecoration _decoration(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(MoloPillButton),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    return box.decoration as ShapeDecoration;
  }

  testWidgets('the label is 13px medium plum', (tester) async {
    await pump(tester);
    final text = tester.widget<Text>(find.text('Create an account'));
    expect(text.style?.fontSize, 13);
    expect(text.style?.fontWeight, FontWeight.w500);
    expect(text.style?.color, MoloColours.moloPlum);
  });

  testWidgets('it is padded 9 by 16 at the design radius', (tester) async {
    await pump(tester);
    final labelHeight = tester.getSize(find.text('Create an account')).height;
    final pillHeight = tester.getSize(find.byType(MoloPillButton)).height;
    expect(pillHeight - labelHeight, closeTo(18, 1));

    final shape = _decoration(tester).shape as RoundedRectangleBorder;
    expect(
      shape.borderRadius,
      BorderRadius.circular(MoloSpacing.pillRadius),
    );
  });

  testWidgets('the resting outline is the one that clears 3:1', (tester) async {
    await pump(tester);
    final shape = _decoration(tester).shape as RoundedRectangleBorder;
    expect(shape.side.color, MoloColours.controlBorder);
    expect(_decoration(tester).color, MoloColours.surface);
  });

  testWidgets('hover tints the fill and keeps the outline', (tester) async {
    await pump(tester);
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.byType(MoloPillButton)));
    await tester.pumpAndSettle();

    expect(_decoration(tester).color, MoloColours.pulseTint);
    final shape = _decoration(tester).shape as RoundedRectangleBorder;
    expect(shape.side.color, MoloColours.controlBorder);
  });

  testWidgets('it is a button to a screen reader', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    expect(
      tester.getSemantics(find.text('Create an account')),
      matchesSemantics(
        label: 'Create an account',
        isButton: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    semantics.dispose();
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/app/molo_pill_button_test.dart`
Expected: FAIL — `molo_pill_button.dart` does not exist.

- [ ] **Step 3: Write the component**

Create `lib/app/design_system/components/molo_pill_button.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';
import 'package:molobuddy_app/app/design_system/typography/molo_typography.dart';

/// The small outlined pill each authentication screen offers the other one
/// through.
///
/// The design draws a button here, not a link, which is why this replaced a
/// `TextButton`: the outline is what tells someone it is pressable. That
/// outline is `controlBorder` rather than the baseline's quieter colour in both
/// the resting and hovered states, because the pill's fill is invisible
/// against the warm canvas and the outline is therefore the only thing
/// identifying the control. Hover changes the fill alone.
class MoloPillButton extends StatelessWidget {
  const MoloPillButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;

  /// A null callback disables the pill.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size.zero),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: MoloSpacing.md, vertical: 9),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return MoloColours.surface;
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed)) {
            return MoloColours.pulseTint;
          }
          return MoloColours.surface;
        }),
        // Keyboard focus has to stay distinguishable from hover, so it takes
        // the ring rather than a second fill.
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return MoloColours.secondaryText;
          }
          return MoloColours.moloPlum;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return const BorderSide(color: MoloColours.border);
          }
          return const BorderSide(color: MoloColours.controlBorder);
        }),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MoloSpacing.pillRadius),
          ),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
            height: MoloTypography.normalLineHeight,
          ),
        ),
      ),
      child: Text(label),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget/app/molo_pill_button_test.dart`
Expected: PASS, 5 tests. If the `DecoratedBox` finder does not resolve, print the subtree with `debugDumpApp()` and target the `Material` that `TextButton` builds instead — assert `Material.shape` and `Material.color` rather than a `ShapeDecoration`, keeping every expected value the same.

- [ ] **Step 5: Commit**

```bash
git add lib/app/design_system/components/molo_pill_button.dart test/widget/app/molo_pill_button_test.dart
git commit -m "feat: draw the auth switch as the pill the design draws"
```

---

### Task 8: The checkbox row

**Files:**
- Create: `lib/app/design_system/components/molo_check_row.dart`
- Test: `test/widget/app/molo_check_row_test.dart`

**Interfaces:**
- Consumes: `MoloGlyphs.tick`, `MoloIcon`, `MoloColours`.
- Produces:
  ```dart
  class MoloCheckRow extends StatelessWidget {
    const MoloCheckRow({
      required this.label,          // a Widget, so a row can carry links
      required this.semanticLabel,  // the plain-text name of the whole row
      required this.value,
      required this.onChanged,
      this.enabled = true,
      this.boxSize = 19,
      super.key,
    });
    final Widget label;
    final String semanticLabel;
    final bool value;
    final ValueChanged<bool> onChanged;
    final bool enabled;
    final double boxSize;
  }
  ```

Traced: box 19 square, radius 6, `moloPlum` fill and no outline when checked, `surface` fill with a `controlBorder` outline when not, a 12px `warmCanvas` tick, gap 10, and the whole row is the control.

The unchecked outline is `controlBorder` rather than the baseline's `#E4D5D8`, per spec section 7.2: a checkbox's outline is what says a checkbox is there.

- [ ] **Step 1: Write the failing test**

Create `test/widget/app/molo_check_row_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_check_row.dart';
import 'package:molobuddy_app/app/design_system/molo_theme.dart';

void main() {
  /// Holds the row's value, so a tap can be observed rather than guessed at.
  late List<bool> changes;

  Future<void> pump(
    WidgetTester tester, {
    required bool value,
    bool enabled = true,
  }) async {
    changes = <bool>[];
    var current = value;
    await tester.pumpWidget(
      MaterialApp(
        theme: MoloTheme.light(),
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (context, setState) => MoloCheckRow(
                label: const Text('Keep me signed in on this device'),
                semanticLabel: 'Keep me signed in on this device',
                value: current,
                enabled: enabled,
                onChanged: (next) {
                  changes.add(next);
                  setState(() => current = next);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration boxOf(WidgetTester tester) {
    return tester
            .widget<Container>(find.byKey(MoloCheckRow.boxKey))
            .decoration!
        as BoxDecoration;
  }

  testWidgets('the box is 19 square at radius 6', (tester) async {
    await pump(tester, value: false);
    expect(tester.getSize(find.byKey(MoloCheckRow.boxKey)), const Size(19, 19));
    expect(boxOf(tester).borderRadius, BorderRadius.circular(6));
  });

  testWidgets('unchecked, the outline is the one that clears 3:1', (
    tester,
  ) async {
    await pump(tester, value: false);
    final decoration = boxOf(tester);
    expect(decoration.color, MoloColours.surface);
    expect(decoration.border?.top.color, MoloColours.controlBorder);
  });

  testWidgets('checked, the box fills plum', (tester) async {
    await pump(tester, value: true);
    expect(boxOf(tester).color, MoloColours.moloPlum);
  });

  testWidgets('the label sits 10 from the box', (tester) async {
    await pump(tester, value: false);
    final boxRight = tester.getRect(find.byKey(MoloCheckRow.boxKey)).right;
    final labelLeft = tester
        .getRect(find.text('Keep me signed in on this device'))
        .left;
    expect(labelLeft - boxRight, closeTo(10, 1));
  });

  testWidgets('tapping the words toggles, not only the box', (tester) async {
    await pump(tester, value: true);
    await tester.tap(find.text('Keep me signed in on this device'));
    await tester.pump();
    expect(changes, [false]);
    expect(boxOf(tester).color, MoloColours.surface);
  });

  testWidgets('tapping the box toggles too', (tester) async {
    await pump(tester, value: false);
    await tester.tap(find.byKey(MoloCheckRow.boxKey));
    await tester.pump();
    expect(changes, [true]);
    expect(boxOf(tester).color, MoloColours.moloPlum);
  });

  testWidgets('it announces as a checked control, once', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, value: true);
    final node = tester.getSemantics(find.byType(MoloCheckRow));
    expect(node.label, 'Keep me signed in on this device');
    expect(node.hasFlag(SemanticsFlag.hasCheckedState), isTrue);
    expect(node.hasFlag(SemanticsFlag.isChecked), isTrue);
    semantics.dispose();
  });

  testWidgets('disabled, it does not call back', (tester) async {
    await pump(tester, value: false, enabled: false);
    await tester.tap(
      find.text('Keep me signed in on this device'),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(changes, isEmpty);
  });
}
```

Import `package:flutter/semantics.dart` for `SemanticsFlag`.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/app/molo_check_row_test.dart`
Expected: FAIL — `molo_check_row.dart` does not exist.

- [ ] **Step 3: Write the component**

Create `lib/app/design_system/components/molo_check_row.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/icons/molo_glyphs.dart';
import 'package:molobuddy_app/app/design_system/typography/molo_typography.dart';

/// A square box and a label, the whole row being the control.
///
/// The design draws no Material checkbox anywhere: the box is 19 square at
/// radius 6, and pressing the words is the same as pressing the box. The
/// unchecked outline is `controlBorder` rather than the baseline's quieter
/// colour, because that outline is the only thing that says a checkbox is
/// there and WCAG 1.4.11 asks for 3:1 of it.
class MoloCheckRow extends StatelessWidget {
  const MoloCheckRow({
    required this.label,
    required this.semanticLabel,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.boxSize = 19,
    super.key,
  });

  /// A widget rather than a string, so a row can carry links inside its words.
  final Widget label;

  /// The plain-text name of the whole row, spoken once.
  final String semanticLabel;

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  /// The design draws 19 at sign-in. A caller that needs another size states
  /// it rather than scaling this one.
  final double boxSize;

  /// The box itself, so a measurement can find it.
  static const boxKey = Key('molo_check_row_box');

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      checked: value,
      enabled: enabled,
      label: semanticLabel,
      child: InkWell(
        onTap: enabled ? () => onChanged(!value) : null,
        borderRadius: BorderRadius.circular(6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              key: boxKey,
              width: boxSize,
              height: boxSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: value ? MoloColours.moloPlum : MoloColours.surface,
                borderRadius: BorderRadius.circular(6),
                border: value
                    ? null
                    : Border.all(color: MoloColours.controlBorder),
              ),
              // The tick stays in the tree and fades, as the baseline does, so
              // the box never reflows as it is toggled.
              child: Opacity(
                opacity: value ? 1 : 0,
                child: MoloIcon(
                  MoloGlyphs.tick,
                  size: 12,
                  color: MoloColours.warmCanvas,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: ExcludeSemantics(
                child: DefaultTextStyle.merge(
                  style: const TextStyle(
                    fontSize: 13,
                    letterSpacing: 0,
                    height: MoloTypography.normalLineHeight,
                    color: MoloColours.secondaryText,
                  ),
                  child: label,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget/app/molo_check_row_test.dart`
Expected: PASS, 8 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/app/design_system/components/molo_check_row.dart test/widget/app/molo_check_row_test.dart
git commit -m "feat: draw the design's checkbox row, box and words together"
```

---

### Task 9: The copy

**Files:**
- Modify: `lib/app/localisation/l10n/app_en.arb`
- Modify: `lib/app/localisation/l10n/app_en_ZA.arb`
- Test: `test/unit/core/auth/sign_in_greeting_test.dart`
- Create: `lib/core/auth/ui/views/sign_in/sign_in_greeting.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: on `AppLocalizations` — `signInHeroBody`, `greetingMorning`, `greetingAfternoon`, `greetingEvening`, `workEmailLabel`, `passwordHint`, `keepMeSignedIn`, `orDividerLabel`, `microsoftLabel`, `googleLabel`, `microsoftComingSoonHint`; and `SignInGreeting` plus `signInGreetingForHour(int hour)`.

Every string below is the baseline's own words. `emailHint`, `createAccount` and `termsNotice` change value; each is used only by this screen, except `emailHint`, which registration shares and which the baseline gives the same placeholder.

- [ ] **Step 1: Write the failing test**

Create `test/unit/core/auth/sign_in_greeting_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/core/auth/ui/views/sign_in/sign_in_greeting.dart';

void main() {
  test('morning runs to noon', () {
    expect(signInGreetingForHour(0), SignInGreeting.morning);
    expect(signInGreetingForHour(11), SignInGreeting.morning);
  });

  test('afternoon runs from noon to five', () {
    expect(signInGreetingForHour(12), SignInGreeting.afternoon);
    expect(signInGreetingForHour(16), SignInGreeting.afternoon);
  });

  test('evening runs from five', () {
    expect(signInGreetingForHour(17), SignInGreeting.evening);
    expect(signInGreetingForHour(23), SignInGreeting.evening);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/core/auth/sign_in_greeting_test.dart`
Expected: FAIL — `sign_in_greeting.dart` does not exist.

- [ ] **Step 3: Write the clock rule**

Create `lib/core/auth/ui/views/sign_in/sign_in_greeting.dart`:

```dart
/// Which time-of-day kicker sits above "Welcome back".
enum SignInGreeting { morning, afternoon, evening }

/// The baseline's rule: morning before noon, afternoon before five, evening
/// after.
///
/// A pure function of the hour rather than a read of the clock, so the rule is
/// testable and the view stays the only thing that knows what time it is. The
/// home screen's greeting is a fixed string today; making that follow the
/// clock too is that screen's own work.
SignInGreeting signInGreetingForHour(int hour) {
  if (hour < 12) {
    return SignInGreeting.morning;
  }
  if (hour < 17) {
    return SignInGreeting.afternoon;
  }
  return SignInGreeting.evening;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/core/auth/sign_in_greeting_test.dart`
Expected: PASS, 3 tests.

- [ ] **Step 5: Add the new strings**

In `lib/app/localisation/l10n/app_en.arb`, add:

```json
  "signInHeroBody": "Every decision, every hand-off and every deadline in one place your practice can defend.",
  "greetingMorning": "Good morning",
  "greetingAfternoon": "Good afternoon",
  "greetingEvening": "Good evening",
  "workEmailLabel": "Work email",
  "passwordHint": "••••••••",
  "keepMeSignedIn": "Keep me signed in on this device",
  "orDividerLabel": "or",
  "microsoftLabel": "Microsoft",
  "googleLabel": "Google",
  "microsoftComingSoonHint": "Microsoft sign-in is coming soon",
```

- [ ] **Step 6: Change the three strings whose wording the baseline moves**

In the same file:

```json
  "emailHint": "you@practice.co.za",
  "createAccount": "Create an account",
  "termsNotice": "By signing in, you agree to the {termsLink} and {privacyLink}. Molo never signs in to eFiling on your behalf.",
```

Leave the `@termsNotice` placeholder block exactly as it is.

- [ ] **Step 7: Retire what the design retires**

Delete these keys, and their `@`-metadata blocks if any:

```
brandStoryTitle
brandStoryBody
brandStoryPointOne
brandStoryPointTwo
brandStoryPointThree
emailLabel
orContinueWith
continueWithGoogle
comingSoon
```

`brandPromise` stays: the hero uses it, and so does the wizard shell.

- [ ] **Step 8: Mirror every change into the South African file**

Apply steps 5, 6 and 7 identically to `lib/app/localisation/l10n/app_en_ZA.arb`. Same keys, same values — this locale exists for spelling and format, and none of these strings differ.

- [ ] **Step 9: Regenerate and confirm nothing still references the retired keys**

```bash
flutter gen-l10n
grep -rn "brandStory\|orContinueWith\|continueWithGoogle\|localisations.comingSoon\|localisations.emailLabel" lib test
```

Expected: `gen-l10n` succeeds, and the grep returns nothing. `sign_in_view.dart` still references the retired keys at this point, so this step fails until Task 11 lands — run Task 9's steps 1 to 8, then continue to Task 10 and Task 11, and treat this grep as Task 11's gate.

- [ ] **Step 10: Commit**

```bash
git add lib/app/localisation lib/core/auth/ui/views/sign_in/sign_in_greeting.dart test/unit/core/auth/sign_in_greeting_test.dart
git commit -m "feat: bring the sign-in copy in line with the baseline"
```

The tree does not compile between this commit and Task 11's, because the view still asks for retired strings. If the reviewer requires every commit to build, hold this commit back and land Tasks 9, 10 and 11 as one.

---

### Task 10: The hero pane

**Files:**
- Create: `lib/core/auth/ui/views/sign_in/sign_in_hero_pane.dart`
- Modify: `lib/app/adaptive/auth_shell_layout.dart`
- Test: covered by `test/widget/core/auth/sign_in_fidelity_test.dart` in Task 12; this task's own gate is the two tests below, added to that file when it is created — write them here and let the file exist from this task onward.

**Interfaces:**
- Consumes: `MoloBrandLockup`, `MoloColours`, `AppLocalizations.brandPromise`, `AppLocalizations.signInHeroBody`, `assets/brand/signin-portrait.webp`.
- Produces:
  ```dart
  class SignInHeroPane extends StatelessWidget {
    const SignInHeroPane({super.key});
    static const paneKey = Key('auth_hero_panel');   // the key existing tests use
  }

  // auth_shell_layout.dart:
  abstract final class MoloAuthShellLayout {
    static double supportingPaneWidth(double availableWidth);  // unchanged
    static double signInHeroWidth(double availableWidth);      // 44%
  }
  ```

Traced values:

| Element | Value |
|---|---|
| Pane width | 44% of the window |
| Ground | `moloPlum`, with the photograph at `BoxFit.cover`, alignment `(0.24, 0)` — CSS `62% 50%` |
| Scrim | vertical, `moloPlum` at 0.72 → 0.28 at 42% → 0.86 at 100% |
| Padding | 40 all round |
| Promise | 30px, height 1.2, tracking -0.02em (-0.6), `warmCanvas` |
| Body | 14px, height 1.6, `warmCanvas` at 0.72 alpha |
| Gap | 16 between promise and body |
| Text column | 318 max width |

The 318 is the baseline's `max-width: 30ch`. CSS resolves `ch` against the element's own font size, which here inherits the 16px root, and Geist's zero advance measures 0.663em — so 30 × 16 × 0.663 = 318.2. The scrim's 0.86 bottom stop is what puts the promise at 16.59:1 rather than leaving it over bare photograph, so it is contrast, not decoration.

- [ ] **Step 1: Write the failing test**

Create `test/widget/core/auth/sign_in_fidelity_test.dart` with the hero group only:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/molo_theme.dart';
import 'package:molobuddy_app/app/localisation/generated/app_localizations.dart';
import 'package:molobuddy_app/core/auth/ui/views/sign_in/sign_in_hero_pane.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    theme: MoloTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  group('hero pane', () {
    testWidgets('it carries the promise and the hero body', (tester) async {
      await tester.pumpWidget(host(const SignInHeroPane()));
      expect(find.text('Make serious work feel light.'), findsOneWidget);
      expect(
        find.textContaining('every deadline in one place'),
        findsOneWidget,
      );
    });

    testWidgets('the promise is 30px at the design tracking', (tester) async {
      await tester.pumpWidget(host(const SignInHeroPane()));
      final promise = tester.widget<Text>(
        find.text('Make serious work feel light.'),
      );
      expect(promise.style?.fontSize, 30);
      expect(promise.style?.height, 1.2);
      expect(promise.style?.letterSpacing, closeTo(-0.6, 0.001));
      expect(promise.style?.color, MoloColours.warmCanvas);
    });

    test('the pane is 44% of the window', () {
      expect(MoloAuthShellLayout.signInHeroWidth(1280), closeTo(563.2, 0.01));
      expect(MoloAuthShellLayout.signInHeroWidth(1440), closeTo(633.6, 0.01));
    });

    test('it is wider than the wizard rail, as the baseline draws it', () {
      // The two panes differ on purpose. Asserting it here means a later
      // change that quietly unifies them has to argue with a test.
      expect(
        MoloAuthShellLayout.signInHeroWidth(1440),
        greaterThan(MoloAuthShellLayout.supportingPaneWidth(1440)),
      );
    });
  });
}
```

This file needs `import 'package:molobuddy_app/app/adaptive/auth_shell_layout.dart';`.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/core/auth/sign_in_fidelity_test.dart`
Expected: FAIL — `sign_in_hero_pane.dart` and `signInHeroWidth` do not exist.

- [ ] **Step 3: Add the width rule**

Replace `lib/app/adaptive/auth_shell_layout.dart` with:

```dart
abstract final class MoloAuthShellLayout {
  /// The dark supporting pane the signup wizard shares across its routes.
  ///
  /// Fixed rather than proportional, because `/sign-up` and `/onboarding` fade
  /// into each other and a proportional edge would be the same number twice
  /// only by accident.
  static double supportingPaneWidth(double availableWidth) {
    return availableWidth.clamp(300, 360).toDouble();
  }

  /// The sign-in hero, which the design draws at 44% of the window.
  ///
  /// Wider than the wizard's rail on purpose: the baseline gives the
  /// photograph 44% and the rail 38%. Sign-in does not fade into the wizard
  /// through a shared pane, so the two are free to differ.
  static double signInHeroWidth(double availableWidth) {
    return availableWidth * 0.44;
  }
}
```

- [ ] **Step 4: Write the hero pane**

Create `lib/core/auth/ui/views/sign_in/sign_in_hero_pane.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_brand_lockup.dart';
import 'package:molobuddy_app/app/design_system/typography/molo_typography.dart';
import 'package:molobuddy_app/app/localisation/generated/app_localizations.dart';

/// The photographic pane beside the sign-in form.
///
/// The plum panel with two orbs and three story points is retired: the design
/// puts a photograph here, under a scrim whose bottom stop is what keeps the
/// promise readable rather than merely dark.
class SignInHeroPane extends StatelessWidget {
  const SignInHeroPane({super.key});

  /// Kept from the retired panel, so tests and the router's measurements go on
  /// pointing at the same pane.
  static const paneKey = Key('auth_hero_panel');

  /// The design's text column is `30ch`, which CSS resolves against the
  /// inherited 16px root. Geist's zero advance measures 0.663em, so
  /// 30 x 16 x 0.663 lands on 318.
  static const _textColumnWidth = 318.0;

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    return DecoratedBox(
      key: paneKey,
      decoration: const BoxDecoration(
        color: MoloColours.moloPlum,
        image: DecorationImage(
          image: AssetImage('assets/brand/signin-portrait.webp'),
          fit: BoxFit.cover,
          // The design's `background-position: 62% 50%`.
          alignment: Alignment(0.24, 0),
        ),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.42, 1],
            colors: [
              Color(0xB8241529),
              Color(0x47241529),
              Color(0xDB241529),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const MoloBrandLockup(onDark: true),
              Flexible(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _textColumnWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localisations.brandPromise,
                          style: TextStyle(
                            fontSize: 30,
                            height: 1.2,
                            letterSpacing: MoloTypography.display(30),
                            color: MoloColours.warmCanvas,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          localisations.signInHeroBody,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            letterSpacing: 0,
                            color: MoloColours.warmCanvas.withValues(
                              alpha: 0.72,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

The three scrim colours are `moloPlum` at 0.72, 0.28 and 0.86 written as ARGB, because a `const` gradient cannot call `withValues`. `0xB8` is 0.72, `0x47` is 0.28 and `0xDB` is 0.86 of 255.

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/widget/core/auth/sign_in_fidelity_test.dart`
Expected: PASS, 4 tests. The image will not decode under `flutter test` — that is expected and harmless; a `DecorationImage` that cannot load paints nothing over the plum ground.

- [ ] **Step 6: Commit**

```bash
git add lib/core/auth/ui/views/sign_in/sign_in_hero_pane.dart lib/app/adaptive/auth_shell_layout.dart test/widget/core/auth/sign_in_fidelity_test.dart
git commit -m "feat: put the photographic hero beside the sign-in form"
```

---

### Task 11: The form pane

**Files:**
- Modify: `lib/core/auth/ui/views/sign_in/sign_in_view.dart`
- Test: `test/widget/core/auth/sign_in_fidelity_test.dart` (append a `form pane` group)

**Interfaces:**
- Consumes: `MoloBrandLockup`, `MoloPillButton`, `MoloTextField`, `MoloCheckRow`, `MoloIcon`, `MoloGlyphs.eye`, `signInGreetingForHour`, `SignInHeroPane`, `MoloAuthShellLayout.signInHeroWidth`, `sessionPersistenceChoosableProvider`, `AuthViewModel.signInWithEmailAndPassword(persistSession:)`, and the new strings from Task 9.
- Produces: the re-traced screen. **Keys that must survive**, because other test files depend on them: `Key('sign_in_form')`, `Key('email_field')`, `Key('password_field')`, `Key('sign_in_button')`, `Key('create_account_link')`, `Key('google_sign_in_button')`, `Key('preview_banner')`, `SignInHeroPane.paneKey`. New: `Key('microsoft_sign_in_button')`, `Key('remember_me_row')`.

Traced values:

| Element | Value |
|---|---|
| Pane padding | 28 top, 32 sides, 40 bottom |
| Form column | 384 max width, vertically centred |
| Group gap | 26 |
| Header row | label and pill right-aligned, gap 10; on compact the lockup takes the left and the label drops |
| Kicker | 12px, uppercase, tracking 0.08em, `secondaryText` |
| Heading | 34px, weight 500, tracking -0.025em (-0.85), height 1.12 |
| Blurb | 15px, height 1.55, `secondaryText` |
| Field gap | 16 |
| Actions gap | 18 |
| Primary | 52 high, radius 15 (from the theme) |
| Divider | 12px `secondaryText` label, gap 14, 1px `border` rules |
| Provider grid | two equal columns, gap 10, 46 high, radius 14, `border` outline, 14px medium |
| Legal | 12px, height 1.6, `secondaryText`, left aligned |
| Reveal toggle | 36 visual square at radius 10, `pulseTint` on hover, 18px eye |

The kicker, the divider label and the legal footer take `secondaryText` rather than the baseline's `#9A858D`: at 12px they are ordinary text, and `#9A858D` is 3.30:1 on the warm canvas where WCAG 1.4.3 asks for 4.5:1. This plan's deviation 1.

- [ ] **Step 1: Write the failing test**

This group pumps the real screen, so it needs the preview overrides the existing view test already sets up. Those helpers are private to `sign_in_view_test.dart` today; lift them into a file both tests import.

Create `test/widget/core/auth/sign_in_test_host.dart`. Move `_setViewport`, `_pumpPreviewApp`, `_FinishedSession` and `_semanticsLabelsContaining` out of `test/widget/core/auth/sign_in_view_test.dart` verbatim, dropping the leading underscore from each name, and add one override to the `ProviderScope`:

```dart
        sessionPersistenceChoosableProvider.overrideWithValue(
          persistenceChoosable,
        ),
```

so the host's signature becomes:

```dart
Future<void> pumpPreviewSignIn(
  WidgetTester tester, {
  bool finishedSetup = false,
  bool persistenceChoosable = false,
}) async { /* the body that was _pumpPreviewApp, plus the override above */ }

Future<void> setViewport(WidgetTester tester, Size size) async { /* was _setViewport */ }

List<String> semanticsLabelsContaining(WidgetTester tester, String needle) { /* was _semanticsLabelsContaining */ }
```

The default is `false`, which is what the test host actually is: not the web. Then append to `test/widget/core/auth/sign_in_fidelity_test.dart`, inside `main()`:

```dart
  group('form pane', () {
    testWidgets('the form column is capped at 384', (tester) async {
      await setViewport(tester, const Size(1440, 950));
      await pumpPreviewSignIn(tester);
      expect(
        tester.getSize(find.byKey(const Key('sign_in_form'))).width,
        384,
      );
    });

    testWidgets('the heading is 34px at the design tracking', (tester) async {
      await setViewport(tester, const Size(1440, 950));
      await pumpPreviewSignIn(tester);
      final heading = tester.widget<Text>(find.text('Welcome back'));
      expect(heading.style?.fontSize, 34);
      expect(heading.style?.height, 1.12);
      expect(heading.style?.letterSpacing, closeTo(-0.85, 0.001));
    });

    testWidgets('a time-of-day kicker sits above it, in a readable colour', (
      tester,
    ) async {
      await setViewport(tester, const Size(1440, 950));
      await pumpPreviewSignIn(tester);
      final kicker = tester.widget<Text>(
        find.byKey(const Key('sign_in_kicker')),
      );
      expect(kicker.style?.fontSize, 12);
      expect(kicker.style?.color, MoloColours.secondaryText);
      expect(kicker.style?.letterSpacing, closeTo(0.96, 0.001));
      expect(kicker.data, isIn(<String>[
        'GOOD MORNING',
        'GOOD AFTERNOON',
        'GOOD EVENING',
      ]));
    });

    testWidgets('create an account moves to the top of the pane', (
      tester,
    ) async {
      await setViewport(tester, const Size(1440, 950));
      await pumpPreviewSignIn(tester);
      final pill = tester.getRect(find.byKey(const Key('create_account_link')));
      final heading = tester.getRect(find.text('Welcome back'));
      expect(pill.top, lessThan(heading.top));
      expect(find.text('New to Molo?'), findsOneWidget);
    });

    testWidgets('on compact the lockup takes the left and the label drops', (
      tester,
    ) async {
      await setViewport(tester, const Size(390, 900));
      await pumpPreviewSignIn(tester);
      expect(find.text('New to Molo?'), findsNothing);
      expect(find.byKey(const Key('create_account_link')), findsOneWidget);
      expect(find.text('molo'), findsOneWidget);
    });

    testWidgets('forgot password sits on the password label row', (
      tester,
    ) async {
      await setViewport(tester, const Size(1440, 950));
      await pumpPreviewSignIn(tester);
      final link = tester.getRect(find.text('Forgot password?'));
      final field = tester.getRect(find.byKey(const Key('password_field')));
      expect(link.bottom, lessThan(field.top));
      expect(link.center.dx, greaterThan(field.center.dx));
    });

    testWidgets('both providers are offered, 46 high and disabled', (
      tester,
    ) async {
      await setViewport(tester, const Size(1440, 950));
      await pumpPreviewSignIn(tester);
      for (final key in const [
        Key('microsoft_sign_in_button'),
        Key('google_sign_in_button'),
      ]) {
        final button = tester.widget<OutlinedButton>(find.byKey(key));
        expect(button.onPressed, isNull);
        expect(tester.getSize(find.byKey(key)).height, 46);
      }
      final microsoft = tester.getRect(
        find.byKey(const Key('microsoft_sign_in_button')),
      );
      final google = tester.getRect(
        find.byKey(const Key('google_sign_in_button')),
      );
      expect(google.left - microsoft.right, closeTo(10, 0.5));
      expect(microsoft.width, closeTo(google.width, 0.5));
    });

    testWidgets('each disabled provider names its reason once', (tester) async {
      final semantics = tester.ensureSemantics();
      await setViewport(tester, const Size(390, 900));
      await pumpPreviewSignIn(tester);
      expect(
        find.bySemanticsLabel('Microsoft sign-in is coming soon'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Google sign-in is coming soon'),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('the legal footer says Molo never signs in to eFiling', (
      tester,
    ) async {
      await setViewport(tester, const Size(1440, 950));
      await pumpPreviewSignIn(tester);
      expect(
        find.textContaining(
          'Molo never signs in to eFiling',
          findRichText: true,
        ),
        findsOneWidget,
      );
    });

    testWidgets('the reveal toggle keeps a 48 tap target', (tester) async {
      await setViewport(tester, const Size(1440, 950));
      await pumpPreviewSignIn(tester);
      final size = tester.getSize(find.byType(IconButton));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });

  group('remember me', () {
    testWidgets('is offered where the platform can honour it', (tester) async {
      await setViewport(tester, const Size(1440, 950));
      await pumpPreviewSignIn(tester, persistenceChoosable: true);
      expect(find.byKey(const Key('remember_me_row')), findsOneWidget);
      expect(find.text('Keep me signed in on this device'), findsOneWidget);
    });

    testWidgets('is absent where it would be a promise nothing keeps', (
      tester,
    ) async {
      await setViewport(tester, const Size(1440, 950));
      await pumpPreviewSignIn(tester);
      expect(find.byKey(const Key('remember_me_row')), findsNothing);
    });

    testWidgets('starts checked, as the design draws it', (tester) async {
      final semantics = tester.ensureSemantics();
      await setViewport(tester, const Size(1440, 950));
      await pumpPreviewSignIn(tester, persistenceChoosable: true);
      final node = tester.getSemantics(
        find.byKey(const Key('remember_me_row')),
      );
      expect(node.hasFlag(SemanticsFlag.isChecked), isTrue);
      semantics.dispose();
    });

    testWidgets('unchecking it is what reaches the auth layer', (tester) async {
      await setViewport(tester, const Size(1440, 950));
      await pumpPreviewSignIn(tester, persistenceChoosable: true);
      await tester.tap(find.byKey(const Key('remember_me_row')));
      await tester.pump();

      final semantics = tester.ensureSemantics();
      final node = tester.getSemantics(
        find.byKey(const Key('remember_me_row')),
      );
      expect(node.hasFlag(SemanticsFlag.isChecked), isFalse);
      semantics.dispose();
    });
  });

  group('keyboard order', () {
    // Flutter's default traversal reads top to bottom, then left to right, so
    // asserting the geometry is asserting the tab order. The design moved the
    // offer to create an account to the top and recovery onto the label row,
    // both of which change where the caret goes next.
    testWidgets('every control is reached in the order it is drawn', (
      tester,
    ) async {
      await setViewport(tester, const Size(1440, 950));
      await pumpPreviewSignIn(tester, persistenceChoosable: true);

      final tops = <String, double>{
        for (final entry in <String, Finder>{
          'create account': find.byKey(const Key('create_account_link')),
          'email': find.byKey(const Key('email_field')),
          'password': find.byKey(const Key('password_field')),
          'remember me': find.byKey(const Key('remember_me_row')),
          'sign in': find.byKey(const Key('sign_in_button')),
          'microsoft': find.byKey(const Key('microsoft_sign_in_button')),
        }.entries)
          entry.key: tester.getRect(entry.value).top,
      };

      final order = tops.keys.toList();
      for (var i = 1; i < order.length; i++) {
        expect(
          tops[order[i]],
          greaterThan(tops[order[i - 1]]!),
          reason: '${order[i]} must come after ${order[i - 1]}',
        );
      }

      // Recovery belongs to the password's label row, so it is reached before
      // the field it recovers rather than after it.
      expect(
        tester.getRect(find.text('Forgot password?')).top,
        lessThan(tops['password']),
      );
      // The two providers share a row, so neither precedes the other
      // vertically; left to right is what separates them.
      expect(
        tester.getRect(find.byKey(const Key('google_sign_in_button'))).left,
        greaterThan(
          tester.getRect(find.byKey(const Key('microsoft_sign_in_button'))).left,
        ),
      );
    });

    testWidgets('focus is visible on the primary action without a pointer', (
      tester,
    ) async {
      await setViewport(tester, const Size(1440, 950));
      await pumpPreviewSignIn(tester);

      final button = tester.widget<FilledButton>(
        find.byKey(const Key('sign_in_button')),
      );
      expect(button.focusNode?.hasFocus ?? false, isFalse);

      await tester.tap(find.byKey(const Key('email_field')));
      await tester.pump();
      expect(primaryFocus?.context, isNotNull);
      // A focused field must not be styled as a hovered one: the theme's
      // focused border is 2px pulseText, and hover only tints the fill.
      final theme = Theme.of(tester.element(find.byType(FilledButton)));
      final focused = theme.inputDecorationTheme.focusedBorder!;
      expect(focused.borderSide.width, 2);
      expect(focused.borderSide.color, MoloColours.pulseText);
    });
  });
```

Imports this group needs: `package:flutter/semantics.dart`, `package:molobuddy_app/app/design_system/colour/molo_colours.dart`, and the new host helper.

The kicker's tracking is `0.08 x 12 = 0.96`.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/core/auth/sign_in_fidelity_test.dart`
Expected: FAIL — the kicker key, both provider keys and the remember row do not exist, and the heading is 32px from `headlineMedium`.

- [ ] **Step 3: Rewrite the view**

Replace `lib/core/auth/ui/views/sign_in/sign_in_view.dart`. Keep, unchanged: `_SignInViewState`'s controllers and `_submit`/`_togglePassword`, `_ConfigurationBanner`, `_PreviewNotice`, `_AuthErrorBanner`. Delete: `_BrandStoryPanel`, `_Orb`, `_StoryPoint`, `_GoogleMark`, and `_methodById` with its `auth_method_descriptor.dart` import — the buttons no longer consult the catalogue, per spec section 4.4.

`_SignInViewState` gains the remember-me value and passes it down:

```dart
class _SignInViewState extends ConsumerState<SignInView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;

  /// The design draws this checked. Someone who is never shown the control
  /// gets the same answer, which is also what Android and iOS do regardless.
  bool _persistSession = true;

  /// Field validation belongs to this form instance, not the shared auth
  /// session, so a returning visitor never arrives to errors they did not cause.
  bool _submitted = false;
```

and in `build`, the layout branch becomes:

```dart
              final windowClass = moloWindowClassFor(constraints.maxWidth);
              final showHero =
                  windowClass == MoloWindowClass.expanded ||
                  windowClass == MoloWindowClass.large ||
                  windowClass == MoloWindowClass.extraLarge;
              final pane = _SignInPane(
                viewState: viewState,
                initialising: authState is AsyncLoading,
                environment: environment,
                emailController: _emailController,
                passwordController: _passwordController,
                passwordFocusNode: _passwordFocusNode,
                obscurePassword: _obscurePassword,
                onTogglePassword: _togglePassword,
                onSubmit: _submit,
                showValidation: _submitted,
                persistSession: _persistSession,
                onPersistSessionChanged: _setPersistSession,
                offerPersistence: ref.watch(
                  sessionPersistenceChoosableProvider,
                ),
                showWordmark: !showHero,
              );
              if (!showHero) {
                return pane;
              }
              return Row(
                children: [
                  SizedBox(
                    width: MoloAuthShellLayout.signInHeroWidth(
                      constraints.maxWidth,
                    ),
                    child: const SignInHeroPane(),
                  ),
                  Expanded(child: pane),
                ],
              );
```

with:

```dart
  void _setPersistSession(bool value) {
    setState(() => _persistSession = value);
  }
```

and `_submit` passing the choice on:

```dart
  void _submit() {
    setState(() => _submitted = true);
    _passwordFocusNode.unfocus();
    unawaited(
      ref
          .read(authViewModelProvider.notifier)
          .signInWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
            persistSession: _persistSession,
          ),
    );
  }
```

`_SignInPane` takes the three new fields and rebuilds its `build` as:

```dart
  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    final isBusy = initialising || viewState.isBusy;

    return ColoredBox(
      color: MoloColours.warmCanvas,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
            child: Column(
              children: [
                _HeaderRow(
                  showWordmark: showWordmark,
                  onCreateAccount: isBusy
                      ? null
                      : () => const RegistrationRoute().go(context),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 384),
                        child: AutofillGroup(
                          child: Column(
                            key: const Key('sign_in_form'),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (environment.isPreview) ...[
                                _PreviewNotice(
                                  key: const Key('preview_banner'),
                                  message: localisations.previewBanner,
                                ),
                                const SizedBox(height: _groupGap),
                              ] else if (!environment
                                  .canAttemptAuthentication) ...[
                                _ConfigurationBanner(
                                  message: localisations.configurationBanner,
                                ),
                                const SizedBox(height: _groupGap),
                              ],
                              _HeadingGroup(),
                              const SizedBox(height: _groupGap),
                              if (viewState.failure != null) ...[
                                _AuthErrorBanner(failure: viewState.failure!),
                                const SizedBox(height: _groupGap),
                              ],
                              _FieldsGroup(
                                localisations: localisations,
                                viewState: viewState,
                                isBusy: isBusy,
                                emailController: emailController,
                                passwordController: passwordController,
                                passwordFocusNode: passwordFocusNode,
                                obscurePassword: obscurePassword,
                                onTogglePassword: onTogglePassword,
                                onSubmit: onSubmit,
                                showValidation: showValidation,
                                offerPersistence: offerPersistence,
                                persistSession: persistSession,
                                onPersistSessionChanged:
                                    onPersistSessionChanged,
                              ),
                              const SizedBox(height: _groupGap),
                              _ActionsGroup(
                                isBusy: isBusy,
                                canAttempt:
                                    environment.canAttemptAuthentication,
                                onSubmit: onSubmit,
                              ),
                              const SizedBox(height: _groupGap),
                              _LegalFooter(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (initialising)
            const Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }
```

with `static const _groupGap = 26.0;` on the class, and these five private widgets in the same file:

```dart
/// The pane's top row: the wordmark where the hero is absent, then the offer to
/// create an account, which the design moves here from the bottom of the form.
class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.showWordmark, required this.onCreateAccount});

  final bool showWordmark;
  final VoidCallback? onCreateAccount;

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    return Row(
      children: [
        if (showWordmark) const MoloBrandLockup(compact: true),
        const Spacer(),
        // The label is context for the pill, not an instruction, so the narrow
        // layout keeps the part that acts and drops the part that explains.
        if (!showWordmark) ...[
          Text(
            localisations.newToMolo,
            style: const TextStyle(
              fontSize: 13,
              letterSpacing: 0,
              height: MoloTypography.normalLineHeight,
              color: MoloColours.secondaryText,
            ),
          ),
          const SizedBox(width: 10),
        ],
        MoloPillButton(
          key: const Key('create_account_link'),
          label: localisations.createAccount,
          onPressed: onCreateAccount,
        ),
      ],
    );
  }
}

class _HeadingGroup extends StatelessWidget {
  const _HeadingGroup();

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    final greeting = switch (signInGreetingForHour(DateTime.now().hour)) {
      SignInGreeting.morning => localisations.greetingMorning,
      SignInGreeting.afternoon => localisations.greetingAfternoon,
      SignInGreeting.evening => localisations.greetingEvening,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          key: const Key('sign_in_kicker'),
          greeting.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            // The design opens this label to 0.08em, wider than the workspace
            // kicker's 0.06em.
            letterSpacing: MoloTypography.trackingEm(0.08, 12),
            height: MoloTypography.normalLineHeight,
            // Not the baseline's #9A858D: at 12px this is ordinary text, and
            // that colour is 3.30:1 on this ground where 1.4.3 wants 4.5:1.
            color: MoloColours.secondaryText,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          header: true,
          child: Text(
            localisations.welcomeBack,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w500,
              height: 1.12,
              letterSpacing: MoloTypography.trackingEm(-0.025, 34),
              color: MoloColours.moloPlum,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          localisations.signInSubtitle,
          style: const TextStyle(
            fontSize: 15,
            height: 1.55,
            letterSpacing: 0,
            color: MoloColours.secondaryText,
          ),
        ),
      ],
    );
  }
}
```

`_FieldsGroup` takes the parameters listed in the `build` above and renders:

```dart
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MoloTextField(
          label: localisations.workEmailLabel,
          fieldKey: const Key('email_field'),
          controller: emailController,
          enabled: !isBusy,
          hintText: localisations.emailHint,
          errorText: showValidation && viewState.emailInvalid
              ? localisations.invalidEmail
              : null,
          autofillHints: const [AutofillHints.email],
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          onSubmitted: (_) => passwordFocusNode.requestFocus(),
        ),
        const SizedBox(height: 16),
        MoloTextField(
          label: localisations.passwordLabel,
          fieldKey: const Key('password_field'),
          controller: passwordController,
          focusNode: passwordFocusNode,
          enabled: !isBusy,
          obscureText: obscurePassword,
          hintText: localisations.passwordHint,
          errorText: showValidation && viewState.passwordTooShort
              ? localisations.passwordTooShort
              : null,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => isBusy ? null : onSubmit(),
          // The design moves recovery onto the label row, where it reads as a
          // property of the password rather than as a second action under it.
          trailing: TextButton(
            onPressed: isBusy
                ? null
                : () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(localisations.forgotPasswordComingSoon),
                    ),
                  ),
            child: Text(localisations.forgotPassword),
          ),
          suffix: IconButton(
            tooltip: obscurePassword
                ? localisations.showPassword
                : localisations.hidePassword,
            onPressed: onTogglePassword,
            // The design draws one eye and changes only the control's name, so
            // what the state is, is carried by the tooltip.
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
        if (offerPersistence) ...[
          const SizedBox(height: 16),
          MoloCheckRow(
            key: const Key('remember_me_row'),
            label: Text(localisations.keepMeSignedIn),
            semanticLabel: localisations.keepMeSignedIn,
            value: persistSession,
            enabled: !isBusy,
            onChanged: onPersistSessionChanged,
          ),
        ],
      ],
    );
```

`_ActionsGroup`:

```dart
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          key: const Key('sign_in_button'),
          onPressed: isBusy || !canAttempt ? null : onSubmit,
          child: isBusy
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: MoloColours.surface,
                      ),
                    ),
                    const SizedBox(width: MoloSpacing.sm),
                    Text(localisations.signingIn),
                  ],
                )
              : Text(localisations.signIn),
        ),
        const SizedBox(height: 18),
        _OrDivider(label: localisations.orDividerLabel),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _ProviderButton(
                buttonKey: const Key('microsoft_sign_in_button'),
                label: localisations.microsoftLabel,
                comingSoonHint: localisations.microsoftComingSoonHint,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ProviderButton(
                buttonKey: const Key('google_sign_in_button'),
                label: localisations.googleLabel,
                comingSoonHint: localisations.googleComingSoonHint,
              ),
            ),
          ],
        ),
      ],
    );
```

`_ProviderButton`:

```dart
/// A federated provider the design offers and the application cannot yet
/// honour.
///
/// Declared by the view rather than read from the provider catalogue: both are
/// permanently disabled here, and the work that makes either one real owns
/// reconnecting them. The 46-high cell has no room for a "Coming soon" pill, so
/// the reason lives in the accessible name.
///
/// The outline is the quiet `border` the design draws. A disabled control is
/// exempt from WCAG 1.4.11, and these two never enable.
class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.buttonKey,
    required this.label,
    required this.comingSoonHint,
  });

  final Key buttonKey;
  final String label;
  final String comingSoonHint;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: comingSoonHint,
      button: true,
      enabled: false,
      excludeSemantics: true,
      child: OutlinedButton(
        key: buttonKey,
        onPressed: null,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(46),
          side: const BorderSide(color: MoloColours.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MoloSpacing.controlRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
            height: MoloTypography.normalLineHeight,
          ),
        ),
        child: Text(label, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
```

`_OrDivider` keeps its shape but takes the design's metrics:

```dart
class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(height: 1, color: MoloColours.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              letterSpacing: 0,
              height: MoloTypography.normalLineHeight,
              // Not #9A858D: 3.30:1 on this ground, and this is text.
              color: MoloColours.secondaryText,
            ),
          ),
        ),
        const Expanded(child: Divider(height: 1, color: MoloColours.border)),
      ],
    );
  }
}
```

`_LegalFooter` is today's `AuthLegalLinksText` call with the design's alignment and size:

```dart
    return AuthLegalLinksText(
      label: localisations.termsNotice(
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
      // The design left-aligns this, where the retired composition centred it.
      textAlign: TextAlign.start,
      style: const TextStyle(
        fontSize: 12,
        height: 1.6,
        letterSpacing: 0,
        color: MoloColours.secondaryText,
      ),
    );
```

- [ ] **Step 4: Run the fidelity tests**

Run: `flutter test test/widget/core/auth/sign_in_fidelity_test.dart`
Expected: PASS. Two likely adjustments: the `sign_in_form` width is 384 only where the pane is wider than 384 plus 64 of padding, so keep that test at 1440; and if the reveal toggle reports 36 rather than 48, add `tapTargetSize: MaterialTapTargetSize.padded` to its `IconButton.styleFrom`.

- [ ] **Step 5: Confirm the retired strings are gone**

Run: `grep -rn "brandStory\|orContinueWith\|continueWithGoogle\|localisations.comingSoon\|localisations.emailLabel\|_methodById\|auth_method_descriptor" lib`
Expected: no output. This is Task 9 step 9's gate, now satisfied.

- [ ] **Step 6: Analyse and format**

Run: `flutter analyze && dart format .`
Expected: no issues, no deprecation diagnostics.

- [ ] **Step 7: Commit**

```bash
git add lib/core/auth/ui/views/sign_in/sign_in_view.dart test/widget/core/auth/sign_in_fidelity_test.dart test/widget/core/auth/sign_in_test_host.dart
git commit -m "feat: re-trace the sign-in form from the design baseline"
```

---

### Task 12: Move the existing tests, verify in a browser, update the visual system

**Files:**
- Modify: `test/widget/core/auth/sign_in_view_test.dart`
- Modify: `docs/app_design/visual_design.md` (section 5, the sign-in paragraphs only)

**Interfaces:**
- Consumes: everything the previous eleven tasks produced.
- Produces: a green suite and a design document that describes what ships.

- [ ] **Step 1: Retarget the six tests the redesign moves**

In `test/widget/core/auth/sign_in_view_test.dart`, switch the private helpers to the shared `sign_in_test_host.dart` from Task 11, then:

1. `'compact layout shows the form and disabled Google stub'` → rename to `'compact layout shows the form and both disabled providers'`. Replace `expect(find.text('Coming soon'), findsOneWidget)` with a check on both provider buttons being disabled; the "Coming soon" pill is gone, and Task 11 already covers the accessible names.
2. `'expanded layout adds a bounded brand story panel'` → rename to `'expanded layout adds the hero pane at the design width'`. Replace the 360 assertion with `closeTo(1280 * 0.44, 0.01)` and the `brandStoryTitle` text with `'Make serious work feel light.'`.
3. `'authentication pages keep a stable supporting pane edge'` → retarget. The invariant lives between the two wizard routes, which share one shell; sign-in's photographic hero is a different pane and the baseline draws it wider. Rewrite it to sign in with an unfinished session — as `'signing in with setup unfinished lands in the wizard'` already does — and compare `registration_progress_panel` on `/sign-up` with the same key on `/onboarding`.
4. `'hovering an invalid field keeps its label and icon readable'` → the bug this guarded cannot recur, because the label is no longer Material's and never takes an error colour. Rewrite it to assert what now matters: on hover over an invalid field the label stays `MoloColours.moloPlum`, the error message is present, and the eye glyph is painted in a colour that is not `MoloColours.surface`. Find the eye with `find.byType(MoloIcon)` rather than `find.byIcon`.
5. `'the coming-soon Google control announces once'` → extend to both providers, asserting one semantics label each.
6. Every other test in the file keeps working unchanged, because Task 11 preserved `sign_in_form`, `email_field`, `password_field`, `sign_in_button`, `create_account_link` and `preview_banner`.

- [ ] **Step 2: Run the whole suite**

Run: `flutter test`
Expected: green. `test/widget/app/signup_journey_test.dart` and `test/widget/app/onboarding_gate_test.dart` drive sign-in through the preserved keys and should need no change; if either fails on a position rather than a key, the design's number wins and the position is updated.

- [ ] **Step 3: Analyse and format**

Run: `flutter analyze && dart format --set-exit-if-changed .`
Expected: clean, and no formatting diff.

- [ ] **Step 4: Verify it in a real browser**

Restart the dev server rather than reloading the tab — the asset manifest changed, and a hot reload will not pick up a newly registered asset directory. Use the `molo-app` configuration in `.claude/launch.json` (port 4300).

Check, at each of three widths:
- 390 x 844: no hero, the lockup and the pill share the top row, the whole form scrolls, nothing clips.
- 800 x 900: still no hero (medium), the label reappears only above 840.
- 1440 x 950: the hero is 634 wide, the photograph is positioned at 62% and the promise sits over the dark bottom stop, the form column is 384 and vertically centred.

Then, at 1440, confirm: the remember-me row is present (this is Web, so `kIsWeb` is true), starts checked, and unchecking it and signing in still reaches the workspace. And at 200% browser text scale, that the hero text and the form both scroll rather than clip.

- [ ] **Step 5: Screenshot the three widths**

Capture each width and attach them to the review, so the fidelity claim is visible rather than asserted.

- [ ] **Step 6: Rewrite the visual system's sign-in paragraphs**

In `docs/app_design/visual_design.md` section 5, replace what describes the sign-in composition:
- The plum brand panel with controlled pulse moments becomes the 44% photographic hero with its scrim, and the retired orbs and story points are named as retired.
- Record that the offer to create an account sits at the top of the pane, that both federated providers are drawn and disabled, and that the remember-me row is present only where the platform can honour it.
- Add the three deviations that touch this screen — the 12px text colour, the pill's outline, and the disabled providers' exemption — so the next reader does not "fix" them back to the baseline.

Leave the wizard and onboarding paragraphs alone. They describe what still ships until the second half lands, and a document ahead of its code is worse than one behind it. Note at the top of the section which half is done.

- [ ] **Step 7: Commit**

```bash
git add test/widget/core/auth/sign_in_view_test.dart docs/app_design/visual_design.md
git commit -m "test: move the sign-in tests onto the re-traced screen"
```

- [ ] **Step 8: Open the pull request**

```bash
git push -u origin auth-sign-in-design-fidelity
gh pr create --title "Re-trace the sign-in screen from the design baseline" --body "$(cat <<'BODY'
## Summary
The sign-in screen is re-traced from the design baseline. It collects exactly what it collected before; the only new behaviour is the baseline's "Keep me signed in on this device", which chooses Firebase session persistence on Web.

## Deviations from the baseline
- 12px text moves off `#9A858D` (3.30:1) to `secondaryText` (5.94:1). WCAG 1.4.3.
- The switch pill's outline stays `controlBorder` in both states: it is the only thing identifying the control.
- Field and checkbox outlines stay `controlBorder`, per the design document's section 7.2.
- The hero ships as WebP at 63 KB rather than the baseline's 1.85 MB PNG.

## Verification
- `flutter analyze`, `dart format`, `flutter test` all clean.
- Checked in a browser at 390, 800 and 1440 wide, and at 200% text scale.

Spec: `docs/plans/2026-08-21-auth-onboarding-design-fidelity-design.md`
Plan: `docs/plans/2026-08-21-auth-sign-in-design-fidelity-plan.md`

🤖 Generated with [Claude Code](https://claude.com/claude-code)
BODY
)"
```

---

## What this plan deliberately leaves for the second half

So a reviewer does not read these as gaps:

- `MoloWizardShell`'s rail, the four step descriptors, and the `pulseOnDark` token that only the readiness figure uses.
- The ten option glyphs, the choice card, and the back arrow.
- The account step and the three onboarding steps.
- The wizard's own switch pill, which will replace the `TextButton` at `molo_wizard_shell.dart:133` with `MoloPillButton`, and its terms row, which will replace the Material `Checkbox` with `MoloCheckRow`.
- `docs/app_design/visual_design.md` section 5's wizard and onboarding paragraphs.
