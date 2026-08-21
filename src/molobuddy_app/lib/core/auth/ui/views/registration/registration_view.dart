import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:molobuddy_app/app/adaptive/molo_wizard_shell.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_check_row.dart';
import 'package:molobuddy_app/app/design_system/components/molo_field_label.dart';
import 'package:molobuddy_app/app/design_system/components/molo_text_field.dart';
import 'package:molobuddy_app/app/design_system/icons/molo_glyphs.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';
import 'package:molobuddy_app/app/design_system/typography/molo_typography.dart';
import 'package:molobuddy_app/app/localisation/generated/app_localizations.dart';
import 'package:molobuddy_app/app/router/app_router.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/ui/view_models/registration_view_model.dart';
import 'package:molobuddy_app/core/auth/ui/widgets/auth_legal_links_text.dart';

/// The account step of signup.
///
/// Creating the account signs the user in immediately, which is Firebase's
/// behaviour rather than a choice. Everything after this point is persisted
/// server-side and lives at `/onboarding`, so an interrupted signup resumes
/// instead of stranding an account.
class RegistrationView extends ConsumerStatefulWidget {
  const RegistrationView({super.key});

  @override
  ConsumerState<RegistrationView> createState() => _RegistrationViewState();
}

class _RegistrationViewState extends ConsumerState<RegistrationView> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
  final ValueChanged<bool> onAcceptedTermsChanged;

  /// Creates the account, then hands over to the resumable half of signup.
  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final created = await ref
        .read(registrationViewModelProvider.notifier)
        .createAccount(
          displayName: nameController.text,
          email: emailController.text,
          password: passwordController.text,
          acceptedTerms: acceptedTerms,
        );
    if (created && context.mounted) {
      const OnboardingRoute().go(context);
    }
  }

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
            // The two document names stay separate links: reading one must not
            // be the thing that grants consent.
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
          // rebuilds on every keystroke rather than only on submit.
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
              onPressed: () => unawaited(_submit(context, ref)),
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
}

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

/// Says why the provider refused, in Molo's words.
class _AccountFailureNotice extends StatelessWidget {
  const _AccountFailureNotice({required this.failure});

  final AuthFailure failure;

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    // Only the kinds no single field explains reach here; the rest are shown
    // on the field they are about.
    final message = switch (failure.kind) {
      AuthFailureKind.networkUnavailable => localisations.networkUnavailable,
      AuthFailureKind.providerUnavailable ||
      AuthFailureKind.configurationMissing => localisations.authUnavailable,
      AuthFailureKind.attestationRequired =>
        localisations.sessionAttestationRequired,
      _ => localisations.unexpectedAuthError,
    };
    return DecoratedBox(
      key: const Key('registration_failure_notice'),
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
