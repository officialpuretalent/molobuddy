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
  String get previewBanner => 'Preview mode · Nothing is saved';

  @override
  String get configurationBanner =>
      'Authentication needs to be configured before this build can sign in.';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInSubtitle => 'Continue to your Molo workspace.';

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
  String termsNotice(String termsLink, String privacyLink) {
    return 'By signing in, you agree to the $termsLink and $privacyLink.';
  }

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
  String get sessionLoading => 'Checking what you can reach.';

  @override
  String get sessionAttestationRequired => 'This device could not be verified.';

  @override
  String get sessionExpired => 'Your session ended. Sign in again to continue.';

  @override
  String get sessionUnavailable =>
      'Session details are not available in this build yet.';

  @override
  String get sessionNoPractices =>
      'You are signed in. No practice has been connected to this account yet.';

  @override
  String get retrySessionLoad => 'Try again';

  @override
  String get welcomeHeading => 'You\'re in.';

  @override
  String welcomeName(String name) {
    return 'Welcome, $name';
  }

  @override
  String get welcomeNameless => 'Welcome back';

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

  @override
  String get emailAlreadyRegistered =>
      'That address already has an account. Sign in instead.';

  @override
  String get onboardingLoadFailed => 'Molo could not load your setup.';

  @override
  String get onboardingChangedElsewhere =>
      'Your setup changed somewhere else. We\'ve loaded the latest answers.';

  @override
  String get onboardingAnswerRejected =>
      'That answer could not be saved. Check it and try again.';

  @override
  String get onboardingIncomplete =>
      'A question is still unanswered. Go back and complete it.';

  @override
  String get notFoundPageTitle => 'Page not found | Molo';

  @override
  String get notFoundHeading => 'We can\'t find that page.';

  @override
  String get notFoundBody =>
      'The link may be out of date, or the page may have moved. Nothing in your workspace has changed.';

  @override
  String get notFoundAction => 'Go to your workspace';

  @override
  String get signUpPageTitle => 'Create account | Molo';

  @override
  String get newToMolo => 'New to Molo?';

  @override
  String get createAccount => 'Create account';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get registrationStepAccount => 'Your account';

  @override
  String get registrationStepPractice => 'Shape your workspace';

  @override
  String get registrationStepPriorities => 'Choose your first win';

  @override
  String get registrationStepStartingPoint => 'Make it useful';

  @override
  String get createYourAccount => 'Let\'s get you started';

  @override
  String get createAccountSubtitle =>
      'Create your login, then shape a workspace around your practice.';

  @override
  String get fullNameLabel => 'Full name';

  @override
  String get fullNameRequired => 'Enter your full name.';

  @override
  String get workEmailLabel => 'Work email';

  @override
  String get createPasswordLabel => 'Create a password';

  @override
  String get passwordHelper => 'Use at least 8 characters.';

  @override
  String acceptTermsLabel(String termsLink, String privacyLink) {
    return 'I agree to the $termsLink and $privacyLink.';
  }

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get legalPreviewBody =>
      'This document will be available before account creation is enabled.';

  @override
  String get closeLabel => 'Close';

  @override
  String get acceptTermsRequired => 'You need to agree before continuing.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get registrationPreviewNotice =>
      'This is a product preview. Your details are not saved.';

  @override
  String get tellUsAboutPractice => 'Tell us about your practice';

  @override
  String get practiceSubtitle =>
      'These details shape your workspace, local terminology and starting defaults.';

  @override
  String get practiceNameLabel => 'Practice name';

  @override
  String get practiceNameHint => 'Mokoena Tax Studio';

  @override
  String get practiceNameRequired => 'Enter your practice name.';

  @override
  String get practiceSizeQuestion => 'Who will use Molo?';

  @override
  String get practiceSizeSolo => 'Just me';

  @override
  String get practiceSizeSoloBody =>
      'A focused workspace for a solo practitioner.';

  @override
  String get practiceSizeSmall => 'A team of 2 to 10';

  @override
  String get practiceSizeSmallBody => 'Clear ownership and smooth hand-offs.';

  @override
  String get practiceSizeGrowing => 'A team of 11 or more';

  @override
  String get practiceSizeGrowingBody =>
      'More structure for a growing practice.';

  @override
  String get primaryTaxRegionLabel => 'Primary tax region';

  @override
  String get primaryTaxRegionHelper =>
      'South Africa is available first. More regions will follow.';

  @override
  String get southAfrica => 'South Africa';

  @override
  String get whatShouldMoloHelpWith => 'What should feel easier first?';

  @override
  String get prioritiesSubtitle =>
      'Choose one or more. We will use this to shape your starting workspace.';

  @override
  String get priorityDeadlines => 'Stay ahead of deadlines';

  @override
  String get priorityDeadlinesBody =>
      'See what is due and what needs attention now.';

  @override
  String get priorityDocuments => 'Keep documents moving';

  @override
  String get priorityDocumentsBody =>
      'Make requests, uploads and follow-ups clear.';

  @override
  String get priorityTeamwork => 'Run work with a team';

  @override
  String get priorityTeamworkBody =>
      'Keep ownership, hand-offs and reviews visible.';

  @override
  String get priorityVisibility => 'See the whole practice clearly';

  @override
  String get priorityVisibilityBody =>
      'Understand progress without chasing updates.';

  @override
  String get choosePriorityRequired => 'Choose at least one priority.';

  @override
  String get finishSetup => 'Finish setup';

  @override
  String get putSomethingUsefulInside => 'How would you like to begin?';

  @override
  String get startingPointSubtitle =>
      'Start with something real or explore safely with sample data. You can change this later.';

  @override
  String get startingPointImport => 'Import a client list';

  @override
  String get startingPointImportBody =>
      'Best when your practice already runs from a spreadsheet.';

  @override
  String get startingPointClient => 'Add the first client';

  @override
  String get startingPointClientBody =>
      'Start with one real taxpayer and the work you manage for them.';

  @override
  String get startingPointSample => 'Explore a sample workspace';

  @override
  String get startingPointSampleBody =>
      'See Molo in motion before adding any practice data.';

  @override
  String get chooseStartingPointRequired =>
      'Choose how you would like to begin.';

  @override
  String get buildMyWorkspace => 'Build my workspace';

  @override
  String get workspacePreviewTitle => 'Your workspace';

  @override
  String get workspacePreviewPlaceholder => 'Your practice';

  @override
  String get workspacePreviewBody =>
      'A clear place for clients, documents, deadlines and your team.';

  @override
  String workspaceReadiness(int percent) {
    return 'Workspace $percent% ready';
  }

  @override
  String registrationCompleteTitle(String name) {
    return 'Your workspace is ready, $name';
  }

  @override
  String registrationCompleteBody(String practiceName) {
    return '$practiceName is shaped around what matters to you.';
  }

  @override
  String get registrationCompleteSummary =>
      'Your practice defaults, first priorities and preferred starting point are ready for the real account flow.';

  @override
  String get continueToSignIn => 'Continue to sign in';

  @override
  String get noRegistrationDataSaved =>
      'Preview complete. No account or practice data was saved.';

  @override
  String get registrationHeroTitle => 'Watch your workspace take shape.';

  @override
  String get registrationHeroBody =>
      'Every choice should make Molo more useful before you arrive at the home screen.';

  @override
  String get progressAccount => 'Create your account';

  @override
  String get progressAccountBody => 'Your secure way into Molo.';

  @override
  String get progressPractice => 'Shape your practice';

  @override
  String get progressPracticeBody => 'Start solo or bring your team.';

  @override
  String get progressPriorities => 'Choose your focus';

  @override
  String get progressPrioritiesBody =>
      'Make the first workspace feel relevant.';

  @override
  String registrationProgress(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get backLabel => 'Back';
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
  String get previewBanner => 'Preview mode · Nothing is saved';

  @override
  String get configurationBanner =>
      'Authentication needs to be configured before this build can sign in.';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInSubtitle => 'Continue to your Molo workspace.';

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
  String termsNotice(String termsLink, String privacyLink) {
    return 'By signing in, you agree to the $termsLink and $privacyLink.';
  }

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
  String get sessionLoading => 'Checking what you can reach.';

  @override
  String get sessionAttestationRequired => 'This device could not be verified.';

  @override
  String get sessionExpired => 'Your session ended. Sign in again to continue.';

  @override
  String get sessionUnavailable =>
      'Session details are not available in this build yet.';

  @override
  String get sessionNoPractices =>
      'You are signed in. No practice has been connected to this account yet.';

  @override
  String get retrySessionLoad => 'Try again';

  @override
  String get welcomeHeading => 'You\'re in.';

  @override
  String welcomeName(String name) {
    return 'Welcome, $name';
  }

  @override
  String get welcomeNameless => 'Welcome back';

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

  @override
  String get emailAlreadyRegistered =>
      'That address already has an account. Sign in instead.';

  @override
  String get onboardingLoadFailed => 'Molo could not load your setup.';

  @override
  String get onboardingChangedElsewhere =>
      'Your setup changed somewhere else. We\'ve loaded the latest answers.';

  @override
  String get onboardingAnswerRejected =>
      'That answer could not be saved. Check it and try again.';

  @override
  String get onboardingIncomplete =>
      'A question is still unanswered. Go back and complete it.';

  @override
  String get notFoundPageTitle => 'Page not found | Molo';

  @override
  String get notFoundHeading => 'We can\'t find that page.';

  @override
  String get notFoundBody =>
      'The link may be out of date, or the page may have moved. Nothing in your workspace has changed.';

  @override
  String get notFoundAction => 'Go to your workspace';

  @override
  String get signUpPageTitle => 'Create account | Molo';

  @override
  String get newToMolo => 'New to Molo?';

  @override
  String get createAccount => 'Create account';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get registrationStepAccount => 'Your account';

  @override
  String get registrationStepPractice => 'Shape your workspace';

  @override
  String get registrationStepPriorities => 'Choose your first win';

  @override
  String get registrationStepStartingPoint => 'Make it useful';

  @override
  String get createYourAccount => 'Let\'s get you started';

  @override
  String get createAccountSubtitle =>
      'Create your login, then shape a workspace around your practice.';

  @override
  String get fullNameLabel => 'Full name';

  @override
  String get fullNameRequired => 'Enter your full name.';

  @override
  String get workEmailLabel => 'Work email';

  @override
  String get createPasswordLabel => 'Create a password';

  @override
  String get passwordHelper => 'Use at least 8 characters.';

  @override
  String acceptTermsLabel(String termsLink, String privacyLink) {
    return 'I agree to the $termsLink and $privacyLink.';
  }

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get legalPreviewBody =>
      'This document will be available before account creation is enabled.';

  @override
  String get closeLabel => 'Close';

  @override
  String get acceptTermsRequired => 'You need to agree before continuing.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get registrationPreviewNotice =>
      'This is a product preview. Your details are not saved.';

  @override
  String get tellUsAboutPractice => 'Tell us about your practice';

  @override
  String get practiceSubtitle =>
      'These details shape your workspace, local terminology and starting defaults.';

  @override
  String get practiceNameLabel => 'Practice name';

  @override
  String get practiceNameHint => 'Mokoena Tax Studio';

  @override
  String get practiceNameRequired => 'Enter your practice name.';

  @override
  String get practiceSizeQuestion => 'Who will use Molo?';

  @override
  String get practiceSizeSolo => 'Just me';

  @override
  String get practiceSizeSoloBody =>
      'A focused workspace for a solo practitioner.';

  @override
  String get practiceSizeSmall => 'A team of 2 to 10';

  @override
  String get practiceSizeSmallBody => 'Clear ownership and smooth hand-offs.';

  @override
  String get practiceSizeGrowing => 'A team of 11 or more';

  @override
  String get practiceSizeGrowingBody =>
      'More structure for a growing practice.';

  @override
  String get primaryTaxRegionLabel => 'Primary tax region';

  @override
  String get primaryTaxRegionHelper =>
      'South Africa is available first. More regions will follow.';

  @override
  String get southAfrica => 'South Africa';

  @override
  String get whatShouldMoloHelpWith => 'What should feel easier first?';

  @override
  String get prioritiesSubtitle =>
      'Choose one or more. We will use this to shape your starting workspace.';

  @override
  String get priorityDeadlines => 'Stay ahead of deadlines';

  @override
  String get priorityDeadlinesBody =>
      'See what is due and what needs attention now.';

  @override
  String get priorityDocuments => 'Keep documents moving';

  @override
  String get priorityDocumentsBody =>
      'Make requests, uploads and follow-ups clear.';

  @override
  String get priorityTeamwork => 'Run work with a team';

  @override
  String get priorityTeamworkBody =>
      'Keep ownership, hand-offs and reviews visible.';

  @override
  String get priorityVisibility => 'See the whole practice clearly';

  @override
  String get priorityVisibilityBody =>
      'Understand progress without chasing updates.';

  @override
  String get choosePriorityRequired => 'Choose at least one priority.';

  @override
  String get finishSetup => 'Finish setup';

  @override
  String get putSomethingUsefulInside => 'How would you like to begin?';

  @override
  String get startingPointSubtitle =>
      'Start with something real or explore safely with sample data. You can change this later.';

  @override
  String get startingPointImport => 'Import a client list';

  @override
  String get startingPointImportBody =>
      'Best when your practice already runs from a spreadsheet.';

  @override
  String get startingPointClient => 'Add the first client';

  @override
  String get startingPointClientBody =>
      'Start with one real taxpayer and the work you manage for them.';

  @override
  String get startingPointSample => 'Explore a sample workspace';

  @override
  String get startingPointSampleBody =>
      'See Molo in motion before adding any practice data.';

  @override
  String get chooseStartingPointRequired =>
      'Choose how you would like to begin.';

  @override
  String get buildMyWorkspace => 'Build my workspace';

  @override
  String get workspacePreviewTitle => 'Your workspace';

  @override
  String get workspacePreviewPlaceholder => 'Your practice';

  @override
  String get workspacePreviewBody =>
      'A clear place for clients, documents, deadlines and your team.';

  @override
  String workspaceReadiness(int percent) {
    return 'Workspace $percent% ready';
  }

  @override
  String registrationCompleteTitle(String name) {
    return 'Your workspace is ready, $name';
  }

  @override
  String registrationCompleteBody(String practiceName) {
    return '$practiceName is shaped around what matters to you.';
  }

  @override
  String get registrationCompleteSummary =>
      'Your practice defaults, first priorities and preferred starting point are ready for the real account flow.';

  @override
  String get continueToSignIn => 'Continue to sign in';

  @override
  String get noRegistrationDataSaved =>
      'Preview complete. No account or practice data was saved.';

  @override
  String get registrationHeroTitle => 'Watch your workspace take shape.';

  @override
  String get registrationHeroBody =>
      'Every choice should make Molo more useful before you arrive at the home screen.';

  @override
  String get progressAccount => 'Create your account';

  @override
  String get progressAccountBody => 'Your secure way into Molo.';

  @override
  String get progressPractice => 'Shape your practice';

  @override
  String get progressPracticeBody => 'Start solo or bring your team.';

  @override
  String get progressPriorities => 'Choose your focus';

  @override
  String get progressPrioritiesBody =>
      'Make the first workspace feel relevant.';

  @override
  String registrationProgress(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get backLabel => 'Back';
}
