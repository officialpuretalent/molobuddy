import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:molobuddy_app/app/adaptive/window_class.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_status_pill.dart';
import 'package:molobuddy_app/app/design_system/components/molo_wordmark.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';
import 'package:molobuddy_app/app/localisation/generated/app_localizations.dart';
import 'package:molobuddy_app/app/router/app_router.dart';
import 'package:molobuddy_app/bootstrap/app_environment.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_method_descriptor.dart';
import 'package:molobuddy_app/core/auth/ui/view_models/auth_view_model.dart';
import 'package:molobuddy_app/core/auth/ui/view_models/auth_view_state.dart';

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
      color: MoloColours.deepInk,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final windowClass = moloWindowClassFor(constraints.maxWidth);
              final showHero =
                  windowClass == MoloWindowClass.expanded ||
                  windowClass == MoloWindowClass.large ||
                  windowClass == MoloWindowClass.extraLarge;
              if (showHero) {
                return Row(
                  children: [
                    const Expanded(flex: 9, child: _BrandStoryPanel()),
                    Expanded(
                      flex: 11,
                      child: _SignInPane(
                        viewState: viewState,
                        initialising: authState is AsyncLoading,
                        environment: environment,
                        emailController: _emailController,
                        passwordController: _passwordController,
                        passwordFocusNode: _passwordFocusNode,
                        obscurePassword: _obscurePassword,
                        onTogglePassword: _togglePassword,
                        onSubmit: _submit,
                      ),
                    ),
                  ],
                );
              }
              return _SignInPane(
                viewState: viewState,
                initialising: authState is AsyncLoading,
                environment: environment,
                emailController: _emailController,
                passwordController: _passwordController,
                passwordFocusNode: _passwordFocusNode,
                obscurePassword: _obscurePassword,
                onTogglePassword: _togglePassword,
                onSubmit: _submit,
                showWordmark: true,
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

  void _submit() {
    _passwordFocusNode.unfocus();
    unawaited(
      ref
          .read(authViewModelProvider.notifier)
          .signInWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
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
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    final isBusy = initialising || viewState.isBusy;
    final googleMethod = _methodById(viewState.methods, 'google.com');

    return ColoredBox(
      color: MoloColours.canvas,
      child: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: MoloSpacing.lg,
                vertical: MoloSpacing.xl,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: AutofillGroup(
                  child: Column(
                    key: const Key('sign_in_form'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showWordmark) ...[
                        const MoloWordmark(compact: true),
                        const SizedBox(height: MoloSpacing.xxl),
                      ],
                      if (environment.isPreview) ...[
                        _PreviewNotice(
                          key: const Key('preview_banner'),
                          message: localisations.previewBanner,
                        ),
                        const SizedBox(height: MoloSpacing.lg),
                      ] else if (!environment.canAttemptAuthentication) ...[
                        _ConfigurationBanner(
                          message: localisations.configurationBanner,
                        ),
                        const SizedBox(height: MoloSpacing.lg),
                      ],
                      Text(
                        localisations.welcomeBack,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: MoloSpacing.sm),
                      Text(
                        localisations.signInSubtitle,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: MoloColours.secondaryText,
                        ),
                      ),
                      const SizedBox(height: MoloSpacing.xl),
                      if (viewState.failure != null) ...[
                        _AuthErrorBanner(failure: viewState.failure!),
                        const SizedBox(height: MoloSpacing.md),
                      ],
                      TextField(
                        key: const Key('email_field'),
                        controller: emailController,
                        enabled: !isBusy,
                        autofillHints: const [AutofillHints.email],
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: localisations.emailLabel,
                          hintText: localisations.emailHint,
                          errorText: viewState.emailInvalid
                              ? localisations.invalidEmail
                              : null,
                        ),
                        onSubmitted: (_) => passwordFocusNode.requestFocus(),
                      ),
                      const SizedBox(height: MoloSpacing.md),
                      TextField(
                        key: const Key('password_field'),
                        controller: passwordController,
                        focusNode: passwordFocusNode,
                        enabled: !isBusy,
                        obscureText: obscurePassword,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: localisations.passwordLabel,
                          errorText: viewState.passwordTooShort
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
                        onSubmitted: (_) => isBusy ? null : onSubmit(),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: isBusy
                              ? null
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        localisations.forgotPasswordComingSoon,
                                      ),
                                    ),
                                  );
                                },
                          child: Text(localisations.forgotPassword),
                        ),
                      ),
                      const SizedBox(height: MoloSpacing.xs),
                      FilledButton(
                        key: const Key('sign_in_button'),
                        onPressed:
                            isBusy || !environment.canAttemptAuthentication
                            ? null
                            : onSubmit,
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
                      if (googleMethod != null) ...[
                        const SizedBox(height: MoloSpacing.lg),
                        _OrDivider(label: localisations.orContinueWith),
                        const SizedBox(height: MoloSpacing.lg),
                        Semantics(
                          label: localisations.googleComingSoonHint,
                          button: true,
                          enabled: false,
                          child: OutlinedButton(
                            key: const Key('google_sign_in_button'),
                            onPressed: null,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const _GoogleMark(),
                                const SizedBox(width: MoloSpacing.sm),
                                Flexible(
                                  child: Text(
                                    localisations.continueWithGoogle,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: MoloSpacing.sm),
                                MoloStatusPill(
                                  label: localisations.comingSoon,
                                  foreground: MoloColours.secondaryText,
                                  background: MoloColours.softCloud,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: MoloSpacing.lg),
                      Text(
                        localisations.termsNotice,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: MoloColours.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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

  static AuthMethodDescriptor? _methodById(
    List<AuthMethodDescriptor> methods,
    String providerId,
  ) {
    for (final method in methods) {
      if (method.providerId == providerId &&
          method.availability == AuthMethodAvailability.comingSoon) {
        return method;
      }
    }
    return null;
  }
}

class _BrandStoryPanel extends StatelessWidget {
  const _BrandStoryPanel();

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    return ClipRect(
      child: ColoredBox(
        key: const Key('auth_hero_panel'),
        color: MoloColours.deepInk,
        child: Stack(
          children: [
            const Positioned(
              top: -110,
              right: -90,
              child: _Orb(size: 300, color: MoloColours.moloBlue),
            ),
            Positioned(
              bottom: -70,
              left: -40,
              child: _Orb(
                size: 190,
                color: MoloColours.helloCoral.withValues(alpha: 0.9),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(MoloSpacing.display),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MoloWordmark(onDark: true),
                  const Spacer(),
                  Text(
                    localisations.brandStoryTitle,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: MoloColours.surface,
                    ),
                  ),
                  const SizedBox(height: MoloSpacing.lg),
                  Text(
                    localisations.brandStoryBody,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: MoloColours.surface.withValues(alpha: 0.72),
                    ),
                  ),
                  const SizedBox(height: MoloSpacing.xl),
                  _StoryPoint(label: localisations.brandStoryPointOne),
                  const SizedBox(height: MoloSpacing.md),
                  _StoryPoint(label: localisations.brandStoryPointTwo),
                  const SizedBox(height: MoloSpacing.md),
                  _StoryPoint(label: localisations.brandStoryPointThree),
                  const Spacer(),
                  Text(
                    localisations.brandPromise,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: MoloColours.surface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: SizedBox.square(dimension: size),
      ),
    );
  }
}

class _StoryPoint extends StatelessWidget {
  const _StoryPoint({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.arrow_forward_rounded,
          color: MoloColours.helloCoral,
          size: 20,
        ),
        const SizedBox(width: MoloSpacing.sm),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: MoloColours.surface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
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
        color: MoloColours.moloBlueTint,
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
              color: MoloColours.moloBlue,
            ),
            const SizedBox(width: MoloSpacing.xs),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: MoloColours.moloBlue,
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
      AuthFailureKind.unexpected => localisations.unexpectedAuthError,
    };
    return Material(
      color: const Color(0xFFFFF1F0),
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

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MoloSpacing.sm),
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: MoloColours.secondaryText),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Text(
        'G',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: MoloColours.secondaryText,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
