// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MuseMend';

  @override
  String get navSky => 'Sky';

  @override
  String get navJournal => 'Journal';

  @override
  String get navExplore => 'Explore';

  @override
  String get navProfile => 'Profile';

  @override
  String get language => 'Language';

  @override
  String get languageAutomatic => 'Automatic (device)';

  @override
  String get languageAutomaticDescription =>
      'Uses your device language. Unsupported languages use English.';

  @override
  String get profileAndSettings => 'Profile and settings';

  @override
  String get displayName => 'Display name';

  @override
  String get cloudName => 'Cloud name';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'Device setting';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get sound => 'Sound';

  @override
  String get notifications => 'Notifications';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get settingsUpdated => 'Settings updated.';

  @override
  String get settingsUpdateFailed => 'Could not update settings.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get back => 'Back';

  @override
  String get skip => 'Skip';

  @override
  String get continueLabel => 'Continue';

  @override
  String get retry => 'Try again';

  @override
  String get authAccountCreated =>
      'Your account has been created. Please check your email if confirmation is required.';

  @override
  String get authMascotSemantics => 'MuseMend cloud mascot';

  @override
  String get authWelcomeHeadline =>
      'A sky of your own\nfor days that need a little softness.';

  @override
  String get authWelcomeBody =>
      'Notice your feelings, complete small acts of care, and keep moving along your own journey.';

  @override
  String get authSignUpTitle => 'Create your own sky';

  @override
  String get authSignInTitle => 'Welcome back';

  @override
  String get authSignUpSubtitle => 'Begin with just a few simple details.';

  @override
  String get authSignInSubtitle =>
      'Let’s slow down together for a moment today.';

  @override
  String get authDisplayNameLength =>
      'Your name must be between 2 and 60 characters.';

  @override
  String get authEmailInvalid => 'Please enter a valid email address.';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authPasswordMinLength =>
      'Your password must be at least 8 characters.';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authSwitchToSignIn => 'Already have an account? Sign in';

  @override
  String get authSwitchToSignUp => 'New here? Create an account';

  @override
  String get authNetworkError =>
      'We can’t connect right now. Please try again.';

  @override
  String get authInvalidCredentials =>
      'That email or password doesn’t look right.';

  @override
  String get authEmailAlreadyRegistered =>
      'An account already uses this email.';

  @override
  String get authEmailNotConfirmed =>
      'Please confirm your email before signing in.';

  @override
  String get authWeakPassword =>
      'This password does not meet the security requirements.';

  @override
  String get onboardingBackToSignIn => 'Back to sign in';

  @override
  String get onboardingNameLength =>
      'Your name must be between 2 and 80 characters.';

  @override
  String get onboardingFallbackName => 'Muse’s friend';

  @override
  String get onboardingSaveFailed =>
      'We couldn’t save this. Check your connection and try again.';

  @override
  String get onboardingStartWithMuse => 'Begin with Muse';

  @override
  String get onboardingWelcomeHeadline =>
      'A place to listen to yourself,\nwith a little more gentleness.';

  @override
  String get onboardingEmotionTitle => 'Name what you feel';

  @override
  String get onboardingEmotionDescription =>
      'Notice how you are feeling today.';

  @override
  String get onboardingPrivateWritingTitle => 'Write just for you';

  @override
  String get onboardingPrivateWritingDescription =>
      'A quiet page for the things that are hard to say aloud.';

  @override
  String get onboardingSmallStepsTitle => 'Care through small steps';

  @override
  String get onboardingSmallStepsDescription =>
      'Gentle, manageable acts that can make today feel a little lighter.';

  @override
  String get onboardingPrivacyHeadline =>
      'What is private to you\nshould remain yours.';

  @override
  String get onboardingPrivacyBody =>
      'MuseMend is being built around privacy and your choices.';

  @override
  String get onboardingDeviceJournalTitle => 'Journal kept on your device';

  @override
  String get onboardingDeviceJournalDescription =>
      'Your private thoughts stay safely here with you.';

  @override
  String get onboardingOfflineTitle => 'Available offline';

  @override
  String get onboardingOfflineDescription =>
      'Even without a connection, Muse is still here.';

  @override
  String get onboardingOptionalBackupTitle => 'Backup is optional';

  @override
  String get onboardingOptionalBackupDescription =>
      'Sync only when you truly want to.';

  @override
  String get onboardingNamePrompt => 'What should Muse call you?';

  @override
  String get onboardingNameCanChange =>
      'You can change this anytime from your Profile.';

  @override
  String get onboardingDisplayNameLabel => 'Name you’d like to show';

  @override
  String get onboardingNameHint => 'Enter a name or leave this blank';

  @override
  String get onboardingAddressLabel => 'How Muse should address you';

  @override
  String onboardingGreeting(String name) {
    return 'Hello $name, it’s lovely to be here with you!';
  }

  @override
  String get onboardingLoadFailed =>
      'Muse couldn’t prepare your welcome just yet.';

  @override
  String get preferredAddressCauMinh => 'close friends';

  @override
  String get preferredAddressBanMinh => 'you / me';

  @override
  String get preferredAddressAnhEm => 'older brother / younger sibling';

  @override
  String get preferredAddressChiEm => 'older sister / younger sibling';

  @override
  String get preferredAddressNameOnly => 'name only';

  @override
  String get profileTagline => 'A quiet corner for your account and privacy.';

  @override
  String get profileLoadFailed => 'We couldn\'t load your profile';

  @override
  String get profileMuseFriend => 'Muse\'s friend';

  @override
  String get profileProtectedEmail => 'Protected email';

  @override
  String get profileCloudNameTitle => 'Your cloud\'s name';

  @override
  String get profileFutureLetterReminder =>
      'Remind me about future letters on this device';

  @override
  String get profileEditSettings => 'Edit profile and settings';

  @override
  String get profileInboxTitle => 'In-app notifications';

  @override
  String get profileInboxLoadFailed => 'We couldn\'t load your notifications';

  @override
  String get profileInboxEmpty => 'No new notifications';

  @override
  String get profileInboxEmptyDescription =>
      'Letters that are ready to open will appear here.';

  @override
  String get profilePrivacyTitle => 'Privacy';

  @override
  String get profilePrivacyBody =>
      'Your journals are stored privately on Supabase and protected by row-level security so only your account can read them. MuseMend never includes letter content in lock-screen notifications. The MVP does not yet provide end-to-end encryption or data export.';

  @override
  String get profileTermsTitle => 'Terms and limitations';

  @override
  String get profileTermsBody =>
      'MuseMend is a reflection aid, not a diagnostic tool or a substitute for medical or mental-health care. If you are in immediate danger, contact emergency services or someone you trust.';

  @override
  String get profileSignOut => 'Sign out';

  @override
  String get profileRequestDeletion => 'Request account deletion';

  @override
  String get profileDeletionRequestFailed =>
      'We couldn\'t submit your account deletion request.';

  @override
  String get profileDeleteTitle => 'Delete your account permanently?';

  @override
  String get profileDeleteBody =>
      'This request locks your account immediately, hides your journals, and queues private files for deletion. It cannot currently be undone.';

  @override
  String profileDeleteConfirmationPrompt(String keyword) {
    return 'Type $keyword to confirm:';
  }

  @override
  String get profileDeleteConfirmationKeyword => 'DELETE';

  @override
  String get profileDeleteAccount => 'Delete account';

  @override
  String get profileFutureLetterDue => 'Your future letter is ready';

  @override
  String profileFutureLetterScheduled(String date) {
    return 'Scheduled for $date';
  }

  @override
  String get moodAwful => 'ANGRY';

  @override
  String get moodSad => 'EMPTY';

  @override
  String get moodOkay => 'OKAY';

  @override
  String get moodGood => 'RELAXED';

  @override
  String get moodGreat => 'HEALING';

  @override
  String moodRecorded(String mood) {
    return 'Feeling $mood has been noted.';
  }

  @override
  String get moodSaveFailed =>
      'We couldn\'t save how you feel. Please try again.';

  @override
  String get moodPickerPrompt => 'How is your cloud feeling today?';

  @override
  String get moodCloudSemantics =>
      'Mood cloud. Tap to return to Sky, or press and hold to choose a feeling.';

  @override
  String get checkinSaved => 'Today\'s check-in has been saved.';

  @override
  String get checkinSaveFailed =>
      'We couldn\'t save this yet. Please try again.';

  @override
  String skyStatusSemantics(int energy, int streak) {
    return '$energy energy, $streak-day streak';
  }

  @override
  String get checkinMoodPrompt => 'Has today been gentle with you?';

  @override
  String get checkinQuickSave => 'QUICK SAVE';

  @override
  String get checkinUpdateToday => 'Update today\'s check-in';

  @override
  String get checkinSaveToday => 'Quick-save today\'s check-in';

  @override
  String get checkinSaveAndWrite => 'SAVE AND WRITE';

  @override
  String get skyMascotSemantics => 'MuseMend cloud companion';

  @override
  String get skyCompanionSemantics => 'Your cloud companion';

  @override
  String journeyProgressSemantics(String name, int current, int total) {
    return 'Journey $name, stop $current of $total';
  }

  @override
  String get journeyWaiting => 'waiting';

  @override
  String get journeyDefaultTitle => 'JOURNEY';

  @override
  String get checkpointLabel => 'Stop';

  @override
  String get journeyDataWaiting =>
      'Your journey will appear when its stops are ready.';

  @override
  String get quoteLoadFailed => 'Today\'s gentle note couldn\'t be loaded.';

  @override
  String get shareMoments => 'Share a moment';

  @override
  String get shareWeekTitle => 'A nourishing week';

  @override
  String get shareWeekSubtitle => '7-day template';

  @override
  String get shareMonthTitle => 'Your month in moments';

  @override
  String get shareMonthSubtitle => 'A collage of 6 photos';

  @override
  String get shareYearTitle => 'A gentle year';

  @override
  String get shareYearSubtitle => 'Moments worth remembering';

  @override
  String shareTemplateComingSoon(String title) {
    return 'The “$title” sharing template will be ready in a future update.';
  }

  @override
  String get shareAction => 'Share';

  @override
  String get userDataLoadFailed => 'We couldn\'t load your data.';

  @override
  String get missionLoadFailed => 'We couldn\'t load your missions.';

  @override
  String get missionToday => 'Today\'s missions';

  @override
  String missionTaskCount(int count) {
    return '$count tasks';
  }

  @override
  String get missionCreateNew => 'Create your own mission';

  @override
  String get missionMuseSuggestions => 'Suggestions from Muse';

  @override
  String get missionSuggestionsDescription =>
      'Small steps that fit how you feel today.';

  @override
  String get missionSuggestionsEmpty =>
      'You\'ve added all of today\'s fitting suggestions.';

  @override
  String get missionCompleteFailed =>
      'We couldn\'t complete this mission. Please try again.';

  @override
  String get missionAlreadyCompleted => 'This mission was already completed.';

  @override
  String missionRewardReceived(int reward) {
    return 'You received $reward energy.';
  }

  @override
  String get missionSkipped => 'Mission skipped. No energy was deducted.';

  @override
  String get missionSkipFailed => 'We couldn\'t skip this mission.';

  @override
  String get missionAdded => 'Mission added.';

  @override
  String get missionAddFailed => 'We couldn\'t add this mission.';

  @override
  String get missionCustomAdded =>
      'Your mission was added with a reward of 5 energy.';

  @override
  String get missionCreateFailed => 'We couldn\'t create this mission.';

  @override
  String get missionCareToday => 'Care for\ntoday';

  @override
  String get missionGentleStep =>
      'Be gentle with yourself through one small step.';

  @override
  String get missionTypeDaily => 'Daily';

  @override
  String get missionTypeWeekly => 'Weekly';

  @override
  String get missionTypeMonthly => 'Monthly';

  @override
  String get missionTypeYearly => 'Yearly';

  @override
  String get missionTypeCustom => 'Custom';

  @override
  String missionGroupType(String type) {
    return '$type missions';
  }

  @override
  String missionSuggestionMeta(String type, int minutes, int energy) {
    return '$type · $minutes min · +$energy energy';
  }

  @override
  String get missionAddTemplate => 'Add suggested mission';

  @override
  String get missionPeriodMorning => 'Morning';

  @override
  String get missionPeriodAfternoon => 'Afternoon';

  @override
  String get missionPeriodEvening => 'Evening';

  @override
  String get missionPeriodAnytime => 'Anytime';

  @override
  String get missionCurrentLandmarkSemantics =>
      'Illustration of the current stop\'s landmark';

  @override
  String missionAddToGroup(String group) {
    return 'Add a mission to $group';
  }

  @override
  String get missionComplete => 'Complete';

  @override
  String get missionOptions => 'Mission options';

  @override
  String get missionSkip => 'Skip mission';

  @override
  String get missionEnergyAccumulated => 'Accumulated energy';

  @override
  String missionEnergySummary(int current, int available) {
    return '$current total · $available ready for your journey';
  }

  @override
  String missionEnergyReward(int energy) {
    return '+$energy energy';
  }

  @override
  String get missionEmpty => 'No missions yet. Choose one gentle little step.';

  @override
  String get missionCustomSheetTitle => 'Your mission';

  @override
  String get missionSuggestionSheetTitle => 'Add a Muse suggestion';

  @override
  String get close => 'Close';

  @override
  String get missionCustomRewardDescription =>
      'Your own missions always reward 5 energy.';

  @override
  String get missionSuggestionPrepared =>
      'Muse has prepared this suggestion for you.';

  @override
  String get missionName => 'Mission name';

  @override
  String get missionNameHint => 'Enter a mission name';

  @override
  String get missionNameValidation =>
      'Mission name must be between 1 and 200 characters.';

  @override
  String get missionNoteOptional => 'Note (optional)';

  @override
  String get missionNoteHint => 'Add a gentle reminder';

  @override
  String get missionSchedule => 'Schedule';

  @override
  String get missionAddAction => 'Add mission';

  @override
  String get missionStart => 'Start';

  @override
  String get missionEnd => 'End';

  @override
  String missionDailyRenewal(String period) {
    return 'Placed in $period and refreshed every day.';
  }

  @override
  String get missionWeeklyEnd => 'Ends at 00:00 at the start of next week.';

  @override
  String get missionMonthlyEnd =>
      'Ends at 00:00 on the first day of next month.';

  @override
  String get missionYearlyEnd => 'Ends at 00:00 on the first day of next year.';

  @override
  String get missionEndTimeAfterStart =>
      'The end time must be later than the start time on the same day.';

  @override
  String get missionEndTimeFuture => 'The end time must be in the future.';

  @override
  String get missionEndDateFuture =>
      'The end must be in the future and later than the start.';

  @override
  String get missionTimeFormat => 'Enter time as HH:mm.';

  @override
  String get missionDateFormat => 'Enter date as dd/MM/yyyy.';

  @override
  String get missionDateNotPast => 'Choose today or a future date.';

  @override
  String missionDateField(String label) {
    return '$label · date';
  }

  @override
  String missionTimeField(String label) {
    return '$label · time';
  }

  @override
  String get missionType => 'Mission type';

  @override
  String missionDue(String date) {
    return 'Due $date';
  }

  @override
  String get journalTagline =>
      'A small page each day to find your way back to yourself.';

  @override
  String get futureLetters => 'Letters to the future';

  @override
  String get futureLetterWriteNew => 'Write a new letter';

  @override
  String get futureLettersDescription =>
      'Messages you want to send to a day ahead.';

  @override
  String get journalEntryNotFound => 'This journal entry couldn\'t be found.';

  @override
  String get journalMoodRequired =>
      'Choose today\'s mood before writing. You can change it anytime.';

  @override
  String get journalChooseMood => 'Choose mood';

  @override
  String get journalDeleteTitle => 'Delete this entry?';

  @override
  String get journalDeleteBody =>
      'The entry will be hidden now. Related files follow the soft-deletion policy.';

  @override
  String get keep => 'Keep';

  @override
  String get delete => 'Delete';

  @override
  String get journalDeleted => 'Journal entry deleted.';

  @override
  String get saveFailed => 'We couldn\'t save this yet. Please try again.';

  @override
  String get futureLetterOpenFailed =>
      'We couldn\'t open this letter. Please try again.';

  @override
  String get dailyJournal => 'Daily journal';

  @override
  String get journalChooseMoodFirst => 'Choose a mood first';

  @override
  String get journalEditToday => 'Edit today';

  @override
  String get journalWriteToday => 'Write today';

  @override
  String get journalPastHint =>
      'Scroll down through earlier months to revisit what you\'ve written.';

  @override
  String get journalViewing => 'Viewing';

  @override
  String journalDaySemantics(
    Object day,
    Object month,
    Object mood,
    Object written,
  ) {
    return 'Day $day, month $month$mood$written';
  }

  @override
  String journalMoodSemantics(Object mood) {
    return ', $mood';
  }

  @override
  String get journalWrittenSemantics => ', journal written';

  @override
  String get futureLettersEmpty =>
      'No letters yet. Would you like to leave a note for your future self?';

  @override
  String get futureLetterWriteFirst => 'Write your first letter';

  @override
  String get journalMyDay => 'A day of mine';

  @override
  String futureLetterScheduleState(Object date, Object state) {
    return 'For $date · $state';
  }

  @override
  String get futureLetterUnopened => 'unopened';

  @override
  String get futureLetterOpened => 'opened';

  @override
  String get futureLetterOptions => 'Letter options';

  @override
  String get futureLetterDelete => 'Delete letter';

  @override
  String get journalNoContent => 'No content yet';

  @override
  String get journalLoadFailed => 'Your journal couldn\'t be loaded right now.';

  @override
  String get futureLetterCreateTitle => 'Letter to the future';

  @override
  String get futureLetterEditTitle => 'Edit letter';

  @override
  String get journalWriteTitle => 'Write for today';

  @override
  String get journalEditTitle => 'Edit journal';

  @override
  String get futureLetterTitleHint => 'A note for the days ahead';

  @override
  String get journalTitleHint => 'Title';

  @override
  String get journalContentHint =>
      'What would you like to tell yourself today?';

  @override
  String get journalTags => 'Tags';

  @override
  String get journalTagsHint => 'family, learning, gratitude';

  @override
  String get futureLetterDeviceReminder => 'Remind me on this device';

  @override
  String get futureLetterReminderPrivate =>
      'Notifications contain only a general reminder, never your private words.';

  @override
  String get futureLetterReminderDisabled =>
      'Turn on notifications in Profile first.';

  @override
  String get futureLetterDeliveryDate => 'Delivery date';

  @override
  String get futureLetterCanOpenEarly =>
      'You can still open this letter before then';

  @override
  String get journalContentValidation =>
      'Write a few lines and check your tags.';

  @override
  String get futureLetterReminderFailed =>
      'Your letter was saved, but the device reminder couldn\'t be enabled.';

  @override
  String get journalSaveBeforeImage =>
      'Save this page before adding an image to your note.';

  @override
  String get journalImageSaved => 'Your image was saved privately.';

  @override
  String get journalImageTooLarge => 'The image is larger than 10 MiB.';

  @override
  String get journalImageUnsupported =>
      'Only JPG, PNG, WebP, or HEIC images are supported.';

  @override
  String get journalImageUploadFailed =>
      'The image couldn\'t be uploaded. Please try again.';

  @override
  String journalWritingDate(Object date) {
    return 'Written · $date';
  }

  @override
  String journalFullDate(Object day, Object month, Object year) {
    return '$day/$month/$year';
  }

  @override
  String get journalImageAttach => 'Attach images';

  @override
  String get journalImagesInEntry => 'Images in this entry';

  @override
  String get journalImageAdd => 'Add image';

  @override
  String get journalImageSwipeHint =>
      'Swipe or drag left and right to view images.';

  @override
  String get journalImageAddLater =>
      'Save first, then add images whenever you like.';

  @override
  String journalFilmStripSemantics(Object count) {
    return 'Film strip with $count attached images. Scroll horizontally to view them.';
  }

  @override
  String journalImageSemantics(Object index) {
    return 'Attached image $index';
  }

  @override
  String get exploreTagline =>
      'Turn the small things you complete into a gentle journey.';

  @override
  String get journeyCollection => 'Journey collection';

  @override
  String journeyUnlockedCount(Object count) {
    return '$count memories unlocked';
  }

  @override
  String get journeyCompletedMetric => 'completed';

  @override
  String get journeyEnergyReady => 'energy ready';

  @override
  String get journeySync => 'Sync progress';

  @override
  String get journeyWaitingStops => 'Stops ahead';

  @override
  String get journeyNextDestination => 'Continue to the next stop';

  @override
  String get journeyStart => 'Begin journey';

  @override
  String get journeyAllCompleted =>
      'You\'ve completed every available destination. A new journey will open soon.';

  @override
  String get journeyReady => 'Your journey is ready.';

  @override
  String get journeyStartFailed =>
      'We couldn\'t begin the journey. Please try again.';

  @override
  String get journeySyncFailed =>
      'We couldn\'t sync your progress. Please try again.';

  @override
  String destinationSemantics(Object description, Object name) {
    return 'Destination $name, $description';
  }

  @override
  String destinationImageSemantics(Object name) {
    return 'Image of $name';
  }

  @override
  String get destinationProvince => 'Province';

  @override
  String get destinationCity => 'City';

  @override
  String get destinationIsland => 'Island';

  @override
  String get destinationHeritage => 'Heritage site';

  @override
  String get destinationRegion => 'Region';

  @override
  String get destinationDefault => 'Destination';

  @override
  String checkpointTitle(Object number, Object title) {
    return 'Stop $number · $title';
  }

  @override
  String checkpointEnergy(Object earned, Object required) {
    return '$earned/$required energy';
  }

  @override
  String get journeyStartDescription =>
      'Set out to reveal your first destination. Each stop uses accumulated energy, with rewards chosen by Muse.';

  @override
  String get journeyStatusNotStarted => 'The world is waiting for you';

  @override
  String get journeyStatusInProgress => 'Exploring';

  @override
  String get journeyStatusPaused => 'Ready to continue';

  @override
  String get journeyStatusCompleted => 'Journey completed';

  @override
  String get filterAll => 'All';

  @override
  String get collectibleLandmark => 'Landmarks';

  @override
  String get collectibleFood => 'Food';

  @override
  String get collectibleItem => 'Items';

  @override
  String get newLabel => 'New';

  @override
  String get rarityCommon => 'Common';

  @override
  String get rarityUncommon => 'Uncommon';

  @override
  String get rarityRare => 'Rare';

  @override
  String get rarityEpic => 'Epic';

  @override
  String get rarityLegendary => 'Legendary';

  @override
  String collectionFilteredEmpty(Object kind) {
    return 'You haven\'t unlocked any $kind on this journey yet.';
  }

  @override
  String get collectionEmpty =>
      'Complete a stop to unlock your first landmark, food, and item.';

  @override
  String get journeyLoadFailed => 'Your journey couldn\'t be loaded right now.';

  @override
  String get futureLetterNotificationTitle => 'A letter is waiting for you';

  @override
  String get futureLetterNotificationBody =>
      'Open MuseMend whenever you feel ready.';

  @override
  String get futureLetterNotificationChannel => 'Future letters';

  @override
  String get futureLetterNotificationChannelDescription =>
      'Reminders when a future letter is ready to open';

  @override
  String get defaultCloudName => 'Cloud';
}
