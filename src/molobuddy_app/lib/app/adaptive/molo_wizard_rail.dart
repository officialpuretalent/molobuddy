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
      child: LayoutBuilder(
        // The rail pushes its workspace card to the bottom with a spacer, which
        // needs a bounded height to push into. On a short window the four step
        // rows plus the card are taller than that, so the column scrolls and
        // the spacer collapses rather than the whole rail clipping.
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
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
                            color: MoloColours.warmCanvas.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    for (
                      var step = 1;
                      step <= WizardProgress.totalSteps;
                      step++
                    ) ...[
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
            ),
          ),
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
      WizardStepState.current => (MoloColours.warmCanvas, MoloColours.moloPlum),
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
                // Tabular, so the figure does not shuffle sideways as it climbs
                // from 12 to 82.
                fontFeatures: [FontFeature.tabularFigures()],
                color: MoloColours.pulseOnDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
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
