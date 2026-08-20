import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:molobuddy_app/app/adaptive/molo_wizard_shell.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';
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
        practiceName:
            state.draftPracticeName ?? state.answers.practiceName ?? '',
      ),
      showWorkspaceSummary: true,
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
        const SizedBox(height: MoloSpacing.md),
        MoloStepEyebrow(label: localisations.registrationStepPractice),
        const SizedBox(height: MoloSpacing.sm),
        MoloStepHeading(label: localisations.tellUsAboutPractice),
        const SizedBox(height: MoloSpacing.sm),
        Text(
          localisations.practiceSubtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: MoloColours.secondaryText),
        ),
        const SizedBox(height: MoloSpacing.xl),
        TextField(
          key: const Key('practice_name_field'),
          controller: _controller,
          onChanged: ref
              .read(onboardingViewModelProvider.notifier)
              .previewPracticeName,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: localisations.practiceNameLabel,
            hintText: localisations.practiceNameHint,
            errorText: _nameInvalid ? localisations.practiceNameRequired : null,
          ),
        ),
        const SizedBox(height: MoloSpacing.lg),
        Text(
          localisations.practiceSizeQuestion,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: MoloSpacing.sm),
        for (final choice in [
          (
            PracticeSize.solo,
            'practice_size_solo',
            Icons.person_outline_rounded,
            localisations.practiceSizeSolo,
            localisations.practiceSizeSoloBody,
          ),
          (
            PracticeSize.smallTeam,
            'practice_size_small',
            Icons.groups_2_outlined,
            localisations.practiceSizeSmall,
            localisations.practiceSizeSmallBody,
          ),
          (
            PracticeSize.growingTeam,
            'practice_size_growing',
            Icons.apartment_rounded,
            localisations.practiceSizeGrowing,
            localisations.practiceSizeGrowingBody,
          ),
        ]) ...[
          MoloChoiceCard(
            key: Key(choice.$2),
            icon: choice.$3,
            title: choice.$4,
            subtitle: choice.$5,
            selected: _size == choice.$1,
            onTap: () => setState(() => _size = choice.$1),
          ),
          const SizedBox(height: MoloSpacing.sm),
        ],
        const SizedBox(height: MoloSpacing.lg),
        DropdownButtonFormField<String>(
          key: const Key('practice_region_field'),
          initialValue: 'ZA',
          decoration: InputDecoration(
            labelText: localisations.primaryTaxRegionLabel,
            helperText: localisations.primaryTaxRegionHelper,
          ),
          items: [
            DropdownMenuItem(
              value: 'ZA',
              child: Text(localisations.southAfrica),
            ),
          ],
          onChanged: (_) {},
        ),
        const SizedBox(height: MoloSpacing.xl),
        if (state.failure != null) ...[
          _OnboardingFailureNotice(failure: state.failure!),
          const SizedBox(height: MoloSpacing.md),
        ],
        FilledButton(
          key: const Key('registration_practice_continue'),
          onPressed: state.busy ? null : _continue,
          child: Text(localisations.continueLabel),
        ),
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
        Icons.event_available_outlined,
        localisations.priorityDeadlines,
        localisations.priorityDeadlinesBody,
      ),
      (
        OnboardingPriority.documents,
        Icons.folder_copy_outlined,
        localisations.priorityDocuments,
        localisations.priorityDocumentsBody,
      ),
      (
        OnboardingPriority.teamwork,
        Icons.hub_outlined,
        localisations.priorityTeamwork,
        localisations.priorityTeamworkBody,
      ),
      (
        OnboardingPriority.visibility,
        Icons.auto_graph_rounded,
        localisations.priorityVisibility,
        localisations.priorityVisibilityBody,
      ),
    ];
    return Column(
      key: const Key('registration_priorities_step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MoloWizardBackButton(
          onPressed: ref.read(onboardingViewModelProvider.notifier).goBack,
        ),
        const SizedBox(height: MoloSpacing.md),
        MoloStepEyebrow(label: localisations.registrationStepPriorities),
        const SizedBox(height: MoloSpacing.sm),
        MoloStepHeading(label: localisations.whatShouldMoloHelpWith),
        const SizedBox(height: MoloSpacing.sm),
        Text(
          localisations.prioritiesSubtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: MoloColours.secondaryText),
        ),
        const SizedBox(height: MoloSpacing.xl),
        for (final choice in choices) ...[
          MoloChoiceCard(
            key: Key('priority_${choice.$1.name}'),
            icon: choice.$2,
            title: choice.$3,
            subtitle: choice.$4,
            selected: _chosen.contains(choice.$1),
            trailing: Checkbox(
              value: _chosen.contains(choice.$1),
              onChanged: (_) => _toggle(choice.$1),
            ),
            onTap: () => _toggle(choice.$1),
          ),
          const SizedBox(height: MoloSpacing.sm),
        ],
        if (_invalid) ...[
          const SizedBox(height: MoloSpacing.xs),
          Text(
            localisations.choosePriorityRequired,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: MoloColours.error),
          ),
        ],
        const SizedBox(height: MoloSpacing.lg),
        if (state.failure != null) ...[
          _OnboardingFailureNotice(failure: state.failure!),
          const SizedBox(height: MoloSpacing.md),
        ],
        FilledButton(
          key: const Key('complete_registration_preview'),
          onPressed: state.busy ? null : _continue,
          child: Text(localisations.continueLabel),
        ),
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
        MoloWizardBackButton(
          onPressed: ref.read(onboardingViewModelProvider.notifier).goBack,
        ),
        const SizedBox(height: MoloSpacing.md),
        MoloStepEyebrow(label: localisations.registrationStepStartingPoint),
        const SizedBox(height: MoloSpacing.sm),
        MoloStepHeading(label: localisations.putSomethingUsefulInside),
        const SizedBox(height: MoloSpacing.sm),
        Text(
          localisations.startingPointSubtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: MoloColours.secondaryText),
        ),
        const SizedBox(height: MoloSpacing.xl),
        for (final choice in [
          (
            WorkspaceStartingPoint.importClients,
            'starting_point_import',
            Icons.upload_file_outlined,
            localisations.startingPointImport,
            localisations.startingPointImportBody,
          ),
          (
            WorkspaceStartingPoint.addFirstClient,
            'starting_point_client',
            Icons.person_add_alt_1_outlined,
            localisations.startingPointClient,
            localisations.startingPointClientBody,
          ),
          (
            WorkspaceStartingPoint.sampleWorkspace,
            'starting_point_sample',
            Icons.explore_outlined,
            localisations.startingPointSample,
            localisations.startingPointSampleBody,
          ),
        ]) ...[
          MoloChoiceCard(
            key: Key(choice.$2),
            icon: choice.$3,
            title: choice.$4,
            subtitle: choice.$5,
            selected: _chosen == choice.$1,
            onTap: () => setState(() {
              _chosen = choice.$1;
              _invalid = false;
            }),
          ),
          const SizedBox(height: MoloSpacing.sm),
        ],
        if (_invalid) ...[
          const SizedBox(height: MoloSpacing.sm),
          Text(
            localisations.chooseStartingPointRequired,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: MoloColours.error),
          ),
        ],
        const SizedBox(height: MoloSpacing.xl),
        if (state.failure != null) ...[
          _OnboardingFailureNotice(failure: state.failure!),
          const SizedBox(height: MoloSpacing.md),
        ],
        FilledButton(
          key: const Key('finish_registration_preview'),
          onPressed: state.busy ? null : _finish,
          child: state.busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(localisations.buildMyWorkspace),
        ),
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
