import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:molobuddy_app/app/adaptive/molo_app_shell.dart';
import 'package:molobuddy_app/app/adaptive/window_class.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_account_row.dart';
import 'package:molobuddy_app/app/design_system/components/molo_card.dart';
import 'package:molobuddy_app/app/design_system/components/molo_status_pill.dart';
import 'package:molobuddy_app/app/design_system/components/molo_wordmark.dart';
import 'package:molobuddy_app/app/design_system/icons/molo_glyphs.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';
import 'package:molobuddy_app/app/design_system/typography/molo_typography.dart';
import 'package:molobuddy_app/app/localisation/generated/app_localizations.dart';
import 'package:molobuddy_app/app/router/app_router.dart';
import 'package:molobuddy_app/bootstrap/app_environment.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_failure.dart';
import 'package:molobuddy_app/core/auth/data/models/auth_user.dart';
import 'package:molobuddy_app/core/auth/data/models/molo_session.dart';
import 'package:molobuddy_app/core/auth/ui/view_models/auth_view_model.dart';
import 'package:molobuddy_app/core/auth/ui/view_models/auth_view_state.dart';

/// The authenticated entry point.
///
/// The home layout is display-only until work, deadline and document features
/// have their own repository-backed states. It reads no business data and does
/// not widen the authentication boundary.
class WelcomeView extends ConsumerWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localisations = AppLocalizations.of(context);
    final viewState = switch (ref.watch(authViewModelProvider)) {
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
      return Title(
        title: localisations.homePageTitle,
        color: MoloColours.moloPlum,
        child: _StartupLoadingState(message: localisations.sessionLoading),
      );
    }

    final user = viewState.user!;
    final session = viewState.session;
    final sessionNotice = _sessionStatusNotice(
      localisations,
      viewState,
      onRetry: () => ref.read(authViewModelProvider.notifier).reloadSession(),
    );
    final practice = session == null ? null : _firstActivePractice(session);
    final signingOut = viewState.status == AuthViewStatus.signingOut;
    final onSignOut = signingOut
        ? null
        : () => ref.read(authViewModelProvider.notifier).signOut();

    return Title(
      title: localisations.homePageTitle,
      color: MoloColours.moloPlum,
      child: sessionNotice == null && practice != null
          ? _WorkspaceHome(
              environment: ref.watch(appEnvironmentProvider),
              greetingName: _greetingName(session, user),
              practice: practice,
              signingOut: signingOut,
              onSignOut: onSignOut,
            )
          : _SessionStateHome(
              greetingName: _greetingName(session, user),
              identity: session?.emailMasked ?? user.email,
              signingOut: signingOut,
              onSignOut: onSignOut,
              notice:
                  sessionNotice ??
                  _SessionStatusNotice(
                    message: localisations.sessionNoPractices,
                    icon: Icons.groups_outlined,
                    tone: _SessionStatusTone.info,
                  ),
            ),
    );
  }
}

/// A full refresh can restore the authenticated identity before the session
/// model has rebuilt. Give that ordinary startup gap a named, branded state
/// instead of a lone progress indicator that reads as an empty page.
class _StartupLoadingState extends StatelessWidget {
  const _StartupLoadingState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('workspace_starting'),
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(MoloSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MoloWordmark(),
              const SizedBox(height: MoloSpacing.xl),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(height: MoloSpacing.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: MoloColours.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

PracticeRef? _firstActivePractice(MoloSession session) {
  for (final practice in session.selectablePractices) {
    return practice;
  }
  return null;
}

String? _greetingName(MoloSession? session, AuthUser user) {
  final fromSession = session?.displayName?.trim();
  if (fromSession != null && fromSession.isNotEmpty) {
    return fromSession;
  }
  return user.greetingName;
}

class _WorkspaceHome extends StatelessWidget {
  const _WorkspaceHome({
    required this.environment,
    required this.greetingName,
    required this.practice,
    required this.signingOut,
    required this.onSignOut,
  });

  final AppEnvironment environment;
  final String? greetingName;
  final PracticeRef practice;
  final bool signingOut;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    return MoloAppShell(
      scaffoldKey: const Key('welcome_view'),
      title: localisations.homeNavigationHome,
      selectedDestinationId: 'home',
      destinations: [
        MoloNavigationDestination(
          id: 'home',
          label: localisations.homeNavigationHome,
          glyph: MoloGlyphs.home,
          showInCompact: true,
        ),
        MoloNavigationDestination(
          id: 'work',
          label: localisations.homeNavigationWork,
          glyph: MoloGlyphs.work,
          showInCompact: true,
        ),
        MoloNavigationDestination(
          id: 'clients',
          label: localisations.homeNavigationClients,
          glyph: MoloGlyphs.clients,
        ),
        MoloNavigationDestination(
          id: 'documents',
          label: localisations.homeNavigationDocuments,
          glyph: MoloGlyphs.documents,
          showInCompact: true,
        ),
        MoloNavigationDestination(
          id: 'deadlines',
          label: localisations.homeNavigationDeadlines,
          glyph: MoloGlyphs.deadlines,
        ),
        // In the design's navigation, but the screen is not built yet, so it
        // is shown without pretending to work.
        MoloNavigationDestination(
          id: 'meetings',
          label: localisations.homeNavigationMeetings,
          glyph: MoloGlyphs.meetings,
          enabled: false,
        ),
        MoloNavigationDestination(
          id: 'ask-molo',
          label: localisations.homeAskMolo,
          glyph: MoloGlyphs.askMolo,
          section: MoloNavigationSection.secondary,
          showInCompact: true,
        ),
        MoloNavigationDestination(
          id: 'team',
          label: localisations.homeTeamActivity,
          glyph: MoloGlyphs.team,
          section: MoloNavigationSection.secondary,
        ),
        MoloNavigationDestination(
          id: 'practice',
          label: localisations.homeNavigationPracticeView,
          glyph: MoloGlyphs.practiceView,
          section: MoloNavigationSection.secondary,
          enabled: false,
        ),
      ],
      primaryActionLabel: localisations.homeCreateWork,
      primaryActionTooltip: localisations.homeCreateWork,
      brandSemanticLabel: localisations.appName,
      searchHint: localisations.homeSearchHint,
      onDestinationSelected: (_) => _showUnavailable(context),
      onPrimaryAction: () => _showUnavailable(context),
      accountMenuBuilder: (context, windowClass) => _AccountMenu(
        compact:
            windowClass != MoloWindowClass.large &&
            windowClass != MoloWindowClass.extraLarge,
        onDark:
            windowClass == MoloWindowClass.medium ||
            windowClass == MoloWindowClass.expanded,
        practice: practice,
        signingOut: signingOut,
        onSignOut: onSignOut,
      ),
      topBarTrailingBuilder: (context, windowClass) {
        if (windowClass == MoloWindowClass.compact) {
          return const [];
        }
        // The design's top bar carries the screen title and the search
        // field, nothing else. The practice name belongs to the account row
        // at the foot of the sidebar, where the design puts it; repeating it
        // here was a duplicate the design does not have.
        return [
          if (environment.isPreview)
            MoloStatusPill(
              label: localisations.previewModeLabel,
              icon: Icons.science_outlined,
            ),
        ];
      },
      child: LayoutBuilder(
        builder: (context, _) => _HomeContent(
          greetingName: greetingName,
          padded: MediaQuery.sizeOf(context).width >= MoloBreakpoints.medium,
        ),
      ),
    );
  }
}

class _AccountMenu extends StatelessWidget {
  const _AccountMenu({
    required this.compact,
    required this.practice,
    required this.signingOut,
    required this.onSignOut,
    this.onDark = false,
  });

  final bool compact;
  final PracticeRef practice;
  final bool signingOut;
  final VoidCallback? onSignOut;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    return PopupMenuButton<void>(
      key: const Key('account_menu_button'),
      enabled: !signingOut,
      tooltip: localisations.homeAccountMenu,
      color: MoloColours.surface,
      onSelected: (_) => onSignOut?.call(),
      itemBuilder: (context) => [
        PopupMenuItem<void>(
          key: const Key('sign_out_button'),
          value: null,
          child: Row(
            children: [
              const Icon(Icons.logout_rounded, color: MoloColours.pulseText),
              const SizedBox(width: MoloSpacing.sm),
              Text(
                signingOut ? localisations.signingOut : localisations.signOut,
              ),
            ],
          ),
        ),
      ],
      child: compact
          ? Icon(
              Icons.account_circle_outlined,
              color: onDark ? MoloColours.surface : null,
            )
          : MoloAccountRow(
              initials: _initials(practice.displayLabel),
              name: practice.displayLabel,
              detail: localisations.homePracticeAccount,
            ),
    );
  }
}

String _initials(String value) => value
    .trim()
    .split(RegExp(r'\s+'))
    .where((part) => part.isNotEmpty)
    .take(2)
    .map((part) => part.substring(0, 1).toUpperCase())
    .join();

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.greetingName, required this.padded});

  final String? greetingName;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    final greeting = greetingName == null
        ? localisations.homeGreetingNameless
        : localisations.homeGreeting(greetingName!);
    // The shell stacks the top bar over this content so it scrolls under a
    // translucent bar, and reports the covered height as a top inset. Without
    // adding it the first item would start life hidden behind the bar.
    final barInset = MediaQuery.paddingOf(context).top;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            padded ? MoloSpacing.xl : MoloSpacing.lg,
            MoloSpacing.xl + barInset,
            padded ? MoloSpacing.xl : MoloSpacing.lg,
            MoloSpacing.display,
          ),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localisations.homeKicker,
                      style: MoloTypography.kicker.copyWith(
                        color: MoloColours.pulseText,
                      ),
                    ),
                    const SizedBox(height: MoloSpacing.xs),
                    Text(
                      greeting,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: MoloSpacing.xs),
                    Text(
                      localisations.homeIntro,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: MoloColours.secondaryText,
                      ),
                    ),
                    const SizedBox(height: MoloSpacing.lg),
                    const _MoloBrief(),
                    const SizedBox(height: MoloSpacing.xl),
                    _SectionHeader(
                      title: localisations.homeAttentionTitle,
                      action: localisations.homeViewAllWork,
                    ),
                    const SizedBox(height: MoloSpacing.sm),
                    const _AttentionList(),
                    const SizedBox(height: MoloSpacing.xl),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 760) {
                          return const Column(
                            children: [
                              _DeadlinePanel(),
                              SizedBox(height: MoloSpacing.md),
                              _ActivityPanel(),
                            ],
                          );
                        }
                        return const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _DeadlinePanel()),
                            SizedBox(width: MoloSpacing.md),
                            Expanded(child: _ActivityPanel()),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: MoloSpacing.xl),
                    const _AskMoloField(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MoloBrief extends StatelessWidget {
  const _MoloBrief();

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    return MoloCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  color: MoloColours.moloPlum,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                    bottomLeft: Radius.circular(4),
                  ),
                ),
                child: SizedBox(
                  height: 32,
                  width: 32,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: MoloColours.moloPulse,
                  ),
                ),
              ),
              const SizedBox(width: MoloSpacing.sm),
              Text(
                localisations.homeMoloName,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: MoloSpacing.xs),
              Text(
                localisations.homeDailyBrief,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: MoloColours.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: MoloSpacing.md),
          Text(
            localisations.homeBriefBody,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: MoloSpacing.md),
          Wrap(
            spacing: MoloSpacing.sm,
            runSpacing: MoloSpacing.sm,
            children: [
              FilledButton(
                onPressed: () => _showUnavailable(context),
                child: Text(localisations.homeReviewVat),
              ),
              OutlinedButton(
                onPressed: () => _showUnavailable(context),
                child: Text(localisations.homeSeeBlockers),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action});

  final String title;
  final String action;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      TextButton(
        onPressed: () => _showUnavailable(context),
        child: Text(action),
      ),
    ],
  );
}

class _AttentionList extends StatelessWidget {
  const _AttentionList();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: MoloColours.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: MoloColours.border),
    ),
    child: const Column(
      children: [
        _AttentionItem(
          icon: Icons.task_alt_rounded,
          titleKey: _HomeText.vatReturn,
          bodyKey: _HomeText.vatReturnBody,
          statusKey: _HomeText.finalReview,
        ),
        Divider(height: 1),
        _AttentionItem(
          icon: Icons.north_east_rounded,
          warning: true,
          titleKey: _HomeText.incomeTax,
          bodyKey: _HomeText.incomeTaxBody,
          statusKey: _HomeText.clientReply,
        ),
        Divider(height: 1),
        _AttentionItem(
          icon: Icons.add_rounded,
          titleKey: _HomeText.vatRegistration,
          bodyKey: _HomeText.vatRegistrationBody,
          statusKey: _HomeText.assignOwner,
        ),
      ],
    ),
  );
}

enum _HomeText {
  vatReturn,
  vatReturnBody,
  finalReview,
  incomeTax,
  incomeTaxBody,
  clientReply,
  vatRegistration,
  vatRegistrationBody,
  assignOwner,
}

class _AttentionItem extends StatelessWidget {
  const _AttentionItem({
    required this.icon,
    required this.titleKey,
    required this.bodyKey,
    required this.statusKey,
    this.warning = false,
  });

  final IconData icon;
  final _HomeText titleKey;
  final _HomeText bodyKey;
  final _HomeText statusKey;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    final title = _text(localisations, titleKey);
    final body = _text(localisations, bodyKey);
    final status = _text(localisations, statusKey);
    final signal = warning ? MoloColours.warning : MoloColours.pulseText;
    return Semantics(
      button: true,
      label: '$title. $body. $status',
      child: InkWell(
        onTap: () => _showUnavailable(context),
        child: Padding(
          padding: const EdgeInsets.all(MoloSpacing.md),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: warning
                      ? const Color(0xFFFFF1DD)
                      : MoloColours.pulseTint,
                  borderRadius: BorderRadius.circular(MoloSpacing.sm),
                ),
                child: SizedBox(
                  height: 34,
                  width: 34,
                  child: Icon(icon, color: signal, size: 19),
                ),
              ),
              const SizedBox(width: MoloSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: MoloColours.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: MoloSpacing.sm),
              Text(
                status,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: signal,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _text(AppLocalizations localisations, _HomeText key) => switch (key) {
  _HomeText.vatReturn => localisations.homeVatReturn,
  _HomeText.vatReturnBody => localisations.homeVatReturnBody,
  _HomeText.finalReview => localisations.homeFinalReview,
  _HomeText.incomeTax => localisations.homeIncomeTax,
  _HomeText.incomeTaxBody => localisations.homeIncomeTaxBody,
  _HomeText.clientReply => localisations.homeClientReply,
  _HomeText.vatRegistration => localisations.homeVatRegistration,
  _HomeText.vatRegistrationBody => localisations.homeVatRegistrationBody,
  _HomeText.assignOwner => localisations.homeAssignOwner,
};

class _DeadlinePanel extends StatelessWidget {
  const _DeadlinePanel();

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    return _QuietPanel(
      title: localisations.homeDeadlinesTitle,
      child: Column(
        children: [
          _DeadlineRow(
            date: localisations.homeDueTomorrow,
            title: localisations.homeVatReturn,
            subtitle: localisations.homeMokoenaMedia,
          ),
          const Divider(height: MoloSpacing.lg),
          _DeadlineRow(
            date: localisations.homeDueInTwoDays,
            title: localisations.homeProvisionalTax,
            subtitle: localisations.homeThandoMokoena,
            warning: true,
          ),
        ],
      ),
    );
  }
}

class _DeadlineRow extends StatelessWidget {
  const _DeadlineRow({
    required this.date,
    required this.title,
    required this.subtitle,
    this.warning = false,
  });

  final String date;
  final String title;
  final String subtitle;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final colour = warning ? MoloColours.warning : MoloColours.pulseText;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.calendar_today_outlined, color: colour, size: 19),
        const SizedBox(width: MoloSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: MoloColours.secondaryText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: MoloSpacing.sm),
        Text(
          date,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colour,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel();

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    return _QuietPanel(
      title: localisations.homeFlowTitle,
      child: Column(
        children: [
          _ActivityRow(
            name: localisations.homeActivityDavid,
            body: localisations.homeActivityDavidBody,
            time: localisations.homeActivityDavidTime,
            success: true,
          ),
          const Divider(height: MoloSpacing.lg),
          _ActivityRow(
            name: localisations.homeActivityKhanyisile,
            body: localisations.homeActivityKhanyisileBody,
            time: localisations.homeActivityKhanyisileTime,
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.name,
    required this.body,
    required this.time,
    this.success = false,
  });

  final String name;
  final String body;
  final String time;
  final bool success;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: success ? MoloColours.success : MoloColours.moloPulse,
            shape: BoxShape.circle,
          ),
          child: const SizedBox(width: 8, height: 8),
        ),
      ),
      const SizedBox(width: MoloSpacing.sm),
      Expanded(
        child: RichText(
          text: TextSpan(
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: MoloColours.moloPlum),
            children: [
              TextSpan(
                text: name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              TextSpan(text: ' $body'),
            ],
          ),
        ),
      ),
      const SizedBox(width: MoloSpacing.sm),
      Text(
        time,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: MoloColours.secondaryText),
      ),
    ],
  );
}

class _QuietPanel extends StatelessWidget {
  const _QuietPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => MoloCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: MoloSpacing.lg),
        child,
      ],
    ),
  );
}

class _AskMoloField extends StatelessWidget {
  const _AskMoloField();

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: localisations.homeAskMoloHint,
      child: InkWell(
        onTap: () => _showUnavailable(context),
        borderRadius: BorderRadius.circular(MoloSpacing.controlRadius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: MoloColours.surface,
            border: Border.all(color: const Color(0xFFD8A4B1)),
            borderRadius: BorderRadius.circular(MoloSpacing.controlRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MoloSpacing.md,
              vertical: MoloSpacing.sm,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_outlined,
                  color: MoloColours.pulseText,
                ),
                const SizedBox(width: MoloSpacing.sm),
                Expanded(
                  child: Text(
                    localisations.homeAskMoloHint,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    color: MoloColours.moloPlum,
                    borderRadius: BorderRadius.all(Radius.circular(9)),
                  ),
                  child: SizedBox(
                    height: 30,
                    width: 30,
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      size: 18,
                      color: MoloColours.surface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionStateHome extends StatelessWidget {
  const _SessionStateHome({
    required this.greetingName,
    required this.identity,
    required this.signingOut,
    required this.onSignOut,
    required this.notice,
  });

  final String? greetingName;
  final String identity;
  final bool signingOut;
  final VoidCallback? onSignOut;
  final _SessionStatusNotice notice;

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context);
    final greeting = greetingName == null
        ? localisations.homeGreetingNameless
        : localisations.homeGreeting(greetingName!);
    return Scaffold(
      key: const Key('welcome_view'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MoloSpacing.lg),
          child: Column(
            children: [
              Row(
                children: [
                  const MoloWordmark(compact: true),
                  const Spacer(),
                  IconButton(
                    key: const Key('sign_out_button'),
                    tooltip: localisations.signOut,
                    onPressed: onSignOut,
                    icon: signingOut
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.logout_rounded),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: MoloSpacing.md),
                        _SessionIdentity(
                          label: localisations.signedInAs,
                          value: identity,
                        ),
                        const SizedBox(height: MoloSpacing.xl),
                        notice,
                      ],
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

void _showUnavailable(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(AppLocalizations.of(context).homeActionUnavailable)),
  );
}

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
  final failure = viewState.sessionFailure;
  if (failure == null) {
    return null;
  }
  final (message, icon, retryable) = switch (failure.kind) {
    AuthFailureKind.attestationRequired => (
      localisations.sessionAttestationRequired,
      Icons.phonelink_lock_outlined,
      true,
    ),
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

enum _SessionStatusTone { loading, info, error }

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
    final retry = onRetry == null || retryLabel == null
        ? null
        : _RetryButton(label: retryLabel!, onPressed: onRetry!);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(MoloSpacing.cardRadius),
        border: tone == _SessionStatusTone.loading
            ? Border.all(color: MoloColours.border)
            : null,
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
                    retry,
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

class _RetryButton extends StatelessWidget {
  const _RetryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    key: const Key('retry_session_button'),
    onPressed: onPressed,
    icon: const Icon(Icons.refresh_rounded, size: 20),
    label: Text(label),
  );
}

class _SessionIdentity extends StatelessWidget {
  const _SessionIdentity({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
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
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: MoloColours.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: MoloSpacing.xxs),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    ],
  );
}
