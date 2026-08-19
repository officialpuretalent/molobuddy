import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:molobuddy_app/app/adaptive/auth_shell_layout.dart';
import 'package:molobuddy_app/app/adaptive/window_class.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_status_pill.dart';
import 'package:molobuddy_app/app/design_system/components/molo_wordmark.dart';
import 'package:molobuddy_app/app/design_system/motion/molo_motion.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';
import 'package:molobuddy_app/app/localisation/generated/app_localizations.dart';
import 'package:molobuddy_app/app/router/app_router.dart';
import 'package:molobuddy_app/core/auth/ui/view_models/registration_view_model.dart';
import 'package:molobuddy_app/core/auth/ui/widgets/auth_legal_links_text.dart';

class RegistrationView extends ConsumerStatefulWidget {
  const RegistrationView({super.key});

  @override
  ConsumerState<RegistrationView> createState() => _RegistrationViewState();
}

class _RegistrationViewState extends ConsumerState<RegistrationView> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _practiceController = TextEditingController();
  bool _obscurePassword = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _practiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    final state = ref.watch(registrationViewModelProvider);
    return Title(
      title: localisations.signUpPageTitle,
      color: MoloColours.moloPlum,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final windowClass = moloWindowClassFor(constraints.maxWidth);
              final showProgressPanel =
                  windowClass == MoloWindowClass.expanded ||
                  windowClass == MoloWindowClass.large ||
                  windowClass == MoloWindowClass.extraLarge;
              if (showProgressPanel) {
                return Row(
                  children: [
                    SizedBox(
                      width: MoloAuthShellLayout.supportingPaneWidth(
                        constraints.maxWidth,
                      ),
                      child: _WorkspacePreviewPanel(state: state),
                    ),
                    Expanded(
                      child: _RegistrationPane(
                        state: state,
                        nameController: _nameController,
                        emailController: _emailController,
                        passwordController: _passwordController,
                        practiceController: _practiceController,
                        obscurePassword: _obscurePassword,
                        acceptedTerms: _acceptedTerms,
                        onTogglePassword: _togglePassword,
                        onAcceptedTermsChanged: _setAcceptedTerms,
                      ),
                    ),
                  ],
                );
              }
              return _RegistrationPane(
                state: state,
                nameController: _nameController,
                emailController: _emailController,
                passwordController: _passwordController,
                practiceController: _practiceController,
                obscurePassword: _obscurePassword,
                acceptedTerms: _acceptedTerms,
                onTogglePassword: _togglePassword,
                onAcceptedTermsChanged: _setAcceptedTerms,
                showCompactHeader: true,
              );
            },
          ),
        ),
      ),
    );
  }

  void _togglePassword() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  void _setAcceptedTerms(bool? value) {
    setState(() => _acceptedTerms = value ?? false);
  }
}

class _RegistrationPane extends ConsumerWidget {
  const _RegistrationPane({
    required this.state,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.practiceController,
    required this.obscurePassword,
    required this.acceptedTerms,
    required this.onTogglePassword,
    required this.onAcceptedTermsChanged,
    this.showCompactHeader = false,
  });

  final RegistrationViewState state;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController practiceController;
  final bool obscurePassword;
  final bool acceptedTerms;
  final VoidCallback onTogglePassword;
  final ValueChanged<bool?> onAcceptedTermsChanged;
  final bool showCompactHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localisations = AppLocalizations.of(context);
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
                if (state.step != RegistrationStep.complete) ...[
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
          if (showCompactHeader && state.step != RegistrationStep.complete)
            _CompactProgress(state: state),
          if (showCompactHeader &&
              state.step != RegistrationStep.account &&
              state.step != RegistrationStep.complete)
            _CompactWorkspaceSummary(state: state),
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
                    child: switch (state.step) {
                      RegistrationStep.account => _AccountStep(
                        key: const ValueKey('account'),
                        state: state,
                        nameController: nameController,
                        emailController: emailController,
                        passwordController: passwordController,
                        obscurePassword: obscurePassword,
                        acceptedTerms: acceptedTerms,
                        onTogglePassword: onTogglePassword,
                        onAcceptedTermsChanged: onAcceptedTermsChanged,
                      ),
                      RegistrationStep.practice => _PracticeStep(
                        key: const ValueKey('practice'),
                        state: state,
                        practiceController: practiceController,
                      ),
                      RegistrationStep.priorities => _PrioritiesStep(
                        key: const ValueKey('priorities'),
                        state: state,
                      ),
                      RegistrationStep.startingPoint => _StartingPointStep(
                        key: const ValueKey('startingPoint'),
                        state: state,
                      ),
                      RegistrationStep.complete => _CompleteStep(
                        key: const ValueKey('complete'),
                        state: state,
                      ),
                    },
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

class _AccountStep extends ConsumerWidget {
  const _AccountStep({
    required this.state,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.acceptedTerms,
    required this.onTogglePassword,
    required this.onAcceptedTermsChanged,
    super.key,
  });

  final RegistrationViewState state;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool acceptedTerms;
  final VoidCallback onTogglePassword;
  final ValueChanged<bool?> onAcceptedTermsChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localisations = AppLocalizations.of(context);
    return AutofillGroup(
      child: Column(
        key: const Key('registration_account_step'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepEyebrow(label: localisations.registrationStepAccount),
          const SizedBox(height: MoloSpacing.sm),
          _StepHeading(label: localisations.createYourAccount),
          const SizedBox(height: MoloSpacing.sm),
          Text(
            localisations.createAccountSubtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: MoloColours.secondaryText),
          ),
          const SizedBox(height: MoloSpacing.xl),
          TextField(
            key: const Key('registration_name_field'),
            controller: nameController,
            autofillHints: const [AutofillHints.name],
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: localisations.fullNameLabel,
              errorText: state.nameInvalid
                  ? localisations.fullNameRequired
                  : null,
            ),
          ),
          const SizedBox(height: MoloSpacing.md),
          TextField(
            key: const Key('registration_email_field'),
            controller: emailController,
            autofillHints: const [AutofillHints.newUsername],
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: localisations.workEmailLabel,
              hintText: localisations.emailHint,
              errorText: state.emailInvalid ? localisations.invalidEmail : null,
            ),
          ),
          const SizedBox(height: MoloSpacing.md),
          TextField(
            key: const Key('registration_password_field'),
            controller: passwordController,
            autofillHints: const [AutofillHints.newPassword],
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: localisations.createPasswordLabel,
              helperText: localisations.passwordHelper,
              errorText: state.passwordTooShort
                  ? localisations.passwordTooShort
                  : null,
              suffixIcon: IconButton(
                tooltip: obscurePassword
                    ? localisations.showPassword
                    : localisations.hidePassword,
                onPressed: onTogglePassword,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: MoloSpacing.md),
          _TermsAgreement(
            value: acceptedTerms,
            hasError: state.termsNotAccepted,
            label: localisations.acceptTermsLabel(
              localisations.termsOfService,
              localisations.privacyPolicy,
            ),
            termsLabel: localisations.termsOfService,
            privacyLabel: localisations.privacyPolicy,
            errorLabel: localisations.acceptTermsRequired,
            onChanged: onAcceptedTermsChanged,
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
          const SizedBox(height: MoloSpacing.lg),
          FilledButton(
            key: const Key('registration_account_continue'),
            onPressed: () => ref
                .read(registrationViewModelProvider.notifier)
                .continueFromAccount(
                  displayName: nameController.text,
                  email: emailController.text,
                  password: passwordController.text,
                  acceptedTerms: acceptedTerms,
                ),
            child: Text(localisations.continueLabel),
          ),
          const SizedBox(height: MoloSpacing.md),
          Text(
            localisations.registrationPreviewNotice,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: MoloColours.secondaryText),
          ),
        ],
      ),
    );
  }
}

class _TermsAgreement extends StatelessWidget {
  const _TermsAgreement({
    required this.value,
    required this.hasError,
    required this.label,
    required this.termsLabel,
    required this.privacyLabel,
    required this.errorLabel,
    required this.onChanged,
    required this.onTermsPressed,
    required this.onPrivacyPressed,
  });

  final bool value;
  final bool hasError;
  final String label;
  final String termsLabel;
  final String privacyLabel;
  final String errorLabel;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onTermsPressed;
  final VoidCallback onPrivacyPressed;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              key: const Key('registration_terms_checkbox'),
              value: value,
              isError: hasError,
              onChanged: onChanged,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: MoloSpacing.xs),
                child: AuthLegalLinksText(
                  label: label,
                  termsLabel: termsLabel,
                  privacyLabel: privacyLabel,
                  onTermsPressed: onTermsPressed,
                  onPrivacyPressed: onPrivacyPressed,
                  style: defaultStyle,
                ),
              ),
            ),
          ],
        ),
        if (hasError)
          Padding(
            // Indent past the checkbox's tap target so the message lines up
            // with the sentence it belongs to.
            padding: const EdgeInsets.only(
              left: kMinInteractiveDimension,
              bottom: MoloSpacing.xs,
            ),
            child: Text(
              errorLabel,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: MoloColours.error),
            ),
          ),
      ],
    );
  }
}

class _PracticeStep extends ConsumerWidget {
  const _PracticeStep({
    required this.state,
    required this.practiceController,
    super.key,
  });

  final RegistrationViewState state;
  final TextEditingController practiceController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localisations = AppLocalizations.of(context);
    final viewModel = ref.read(registrationViewModelProvider.notifier);
    return Column(
      key: const Key('registration_practice_step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BackButton(onPressed: viewModel.goBack),
        const SizedBox(height: MoloSpacing.md),
        _StepEyebrow(label: localisations.registrationStepPractice),
        const SizedBox(height: MoloSpacing.sm),
        _StepHeading(label: localisations.tellUsAboutPractice),
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
          controller: practiceController,
          onChanged: viewModel.updatePracticeNamePreview,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: localisations.practiceNameLabel,
            hintText: localisations.practiceNameHint,
            errorText: state.practiceNameInvalid
                ? localisations.practiceNameRequired
                : null,
          ),
        ),
        const SizedBox(height: MoloSpacing.lg),
        Text(
          localisations.practiceSizeQuestion,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: MoloSpacing.sm),
        _ChoiceCard(
          key: const Key('practice_size_solo'),
          icon: Icons.person_outline_rounded,
          title: localisations.practiceSizeSolo,
          subtitle: localisations.practiceSizeSoloBody,
          selected: state.practiceSize == PracticeSize.solo,
          onTap: () => viewModel.selectPracticeSize(PracticeSize.solo),
        ),
        const SizedBox(height: MoloSpacing.sm),
        _ChoiceCard(
          key: const Key('practice_size_small'),
          icon: Icons.groups_2_outlined,
          title: localisations.practiceSizeSmall,
          subtitle: localisations.practiceSizeSmallBody,
          selected: state.practiceSize == PracticeSize.smallTeam,
          onTap: () => viewModel.selectPracticeSize(PracticeSize.smallTeam),
        ),
        const SizedBox(height: MoloSpacing.sm),
        _ChoiceCard(
          key: const Key('practice_size_growing'),
          icon: Icons.apartment_rounded,
          title: localisations.practiceSizeGrowing,
          subtitle: localisations.practiceSizeGrowingBody,
          selected: state.practiceSize == PracticeSize.growingTeam,
          onTap: () => viewModel.selectPracticeSize(PracticeSize.growingTeam),
        ),
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
        FilledButton(
          key: const Key('registration_practice_continue'),
          onPressed: () => viewModel.continueFromPractice(
            practiceName: practiceController.text,
          ),
          child: Text(localisations.continueLabel),
        ),
      ],
    );
  }
}

class _PrioritiesStep extends ConsumerWidget {
  const _PrioritiesStep({required this.state, super.key});

  final RegistrationViewState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localisations = AppLocalizations.of(context);
    final viewModel = ref.read(registrationViewModelProvider.notifier);
    final choices = [
      (
        RegistrationPriority.deadlines,
        Icons.event_available_outlined,
        localisations.priorityDeadlines,
        localisations.priorityDeadlinesBody,
      ),
      (
        RegistrationPriority.documents,
        Icons.folder_copy_outlined,
        localisations.priorityDocuments,
        localisations.priorityDocumentsBody,
      ),
      (
        RegistrationPriority.teamwork,
        Icons.hub_outlined,
        localisations.priorityTeamwork,
        localisations.priorityTeamworkBody,
      ),
      (
        RegistrationPriority.visibility,
        Icons.auto_graph_rounded,
        localisations.priorityVisibility,
        localisations.priorityVisibilityBody,
      ),
    ];
    return Column(
      key: const Key('registration_priorities_step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BackButton(onPressed: viewModel.goBack),
        const SizedBox(height: MoloSpacing.md),
        _StepEyebrow(label: localisations.registrationStepPriorities),
        const SizedBox(height: MoloSpacing.sm),
        _StepHeading(label: localisations.whatShouldMoloHelpWith),
        const SizedBox(height: MoloSpacing.sm),
        Text(
          localisations.prioritiesSubtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: MoloColours.secondaryText),
        ),
        const SizedBox(height: MoloSpacing.xl),
        for (final choice in choices) ...[
          _ChoiceCard(
            key: Key('priority_${choice.$1.name}'),
            icon: choice.$2,
            title: choice.$3,
            subtitle: choice.$4,
            selected: state.priorities.contains(choice.$1),
            trailing: Checkbox(
              value: state.priorities.contains(choice.$1),
              onChanged: (_) => viewModel.togglePriority(choice.$1),
            ),
            onTap: () => viewModel.togglePriority(choice.$1),
          ),
          const SizedBox(height: MoloSpacing.sm),
        ],
        if (state.prioritiesInvalid) ...[
          const SizedBox(height: MoloSpacing.xs),
          Text(
            localisations.choosePriorityRequired,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: MoloColours.error),
          ),
        ],
        const SizedBox(height: MoloSpacing.lg),
        FilledButton(
          key: const Key('complete_registration_preview'),
          onPressed: viewModel.continueFromPriorities,
          child: Text(localisations.continueLabel),
        ),
      ],
    );
  }
}

class _StartingPointStep extends ConsumerWidget {
  const _StartingPointStep({required this.state, super.key});

  final RegistrationViewState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localisations = AppLocalizations.of(context);
    final viewModel = ref.read(registrationViewModelProvider.notifier);
    return Column(
      key: const Key('registration_starting_point_step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BackButton(onPressed: viewModel.goBack),
        const SizedBox(height: MoloSpacing.md),
        _StepEyebrow(label: localisations.registrationStepStartingPoint),
        const SizedBox(height: MoloSpacing.sm),
        _StepHeading(label: localisations.putSomethingUsefulInside),
        const SizedBox(height: MoloSpacing.sm),
        Text(
          localisations.startingPointSubtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: MoloColours.secondaryText),
        ),
        const SizedBox(height: MoloSpacing.xl),
        _ChoiceCard(
          key: const Key('starting_point_import'),
          icon: Icons.upload_file_outlined,
          title: localisations.startingPointImport,
          subtitle: localisations.startingPointImportBody,
          selected: state.startingPoint == WorkspaceStartingPoint.importClients,
          onTap: () => viewModel.selectStartingPoint(
            WorkspaceStartingPoint.importClients,
          ),
        ),
        const SizedBox(height: MoloSpacing.sm),
        _ChoiceCard(
          key: const Key('starting_point_client'),
          icon: Icons.person_add_alt_1_outlined,
          title: localisations.startingPointClient,
          subtitle: localisations.startingPointClientBody,
          selected:
              state.startingPoint == WorkspaceStartingPoint.addFirstClient,
          onTap: () => viewModel.selectStartingPoint(
            WorkspaceStartingPoint.addFirstClient,
          ),
        ),
        const SizedBox(height: MoloSpacing.sm),
        _ChoiceCard(
          key: const Key('starting_point_sample'),
          icon: Icons.explore_outlined,
          title: localisations.startingPointSample,
          subtitle: localisations.startingPointSampleBody,
          selected:
              state.startingPoint == WorkspaceStartingPoint.sampleWorkspace,
          onTap: () => viewModel.selectStartingPoint(
            WorkspaceStartingPoint.sampleWorkspace,
          ),
        ),
        if (state.startingPointInvalid) ...[
          const SizedBox(height: MoloSpacing.sm),
          Text(
            localisations.chooseStartingPointRequired,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: MoloColours.error),
          ),
        ],
        const SizedBox(height: MoloSpacing.xl),
        FilledButton(
          key: const Key('finish_registration_preview'),
          onPressed: viewModel.completePreview,
          child: Text(localisations.buildMyWorkspace),
        ),
      ],
    );
  }
}

class _CompleteStep extends StatelessWidget {
  const _CompleteStep({required this.state, super.key});

  final RegistrationViewState state;

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    return Column(
      key: const Key('registration_complete_step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.center,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: MoloColours.moloPlum,
              shape: BoxShape.circle,
            ),
            child: const SizedBox.square(
              dimension: 72,
              child: Icon(
                Icons.done_rounded,
                size: 38,
                color: MoloColours.moloPulse,
              ),
            ),
          ),
        ),
        const SizedBox(height: MoloSpacing.xl),
        _StepHeading(
          label: localisations.registrationCompleteTitle(state.displayName),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: MoloSpacing.sm),
        Text(
          localisations.registrationCompleteBody(state.practiceName),
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: MoloColours.secondaryText),
        ),
        const SizedBox(height: MoloSpacing.xl),
        DecoratedBox(
          decoration: BoxDecoration(
            color: MoloColours.surface,
            borderRadius: BorderRadius.circular(MoloSpacing.cardRadius),
            border: Border.all(color: MoloColours.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(MoloSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MoloStatusPill(
                  label: localisations.previewModeLabel,
                  foreground: MoloColours.pulseText,
                  background: MoloColours.pulseTint,
                ),
                const SizedBox(height: MoloSpacing.md),
                Text(
                  state.practiceName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: MoloSpacing.xs),
                Text(
                  localisations.registrationCompleteSummary,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: MoloSpacing.xl),
        FilledButton(
          key: const Key('registration_return_to_sign_in'),
          onPressed: () => const SignInRoute().go(context),
          child: Text(localisations.continueToSignIn),
        ),
        const SizedBox(height: MoloSpacing.md),
        Text(
          localisations.noRegistrationDataSaved,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: MoloColours.secondaryText),
        ),
      ],
    );
  }
}

class _WorkspacePreviewPanel extends StatelessWidget {
  const _WorkspacePreviewPanel({required this.state});

  final RegistrationViewState state;

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
                  localisations.registrationProgress(
                    state.progressIndex + 1,
                    4,
                  ),
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
              state.practiceName.isEmpty
                  ? localisations.workspacePreviewPlaceholder
                  : state.practiceName,
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
                    localisations.workspaceReadiness(state.readinessPercent),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: MoloColours.surface,
                    ),
                  ),
                ),
                Text(
                  '${state.readinessPercent}%',
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
              value: state.readinessPercent / 100,
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
  const _CompactProgress({required this.state});

  final RegistrationViewState state;

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
            value: (state.progressIndex + 1) / 4,
            color: MoloColours.pulseText,
            backgroundColor: MoloColours.pulseTint,
          ),
          const SizedBox(height: MoloSpacing.xs),
          Text(
            localisations.registrationProgress(state.progressIndex + 1, 4),
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
  const _CompactWorkspaceSummary({required this.state});

  final RegistrationViewState state;

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    final practiceName = state.practiceName.isEmpty
        ? localisations.workspacePreviewPlaceholder
        : state.practiceName;
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
                      localisations.workspaceReadiness(state.readinessPercent),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MoloColours.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${state.readinessPercent}%',
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

class _StepEyebrow extends StatelessWidget {
  const _StepEyebrow({required this.label});

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

class _StepHeading extends StatelessWidget {
  const _StepHeading({required this.label, this.textAlign});

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

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

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

class _ChoiceCard extends StatefulWidget {
  const _ChoiceCard({
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
  State<_ChoiceCard> createState() => _ChoiceCardState();
}

class _ChoiceCardState extends State<_ChoiceCard> {
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
