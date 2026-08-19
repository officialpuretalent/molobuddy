// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Molo';

  @override
  String get signInPageTitle => 'Sign in | Molo';

  @override
  String get welcomePageTitle => 'Welcome | Molo';

  @override
  String get brandPromise => 'Make serious work feel light.';

  @override
  String get brandStoryTitle =>
      'Everything your practice needs to keep work moving.';

  @override
  String get brandStoryBody =>
      'Clear priorities, calm collaboration and confident progress, all in one place.';

  @override
  String get brandStoryPointOne => 'See what needs attention now';

  @override
  String get brandStoryPointTwo => 'Keep every hand-off clear';

  @override
  String get brandStoryPointThree => 'Move work forward with confidence';

  @override
  String get previewBanner => 'Local preview · No data saved';

  @override
  String get configurationBanner =>
      'Authentication needs to be configured before this build can sign in.';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInSubtitle => 'Sign in to continue to your practice.';

  @override
  String get emailLabel => 'Email address';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get passwordLabel => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get forgotPasswordComingSoon => 'Password recovery is coming soon.';

  @override
  String get signIn => 'Sign in';

  @override
  String get signingIn => 'Signing in…';

  @override
  String get orContinueWith => 'or continue with';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get googleComingSoonHint => 'Google sign-in is coming soon';

  @override
  String get termsNotice =>
      'By continuing, you agree to Molo\'s Terms and Privacy Policy.';

  @override
  String get invalidEmail => 'Enter a valid email address.';

  @override
  String get passwordTooShort => 'Use at least 8 characters.';

  @override
  String get invalidCredentials =>
      'Check your email and password, then try again.';

  @override
  String get networkUnavailable =>
      'Molo cannot connect right now. Check your connection and try again.';

  @override
  String get authUnavailable => 'Sign-in is not available in this build yet.';

  @override
  String get unexpectedAuthError => 'Something went wrong. Try again.';

  @override
  String get dismissMessage => 'Dismiss message';

  @override
  String get welcomeHeading => 'You\'re in.';

  @override
  String welcomeName(String name) {
    return 'Welcome, $name';
  }

  @override
  String get previewWorkspaceTitle => 'Your Molo workspace is ready';

  @override
  String get previewWorkspaceBody =>
      'This first slice proves the responsive sign-in journey. Practice work will appear here as we connect the next feature.';

  @override
  String get signedInAs => 'Signed in as';

  @override
  String get previewModeLabel => 'Preview mode';

  @override
  String get signOut => 'Sign out';

  @override
  String get signingOut => 'Signing out…';

  @override
  String get homeNextAction => 'Next up';

  @override
  String get homeNextActionBody =>
      'Connect the real Firebase project, then load your authorised practices from the Molo API.';

  @override
  String get secureSession => 'Secure session';

  @override
  String get secureSessionBody =>
      'Firebase identity stays behind Molo\'s authentication boundary.';
}

/// The translations for English, as used in South Africa (`en_ZA`).
class AppLocalizationsEnZa extends AppLocalizationsEn {
  AppLocalizationsEnZa() : super('en_ZA');

  @override
  String get appName => 'Molo';

  @override
  String get signInPageTitle => 'Sign in | Molo';

  @override
  String get welcomePageTitle => 'Welcome | Molo';

  @override
  String get brandPromise => 'Make serious work feel light.';

  @override
  String get brandStoryTitle =>
      'Everything your practice needs to keep work moving.';

  @override
  String get brandStoryBody =>
      'Clear priorities, calm collaboration and confident progress, all in one place.';

  @override
  String get brandStoryPointOne => 'See what needs attention now';

  @override
  String get brandStoryPointTwo => 'Keep every hand-off clear';

  @override
  String get brandStoryPointThree => 'Move work forward with confidence';

  @override
  String get previewBanner => 'Local preview · No data saved';

  @override
  String get configurationBanner =>
      'Authentication needs to be configured before this build can sign in.';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInSubtitle => 'Sign in to continue to your practice.';

  @override
  String get emailLabel => 'Email address';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get passwordLabel => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get forgotPasswordComingSoon => 'Password recovery is coming soon.';

  @override
  String get signIn => 'Sign in';

  @override
  String get signingIn => 'Signing in…';

  @override
  String get orContinueWith => 'or continue with';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get googleComingSoonHint => 'Google sign-in is coming soon';

  @override
  String get termsNotice =>
      'By continuing, you agree to Molo\'s Terms and Privacy Policy.';

  @override
  String get invalidEmail => 'Enter a valid email address.';

  @override
  String get passwordTooShort => 'Use at least 8 characters.';

  @override
  String get invalidCredentials =>
      'Check your email and password, then try again.';

  @override
  String get networkUnavailable =>
      'Molo cannot connect right now. Check your connection and try again.';

  @override
  String get authUnavailable => 'Sign-in is not available in this build yet.';

  @override
  String get unexpectedAuthError => 'Something went wrong. Try again.';

  @override
  String get dismissMessage => 'Dismiss message';

  @override
  String get welcomeHeading => 'You\'re in.';

  @override
  String welcomeName(String name) {
    return 'Welcome, $name';
  }

  @override
  String get previewWorkspaceTitle => 'Your Molo workspace is ready';

  @override
  String get previewWorkspaceBody =>
      'This first slice proves the responsive sign-in journey. Practice work will appear here as we connect the next feature.';

  @override
  String get signedInAs => 'Signed in as';

  @override
  String get previewModeLabel => 'Preview mode';

  @override
  String get signOut => 'Sign out';

  @override
  String get signingOut => 'Signing out…';

  @override
  String get homeNextAction => 'Next up';

  @override
  String get homeNextActionBody =>
      'Connect the real Firebase project, then load your authorised practices from the Molo API.';

  @override
  String get secureSession => 'Secure session';

  @override
  String get secureSessionBody =>
      'Firebase identity stays behind Molo\'s authentication boundary.';
}
