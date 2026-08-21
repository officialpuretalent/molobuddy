import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('en', 'ZA'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Molo'**
  String get appName;

  /// No description provided for @signInPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in | Molo'**
  String get signInPageTitle;

  /// No description provided for @welcomePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome | Molo'**
  String get welcomePageTitle;

  /// No description provided for @brandPromise.
  ///
  /// In en, this message translates to:
  /// **'Make serious work feel light.'**
  String get brandPromise;

  /// No description provided for @brandStoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Everything your practice needs to keep work moving.'**
  String get brandStoryTitle;

  /// No description provided for @brandStoryBody.
  ///
  /// In en, this message translates to:
  /// **'Clear priorities, calm collaboration and confident progress, all in one place.'**
  String get brandStoryBody;

  /// No description provided for @brandStoryPointOne.
  ///
  /// In en, this message translates to:
  /// **'See what needs attention now'**
  String get brandStoryPointOne;

  /// No description provided for @brandStoryPointTwo.
  ///
  /// In en, this message translates to:
  /// **'Keep every hand-off clear'**
  String get brandStoryPointTwo;

  /// No description provided for @brandStoryPointThree.
  ///
  /// In en, this message translates to:
  /// **'Move work forward with confidence'**
  String get brandStoryPointThree;

  /// No description provided for @previewBanner.
  ///
  /// In en, this message translates to:
  /// **'Preview mode · Nothing is saved'**
  String get previewBanner;

  /// No description provided for @configurationBanner.
  ///
  /// In en, this message translates to:
  /// **'Authentication needs to be configured before this build can sign in.'**
  String get configurationBanner;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Continue to your Molo workspace.'**
  String get signInSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Password recovery is coming soon.'**
  String get forgotPasswordComingSoon;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get signingIn;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get orContinueWith;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @googleComingSoonHint.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is coming soon'**
  String get googleComingSoonHint;

  /// Sign-in agreement sentence with labels that are rendered as separate links.
  ///
  /// In en, this message translates to:
  /// **'By signing in, you agree to the {termsLink} and {privacyLink}.'**
  String termsNotice(String termsLink, String privacyLink);

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get passwordTooShort;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Check your email and password, then try again.'**
  String get invalidCredentials;

  /// No description provided for @networkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Molo cannot connect right now. Check your connection and try again.'**
  String get networkUnavailable;

  /// No description provided for @authUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sign-in is not available in this build yet.'**
  String get authUnavailable;

  /// No description provided for @unexpectedAuthError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get unexpectedAuthError;

  /// No description provided for @dismissMessage.
  ///
  /// In en, this message translates to:
  /// **'Dismiss message'**
  String get dismissMessage;

  /// Shown while the Molo session (practice access) is being loaded after sign-in.
  ///
  /// In en, this message translates to:
  /// **'Checking what you can reach.'**
  String get sessionLoading;

  /// Shown when App Check could not attest the device, blocking the session or sign-in request. The recovery action is a button, so the sentence does not name one.
  ///
  /// In en, this message translates to:
  /// **'This device could not be verified.'**
  String get sessionAttestationRequired;

  /// Shown when the server reports the session has expired and needs a fresh sign-in.
  ///
  /// In en, this message translates to:
  /// **'Your session ended. Sign in again to continue.'**
  String get sessionExpired;

  /// Shown to a signed-in user when this build cannot reach the session service at all, such as a preview build.
  ///
  /// In en, this message translates to:
  /// **'Session details are not available in this build yet.'**
  String get sessionUnavailable;

  /// Shown on the welcome screen when the loaded session has no practices to work in.
  ///
  /// In en, this message translates to:
  /// **'You are signed in. No practice has been connected to this account yet.'**
  String get sessionNoPractices;

  /// Button that asks the server for the session again after it failed to load.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retrySessionLoad;

  /// No description provided for @welcomeHeading.
  ///
  /// In en, this message translates to:
  /// **'You\'\'re in.'**
  String get welcomeHeading;

  /// Signed-in welcome using a display name. Never an email address: the address is shown separately and in masked form.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String welcomeName(String name);

  /// Signed-in welcome for an account that has told us no name. Greeting someone by their email address is worse than not naming them.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeNameless;

  /// No description provided for @previewWorkspaceBody.
  ///
  /// In en, this message translates to:
  /// **'This first slice proves the responsive sign-in journey. Practice work will appear here as we connect the next feature.'**
  String get previewWorkspaceBody;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as'**
  String get signedInAs;

  /// No description provided for @previewModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Preview mode'**
  String get previewModeLabel;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get signOut;

  /// No description provided for @signingOut.
  ///
  /// In en, this message translates to:
  /// **'Logging out…'**
  String get signingOut;

  /// No description provided for @homePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Home | Molo'**
  String get homePageTitle;

  /// No description provided for @homeNavigationHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeNavigationHome;

  /// No description provided for @homeNavigationWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get homeNavigationWork;

  /// No description provided for @homeNavigationClients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get homeNavigationClients;

  /// No description provided for @homeNavigationDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get homeNavigationDocuments;

  /// No description provided for @homeNavigationDeadlines.
  ///
  /// In en, this message translates to:
  /// **'Deadlines'**
  String get homeNavigationDeadlines;

  /// No description provided for @homeNavigationMeetings.
  ///
  /// In en, this message translates to:
  /// **'Meetings'**
  String get homeNavigationMeetings;

  /// No description provided for @homeNavigationTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get homeNavigationTeam;

  /// No description provided for @homeNavigationPracticeView.
  ///
  /// In en, this message translates to:
  /// **'Practice view'**
  String get homeNavigationPracticeView;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search clients, work, documents'**
  String get homeSearchHint;

  /// No description provided for @homeAskMolo.
  ///
  /// In en, this message translates to:
  /// **'Ask Molo'**
  String get homeAskMolo;

  /// No description provided for @homeCreateWork.
  ///
  /// In en, this message translates to:
  /// **'Create work'**
  String get homeCreateWork;

  /// No description provided for @accountMenuSwitchPractice.
  ///
  /// In en, this message translates to:
  /// **'Switch practice'**
  String get accountMenuSwitchPractice;

  /// No description provided for @accountMenuConnectors.
  ///
  /// In en, this message translates to:
  /// **'Connectors and intake'**
  String get accountMenuConnectors;

  /// No description provided for @accountMenuYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get accountMenuYourProfile;

  /// No description provided for @accountMenuSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get accountMenuSettings;

  /// No description provided for @accountMenuHelp.
  ///
  /// In en, this message translates to:
  /// **'Help and support'**
  String get accountMenuHelp;

  /// No description provided for @homePracticeAccount.
  ///
  /// In en, this message translates to:
  /// **'Practice account'**
  String get homePracticeAccount;

  /// No description provided for @homeAccountMenu.
  ///
  /// In en, this message translates to:
  /// **'Open practice account menu'**
  String get homeAccountMenu;

  /// No description provided for @homeKicker.
  ///
  /// In en, this message translates to:
  /// **'Your practice, in flow'**
  String get homeKicker;

  /// Personal home greeting. The name is a display name only and never an email address.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}.'**
  String homeGreeting(String name);

  /// No description provided for @homeGreetingNameless.
  ///
  /// In en, this message translates to:
  /// **'Good morning.'**
  String get homeGreetingNameless;

  /// No description provided for @homeIntro.
  ///
  /// In en, this message translates to:
  /// **'Three things need attention today. Start with the one that keeps a deadline moving.'**
  String get homeIntro;

  /// No description provided for @homeMoloName.
  ///
  /// In en, this message translates to:
  /// **'Molo'**
  String get homeMoloName;

  /// No description provided for @homeDailyBrief.
  ///
  /// In en, this message translates to:
  /// **'Daily brief'**
  String get homeDailyBrief;

  /// No description provided for @homeBriefBody.
  ///
  /// In en, this message translates to:
  /// **'Your VAT return for Mokoena Media is due tomorrow and is waiting for final review. Two client replies could also unblock this week’s work.'**
  String get homeBriefBody;

  /// No description provided for @homeReviewVat.
  ///
  /// In en, this message translates to:
  /// **'Review VAT return'**
  String get homeReviewVat;

  /// No description provided for @homeSeeBlockers.
  ///
  /// In en, this message translates to:
  /// **'See what is blocked'**
  String get homeSeeBlockers;

  /// No description provided for @homeAttentionTitle.
  ///
  /// In en, this message translates to:
  /// **'Needs your attention'**
  String get homeAttentionTitle;

  /// No description provided for @homeViewAllWork.
  ///
  /// In en, this message translates to:
  /// **'View all work'**
  String get homeViewAllWork;

  /// No description provided for @homeVatReturn.
  ///
  /// In en, this message translates to:
  /// **'VAT return · July 2026'**
  String get homeVatReturn;

  /// No description provided for @homeVatReturnBody.
  ///
  /// In en, this message translates to:
  /// **'Mokoena Media (Pty) Ltd · Due tomorrow'**
  String get homeVatReturnBody;

  /// No description provided for @homeFinalReview.
  ///
  /// In en, this message translates to:
  /// **'Final review'**
  String get homeFinalReview;

  /// No description provided for @homeIncomeTax.
  ///
  /// In en, this message translates to:
  /// **'Income tax return · 2026'**
  String get homeIncomeTax;

  /// No description provided for @homeIncomeTaxBody.
  ///
  /// In en, this message translates to:
  /// **'Khanyisile Dlamini · Document request'**
  String get homeIncomeTaxBody;

  /// No description provided for @homeClientReply.
  ///
  /// In en, this message translates to:
  /// **'Client reply'**
  String get homeClientReply;

  /// No description provided for @homeVatRegistration.
  ///
  /// In en, this message translates to:
  /// **'VAT registration'**
  String get homeVatRegistration;

  /// No description provided for @homeVatRegistrationBody.
  ///
  /// In en, this message translates to:
  /// **'Coastline Foods · New work item'**
  String get homeVatRegistrationBody;

  /// No description provided for @homeAssignOwner.
  ///
  /// In en, this message translates to:
  /// **'Assign owner'**
  String get homeAssignOwner;

  /// No description provided for @homeDeadlinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Deadlines coming up'**
  String get homeDeadlinesTitle;

  /// No description provided for @homeDueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Due tomorrow'**
  String get homeDueTomorrow;

  /// No description provided for @homeDueInTwoDays.
  ///
  /// In en, this message translates to:
  /// **'Due in 2 days'**
  String get homeDueInTwoDays;

  /// No description provided for @homeMokoenaMedia.
  ///
  /// In en, this message translates to:
  /// **'Mokoena Media (Pty) Ltd'**
  String get homeMokoenaMedia;

  /// No description provided for @homeProvisionalTax.
  ///
  /// In en, this message translates to:
  /// **'Provisional tax · first period'**
  String get homeProvisionalTax;

  /// No description provided for @homeThandoMokoena.
  ///
  /// In en, this message translates to:
  /// **'Thando Mokoena'**
  String get homeThandoMokoena;

  /// No description provided for @homeFlowTitle.
  ///
  /// In en, this message translates to:
  /// **'In the flow'**
  String get homeFlowTitle;

  /// No description provided for @homeActivityDavid.
  ///
  /// In en, this message translates to:
  /// **'David'**
  String get homeActivityDavid;

  /// No description provided for @homeActivityDavidBody.
  ///
  /// In en, this message translates to:
  /// **'completed the reconciliation check.'**
  String get homeActivityDavidBody;

  /// No description provided for @homeActivityDavidTime.
  ///
  /// In en, this message translates to:
  /// **'14 min ago'**
  String get homeActivityDavidTime;

  /// No description provided for @homeActivityKhanyisile.
  ///
  /// In en, this message translates to:
  /// **'Khanyisile'**
  String get homeActivityKhanyisile;

  /// No description provided for @homeActivityKhanyisileBody.
  ///
  /// In en, this message translates to:
  /// **'uploaded an IRP5.'**
  String get homeActivityKhanyisileBody;

  /// No description provided for @homeActivityKhanyisileTime.
  ///
  /// In en, this message translates to:
  /// **'28 min ago'**
  String get homeActivityKhanyisileTime;

  /// No description provided for @homeAskMoloHint.
  ///
  /// In en, this message translates to:
  /// **'Ask Molo about your practice'**
  String get homeAskMoloHint;

  /// No description provided for @homeActionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This workspace action is coming soon.'**
  String get homeActionUnavailable;

  /// No description provided for @homeNextAction.
  ///
  /// In en, this message translates to:
  /// **'Next up'**
  String get homeNextAction;

  /// No description provided for @homeNextActionBody.
  ///
  /// In en, this message translates to:
  /// **'Connect the real Firebase project, then load your authorised practices from the Molo API.'**
  String get homeNextActionBody;

  /// No description provided for @secureSession.
  ///
  /// In en, this message translates to:
  /// **'Secure session'**
  String get secureSession;

  /// No description provided for @secureSessionBody.
  ///
  /// In en, this message translates to:
  /// **'Firebase identity stays behind Molo\'\'s authentication boundary.'**
  String get secureSessionBody;

  /// No description provided for @emailAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'That address already has an account. Sign in instead.'**
  String get emailAlreadyRegistered;

  /// Heading on the onboarding wizard when the saved answers could not be read, so there is no wizard to show. The reason follows underneath.
  ///
  /// In en, this message translates to:
  /// **'Molo could not load your setup.'**
  String get onboardingLoadFailed;

  /// Shown when a save lost to another tab and the wizard reloaded what is stored.
  ///
  /// In en, this message translates to:
  /// **'Your setup changed somewhere else. We\'\'ve loaded the latest answers.'**
  String get onboardingChangedElsewhere;

  /// No description provided for @onboardingAnswerRejected.
  ///
  /// In en, this message translates to:
  /// **'That answer could not be saved. Check it and try again.'**
  String get onboardingAnswerRejected;

  /// No description provided for @onboardingIncomplete.
  ///
  /// In en, this message translates to:
  /// **'A question is still unanswered. Go back and complete it.'**
  String get onboardingIncomplete;

  /// No description provided for @notFoundPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Page not found | Molo'**
  String get notFoundPageTitle;

  /// No description provided for @notFoundHeading.
  ///
  /// In en, this message translates to:
  /// **'We can\'\'t find that page.'**
  String get notFoundHeading;

  /// Shown when a location matches no route. Reassures the reader that a bad link is not a data problem.
  ///
  /// In en, this message translates to:
  /// **'The link may be out of date, or the page may have moved. Nothing in your workspace has changed.'**
  String get notFoundBody;

  /// No description provided for @notFoundAction.
  ///
  /// In en, this message translates to:
  /// **'Go to your workspace'**
  String get notFoundAction;

  /// No description provided for @signUpPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account | Molo'**
  String get signUpPageTitle;

  /// No description provided for @newToMolo.
  ///
  /// In en, this message translates to:
  /// **'New to Molo?'**
  String get newToMolo;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @registrationStepAccount.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get registrationStepAccount;

  /// No description provided for @registrationStepPractice.
  ///
  /// In en, this message translates to:
  /// **'Shape your workspace'**
  String get registrationStepPractice;

  /// No description provided for @registrationStepPriorities.
  ///
  /// In en, this message translates to:
  /// **'Choose your first win'**
  String get registrationStepPriorities;

  /// No description provided for @registrationStepStartingPoint.
  ///
  /// In en, this message translates to:
  /// **'Make it useful'**
  String get registrationStepStartingPoint;

  /// No description provided for @createYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Let\'\'s get you started'**
  String get createYourAccount;

  /// No description provided for @createAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your login, then shape a workspace around your practice.'**
  String get createAccountSubtitle;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameLabel;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name.'**
  String get fullNameRequired;

  /// No description provided for @workEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Work email'**
  String get workEmailLabel;

  /// No description provided for @createPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get createPasswordLabel;

  /// No description provided for @passwordHelper.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get passwordHelper;

  /// Account agreement sentence with labels that are rendered as separate links.
  ///
  /// In en, this message translates to:
  /// **'I agree to the {termsLink} and {privacyLink}.'**
  String acceptTermsLabel(String termsLink, String privacyLink);

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @legalPreviewBody.
  ///
  /// In en, this message translates to:
  /// **'This document will be available before account creation is enabled.'**
  String get legalPreviewBody;

  /// No description provided for @closeLabel.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeLabel;

  /// No description provided for @acceptTermsRequired.
  ///
  /// In en, this message translates to:
  /// **'You need to agree before continuing.'**
  String get acceptTermsRequired;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @registrationPreviewNotice.
  ///
  /// In en, this message translates to:
  /// **'This is a product preview. Your details are not saved.'**
  String get registrationPreviewNotice;

  /// No description provided for @tellUsAboutPractice.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your practice'**
  String get tellUsAboutPractice;

  /// No description provided for @practiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'These details shape your workspace, local terminology and starting defaults.'**
  String get practiceSubtitle;

  /// No description provided for @practiceNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Practice name'**
  String get practiceNameLabel;

  /// No description provided for @practiceNameHint.
  ///
  /// In en, this message translates to:
  /// **'Mokoena Tax Studio'**
  String get practiceNameHint;

  /// No description provided for @practiceNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your practice name.'**
  String get practiceNameRequired;

  /// No description provided for @practiceSizeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Who will use Molo?'**
  String get practiceSizeQuestion;

  /// No description provided for @practiceSizeSolo.
  ///
  /// In en, this message translates to:
  /// **'Just me'**
  String get practiceSizeSolo;

  /// No description provided for @practiceSizeSoloBody.
  ///
  /// In en, this message translates to:
  /// **'A focused workspace for a solo practitioner.'**
  String get practiceSizeSoloBody;

  /// No description provided for @practiceSizeSmall.
  ///
  /// In en, this message translates to:
  /// **'A team of 2 to 10'**
  String get practiceSizeSmall;

  /// No description provided for @practiceSizeSmallBody.
  ///
  /// In en, this message translates to:
  /// **'Clear ownership and smooth hand-offs.'**
  String get practiceSizeSmallBody;

  /// No description provided for @practiceSizeGrowing.
  ///
  /// In en, this message translates to:
  /// **'A team of 11 or more'**
  String get practiceSizeGrowing;

  /// No description provided for @practiceSizeGrowingBody.
  ///
  /// In en, this message translates to:
  /// **'More structure for a growing practice.'**
  String get practiceSizeGrowingBody;

  /// No description provided for @primaryTaxRegionLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary tax region'**
  String get primaryTaxRegionLabel;

  /// No description provided for @primaryTaxRegionHelper.
  ///
  /// In en, this message translates to:
  /// **'South Africa is available first. More regions will follow.'**
  String get primaryTaxRegionHelper;

  /// No description provided for @southAfrica.
  ///
  /// In en, this message translates to:
  /// **'South Africa'**
  String get southAfrica;

  /// No description provided for @whatShouldMoloHelpWith.
  ///
  /// In en, this message translates to:
  /// **'What should feel easier first?'**
  String get whatShouldMoloHelpWith;

  /// No description provided for @prioritiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose one or more. We will use this to shape your starting workspace.'**
  String get prioritiesSubtitle;

  /// No description provided for @priorityDeadlines.
  ///
  /// In en, this message translates to:
  /// **'Stay ahead of deadlines'**
  String get priorityDeadlines;

  /// No description provided for @priorityDeadlinesBody.
  ///
  /// In en, this message translates to:
  /// **'See what is due and what needs attention now.'**
  String get priorityDeadlinesBody;

  /// No description provided for @priorityDocuments.
  ///
  /// In en, this message translates to:
  /// **'Keep documents moving'**
  String get priorityDocuments;

  /// No description provided for @priorityDocumentsBody.
  ///
  /// In en, this message translates to:
  /// **'Make requests, uploads and follow-ups clear.'**
  String get priorityDocumentsBody;

  /// No description provided for @priorityTeamwork.
  ///
  /// In en, this message translates to:
  /// **'Run work with a team'**
  String get priorityTeamwork;

  /// No description provided for @priorityTeamworkBody.
  ///
  /// In en, this message translates to:
  /// **'Keep ownership, hand-offs and reviews visible.'**
  String get priorityTeamworkBody;

  /// No description provided for @priorityVisibility.
  ///
  /// In en, this message translates to:
  /// **'See the whole practice clearly'**
  String get priorityVisibility;

  /// No description provided for @priorityVisibilityBody.
  ///
  /// In en, this message translates to:
  /// **'Understand progress without chasing updates.'**
  String get priorityVisibilityBody;

  /// No description provided for @choosePriorityRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one priority.'**
  String get choosePriorityRequired;

  /// No description provided for @finishSetup.
  ///
  /// In en, this message translates to:
  /// **'Finish setup'**
  String get finishSetup;

  /// No description provided for @putSomethingUsefulInside.
  ///
  /// In en, this message translates to:
  /// **'How would you like to begin?'**
  String get putSomethingUsefulInside;

  /// No description provided for @startingPointSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start with something real or explore safely with sample data. You can change this later.'**
  String get startingPointSubtitle;

  /// No description provided for @startingPointImport.
  ///
  /// In en, this message translates to:
  /// **'Import a client list'**
  String get startingPointImport;

  /// No description provided for @startingPointImportBody.
  ///
  /// In en, this message translates to:
  /// **'Best when your practice already runs from a spreadsheet.'**
  String get startingPointImportBody;

  /// No description provided for @startingPointClient.
  ///
  /// In en, this message translates to:
  /// **'Add the first client'**
  String get startingPointClient;

  /// No description provided for @startingPointClientBody.
  ///
  /// In en, this message translates to:
  /// **'Start with one real taxpayer and the work you manage for them.'**
  String get startingPointClientBody;

  /// No description provided for @startingPointSample.
  ///
  /// In en, this message translates to:
  /// **'Explore a sample workspace'**
  String get startingPointSample;

  /// No description provided for @startingPointSampleBody.
  ///
  /// In en, this message translates to:
  /// **'See Molo in motion before adding any practice data.'**
  String get startingPointSampleBody;

  /// No description provided for @chooseStartingPointRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose how you would like to begin.'**
  String get chooseStartingPointRequired;

  /// No description provided for @buildMyWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Build my workspace'**
  String get buildMyWorkspace;

  /// No description provided for @workspacePreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Your workspace'**
  String get workspacePreviewTitle;

  /// No description provided for @workspacePreviewPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Your practice'**
  String get workspacePreviewPlaceholder;

  /// No description provided for @workspacePreviewBody.
  ///
  /// In en, this message translates to:
  /// **'A clear place for clients, documents, deadlines and your team.'**
  String get workspacePreviewBody;

  /// Readiness of the workspace during onboarding.
  ///
  /// In en, this message translates to:
  /// **'Workspace {percent}% ready'**
  String workspaceReadiness(int percent);

  /// Registration preview completion heading.
  ///
  /// In en, this message translates to:
  /// **'Your workspace is ready, {name}'**
  String registrationCompleteTitle(String name);

  /// Registration preview completion body.
  ///
  /// In en, this message translates to:
  /// **'{practiceName} is shaped around what matters to you.'**
  String registrationCompleteBody(String practiceName);

  /// No description provided for @registrationCompleteSummary.
  ///
  /// In en, this message translates to:
  /// **'Your practice defaults, first priorities and preferred starting point are ready for the real account flow.'**
  String get registrationCompleteSummary;

  /// No description provided for @continueToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Continue to sign in'**
  String get continueToSignIn;

  /// No description provided for @noRegistrationDataSaved.
  ///
  /// In en, this message translates to:
  /// **'Preview complete. No account or practice data was saved.'**
  String get noRegistrationDataSaved;

  /// No description provided for @registrationHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Watch your workspace take shape.'**
  String get registrationHeroTitle;

  /// No description provided for @registrationHeroBody.
  ///
  /// In en, this message translates to:
  /// **'Every choice should make Molo more useful before you arrive at the home screen.'**
  String get registrationHeroBody;

  /// No description provided for @progressAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get progressAccount;

  /// No description provided for @progressAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Your secure way into Molo.'**
  String get progressAccountBody;

  /// No description provided for @progressPractice.
  ///
  /// In en, this message translates to:
  /// **'Shape your practice'**
  String get progressPractice;

  /// No description provided for @progressPracticeBody.
  ///
  /// In en, this message translates to:
  /// **'Start solo or bring your team.'**
  String get progressPracticeBody;

  /// No description provided for @progressPriorities.
  ///
  /// In en, this message translates to:
  /// **'Choose your focus'**
  String get progressPriorities;

  /// No description provided for @progressPrioritiesBody.
  ///
  /// In en, this message translates to:
  /// **'Make the first workspace feel relevant.'**
  String get progressPrioritiesBody;

  /// Compact registration progress label.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String registrationProgress(int current, int total);

  /// No description provided for @backLabel.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'ZA':
            return AppLocalizationsEnZa();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
