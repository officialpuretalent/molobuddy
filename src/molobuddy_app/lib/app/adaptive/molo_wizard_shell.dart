import 'package:flutter/material.dart';
import 'package:molobuddy_app/app/adaptive/auth_shell_layout.dart';
import 'package:molobuddy_app/app/adaptive/molo_wizard_rail.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_brand_lockup.dart';
import 'package:molobuddy_app/app/design_system/components/molo_pill_button.dart';
import 'package:molobuddy_app/app/design_system/icons/molo_glyphs.dart';
import 'package:molobuddy_app/app/design_system/motion/molo_motion.dart';
import 'package:molobuddy_app/app/design_system/typography/molo_typography.dart';
import 'package:molobuddy_app/app/localisation/generated/app_localizations.dart';
import 'package:molobuddy_app/app/router/app_router.dart';

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

  /// One descriptor per step, in order. The rail marks them from [stepNumber]
  /// rather than being told each one's state, so the two can never disagree.
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

/// The chrome both halves of signup share.
///
/// Extracted so the supporting pane edge stays identical across the whole
/// journey. A second copy would drift, and the seam would land exactly where
/// the user crosses from one route to the other.
class MoloWizardShell extends StatelessWidget {
  const MoloWizardShell({
    required this.pageTitle,
    required this.child,
    this.progress,
    this.showSignInLink = false,
    super.key,
  });

  final String pageTitle;

  /// The step on screen. Its key drives the crossfade.
  final Widget child;

  /// Null on a screen with nothing left to progress through, which hides the
  /// panel, the bar and the summary together.
  final WizardProgress? progress;

  final bool showSignInLink;

  @override
  Widget build(BuildContext context) {
    return Title(
      title: pageTitle,
      color: MoloColours.moloPlum,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showPanel = MoloAuthShellLayout.showsSupportingPane(
                constraints.maxWidth,
              );
              final panelProgress = progress;
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
              return _Pane(shell: this, showCompactHeader: true);
            },
          ),
        ),
      ),
    );
  }
}

class _Pane extends StatelessWidget {
  const _Pane({required this.shell, this.showCompactHeader = false});

  final MoloWizardShell shell;
  final bool showCompactHeader;

  @override
  Widget build(BuildContext context) {
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
}

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
    // The design words the offer the same at every width, so the label travels
    // with its pill rather than dropping when the wordmark appears beside it.
    final offer = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            // Two lines rather than one. The design's header has room for the
            // sentence beside the wordmark from about 430 up; a phone at 375
            // does not, and truncating it to "Already have an a..." says less
            // than wrapping it. The words stay the design's at every width;
            // only the number of lines they take moves.
            localisations.alreadyHaveAccount,
            maxLines: 2,
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
        Flexible(
          child: MoloPillButton(
            key: const Key('registration_sign_in_link'),
            label: localisations.signIn,
            onPressed: () => const SignInRoute().go(context),
          ),
        ),
      ],
    );

    return Row(
      // No spacer: a spacer is a tight flex child and would take a share of the
      // row the pill then could not have, truncating its label while the row
      // still had room.
      mainAxisAlignment: showWordmark
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.end,
      children: [
        if (showWordmark) const MoloBrandLockup(compact: true),
        if (showSignInOffer) Flexible(child: offer),
      ],
    );
  }
}

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

  /// Null on a step with nowhere to go back to.
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
        // Not the design's #9A858D, which is 3.30:1 on this ground. At 12px this
        // is ordinary text and 1.4.3 asks for 4.5:1.
        color: MoloColours.secondaryText,
      ),
    );
  }
}

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
    // MergeSemantics outside, so the hint and the button's own label and action
    // land on one node. The other way round leaves the hint on an empty parent
    // that a screen reader never reaches.
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
