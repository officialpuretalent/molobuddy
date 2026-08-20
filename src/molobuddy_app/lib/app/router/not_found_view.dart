import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:molobuddy_app/app/design_system/colour/molo_colours.dart';
import 'package:molobuddy_app/app/design_system/components/molo_wordmark.dart';
import 'package:molobuddy_app/app/design_system/spacing/molo_spacing.dart';
import 'package:molobuddy_app/app/localisation/generated/app_localizations.dart';
import 'package:molobuddy_app/app/router/app_router.dart';
import 'package:molobuddy_app/core/auth/auth_providers.dart';

/// What a location matching no route looks like.
///
/// Without this, go_router renders its own diagnostic screen and the reader
/// is shown `GoException: no routes for location: /…`. That is what the
/// router says to itself, not something a person can act on, and it leaks the
/// routing implementation into the product.
class NotFoundView extends ConsumerWidget {
  const NotFoundView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localisations = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    // A signed-out reader has no workspace to return to, and the router would
    // send them straight back here from it.
    final signedIn = ref.read(authRepositoryProvider).currentUser != null;

    return Title(
      title: localisations.notFoundPageTitle,
      color: MoloColours.moloPlum,
      child: Scaffold(
        key: const Key('not_found_view'),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(MoloSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const MoloWordmark(compact: true),
                    const SizedBox(height: MoloSpacing.xxl),
                    Semantics(
                      header: true,
                      child: Text(
                        localisations.notFoundHeading,
                        style: textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: MoloSpacing.md),
                    Text(
                      localisations.notFoundBody,
                      style: textTheme.bodyLarge?.copyWith(
                        color: MoloColours.secondaryText,
                      ),
                    ),
                    const SizedBox(height: MoloSpacing.xxl),
                    FilledButton(
                      key: const Key('not_found_home_button'),
                      onPressed: () => signedIn
                          ? const WelcomeRoute().go(context)
                          : const SignInRoute().go(context),
                      child: Text(
                        signedIn
                            ? localisations.notFoundAction
                            : localisations.signIn,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
