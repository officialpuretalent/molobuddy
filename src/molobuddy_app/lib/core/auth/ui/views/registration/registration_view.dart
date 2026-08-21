import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:molobuddy_app/app/adaptive/molo_wizard_shell.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';
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
            setState(() => _acceptedTerms = value ?? false),
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
          MoloStepEyebrow(label: localisations.registrationStepAccount),
          const SizedBox(height: MoloSpacing.sm),
          MoloStepHeading(label: localisations.createYourAccount),
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
              errorText: state.emailAlreadyRegistered
                  ? localisations.emailAlreadyRegistered
                  : state.emailInvalid
                  ? localisations.invalidEmail
                  : null,
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
          if (state.failure != null) ...[
            _AccountFailureNotice(failure: state.failure!),
            const SizedBox(height: MoloSpacing.md),
          ],
          FilledButton(
            key: const Key('registration_account_continue'),
            onPressed: state.submitting ? null : () => _submit(context, ref),
            child: state.submitting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(localisations.continueLabel),
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
