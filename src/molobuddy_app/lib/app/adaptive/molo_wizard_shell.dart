import 'package:flutter/material.dart';
import 'package:molobuddy_app/app/adaptive/auth_shell_layout.dart';
import 'package:molobuddy_app/app/adaptive/window_class.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_wordmark.dart';
import 'package:molobuddy_app/app/design_system/motion/molo_motion.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';
import 'package:molobuddy_app/app/localisation/generated/app_localizations.dart';
import 'package:molobuddy_app/app/router/app_router.dart';

/// What the signup chrome needs to know, whichever half of the wizard is on
/// screen.
///
/// Signup spans two routes — the account step at `/sign-up` and the rest at
/// `/onboarding` — and each keeps its own state. This is the small shape they
/// both reduce to, so the progress panel does not need to know which half it
/// is decorating.
final class WizardProgress {
  const WizardProgress({
    required this.stepNumber,
    required this.readinessPercent,
    this.practiceName = '',
  });

  /// One-based, out of [totalSteps].
  final int stepNumber;

  final int readinessPercent;

  /// Empty until the user has named their practice.
  final String practiceName;

  static const totalSteps = 4;
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
    this.showWorkspaceSummary = false,
    super.key,
  });

  final String pageTitle;

  /// The step on screen. Its key drives the crossfade.
  final Widget child;

  /// Null on a screen with nothing left to progress through, which hides the
  /// panel, the bar and the summary together.
  final WizardProgress? progress;

  final bool showSignInLink;
  final bool showWorkspaceSummary;

  @override
  Widget build(BuildContext context) {
    return Title(
      title: pageTitle,
      color: MoloColours.moloPlum,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final windowClass = moloWindowClassFor(constraints.maxWidth);
              final showPanel =
                  windowClass == MoloWindowClass.expanded ||
                  windowClass == MoloWindowClass.large ||
                  windowClass == MoloWindowClass.extraLarge;
              final panelProgress = progress;
              if (showPanel && panelProgress != null) {
                return Row(
                  children: [
                    SizedBox(
                      width: MoloAuthShellLayout.supportingPaneWidth(
                        constraints.maxWidth,
                      ),
                      child: _WorkspacePreviewPanel(progress: panelProgress),
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
    final localisations = AppLocalizations.of(context);
    final progress = shell.progress;
    return ColoredBox(
      color: MoloColours.warmCanvas,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MoloSpacing.lg,
              MoloSpacing.md,
              MoloSpacing.lg,
              MoloSpacing.xs,
            ),
            child: Row(
              children: [
                if (showCompactHeader) const MoloWordmark(compact: true),
                const Spacer(),
                if (shell.showSignInLink) ...[
                  if (!showCompactHeader) ...[
                    Text(
                      localisations.alreadyHaveAccount,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: MoloSpacing.xs),
                  ],
                  TextButton(
                    key: const Key('registration_sign_in_link'),
                    onPressed: () => const SignInRoute().go(context),
                    child: Text(localisations.signIn),
                  ),
                ],
              ],
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
              padding: const EdgeInsets.fromLTRB(
                MoloSpacing.lg,
                MoloSpacing.lg,
                MoloSpacing.lg,
                MoloSpacing.xxl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
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

class _WorkspacePreviewPanel extends StatelessWidget {
  const _WorkspacePreviewPanel({required this.progress});

  final WizardProgress progress;

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    return ColoredBox(
      key: const Key('registration_progress_panel'),
      color: MoloColours.moloPlum,
      child: Padding(
        padding: const EdgeInsets.all(MoloSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const MoloWordmark(onDark: true),
                const Spacer(),
                Text(
                  localisations.registrationProgress(progress.stepNumber, 4),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: MoloColours.surface.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
            const Spacer(flex: 2),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: MoloColours.moloPulse,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: MoloSpacing.lg),
            Text(
              localisations.workspacePreviewTitle,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: MoloColours.surface.withValues(alpha: 0.66),
              ),
            ),
            const SizedBox(height: MoloSpacing.xs),
            Text(
              key: const Key('workspace_preview_practice_name'),
              progress.practiceName.isEmpty
                  ? localisations.workspacePreviewPlaceholder
                  : progress.practiceName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: MoloColours.surface),
            ),
            const SizedBox(height: MoloSpacing.sm),
            Text(
              localisations.workspacePreviewBody,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: MoloColours.surface.withValues(alpha: 0.64),
                height: 1.5,
              ),
            ),
            const Spacer(flex: 3),
            Row(
              children: [
                Expanded(
                  child: Text(
                    localisations.workspaceReadiness(progress.readinessPercent),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: MoloColours.surface,
                    ),
                  ),
                ),
                Text(
                  '${progress.readinessPercent}%',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: MoloColours.moloPulse,
                  ),
                ),
              ],
            ),
            const SizedBox(height: MoloSpacing.xs),
            LinearProgressIndicator(
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
              value: progress.readinessPercent / 100,
              color: MoloColours.moloPulse,
              backgroundColor: MoloColours.surface.withValues(alpha: 0.14),
            ),
            const SizedBox(height: MoloSpacing.lg),
            Text(
              localisations.brandPromise,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: MoloColours.surface),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactProgress extends StatelessWidget {
  const _CompactProgress({required this.progress});

  final WizardProgress progress;

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MoloSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            key: const Key('registration_compact_progress'),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
            value: progress.stepNumber / 4,
            color: MoloColours.pulseText,
            backgroundColor: MoloColours.pulseTint,
          ),
          const SizedBox(height: MoloSpacing.xs),
          Text(
            localisations.registrationProgress(progress.stepNumber, 4),
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: MoloColours.secondaryText),
          ),
        ],
      ),
    );
  }
}

class _CompactWorkspaceSummary extends StatelessWidget {
  const _CompactWorkspaceSummary({required this.progress});

  final WizardProgress progress;

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    final practiceName = progress.practiceName.isEmpty
        ? localisations.workspacePreviewPlaceholder
        : progress.practiceName;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MoloSpacing.lg,
        MoloSpacing.sm,
        MoloSpacing.lg,
        0,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: MoloColours.pulseTint,
          borderRadius: BorderRadius.circular(MoloSpacing.controlRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(MoloSpacing.sm),
          child: Row(
            children: [
              const SizedBox.square(
                dimension: 38,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: MoloColours.moloPlum,
                    borderRadius: BorderRadius.all(Radius.circular(11)),
                  ),
                  child: Icon(
                    Icons.space_dashboard_outlined,
                    size: 19,
                    color: MoloColours.moloPulse,
                  ),
                ),
              ),
              const SizedBox(width: MoloSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      practiceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Text(
                      localisations.workspaceReadiness(
                        progress.readinessPercent,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MoloColours.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${progress.readinessPercent}%',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: MoloColours.pulseText),
              ),
            ],
          ),
        ),
      ),
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
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: MoloColours.pulseText,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class MoloStepHeading extends StatelessWidget {
  const MoloStepHeading({required this.label, this.textAlign, super.key});

  final String label;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        label,
        textAlign: textAlign,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}

class MoloWizardBackButton extends StatelessWidget {
  const MoloWizardBackButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_back_rounded, size: 18),
        label: Text(localisations.backLabel),
      ),
    );
  }
}

class MoloChoiceCard extends StatefulWidget {
  const MoloChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  State<MoloChoiceCard> createState() => _MoloChoiceCardState();
}

class _MoloChoiceCardState extends State<MoloChoiceCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final radius = BorderRadius.circular(MoloSpacing.controlRadius);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? MoloColours.pulseTint : MoloColours.surface,
        borderRadius: radius,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: radius,
          // Focus paints its own outline below, so the default fill would
          // otherwise linger and read as a second selected card.
          focusColor: Colors.transparent,
          onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected || _focused
                    ? MoloColours.pulseText
                    : MoloColours.border,
                width: selected || _focused ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(MoloSpacing.md),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    color: selected
                        ? MoloColours.pulseText
                        : MoloColours.secondaryText,
                  ),
                  const SizedBox(width: MoloSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: MoloSpacing.xxs),
                        Text(
                          widget.subtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: MoloColours.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  widget.trailing ?? _SingleChoiceMark(selected: selected),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shape-based selection mark for single-choice cards, so the chosen option
/// stays distinguishable without relying on the tint alone.
class _SingleChoiceMark extends StatelessWidget {
  const _SingleChoiceMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Icon(
      selected ? Icons.check_circle_rounded : Icons.circle_outlined,
      color: selected ? MoloColours.pulseText : MoloColours.controlBorder,
    );
  }
}
