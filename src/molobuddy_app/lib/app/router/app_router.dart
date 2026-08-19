import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:molobuddy_app/core/auth/auth_providers.dart';
import 'package:molobuddy_app/core/auth/ui/views/sign_in/sign_in_view.dart';
import 'package:molobuddy_app/core/auth/ui/views/welcome/welcome_view.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

@TypedGoRoute<SignInRoute>(path: '/sign-in')
class SignInRoute extends GoRouteData with $SignInRoute {
  const SignInRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SignInView();
  }
}

@TypedGoRoute<WelcomeRoute>(path: '/home')
class WelcomeRoute extends GoRouteData with $WelcomeRoute {
  const WelcomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const WelcomeView();
  }
}

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: const SignInRoute().location,
    routes: $appRoutes,
    redirect: (context, state) {
      final signedIn = ref.read(authRepositoryProvider).currentUser != null;
      final onSignIn = state.matchedLocation == const SignInRoute().location;
      if (!signedIn && !onSignIn) {
        return const SignInRoute().location;
      }
      if (signedIn && onSignIn) {
        return const WelcomeRoute().location;
      }
      return null;
    },
  );
}
