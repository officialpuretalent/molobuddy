import 'package:molobuddy_app/bootstrap/app_environment.dart';
import 'package:molobuddy_app/core/network/network_providers.dart';
import 'package:molobuddy_app/core/onboarding/data/services/http_onboarding_service.dart';
import 'package:molobuddy_app/core/onboarding/data/services/onboarding_service.dart';
import 'package:molobuddy_app/core/onboarding/data/services/preview_onboarding_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_providers.g.dart';

/// Preview's onboarding, kept as its own provider.
///
/// The preview session service reads the practice this founded, so both need
/// the same instance. Reaching it through the general
/// [onboardingServiceProvider] would mean a cast, and would break the moment
/// preview stopped being the mode in use.
@Riverpod(keepAlive: true)
PreviewOnboardingService previewOnboardingService(Ref ref) {
  return PreviewOnboardingService();
}

/// Reads and writes onboarding over the authenticated transport.
///
/// Mirrors `sessionServiceProvider`: preview answers from memory because
/// preview is a supported way to show the product with no backend, a Firebase
/// build with an API base URL calls the control API, and anything else has no
/// onboarding to read and says so.
@Riverpod(keepAlive: true)
OnboardingService onboardingService(Ref ref) {
  final environment = ref.watch(appEnvironmentProvider);
  if (environment.authMode == AuthRuntimeMode.preview) {
    return ref.watch(previewOnboardingServiceProvider);
  }
  final baseUrl = environment.apiBaseUrl;
  if (environment.authMode != AuthRuntimeMode.firebase || baseUrl == null) {
    return const UnavailableOnboardingService();
  }
  return HttpOnboardingService(
    dio: ref.watch(authenticatedDioProvider),
    baseUrl: baseUrl,
  );
}
