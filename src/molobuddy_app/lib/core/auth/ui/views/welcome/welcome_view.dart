import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_status_pill.dart';
import 'package:molobuddy_app/app/design_system/components/molo_wordmark.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';
import 'package:molobuddy_app/app/localisation/generated/app_localizations.dart';
import 'package:molobuddy_app/app/router/app_router.dart';
import 'package:molobuddy_app/bootstrap/app_environment.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_user.dart';
import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';
import 'package:molobuddy_app/core/auth/ui/view_models/auth_view_model.dart';
import 'package:molobuddy_app/core/auth/ui/view_models/auth_view_state.dart';

class WelcomeView extends ConsumerWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localisations = AppLocalizations.of(context);
    final authState = ref.watch(authViewModelProvider);
    final environment = ref.watch(appEnvironmentProvider);
    final viewState = switch (authState) {
      AsyncData(:final value) => value,
      _ => null,
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
      if (previousStatus != AuthViewStatus.signedOut &&
          nextStatus == AuthViewStatus.signedOut) {
        const SignInRoute().go(context);
      }
    });

    if (viewState == null || viewState.user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = viewState.user!;
    final session = viewState.session;
    final signingOut = viewState.status == AuthViewStatus.signingOut;
    final greetingName = _greetingName(session, user);
    final sessionNotice = _sessionStatusNotice(
      localisations,
      viewState,
      onRetry: () => ref.read(authViewModelProvider.notifier).reloadSession(),
    );
    return Title(
      title: localisations.welcomePageTitle,
      color: MoloColours.moloPlum,
      child: Scaffold(
        key: const Key('welcome_view'),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MoloSpacing.lg,
                    vertical: MoloSpacing.md,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Row(
                            children: [
                              const MoloWordmark(compact: true),
                              const Spacer(),
                              if (environment.isPreview &&
                                  constraints.maxWidth >= 600) ...[
                                MoloStatusPill(
                                  label: localisations.previewModeLabel,
                                  icon: Icons.science_outlined,
                                ),
                                const SizedBox(width: MoloSpacing.sm),
                              ],
                              TextButton.icon(
                                key: const Key('sign_out_button'),
                                onPressed: signingOut
                                    ? null
                                    : () => ref
                                          .read(authViewModelProvider.notifier)
                                          .signOut(),
                                icon: signingOut
                                    ? const SizedBox.square(
                                        dimension: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.logout_rounded,
                                        size: 19,
                                      ),
                                label: Text(
                                  signingOut
                                      ? localisations.signingOut
                                      : localisations.signOut,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  MoloSpacing.lg,
                  MoloSpacing.xxl,
                  MoloSpacing.lg,
                  MoloSpacing.display,
                ),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: MoloSpacing.sm,
                            runSpacing: MoloSpacing.sm,
                            children: [
                              MoloStatusPill(
                                label: localisations.welcomeHeading,
                                icon: Icons.check_circle_outline,
                                foreground: MoloColours.success,
                                background: const Color(0xFFECFDF3),
                              ),
                              if (environment.isPreview)
                                MoloStatusPill(
                                  label: localisations.previewModeLabel,
                                  icon: Icons.science_outlined,
                                ),
                            ],
                          ),
                          const SizedBox(height: MoloSpacing.lg),
                          Text(
                            greetingName == null
                                ? localisations.welcomeNameless
                                : localisations.welcomeName(greetingName),
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: MoloSpacing.md),
                          // Above the split, so the identity the server
                          // returned is visible in every session state. The
                          // masked address is what proves the data came from
                          // /v1/session rather than the sign-in form.
                          _SessionIdentity(
                            label: localisations.signedInAs,
                            value: session?.emailMasked ?? user.email,
                          ),
                          const SizedBox(height: MoloSpacing.lg),
                          if (sessionNotice != null) ...[
                            sessionNotice,
                          ] else ...[
                            Text(
                              localisations.previewWorkspaceBody,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: MoloColours.secondaryText),
                            ),
                            const SizedBox(height: MoloSpacing.xxl),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final expanded = constraints.maxWidth >= 760;
                                final cards = [
                                  _WorkspaceCard(
                                    icon: Icons.arrow_forward_rounded,
                                    eyebrow: localisations.homeNextAction,
                                    title: localisations.homeNextAction,
                                    body: localisations.homeNextActionBody,
                                    accent: true,
                                  ),
                                  _WorkspaceCard(
                                    icon: Icons.lock_outline_rounded,
                                    eyebrow: localisations.secureSession,
                                    title: localisations.secureSession,
                                    body: localisations.secureSessionBody,
                                  ),
                                ];
                                if (!expanded) {
                                  return Column(
                                    children: [
                                      for (
                                        var index = 0;
                                        index < cards.length;
                                        index++
                                      ) ...[
                                        cards[index],
                                        if (index != cards.length - 1)
                                          const SizedBox(
                                            height: MoloSpacing.md,
                                          ),
                                      ],
                                    ],
                                  );
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (
                                      var index = 0;
                                      index < cards.length;
                                      index++
                                    ) ...[
                                      Expanded(child: cards[index]),
                                      if (index != cards.length - 1)
                                        const SizedBox(width: MoloSpacing.md),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The name to greet this person by, or `null` when none is known.
///
/// Prefers the name the server returned, because that is the identity Molo
/// holds, and falls back to the local one only until the server has answered.
/// Neither is allowed to be an email address.
String? _greetingName(MoloSession? session, AuthUser user) {
  final fromSession = session?.displayName?.trim();
  if (fromSession != null && fromSession.isNotEmpty) {
    return fromSession;
  }
  return user.greetingName;
}

/// Maps the auth view model's session status to what the welcome screen
/// should show instead of the ordinary workspace cards, or `null` when the
/// session is loaded and usable and the ordinary cards should show.
_SessionStatusNotice? _sessionStatusNotice(
  AppLocalizations localisations,
  AuthViewState viewState, {
  required VoidCallback onRetry,
}) {
  if (viewState.status == AuthViewStatus.loadingSession) {
    return _SessionStatusNotice(
      message: localisations.sessionLoading,
      tone: _SessionStatusTone.loading,
    );
  }
  // The session slot, not the general one. A provider catalogue that failed
  // is not a broken session, and reporting it as one replaced a reachable
  // workspace with an error whose retry reloaded the wrong thing.
  final failure = viewState.sessionFailure;
  if (failure != null) {
    // Exhaustive on purpose. A kind that falls through here would render the
    // ordinary cards as if the session had loaded, which is how three of these
    // used to fail silently. A new kind must now be given words.
    //
    // The third element says whether asking again could change the answer. An
    // offer to retry that cannot work is worse than no offer: it invites the
    // user to keep pressing a button that reproduces the same failure.
    final (message, icon, retryable) = switch (failure.kind) {
      AuthFailureKind.attestationRequired => (
        localisations.sessionAttestationRequired,
        Icons.phonelink_lock_outlined,
        true,
      ),
      // The copy already asks for a fresh sign-in. Reloading cannot mint a
      // token the server will accept.
      AuthFailureKind.sessionExpired => (
        localisations.sessionExpired,
        Icons.timer_off_outlined,
        false,
      ),
      AuthFailureKind.networkUnavailable => (
        localisations.networkUnavailable,
        Icons.cloud_off_outlined,
        true,
      ),
      // How this build was compiled does not change between presses.
      AuthFailureKind.configurationMissing => (
        localisations.sessionUnavailable,
        Icons.build_circle_outlined,
        false,
      ),
      AuthFailureKind.providerUnavailable => (
        localisations.sessionUnavailable,
        Icons.build_circle_outlined,
        true,
      ),
      // The last two belong to creating an account, not to loading a session.
      // They are listed rather than defaulted so the exhaustiveness guard keeps
      // working: a genuinely new session failure must still be given words.
      AuthFailureKind.invalidCredentials ||
      AuthFailureKind.emailAlreadyRegistered ||
      AuthFailureKind.passwordRejected ||
      AuthFailureKind.unexpected => (
        localisations.unexpectedAuthError,
        Icons.error_outline,
        true,
      ),
    };
    return _SessionStatusNotice(
      message: message,
      icon: icon,
      tone: _SessionStatusTone.error,
      onRetry: retryable ? onRetry : null,
      retryLabel: retryable ? localisations.retrySessionLoad : null,
    );
  }
  final session = viewState.session;
  if (session != null && !session.hasPractices) {
    return _SessionStatusNotice(
      message: localisations.sessionNoPractices,
      icon: Icons.groups_outlined,
      tone: _SessionStatusTone.info,
    );
  }
  return null;
}

enum _SessionStatusTone { loading, info, error }

/// Explains the state of the Molo session (as opposed to Firebase sign-in)
/// with an icon paired with text, so the state is never carried by colour
/// alone.
class _SessionStatusNotice extends StatelessWidget {
  const _SessionStatusNotice({
    required this.message,
    required this.tone,
    this.icon,
    this.onRetry,
    this.retryLabel,
  });

  final String message;
  final IconData? icon;
  final _SessionStatusTone tone;

  /// Recovery for a session that did not load. Without it the only way out of
  /// a failed load is signing out, which is not a recovery.
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final background = switch (tone) {
      _SessionStatusTone.loading => MoloColours.surface,
      _SessionStatusTone.info => MoloColours.pulseTint,
      _SessionStatusTone.error => MoloColours.errorTint,
    };
    final iconColour = switch (tone) {
      _SessionStatusTone.loading => MoloColours.secondaryText,
      _SessionStatusTone.info => MoloColours.pulseText,
      _SessionStatusTone.error => MoloColours.error,
    };
    final border = tone == _SessionStatusTone.loading
        ? Border.all(color: MoloColours.border)
        : null;
    final retryAction = onRetry;
    final retryText = retryLabel;
    final retry = retryAction == null || retryText == null
        ? null
        : _RetryButton(label: retryText, onPressed: retryAction);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(MoloSpacing.cardRadius),
        border: border,
      ),
      child: Padding(
        padding: const EdgeInsets.all(MoloSpacing.lg),
        child: Row(
          crossAxisAlignment: retry == null
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: icon == null
                  ? CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: iconColour,
                    )
                  : Icon(icon, color: iconColour, size: 24),
            ),
            const SizedBox(width: MoloSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message, style: Theme.of(context).textTheme.bodyLarge),
                  if (retry != null) ...[
                    const SizedBox(height: MoloSpacing.md),
                    Align(alignment: Alignment.centerLeft, child: retry),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks for the session again. Sized past the 48x48 target, and its keyboard
/// focus is a two pixel border rather than the hover wash, so the two states
/// never read the same.
class _RetryButton extends StatelessWidget {
  const _RetryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: const Key('retry_session_button'),
      onPressed: onPressed,
      icon: const Icon(Icons.refresh_rounded, size: 20),
      label: Text(label),
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(96, 48)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: MoloSpacing.md),
        ),
        foregroundColor: const WidgetStatePropertyAll(MoloColours.moloPlum),
        backgroundColor: const WidgetStatePropertyAll(MoloColours.surface),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused) ||
              states.contains(WidgetState.pressed)) {
            return MoloColours.pulseTint;
          }
          if (states.contains(WidgetState.hovered)) {
            return MoloColours.softBlush;
          }
          return Colors.transparent;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return const BorderSide(color: MoloColours.pulseText, width: 2);
          }
          return const BorderSide(color: MoloColours.controlBorder);
        }),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MoloSpacing.controlRadius),
          ),
        ),
        textStyle: WidgetStatePropertyAll(
          Theme.of(context).textTheme.labelLarge,
        ),
      ),
    );
  }
}

/// The identity the server returned for this session, or the local sign-in
/// address until the server has answered.
class _SessionIdentity extends StatelessWidget {
  const _SessionIdentity({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.person_outline_rounded,
            size: 20,
            color: MoloColours.secondaryText,
          ),
        ),
        const SizedBox(width: MoloSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: MoloColours.secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: MoloSpacing.xxs),
              Text(
                value,
                style: textTheme.titleMedium?.copyWith(
                  color: MoloColours.moloPlum,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorkspaceCard extends StatelessWidget {
  const _WorkspaceCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.body,
    this.accent = false,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String body;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final foreground = accent ? MoloColours.surface : MoloColours.moloPlum;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent ? MoloColours.moloPlum : MoloColours.surface,
        borderRadius: BorderRadius.circular(MoloSpacing.cardRadius),
        border: accent ? null : Border.all(color: MoloColours.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MoloSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: accent
                    ? MoloColours.surface.withValues(alpha: 0.16)
                    : MoloColours.pulseTint,
                borderRadius: BorderRadius.circular(MoloSpacing.sm),
              ),
              child: Padding(
                padding: const EdgeInsets.all(MoloSpacing.sm),
                child: Icon(
                  icon,
                  color: accent ? MoloColours.moloPulse : MoloColours.pulseText,
                ),
              ),
            ),
            const SizedBox(height: MoloSpacing.lg),
            Text(
              eyebrow,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: accent
                    ? MoloColours.surface.withValues(alpha: 0.76)
                    : MoloColours.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: MoloSpacing.xs),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: foreground),
            ),
            const SizedBox(height: MoloSpacing.sm),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: accent
                    ? MoloColours.surface.withValues(alpha: 0.82)
                    : MoloColours.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
