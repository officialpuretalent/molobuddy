import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:molobuddy_app/app/adaptive/molo_wizard_shell.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_choice_card.dart';
import 'package:molobuddy_app/app/design_system/components/molo_field_label.dart';
import 'package:molobuddy_app/app/design_system/components/molo_text_field.dart';
import 'package:molobuddy_app/app/design_system/icons/molo_glyphs.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';
import 'package:molobuddy_app/app/design_system/typography/molo_typography.dart';
import 'package:molobuddy_app/app/localisation/generated/app_localizations.dart';
import 'package:molobuddy_app/app/router/app_router.dart';
import 'package:molobuddy_app/core/auth/ui/view_models/auth_view_model.dart';
import 'package:molobuddy_app/core/onboarding/data/models/onboarding_answers.dart';
import 'package:molobuddy_app/core/onboarding/data/models/onboarding_failure.dart';
import 'package:molobuddy_app/core/onboarding/ui/view_models/onboarding_view_model.dart';

/// The half of signup that happens after the account exists.
///
/// Every answer is saved before the wizard advances, so closing the tab loses
/// nothing and a returning user resumes at the step the server derived.
class OnboardingView extends ConsumerWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localisations = AppLocalizations.of(context);
    final async = ref.watch(onboardingViewModelProvider);

    ref.listen(onboardingViewModelProvider, (previous, next) {
      final done = switch (next) {
        AsyncData(:final value) => value.completed,
        _ => false,
      };
      if (done) {
        // The practice exists now, so the session must be re-read before the
        // workspace renders or the welcome screen shows its no-practice state
        // on the way in.
        unawaited(_enterWorkspace(ref, context));
      }
    });

    final state = switch (async) {
      AsyncData(:final value) => value,
      _ => null,
    };
    if (state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final loadFailure = state.loadFailure;
    if (loadFailure != null) {
      // Nothing was read, so there is nothing to ask. Rendering the first step
      // here would hide the answers a returning user already gave and send
      // their next save off without a version to match against.
      return MoloWizardShell(
        pageTitle: localisations.signUpPageTitle,
        child: _LoadFailureStep(failure: loadFailure, busy: state.busy),
      );
    }

    return MoloWizardShell(
      pageTitle: localisations.signUpPageTitle,
      progress: WizardProgress(
        stepNumber: _stepNumber(state.step),
        readinessPercent: _readiness(state.step),
        steps: moloWizardSteps(localisations),
        practiceName:
            state.draftPracticeName ?? state.answers.practiceName ?? '',
      ),
      child: switch (state.step) {
        OnboardingStep.practice => _PracticeStep(
          key: const ValueKey('practice'),
          state: state,
        ),
        OnboardingStep.priorities => _PrioritiesStep(
          key: const ValueKey('priorities'),
          state: state,
        ),
        // A resumed onboarding that has every answer lands here, with the
        // choice already made and the founding action ready.
        OnboardingStep.startingPoint ||
        OnboardingStep.readyToComplete => _StartingPointStep(
          key: const ValueKey('startingPoint'),
          state: state,
        ),
      },
    );
  }

  static Future<void> _enterWorkspace(
    WidgetRef ref,
    BuildContext context,
  ) async {
    await ref.read(authViewModelProvider.notifier).reloadSession();
    if (context.mounted) {
      const WelcomeRoute().go(context);
    }
  }

  static int _stepNumber(OnboardingStep step) => switch (step) {
    OnboardingStep.practice => 2,
    OnboardingStep.priorities => 3,
    OnboardingStep.startingPoint || OnboardingStep.readyToComplete => 4,
  };

  static int _readiness(OnboardingStep step) => switch (step) {
    OnboardingStep.practice => 32,
    OnboardingStep.priorities => 58,
    OnboardingStep.startingPoint || OnboardingStep.readyToComplete => 82,
  };
}

/// Shown in place of the wizard when the saved answers could not be read.
///
/// No progress panel: the step number and readiness figure are derived from
/// answers nobody has, and inventing them would be the same lie in smaller
/// print.
class _LoadFailureStep extends ConsumerWidget {
  const _LoadFailureStep({required this.failure, required this.busy});

  final OnboardingFailure failure;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localisations = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      key: const Key('onboarding_load_failure'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: MoloSpacing.md),
        Semantics(
          header: true,
          child: Text(
            localisations.onboardingLoadFailed,
            style: textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: MoloSpacing.md),
        _OnboardingFailureNotice(failure: failure),
        const SizedBox(height: MoloSpacing.xl),
        FilledButton(
          key: const Key('onboarding_load_retry'),
          onPressed: busy
              ? null
              : ref.read(onboardingViewModelProvider.notifier).reload,
          child: Text(localisations.retrySessionLoad),
        ),
      ],
    );
  }
}

class _PracticeStep extends ConsumerStatefulWidget {
  const _PracticeStep({required this.state, super.key});

  final OnboardingViewState state;

  @override
  ConsumerState<_PracticeStep> createState() => _PracticeStepState();
}

class _PracticeStepState extends ConsumerState<_PracticeStep> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.state.answers.practiceName ?? '',
  );
  late PracticeSize? _size = widget.state.answers.practiceSize;
  bool _nameInvalid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    final name = _controller.text.trim();
    if (name.length < 2) {
      setState(() => _nameInvalid = true);
      return;
    }
    setState(() => _nameInvalid = false);
    // The view model owns the busy flag and the failure, so nothing here needs
    // the future back.
    unawaited(
      ref
          .read(onboardingViewModelProvider.notifier)
          .saveAnswers(
            OnboardingAnswers(
              practiceName: name,
              practiceSize: _size ?? PracticeSize.solo,
            ),
          ),
    );
  }

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
          // The rail's workspace card shows the name as it is typed, before it
          // is saved.
          onChanged: ref
              .read(onboardingViewModelProvider.notifier)
              .previewPracticeName,
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
}

class _PrioritiesStep extends ConsumerStatefulWidget {
  const _PrioritiesStep({required this.state, super.key});

  final OnboardingViewState state;

  @override
  ConsumerState<_PrioritiesStep> createState() => _PrioritiesStepState();
}

class _PrioritiesStepState extends ConsumerState<_PrioritiesStep> {
  late final Set<OnboardingPriority> _chosen = {
    ...widget.state.answers.priorities,
  };
  bool _invalid = false;

  void _continue() {
    if (_chosen.isEmpty) {
      setState(() => _invalid = true);
      return;
    }
    setState(() => _invalid = false);
    unawaited(
      ref
          .read(onboardingViewModelProvider.notifier)
          .saveAnswers(OnboardingAnswers(priorities: _chosen)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    final state = widget.state;
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
  }

  void _toggle(OnboardingPriority priority) {
    setState(() {
      if (!_chosen.add(priority)) {
        _chosen.remove(priority);
      }
      _invalid = false;
    });
  }
}

class _StartingPointStep extends ConsumerStatefulWidget {
  const _StartingPointStep({required this.state, super.key});

  final OnboardingViewState state;

  @override
  ConsumerState<_StartingPointStep> createState() => _StartingPointStepState();
}

class _StartingPointStepState extends ConsumerState<_StartingPointStep> {
  late WorkspaceStartingPoint? _chosen = widget.state.answers.startingPoint;
  bool _invalid = false;

  Future<void> _finish() async {
    final chosen = _chosen;
    if (chosen == null) {
      setState(() => _invalid = true);
      return;
    }
    setState(() => _invalid = false);
    final model = ref.read(onboardingViewModelProvider.notifier);
    // Saved first, then founded. A retry after a failed founding calls only
    // completeOnboarding, because the answer is already stored and the version
    // has moved on.
    if (widget.state.step != OnboardingStep.readyToComplete) {
      await model.saveAnswers(OnboardingAnswers(startingPoint: chosen));
    }
    await model.completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    final state = widget.state;
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
  }
}

/// Says what went wrong in Molo's words, never the provider's.
class _OnboardingFailureNotice extends StatelessWidget {
  const _OnboardingFailureNotice({required this.failure});

  final OnboardingFailure failure;

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    // Exhaustive on purpose. A kind that fell through would leave the user
    // looking at a step that silently refused to advance.
    final message = switch (failure.kind) {
      OnboardingFailureKind.versionConflict =>
        localisations.onboardingChangedElsewhere,
      OnboardingFailureKind.answerRejected =>
        localisations.onboardingAnswerRejected,
      OnboardingFailureKind.incomplete => localisations.onboardingIncomplete,
      OnboardingFailureKind.sessionExpired => localisations.sessionExpired,
      OnboardingFailureKind.attestationRequired =>
        localisations.sessionAttestationRequired,
      OnboardingFailureKind.networkUnavailable =>
        localisations.networkUnavailable,
      OnboardingFailureKind.configurationMissing =>
        localisations.sessionUnavailable,
      OnboardingFailureKind.unexpected => localisations.unexpectedAuthError,
    };
    return DecoratedBox(
      key: const Key('onboarding_failure_notice'),
      decoration: BoxDecoration(
        color: MoloColours.errorTint,
        borderRadius: BorderRadius.circular(MoloSpacing.controlRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MoloSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: MoloColours.error),
            const SizedBox(width: MoloSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
