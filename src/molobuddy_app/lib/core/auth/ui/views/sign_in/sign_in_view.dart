import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:molobuddy_app/app/adaptive/auth_shell_layout.dart';
import 'package:molobuddy_app/app/adaptive/window_class.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_brand_lockup.dart';
import 'package:molobuddy_app/app/design_system/components/molo_check_row.dart';
import 'package:molobuddy_app/app/design_system/components/molo_pill_button.dart';
import 'package:molobuddy_app/app/design_system/components/molo_text_field.dart';
import 'package:molobuddy_app/app/design_system/icons/molo_glyphs.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';
import 'package:molobuddy_app/app/design_system/typography/molo_typography.dart';
import 'package:molobuddy_app/app/localisation/generated/app_localizations.dart';
import 'package:molobuddy_app/app/router/app_router.dart';
import 'package:molobuddy_app/bootstrap/app_environment.dart';
import 'package:molobuddy_app/core/auth/auth_providers.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/ui/view_models/auth_view_model.dart';
import 'package:molobuddy_app/core/auth/ui/view_models/auth_view_state.dart';
import 'package:molobuddy_app/core/auth/ui/views/sign_in/sign_in_greeting.dart';
import 'package:molobuddy_app/core/auth/ui/views/sign_in/sign_in_hero_pane.dart';
import 'package:molobuddy_app/core/auth/ui/widgets/auth_legal_links_text.dart';

/// The design separates the pane's four groups by 26.
const _groupGap = 26.0;

class SignInView extends ConsumerStatefulWidget {
  const SignInView({super.key});

  @override
  ConsumerState<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends ConsumerState<SignInView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;

  /// The design draws this checked. Someone who is never shown the control gets
  /// the same answer, which is also what Android and iOS do regardless.
  bool _persistSession = true;

  /// Field validation belongs to this form instance, not the shared auth
  /// session, so a returning visitor never arrives to errors they did not cause.
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    final authState = ref.watch(authViewModelProvider);
    final environment = ref.watch(appEnvironmentProvider);
    final viewState = switch (authState) {
      AsyncData(:final value) => value,
      _ => const AuthViewState.signedOut(),
    };

    ref.listen(authViewModelProvider, (previous, next) {
      final previousStatus = switch (previous) {
        AsyncData(:final value) => value.status,
        _ => null,
      };
      final nextStatus = switch (next) {
        AsyncData(:final value) => value.status,
        _ => null,
      };
      if (previousStatus != AuthViewStatus.signedIn &&
          nextStatus == AuthViewStatus.signedIn &&
          mounted) {
        const WelcomeRoute().go(context);
      }
    });

    return Title(
      title: localisations.signInPageTitle,
      color: MoloColours.moloPlum,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
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
                // Where the hero is absent, the pane carries the brand itself.
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
            },
          ),
        ),
      ),
    );
  }

  void _togglePassword() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  void _setPersistSession(bool value) {
    setState(() => _persistSession = value);
  }

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
}

class _SignInPane extends StatelessWidget {
  const _SignInPane({
    required this.viewState,
    required this.initialising,
    required this.environment,
    required this.emailController,
    required this.passwordController,
    required this.passwordFocusNode,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.showValidation,
    required this.persistSession,
    required this.onPersistSessionChanged,
    required this.offerPersistence,
    this.showWordmark = false,
  });

  final AuthViewState viewState;
  final bool initialising;
  final AppEnvironment environment;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode passwordFocusNode;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final bool showValidation;
  final bool persistSession;
  final ValueChanged<bool> onPersistSessionChanged;
  final bool offerPersistence;
  final bool showWordmark;

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
                              const _HeadingGroup(),
                              const SizedBox(height: _groupGap),
                              if (viewState.failure != null) ...[
                                _AuthErrorBanner(failure: viewState.failure!),
                                const SizedBox(height: _groupGap),
                              ],
                              _FieldsGroup(
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
                              const _LegalFooter(),
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
}

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
      // No spacer: a spacer is a tight flex child, so it would take a share of
      // the row that the pill then could not have, and the action's label would
      // ellipsise while the row still had room. The alignment does the pushing
      // instead, which leaves every flex share for the text that needs it.
      mainAxisAlignment: showWordmark
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.end,
      children: [
        if (showWordmark) const Flexible(child: MoloBrandLockup(compact: true)),
        // The label is context for the pill, not an instruction, so the narrow
        // layout keeps the part that acts and drops the part that explains.
        if (!showWordmark) ...[
          Flexible(
            child: Text(
              localisations.newToMolo,
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
        // Flexible, not fixed: a longer translation of either the label or the
        // pill has to give ground rather than overflow the row.
        Flexible(
          child: MoloPillButton(
            key: const Key('create_account_link'),
            label: localisations.createAccount,
            onPressed: onCreateAccount,
          ),
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
          greeting.toUpperCase(),
          key: const Key('sign_in_kicker'),
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

class _FieldsGroup extends StatelessWidget {
  const _FieldsGroup({
    required this.viewState,
    required this.isBusy,
    required this.emailController,
    required this.passwordController,
    required this.passwordFocusNode,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.showValidation,
    required this.offerPersistence,
    required this.persistSession,
    required this.onPersistSessionChanged,
  });

  final AuthViewState viewState;
  final bool isBusy;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode passwordFocusNode;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final bool showValidation;
  final bool offerPersistence;
  final bool persistSession;
  final ValueChanged<bool> onPersistSessionChanged;

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
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
            // Not const: MoloGlyphs.eye builds its path lazily, so it is
            // `static final` rather than a constant.
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
  }
}

class _ActionsGroup extends StatelessWidget {
  const _ActionsGroup({
    required this.isBusy,
    required this.canAttempt,
    required this.onSubmit,
  });

  final bool isBusy;
  final bool canAttempt;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
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
  }
}

/// A federated provider the design offers and the application cannot yet
/// honour.
///
/// Declared by the view rather than read from the provider catalogue: both are
/// permanently disabled here, and the work that makes either one real owns
/// reconnecting them. The 46-high cell has no room for a "Coming soon" pill, so
/// the reason lives in the accessible name.
///
/// The outline is the quiet [MoloColours.border] the design draws. A disabled
/// control is exempt from WCAG 1.4.11, and these two never enable.
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

class _LegalFooter extends StatelessWidget {
  const _LegalFooter();

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
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
  }
}

class _ConfigurationBanner extends StatelessWidget {
  const _ConfigurationBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(MoloSpacing.controlRadius),
        border: Border.all(color: MoloColours.warning),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MoloSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: MoloColours.warning),
            const SizedBox(width: MoloSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _PreviewNotice extends StatelessWidget {
  const _PreviewNotice({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: MoloColours.pulseTint,
        borderRadius: BorderRadius.circular(MoloSpacing.controlRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MoloSpacing.sm,
          vertical: MoloSpacing.xs,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.science_outlined,
              size: 17,
              color: MoloColours.pulseText,
            ),
            const SizedBox(width: MoloSpacing.xs),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: MoloColours.pulseText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthErrorBanner extends ConsumerWidget {
  const _AuthErrorBanner({required this.failure});

  final AuthFailure failure;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localisations = AppLocalizations.of(context);
    final message = switch (failure.kind) {
      AuthFailureKind.invalidCredentials => localisations.invalidCredentials,
      AuthFailureKind.networkUnavailable => localisations.networkUnavailable,
      AuthFailureKind.providerUnavailable => localisations.authUnavailable,
      AuthFailureKind.configurationMissing => localisations.authUnavailable,
      AuthFailureKind.attestationRequired =>
        localisations.sessionAttestationRequired,
      AuthFailureKind.sessionExpired => localisations.sessionExpired,
      // Neither can arise from signing in; they belong to creating an account.
      // The switch stays exhaustive so a new kind must be given words, and the
      // honest words here are the generic ones.
      AuthFailureKind.emailAlreadyRegistered ||
      AuthFailureKind.passwordRejected ||
      AuthFailureKind.unexpected => localisations.unexpectedAuthError,
    };
    return Material(
      color: MoloColours.errorTint,
      borderRadius: BorderRadius.circular(MoloSpacing.controlRadius),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          MoloSpacing.md,
          MoloSpacing.sm,
          MoloSpacing.xs,
          MoloSpacing.sm,
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: MoloColours.error),
            const SizedBox(width: MoloSpacing.sm),
            Expanded(child: Text(message)),
            IconButton(
              tooltip: localisations.dismissMessage,
              onPressed: () =>
                  ref.read(authViewModelProvider.notifier).clearFailure(),
              icon: const Icon(Icons.close, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
