import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_th.dart';
import 'app_localizations_vi.dart';

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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('ms'),
    Locale('pt'),
    Locale('th'),
    Locale('vi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MuseMend'**
  String get appTitle;

  /// No description provided for @navSky.
  ///
  /// In en, this message translates to:
  /// **'Sky'**
  String get navSky;

  /// No description provided for @navJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get navJournal;

  /// No description provided for @navExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get navExplore;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic (device)'**
  String get languageAutomatic;

  /// No description provided for @languageAutomaticDescription.
  ///
  /// In en, this message translates to:
  /// **'Uses your device language. Unsupported languages use English.'**
  String get languageAutomaticDescription;

  /// No description provided for @profileAndSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile and settings'**
  String get profileAndSettings;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @cloudName.
  ///
  /// In en, this message translates to:
  /// **'Cloud name'**
  String get cloudName;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Device setting'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @settingsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Settings updated.'**
  String get settingsUpdated;

  /// No description provided for @settingsUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update settings.'**
  String get settingsUpdateFailed;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @authAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Your account has been created. Please check your email if confirmation is required.'**
  String get authAccountCreated;

  /// No description provided for @authMascotSemantics.
  ///
  /// In en, this message translates to:
  /// **'MuseMend cloud mascot'**
  String get authMascotSemantics;

  /// No description provided for @authWelcomeHeadline.
  ///
  /// In en, this message translates to:
  /// **'A sky of your own\nfor days that need a little softness.'**
  String get authWelcomeHeadline;

  /// No description provided for @authWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Notice your feelings, complete small acts of care, and keep moving along your own journey.'**
  String get authWelcomeBody;

  /// No description provided for @authSignUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your own sky'**
  String get authSignUpTitle;

  /// No description provided for @authSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authSignInTitle;

  /// No description provided for @authSignUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Begin with just a few simple details.'**
  String get authSignUpSubtitle;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let’s slow down together for a moment today.'**
  String get authSignInSubtitle;

  /// No description provided for @authDisplayNameLength.
  ///
  /// In en, this message translates to:
  /// **'Your name must be between 2 and 60 characters.'**
  String get authDisplayNameLength;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get authEmailInvalid;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// No description provided for @authPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Your password must be at least 8 characters.'**
  String get authPasswordMinLength;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authSwitchToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authSwitchToSignIn;

  /// No description provided for @authSwitchToSignUp.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get authSwitchToSignUp;

  /// No description provided for @authNetworkError.
  ///
  /// In en, this message translates to:
  /// **'We can’t connect right now. Please try again.'**
  String get authNetworkError;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'That email or password doesn’t look right.'**
  String get authInvalidCredentials;

  /// No description provided for @authEmailAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'An account already uses this email.'**
  String get authEmailAlreadyRegistered;

  /// No description provided for @authEmailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your email before signing in.'**
  String get authEmailNotConfirmed;

  /// No description provided for @authWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'This password does not meet the security requirements.'**
  String get authWeakPassword;

  /// No description provided for @onboardingBackToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get onboardingBackToSignIn;

  /// No description provided for @onboardingNameLength.
  ///
  /// In en, this message translates to:
  /// **'Your name must be between 2 and 80 characters.'**
  String get onboardingNameLength;

  /// No description provided for @onboardingFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Muse’s friend'**
  String get onboardingFallbackName;

  /// No description provided for @onboardingSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t save this. Check your connection and try again.'**
  String get onboardingSaveFailed;

  /// No description provided for @onboardingStartWithMuse.
  ///
  /// In en, this message translates to:
  /// **'Begin with Muse'**
  String get onboardingStartWithMuse;

  /// No description provided for @onboardingWelcomeHeadline.
  ///
  /// In en, this message translates to:
  /// **'A place to listen to yourself,\nwith a little more gentleness.'**
  String get onboardingWelcomeHeadline;

  /// No description provided for @onboardingEmotionTitle.
  ///
  /// In en, this message translates to:
  /// **'Name what you feel'**
  String get onboardingEmotionTitle;

  /// No description provided for @onboardingEmotionDescription.
  ///
  /// In en, this message translates to:
  /// **'Notice how you are feeling today.'**
  String get onboardingEmotionDescription;

  /// No description provided for @onboardingPrivateWritingTitle.
  ///
  /// In en, this message translates to:
  /// **'Write just for you'**
  String get onboardingPrivateWritingTitle;

  /// No description provided for @onboardingPrivateWritingDescription.
  ///
  /// In en, this message translates to:
  /// **'A quiet page for the things that are hard to say aloud.'**
  String get onboardingPrivateWritingDescription;

  /// No description provided for @onboardingSmallStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Care through small steps'**
  String get onboardingSmallStepsTitle;

  /// No description provided for @onboardingSmallStepsDescription.
  ///
  /// In en, this message translates to:
  /// **'Gentle, manageable acts that can make today feel a little lighter.'**
  String get onboardingSmallStepsDescription;

  /// No description provided for @onboardingPrivacyHeadline.
  ///
  /// In en, this message translates to:
  /// **'What is private to you\nshould remain yours.'**
  String get onboardingPrivacyHeadline;

  /// No description provided for @onboardingPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'MuseMend is being built around privacy and your choices.'**
  String get onboardingPrivacyBody;

  /// No description provided for @onboardingDeviceJournalTitle.
  ///
  /// In en, this message translates to:
  /// **'Journal kept on your device'**
  String get onboardingDeviceJournalTitle;

  /// No description provided for @onboardingDeviceJournalDescription.
  ///
  /// In en, this message translates to:
  /// **'Your private thoughts stay safely here with you.'**
  String get onboardingDeviceJournalDescription;

  /// No description provided for @onboardingOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Available offline'**
  String get onboardingOfflineTitle;

  /// No description provided for @onboardingOfflineDescription.
  ///
  /// In en, this message translates to:
  /// **'Even without a connection, Muse is still here.'**
  String get onboardingOfflineDescription;

  /// No description provided for @onboardingOptionalBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup is optional'**
  String get onboardingOptionalBackupTitle;

  /// No description provided for @onboardingOptionalBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Sync only when you truly want to.'**
  String get onboardingOptionalBackupDescription;

  /// No description provided for @onboardingNamePrompt.
  ///
  /// In en, this message translates to:
  /// **'What should Muse call you?'**
  String get onboardingNamePrompt;

  /// No description provided for @onboardingNameCanChange.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime from your Profile.'**
  String get onboardingNameCanChange;

  /// No description provided for @onboardingDisplayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name you’d like to show'**
  String get onboardingDisplayNameLabel;

  /// No description provided for @onboardingNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a name or leave this blank'**
  String get onboardingNameHint;

  /// No description provided for @onboardingAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'How Muse should address you'**
  String get onboardingAddressLabel;

  /// No description provided for @onboardingGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello {name}, it’s lovely to be here with you!'**
  String onboardingGreeting(String name);

  /// No description provided for @onboardingLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Muse couldn’t prepare your welcome just yet.'**
  String get onboardingLoadFailed;

  /// No description provided for @preferredAddressCauMinh.
  ///
  /// In en, this message translates to:
  /// **'close friends'**
  String get preferredAddressCauMinh;

  /// No description provided for @preferredAddressBanMinh.
  ///
  /// In en, this message translates to:
  /// **'you / me'**
  String get preferredAddressBanMinh;

  /// No description provided for @preferredAddressAnhEm.
  ///
  /// In en, this message translates to:
  /// **'older brother / younger sibling'**
  String get preferredAddressAnhEm;

  /// No description provided for @preferredAddressChiEm.
  ///
  /// In en, this message translates to:
  /// **'older sister / younger sibling'**
  String get preferredAddressChiEm;

  /// No description provided for @preferredAddressNameOnly.
  ///
  /// In en, this message translates to:
  /// **'name only'**
  String get preferredAddressNameOnly;

  /// No description provided for @profileTagline.
  ///
  /// In en, this message translates to:
  /// **'A quiet corner for your account and privacy.'**
  String get profileTagline;

  /// No description provided for @profileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your profile'**
  String get profileLoadFailed;

  /// No description provided for @profileMuseFriend.
  ///
  /// In en, this message translates to:
  /// **'Muse\'s friend'**
  String get profileMuseFriend;

  /// No description provided for @profileProtectedEmail.
  ///
  /// In en, this message translates to:
  /// **'Protected email'**
  String get profileProtectedEmail;

  /// No description provided for @profileCloudNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Your cloud\'s name'**
  String get profileCloudNameTitle;

  /// No description provided for @profileFutureLetterReminder.
  ///
  /// In en, this message translates to:
  /// **'Remind me about future letters on this device'**
  String get profileFutureLetterReminder;

  /// No description provided for @profileEditSettings.
  ///
  /// In en, this message translates to:
  /// **'Edit profile and settings'**
  String get profileEditSettings;

  /// No description provided for @profileInboxTitle.
  ///
  /// In en, this message translates to:
  /// **'In-app notifications'**
  String get profileInboxTitle;

  /// No description provided for @profileInboxLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your notifications'**
  String get profileInboxLoadFailed;

  /// No description provided for @profileInboxEmpty.
  ///
  /// In en, this message translates to:
  /// **'No new notifications'**
  String get profileInboxEmpty;

  /// No description provided for @profileInboxEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Letters that are ready to open will appear here.'**
  String get profileInboxEmptyDescription;

  /// No description provided for @profilePrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get profilePrivacyTitle;

  /// No description provided for @profilePrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'Your journals are stored privately on Supabase and protected by row-level security so only your account can read them. MuseMend never includes letter content in lock-screen notifications. The MVP does not yet provide end-to-end encryption or data export.'**
  String get profilePrivacyBody;

  /// No description provided for @profileTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms and limitations'**
  String get profileTermsTitle;

  /// No description provided for @profileTermsBody.
  ///
  /// In en, this message translates to:
  /// **'MuseMend is a reflection aid, not a diagnostic tool or a substitute for medical or mental-health care. If you are in immediate danger, contact emergency services or someone you trust.'**
  String get profileTermsBody;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileSignOut;

  /// No description provided for @profileRequestDeletion.
  ///
  /// In en, this message translates to:
  /// **'Request account deletion'**
  String get profileRequestDeletion;

  /// No description provided for @profileDeletionRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t submit your account deletion request.'**
  String get profileDeletionRequestFailed;

  /// No description provided for @profileDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account permanently?'**
  String get profileDeleteTitle;

  /// No description provided for @profileDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This request locks your account immediately, hides your journals, and queues private files for deletion. It cannot currently be undone.'**
  String get profileDeleteBody;

  /// No description provided for @profileDeleteConfirmationPrompt.
  ///
  /// In en, this message translates to:
  /// **'Type {keyword} to confirm:'**
  String profileDeleteConfirmationPrompt(String keyword);

  /// No description provided for @profileDeleteConfirmationKeyword.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get profileDeleteConfirmationKeyword;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get profileDeleteAccount;

  /// No description provided for @profileFutureLetterDue.
  ///
  /// In en, this message translates to:
  /// **'Your future letter is ready'**
  String get profileFutureLetterDue;

  /// No description provided for @profileFutureLetterScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled for {date}'**
  String profileFutureLetterScheduled(String date);

  /// No description provided for @moodAwful.
  ///
  /// In en, this message translates to:
  /// **'ANGRY'**
  String get moodAwful;

  /// No description provided for @moodSad.
  ///
  /// In en, this message translates to:
  /// **'EMPTY'**
  String get moodSad;

  /// No description provided for @moodOkay.
  ///
  /// In en, this message translates to:
  /// **'OKAY'**
  String get moodOkay;

  /// No description provided for @moodGood.
  ///
  /// In en, this message translates to:
  /// **'RELAXED'**
  String get moodGood;

  /// No description provided for @moodGreat.
  ///
  /// In en, this message translates to:
  /// **'HEALING'**
  String get moodGreat;

  /// No description provided for @moodRecorded.
  ///
  /// In en, this message translates to:
  /// **'Feeling {mood} has been noted.'**
  String moodRecorded(String mood);

  /// No description provided for @moodSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save how you feel. Please try again.'**
  String get moodSaveFailed;

  /// No description provided for @moodPickerPrompt.
  ///
  /// In en, this message translates to:
  /// **'How is your cloud feeling today?'**
  String get moodPickerPrompt;

  /// No description provided for @moodCloudSemantics.
  ///
  /// In en, this message translates to:
  /// **'Mood cloud. Tap to return to Sky, or press and hold to choose a feeling.'**
  String get moodCloudSemantics;

  /// No description provided for @checkinSaved.
  ///
  /// In en, this message translates to:
  /// **'Today\'s check-in has been saved.'**
  String get checkinSaved;

  /// No description provided for @checkinSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save this yet. Please try again.'**
  String get checkinSaveFailed;

  /// No description provided for @skyStatusSemantics.
  ///
  /// In en, this message translates to:
  /// **'{energy} energy, {streak}-day streak'**
  String skyStatusSemantics(int energy, int streak);

  /// No description provided for @checkinMoodPrompt.
  ///
  /// In en, this message translates to:
  /// **'Has today been gentle with you?'**
  String get checkinMoodPrompt;

  /// No description provided for @checkinQuickSave.
  ///
  /// In en, this message translates to:
  /// **'QUICK SAVE'**
  String get checkinQuickSave;

  /// No description provided for @checkinUpdateToday.
  ///
  /// In en, this message translates to:
  /// **'Update today\'s check-in'**
  String get checkinUpdateToday;

  /// No description provided for @checkinSaveToday.
  ///
  /// In en, this message translates to:
  /// **'Quick-save today\'s check-in'**
  String get checkinSaveToday;

  /// No description provided for @checkinSaveAndWrite.
  ///
  /// In en, this message translates to:
  /// **'SAVE AND WRITE'**
  String get checkinSaveAndWrite;

  /// No description provided for @skyMascotSemantics.
  ///
  /// In en, this message translates to:
  /// **'MuseMend cloud companion'**
  String get skyMascotSemantics;

  /// No description provided for @skyCompanionSemantics.
  ///
  /// In en, this message translates to:
  /// **'Your cloud companion'**
  String get skyCompanionSemantics;

  /// No description provided for @journeyProgressSemantics.
  ///
  /// In en, this message translates to:
  /// **'Journey {name}, stop {current} of {total}'**
  String journeyProgressSemantics(String name, int current, int total);

  /// No description provided for @journeyWaiting.
  ///
  /// In en, this message translates to:
  /// **'waiting'**
  String get journeyWaiting;

  /// No description provided for @journeyDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'JOURNEY'**
  String get journeyDefaultTitle;

  /// No description provided for @checkpointLabel.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get checkpointLabel;

  /// No description provided for @journeyDataWaiting.
  ///
  /// In en, this message translates to:
  /// **'Your journey will appear when its stops are ready.'**
  String get journeyDataWaiting;

  /// No description provided for @quoteLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Today\'s gentle note couldn\'t be loaded.'**
  String get quoteLoadFailed;

  /// No description provided for @shareMoments.
  ///
  /// In en, this message translates to:
  /// **'Share a moment'**
  String get shareMoments;

  /// No description provided for @shareWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'A nourishing week'**
  String get shareWeekTitle;

  /// No description provided for @shareWeekSubtitle.
  ///
  /// In en, this message translates to:
  /// **'7-day template'**
  String get shareWeekSubtitle;

  /// No description provided for @shareMonthTitle.
  ///
  /// In en, this message translates to:
  /// **'Your month in moments'**
  String get shareMonthTitle;

  /// No description provided for @shareMonthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A collage of 6 photos'**
  String get shareMonthSubtitle;

  /// No description provided for @shareYearTitle.
  ///
  /// In en, this message translates to:
  /// **'A gentle year'**
  String get shareYearTitle;

  /// No description provided for @shareYearSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Moments worth remembering'**
  String get shareYearSubtitle;

  /// No description provided for @shareTemplateComingSoon.
  ///
  /// In en, this message translates to:
  /// **'The “{title}” sharing template will be ready in a future update.'**
  String shareTemplateComingSoon(String title);

  /// No description provided for @shareAction.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareAction;

  /// No description provided for @userDataLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your data.'**
  String get userDataLoadFailed;

  /// No description provided for @missionLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your missions.'**
  String get missionLoadFailed;

  /// No description provided for @missionToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s missions'**
  String get missionToday;

  /// No description provided for @missionTaskCount.
  ///
  /// In en, this message translates to:
  /// **'{count} tasks'**
  String missionTaskCount(int count);

  /// No description provided for @missionCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Create your own mission'**
  String get missionCreateNew;

  /// No description provided for @missionMuseSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions from Muse'**
  String get missionMuseSuggestions;

  /// No description provided for @missionSuggestionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Small steps that fit how you feel today.'**
  String get missionSuggestionsDescription;

  /// No description provided for @missionSuggestionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You\'ve added all of today\'s fitting suggestions.'**
  String get missionSuggestionsEmpty;

  /// No description provided for @missionCompleteFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t complete this mission. Please try again.'**
  String get missionCompleteFailed;

  /// No description provided for @missionAlreadyCompleted.
  ///
  /// In en, this message translates to:
  /// **'This mission was already completed.'**
  String get missionAlreadyCompleted;

  /// No description provided for @missionRewardReceived.
  ///
  /// In en, this message translates to:
  /// **'You received {reward} energy.'**
  String missionRewardReceived(int reward);

  /// No description provided for @missionSkipped.
  ///
  /// In en, this message translates to:
  /// **'Mission skipped. No energy was deducted.'**
  String get missionSkipped;

  /// No description provided for @missionSkipFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t skip this mission.'**
  String get missionSkipFailed;

  /// No description provided for @missionAdded.
  ///
  /// In en, this message translates to:
  /// **'Mission added.'**
  String get missionAdded;

  /// No description provided for @missionAddFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t add this mission.'**
  String get missionAddFailed;

  /// No description provided for @missionCustomAdded.
  ///
  /// In en, this message translates to:
  /// **'Your mission was added with a reward of 5 energy.'**
  String get missionCustomAdded;

  /// No description provided for @missionCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t create this mission.'**
  String get missionCreateFailed;

  /// No description provided for @missionCareToday.
  ///
  /// In en, this message translates to:
  /// **'Care for\ntoday'**
  String get missionCareToday;

  /// No description provided for @missionGentleStep.
  ///
  /// In en, this message translates to:
  /// **'Be gentle with yourself through one small step.'**
  String get missionGentleStep;

  /// No description provided for @missionTypeDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get missionTypeDaily;

  /// No description provided for @missionTypeWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get missionTypeWeekly;

  /// No description provided for @missionTypeMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get missionTypeMonthly;

  /// No description provided for @missionTypeYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get missionTypeYearly;

  /// No description provided for @missionTypeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get missionTypeCustom;

  /// No description provided for @missionGroupType.
  ///
  /// In en, this message translates to:
  /// **'{type} missions'**
  String missionGroupType(String type);

  /// No description provided for @missionSuggestionMeta.
  ///
  /// In en, this message translates to:
  /// **'{type} · {minutes} min · +{energy} energy'**
  String missionSuggestionMeta(String type, int minutes, int energy);

  /// No description provided for @missionAddTemplate.
  ///
  /// In en, this message translates to:
  /// **'Add suggested mission'**
  String get missionAddTemplate;

  /// No description provided for @missionPeriodMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get missionPeriodMorning;

  /// No description provided for @missionPeriodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get missionPeriodAfternoon;

  /// No description provided for @missionPeriodEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get missionPeriodEvening;

  /// No description provided for @missionPeriodAnytime.
  ///
  /// In en, this message translates to:
  /// **'Anytime'**
  String get missionPeriodAnytime;

  /// No description provided for @missionCurrentLandmarkSemantics.
  ///
  /// In en, this message translates to:
  /// **'Illustration of the current stop\'s landmark'**
  String get missionCurrentLandmarkSemantics;

  /// No description provided for @missionAddToGroup.
  ///
  /// In en, this message translates to:
  /// **'Add a mission to {group}'**
  String missionAddToGroup(String group);

  /// No description provided for @missionComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get missionComplete;

  /// No description provided for @missionOptions.
  ///
  /// In en, this message translates to:
  /// **'Mission options'**
  String get missionOptions;

  /// No description provided for @missionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip mission'**
  String get missionSkip;

  /// No description provided for @missionEnergyAccumulated.
  ///
  /// In en, this message translates to:
  /// **'Accumulated energy'**
  String get missionEnergyAccumulated;

  /// No description provided for @missionEnergySummary.
  ///
  /// In en, this message translates to:
  /// **'{current} total · {available} ready for your journey'**
  String missionEnergySummary(int current, int available);

  /// No description provided for @missionEnergyReward.
  ///
  /// In en, this message translates to:
  /// **'+{energy} energy'**
  String missionEnergyReward(int energy);

  /// No description provided for @missionEmpty.
  ///
  /// In en, this message translates to:
  /// **'No missions yet. Choose one gentle little step.'**
  String get missionEmpty;

  /// No description provided for @missionCustomSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Your mission'**
  String get missionCustomSheetTitle;

  /// No description provided for @missionSuggestionSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a Muse suggestion'**
  String get missionSuggestionSheetTitle;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @missionCustomRewardDescription.
  ///
  /// In en, this message translates to:
  /// **'Your own missions always reward 5 energy.'**
  String get missionCustomRewardDescription;

  /// No description provided for @missionSuggestionPrepared.
  ///
  /// In en, this message translates to:
  /// **'Muse has prepared this suggestion for you.'**
  String get missionSuggestionPrepared;

  /// No description provided for @missionName.
  ///
  /// In en, this message translates to:
  /// **'Mission name'**
  String get missionName;

  /// No description provided for @missionNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a mission name'**
  String get missionNameHint;

  /// No description provided for @missionNameValidation.
  ///
  /// In en, this message translates to:
  /// **'Mission name must be between 1 and 200 characters.'**
  String get missionNameValidation;

  /// No description provided for @missionNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get missionNoteOptional;

  /// No description provided for @missionNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add a gentle reminder'**
  String get missionNoteHint;

  /// No description provided for @missionSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get missionSchedule;

  /// No description provided for @missionAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add mission'**
  String get missionAddAction;

  /// No description provided for @missionStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get missionStart;

  /// No description provided for @missionEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get missionEnd;

  /// No description provided for @missionDailyRenewal.
  ///
  /// In en, this message translates to:
  /// **'Placed in {period} and refreshed every day.'**
  String missionDailyRenewal(String period);

  /// No description provided for @missionWeeklyEnd.
  ///
  /// In en, this message translates to:
  /// **'Ends at 00:00 at the start of next week.'**
  String get missionWeeklyEnd;

  /// No description provided for @missionMonthlyEnd.
  ///
  /// In en, this message translates to:
  /// **'Ends at 00:00 on the first day of next month.'**
  String get missionMonthlyEnd;

  /// No description provided for @missionYearlyEnd.
  ///
  /// In en, this message translates to:
  /// **'Ends at 00:00 on the first day of next year.'**
  String get missionYearlyEnd;

  /// No description provided for @missionEndTimeAfterStart.
  ///
  /// In en, this message translates to:
  /// **'The end time must be later than the start time on the same day.'**
  String get missionEndTimeAfterStart;

  /// No description provided for @missionEndTimeFuture.
  ///
  /// In en, this message translates to:
  /// **'The end time must be in the future.'**
  String get missionEndTimeFuture;

  /// No description provided for @missionEndDateFuture.
  ///
  /// In en, this message translates to:
  /// **'The end must be in the future and later than the start.'**
  String get missionEndDateFuture;

  /// No description provided for @missionTimeFormat.
  ///
  /// In en, this message translates to:
  /// **'Enter time as HH:mm.'**
  String get missionTimeFormat;

  /// No description provided for @missionDateFormat.
  ///
  /// In en, this message translates to:
  /// **'Enter date as dd/MM/yyyy.'**
  String get missionDateFormat;

  /// No description provided for @missionDateNotPast.
  ///
  /// In en, this message translates to:
  /// **'Choose today or a future date.'**
  String get missionDateNotPast;

  /// No description provided for @missionDateField.
  ///
  /// In en, this message translates to:
  /// **'{label} · date'**
  String missionDateField(String label);

  /// No description provided for @missionTimeField.
  ///
  /// In en, this message translates to:
  /// **'{label} · time'**
  String missionTimeField(String label);

  /// No description provided for @missionType.
  ///
  /// In en, this message translates to:
  /// **'Mission type'**
  String get missionType;

  /// No description provided for @missionDue.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String missionDue(String date);

  /// No description provided for @journalTagline.
  ///
  /// In en, this message translates to:
  /// **'A small page each day to find your way back to yourself.'**
  String get journalTagline;

  /// No description provided for @futureLetters.
  ///
  /// In en, this message translates to:
  /// **'Letters to the future'**
  String get futureLetters;

  /// No description provided for @futureLetterWriteNew.
  ///
  /// In en, this message translates to:
  /// **'Write a new letter'**
  String get futureLetterWriteNew;

  /// No description provided for @futureLettersDescription.
  ///
  /// In en, this message translates to:
  /// **'Messages you want to send to a day ahead.'**
  String get futureLettersDescription;

  /// No description provided for @journalEntryNotFound.
  ///
  /// In en, this message translates to:
  /// **'This journal entry couldn\'t be found.'**
  String get journalEntryNotFound;

  /// No description provided for @journalMoodRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose today\'s mood before writing. You can change it anytime.'**
  String get journalMoodRequired;

  /// No description provided for @journalChooseMood.
  ///
  /// In en, this message translates to:
  /// **'Choose mood'**
  String get journalChooseMood;

  /// No description provided for @journalDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get journalDeleteTitle;

  /// No description provided for @journalDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The entry will be hidden now. Related files follow the soft-deletion policy.'**
  String get journalDeleteBody;

  /// No description provided for @keep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keep;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @journalDeleted.
  ///
  /// In en, this message translates to:
  /// **'Journal entry deleted.'**
  String get journalDeleted;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save this yet. Please try again.'**
  String get saveFailed;

  /// No description provided for @futureLetterOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t open this letter. Please try again.'**
  String get futureLetterOpenFailed;

  /// No description provided for @dailyJournal.
  ///
  /// In en, this message translates to:
  /// **'Daily journal'**
  String get dailyJournal;

  /// No description provided for @journalChooseMoodFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose a mood first'**
  String get journalChooseMoodFirst;

  /// No description provided for @journalEditToday.
  ///
  /// In en, this message translates to:
  /// **'Edit today'**
  String get journalEditToday;

  /// No description provided for @journalWriteToday.
  ///
  /// In en, this message translates to:
  /// **'Write today'**
  String get journalWriteToday;

  /// No description provided for @journalPastHint.
  ///
  /// In en, this message translates to:
  /// **'Scroll down through earlier months to revisit what you\'ve written.'**
  String get journalPastHint;

  /// No description provided for @journalViewing.
  ///
  /// In en, this message translates to:
  /// **'Viewing'**
  String get journalViewing;

  /// No description provided for @journalDaySemantics.
  ///
  /// In en, this message translates to:
  /// **'Day {day}, month {month}{mood}{written}'**
  String journalDaySemantics(
    Object day,
    Object month,
    Object mood,
    Object written,
  );

  /// No description provided for @journalMoodSemantics.
  ///
  /// In en, this message translates to:
  /// **', {mood}'**
  String journalMoodSemantics(Object mood);

  /// No description provided for @journalWrittenSemantics.
  ///
  /// In en, this message translates to:
  /// **', journal written'**
  String get journalWrittenSemantics;

  /// No description provided for @futureLettersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No letters yet. Would you like to leave a note for your future self?'**
  String get futureLettersEmpty;

  /// No description provided for @futureLetterWriteFirst.
  ///
  /// In en, this message translates to:
  /// **'Write your first letter'**
  String get futureLetterWriteFirst;

  /// No description provided for @journalMyDay.
  ///
  /// In en, this message translates to:
  /// **'A day of mine'**
  String get journalMyDay;

  /// No description provided for @futureLetterScheduleState.
  ///
  /// In en, this message translates to:
  /// **'For {date} · {state}'**
  String futureLetterScheduleState(Object date, Object state);

  /// No description provided for @futureLetterUnopened.
  ///
  /// In en, this message translates to:
  /// **'unopened'**
  String get futureLetterUnopened;

  /// No description provided for @futureLetterOpened.
  ///
  /// In en, this message translates to:
  /// **'opened'**
  String get futureLetterOpened;

  /// No description provided for @futureLetterOptions.
  ///
  /// In en, this message translates to:
  /// **'Letter options'**
  String get futureLetterOptions;

  /// No description provided for @futureLetterDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete letter'**
  String get futureLetterDelete;

  /// No description provided for @journalNoContent.
  ///
  /// In en, this message translates to:
  /// **'No content yet'**
  String get journalNoContent;

  /// No description provided for @journalLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Your journal couldn\'t be loaded right now.'**
  String get journalLoadFailed;

  /// No description provided for @futureLetterCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Letter to the future'**
  String get futureLetterCreateTitle;

  /// No description provided for @futureLetterEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit letter'**
  String get futureLetterEditTitle;

  /// No description provided for @journalWriteTitle.
  ///
  /// In en, this message translates to:
  /// **'Write for today'**
  String get journalWriteTitle;

  /// No description provided for @journalEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit journal'**
  String get journalEditTitle;

  /// No description provided for @futureLetterTitleHint.
  ///
  /// In en, this message translates to:
  /// **'A note for the days ahead'**
  String get futureLetterTitleHint;

  /// No description provided for @journalTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get journalTitleHint;

  /// No description provided for @journalContentHint.
  ///
  /// In en, this message translates to:
  /// **'What would you like to tell yourself today?'**
  String get journalContentHint;

  /// No description provided for @journalTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get journalTags;

  /// No description provided for @journalTagsHint.
  ///
  /// In en, this message translates to:
  /// **'family, learning, gratitude'**
  String get journalTagsHint;

  /// No description provided for @futureLetterDeviceReminder.
  ///
  /// In en, this message translates to:
  /// **'Remind me on this device'**
  String get futureLetterDeviceReminder;

  /// No description provided for @futureLetterReminderPrivate.
  ///
  /// In en, this message translates to:
  /// **'Notifications contain only a general reminder, never your private words.'**
  String get futureLetterReminderPrivate;

  /// No description provided for @futureLetterReminderDisabled.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications in Profile first.'**
  String get futureLetterReminderDisabled;

  /// No description provided for @futureLetterDeliveryDate.
  ///
  /// In en, this message translates to:
  /// **'Delivery date'**
  String get futureLetterDeliveryDate;

  /// No description provided for @futureLetterCanOpenEarly.
  ///
  /// In en, this message translates to:
  /// **'You can still open this letter before then'**
  String get futureLetterCanOpenEarly;

  /// No description provided for @journalContentValidation.
  ///
  /// In en, this message translates to:
  /// **'Write a few lines and check your tags.'**
  String get journalContentValidation;

  /// No description provided for @futureLetterReminderFailed.
  ///
  /// In en, this message translates to:
  /// **'Your letter was saved, but the device reminder couldn\'t be enabled.'**
  String get futureLetterReminderFailed;

  /// No description provided for @journalSaveBeforeImage.
  ///
  /// In en, this message translates to:
  /// **'Save this page before adding an image to your note.'**
  String get journalSaveBeforeImage;

  /// No description provided for @journalImageSaved.
  ///
  /// In en, this message translates to:
  /// **'Your image was saved privately.'**
  String get journalImageSaved;

  /// No description provided for @journalImageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The image is larger than 10 MiB.'**
  String get journalImageTooLarge;

  /// No description provided for @journalImageUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Only JPG, PNG, WebP, or HEIC images are supported.'**
  String get journalImageUnsupported;

  /// No description provided for @journalImageUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'The image couldn\'t be uploaded. Please try again.'**
  String get journalImageUploadFailed;

  /// No description provided for @journalWritingDate.
  ///
  /// In en, this message translates to:
  /// **'Written · {date}'**
  String journalWritingDate(Object date);

  /// No description provided for @journalFullDate.
  ///
  /// In en, this message translates to:
  /// **'{day}/{month}/{year}'**
  String journalFullDate(Object day, Object month, Object year);

  /// No description provided for @journalImageAttach.
  ///
  /// In en, this message translates to:
  /// **'Attach images'**
  String get journalImageAttach;

  /// No description provided for @journalImagesInEntry.
  ///
  /// In en, this message translates to:
  /// **'Images in this entry'**
  String get journalImagesInEntry;

  /// No description provided for @journalImageAdd.
  ///
  /// In en, this message translates to:
  /// **'Add image'**
  String get journalImageAdd;

  /// No description provided for @journalImageSwipeHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe or drag left and right to view images.'**
  String get journalImageSwipeHint;

  /// No description provided for @journalImageAddLater.
  ///
  /// In en, this message translates to:
  /// **'Save first, then add images whenever you like.'**
  String get journalImageAddLater;

  /// No description provided for @journalFilmStripSemantics.
  ///
  /// In en, this message translates to:
  /// **'Film strip with {count} attached images. Scroll horizontally to view them.'**
  String journalFilmStripSemantics(Object count);

  /// No description provided for @journalImageSemantics.
  ///
  /// In en, this message translates to:
  /// **'Attached image {index}'**
  String journalImageSemantics(Object index);

  /// No description provided for @exploreTagline.
  ///
  /// In en, this message translates to:
  /// **'Turn the small things you complete into a gentle journey.'**
  String get exploreTagline;

  /// No description provided for @journeyCollection.
  ///
  /// In en, this message translates to:
  /// **'Journey collection'**
  String get journeyCollection;

  /// No description provided for @journeyUnlockedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} memories unlocked'**
  String journeyUnlockedCount(Object count);

  /// No description provided for @journeyCompletedMetric.
  ///
  /// In en, this message translates to:
  /// **'completed'**
  String get journeyCompletedMetric;

  /// No description provided for @journeyEnergyReady.
  ///
  /// In en, this message translates to:
  /// **'energy ready'**
  String get journeyEnergyReady;

  /// No description provided for @journeySync.
  ///
  /// In en, this message translates to:
  /// **'Sync progress'**
  String get journeySync;

  /// No description provided for @journeyWaitingStops.
  ///
  /// In en, this message translates to:
  /// **'Stops ahead'**
  String get journeyWaitingStops;

  /// No description provided for @journeyNextDestination.
  ///
  /// In en, this message translates to:
  /// **'Continue to the next stop'**
  String get journeyNextDestination;

  /// No description provided for @journeyStart.
  ///
  /// In en, this message translates to:
  /// **'Begin journey'**
  String get journeyStart;

  /// No description provided for @journeyAllCompleted.
  ///
  /// In en, this message translates to:
  /// **'You\'ve completed every available destination. A new journey will open soon.'**
  String get journeyAllCompleted;

  /// No description provided for @journeyReady.
  ///
  /// In en, this message translates to:
  /// **'Your journey is ready.'**
  String get journeyReady;

  /// No description provided for @journeyStartFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t begin the journey. Please try again.'**
  String get journeyStartFailed;

  /// No description provided for @journeySyncFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t sync your progress. Please try again.'**
  String get journeySyncFailed;

  /// No description provided for @destinationSemantics.
  ///
  /// In en, this message translates to:
  /// **'Destination {name}, {description}'**
  String destinationSemantics(Object description, Object name);

  /// No description provided for @destinationImageSemantics.
  ///
  /// In en, this message translates to:
  /// **'Image of {name}'**
  String destinationImageSemantics(Object name);

  /// No description provided for @destinationProvince.
  ///
  /// In en, this message translates to:
  /// **'Province'**
  String get destinationProvince;

  /// No description provided for @destinationCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get destinationCity;

  /// No description provided for @destinationIsland.
  ///
  /// In en, this message translates to:
  /// **'Island'**
  String get destinationIsland;

  /// No description provided for @destinationHeritage.
  ///
  /// In en, this message translates to:
  /// **'Heritage site'**
  String get destinationHeritage;

  /// No description provided for @destinationRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get destinationRegion;

  /// No description provided for @destinationDefault.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destinationDefault;

  /// No description provided for @checkpointTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop {number} · {title}'**
  String checkpointTitle(Object number, Object title);

  /// No description provided for @checkpointEnergy.
  ///
  /// In en, this message translates to:
  /// **'{earned}/{required} energy'**
  String checkpointEnergy(Object earned, Object required);

  /// No description provided for @journeyStartDescription.
  ///
  /// In en, this message translates to:
  /// **'Set out to reveal your first destination. Each stop uses accumulated energy, with rewards chosen by Muse.'**
  String get journeyStartDescription;

  /// No description provided for @journeyStatusNotStarted.
  ///
  /// In en, this message translates to:
  /// **'The world is waiting for you'**
  String get journeyStatusNotStarted;

  /// No description provided for @journeyStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'Exploring'**
  String get journeyStatusInProgress;

  /// No description provided for @journeyStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Ready to continue'**
  String get journeyStatusPaused;

  /// No description provided for @journeyStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Journey completed'**
  String get journeyStatusCompleted;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @collectibleLandmark.
  ///
  /// In en, this message translates to:
  /// **'Landmarks'**
  String get collectibleLandmark;

  /// No description provided for @collectibleFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get collectibleFood;

  /// No description provided for @collectibleItem.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get collectibleItem;

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newLabel;

  /// No description provided for @rarityCommon.
  ///
  /// In en, this message translates to:
  /// **'Common'**
  String get rarityCommon;

  /// No description provided for @rarityUncommon.
  ///
  /// In en, this message translates to:
  /// **'Uncommon'**
  String get rarityUncommon;

  /// No description provided for @rarityRare.
  ///
  /// In en, this message translates to:
  /// **'Rare'**
  String get rarityRare;

  /// No description provided for @rarityEpic.
  ///
  /// In en, this message translates to:
  /// **'Epic'**
  String get rarityEpic;

  /// No description provided for @rarityLegendary.
  ///
  /// In en, this message translates to:
  /// **'Legendary'**
  String get rarityLegendary;

  /// No description provided for @collectionFilteredEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t unlocked any {kind} on this journey yet.'**
  String collectionFilteredEmpty(Object kind);

  /// No description provided for @collectionEmpty.
  ///
  /// In en, this message translates to:
  /// **'Complete a stop to unlock your first landmark, food, and item.'**
  String get collectionEmpty;

  /// No description provided for @journeyLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Your journey couldn\'t be loaded right now.'**
  String get journeyLoadFailed;

  /// No description provided for @futureLetterNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'A letter is waiting for you'**
  String get futureLetterNotificationTitle;

  /// No description provided for @futureLetterNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Open MuseMend whenever you feel ready.'**
  String get futureLetterNotificationBody;

  /// No description provided for @futureLetterNotificationChannel.
  ///
  /// In en, this message translates to:
  /// **'Future letters'**
  String get futureLetterNotificationChannel;

  /// No description provided for @futureLetterNotificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Reminders when a future letter is ready to open'**
  String get futureLetterNotificationChannelDescription;

  /// No description provided for @defaultCloudName.
  ///
  /// In en, this message translates to:
  /// **'Cloud'**
  String get defaultCloudName;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'id',
    'it',
    'ja',
    'ko',
    'ms',
    'pt',
    'th',
    'vi',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'ms':
      return AppLocalizationsMs();
    case 'pt':
      return AppLocalizationsPt();
    case 'th':
      return AppLocalizationsTh();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
