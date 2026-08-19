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
  /// **'Local preview · No data saved'**
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
  /// **'Sign in to continue to your practice.'**
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

  /// No description provided for @termsNotice.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to Molo\'\'s Terms and Privacy Policy.'**
  String get termsNotice;

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

  /// No description provided for @welcomeHeading.
  ///
  /// In en, this message translates to:
  /// **'You\'\'re in.'**
  String get welcomeHeading;

  /// Signed-in welcome using a safe display name or email.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String welcomeName(String name);

  /// No description provided for @previewWorkspaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Molo workspace is ready'**
  String get previewWorkspaceTitle;

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
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signingOut.
  ///
  /// In en, this message translates to:
  /// **'Signing out…'**
  String get signingOut;

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
