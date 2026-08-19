import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_status_pill.dart';
import 'package:molobuddy_app/app/design_system/components/molo_wordmark.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';
import 'package:molobuddy_app/app/localisation/generated/app_localizations.dart';
import 'package:molobuddy_app/app/router/app_router.dart';
import 'package:molobuddy_app/bootstrap/app_environment.dart';
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
    final signingOut = viewState.status == AuthViewStatus.signingOut;
    return Title(
      title: localisations.welcomePageTitle,
      color: MoloColours.deepInk,
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
                                foreground: MoloColours.aloe,
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
                            localisations.welcomeName(user.greetingName),
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: MoloSpacing.sm),
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
                                  icon: Icons.person_outline_rounded,
                                  eyebrow: localisations.signedInAs,
                                  title: user.email,
                                  body: localisations.previewWorkspaceTitle,
                                ),
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
                                        const SizedBox(height: MoloSpacing.md),
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
    final foreground = accent ? MoloColours.surface : MoloColours.deepInk;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent ? MoloColours.moloBlue : MoloColours.surface,
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
                    : MoloColours.moloBlueTint,
                borderRadius: BorderRadius.circular(MoloSpacing.sm),
              ),
              child: Padding(
                padding: const EdgeInsets.all(MoloSpacing.sm),
                child: Icon(
                  icon,
                  color: accent ? MoloColours.surface : MoloColours.moloBlue,
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
