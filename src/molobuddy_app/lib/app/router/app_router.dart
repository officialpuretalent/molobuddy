import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:molobuddy_app/app/design_system/motion/molo_motion.dart';
import 'package:molobuddy_app/app/router/not_found_view.dart';
import 'package:molobuddy_app/core/auth/auth_providers.dart';
import 'package:molobuddy_app/core/auth/ui/views/registration/registration_view.dart';
import 'package:molobuddy_app/core/auth/ui/views/sign_in/sign_in_view.dart';
import 'package:molobuddy_app/core/auth/ui/views/welcome/welcome_view.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

@TypedGoRoute<SignInRoute>(path: '/sign-in')
class SignInRoute extends GoRouteData with $SignInRoute {
  const SignInRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _moloPage(context, state, child: const SignInView());
  }
}

@TypedGoRoute<RegistrationRoute>(path: '/sign-up')
class RegistrationRoute extends GoRouteData with $RegistrationRoute {
  const RegistrationRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _moloPage(context, state, child: const RegistrationView());
  }
}

@TypedGoRoute<WelcomeRoute>(path: '/home')
class WelcomeRoute extends GoRouteData with $WelcomeRoute {
  const WelcomeRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _moloPage(context, state, child: const WelcomeView());
  }
}

Page<void> _moloPage(
  BuildContext context,
  GoRouterState state, {
  required Widget child,
}) {
  if (MediaQuery.disableAnimationsOf(context)) {
    return NoTransitionPage<void>(key: state.pageKey, child: child);
  }

  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: MoloMotion.route,
    reverseTransitionDuration: MoloMotion.routeReverse,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final arrival = CurvedAnimation(
        parent: animation,
        curve: MoloMotion.standard,
        reverseCurve: MoloMotion.exit,
      );
      return FadeTransition(opacity: arrival, child: child);
    },
  );
}

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: const SignInRoute().location,
    routes: $appRoutes,
    // A location matching no route is an ordinary thing a stale link does, so
    // it gets a Molo page. go_router's own screen prints its exception, which
    // tells the reader nothing and leaks the router into the product.
    errorBuilder: (context, state) => const NotFoundView(),
    redirect: (context, state) {
      final signedIn = ref.read(authRepositoryProvider).currentUser != null;
      final onSignIn = state.matchedLocation == const SignInRoute().location;
      final onRegistration =
          state.matchedLocation == const RegistrationRoute().location;
      final onPublicAuthRoute = onSignIn || onRegistration;
      if (!signedIn && !onPublicAuthRoute) {
        return const SignInRoute().location;
      }
      if (signedIn && onPublicAuthRoute) {
        return const WelcomeRoute().location;
      }
      return null;
    },
  );
}
