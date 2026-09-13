// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'MuseMend';

  @override
  String get navSky => 'Ciel';

  @override
  String get navJournal => 'Journal';

  @override
  String get navExplore => 'Explorer';

  @override
  String get navProfile => 'Profil';

  @override
  String get language => 'Langue';

  @override
  String get languageAutomatic => 'Automatique (appareil)';

  @override
  String get languageAutomaticDescription =>
      'Utilise la langue de l’appareil. Les langues non prises en charge utilisent l’anglais.';

  @override
  String get profileAndSettings => 'Profil et paramètres';

  @override
  String get displayName => 'Nom affiché';

  @override
  String get cloudName => 'Nom du nuage';

  @override
  String get appearance => 'Apparence';

  @override
  String get themeSystem => 'Réglage de l’appareil';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get sound => 'Son';

  @override
  String get notifications => 'Notifications';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get settingsUpdated => 'Paramètres mis à jour.';

  @override
  String get settingsUpdateFailed =>
      'Impossible de mettre à jour les paramètres.';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get back => 'Retour';

  @override
  String get skip => 'Passer';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get retry => 'Réessayer';

  @override
  String get authAccountCreated =>
      'Votre compte a été créé. Consultez vos e-mails si une confirmation est nécessaire.';

  @override
  String get authMascotSemantics => 'Mascotte nuage de MuseMend';

  @override
  String get authWelcomeHeadline =>
      'Un ciel rien qu’à vous\npour les jours qui demandent de la douceur.';

  @override
  String get authWelcomeBody =>
      'Accueillez vos émotions, accomplissez de petits gestes bienveillants et poursuivez votre propre chemin.';

  @override
  String get authSignUpTitle => 'Créez votre propre ciel';

  @override
  String get authSignInTitle => 'Heureux de vous retrouver';

  @override
  String get authSignUpSubtitle =>
      'Commencez par quelques informations toutes simples.';

  @override
  String get authSignInSubtitle =>
      'Prenons aujourd’hui un instant pour ralentir.';

  @override
  String get authDisplayNameLength =>
      'Le nom doit contenir entre 2 et 60 caractères.';

  @override
  String get authEmailInvalid => 'Saisissez une adresse e-mail valide.';

  @override
  String get authShowPassword => 'Afficher le mot de passe';

  @override
  String get authHidePassword => 'Masquer le mot de passe';

  @override
  String get authPasswordMinLength =>
      'Le mot de passe doit contenir au moins 8 caractères.';

  @override
  String get authCreateAccount => 'Créer un compte';

  @override
  String get authSignIn => 'Se connecter';

  @override
  String get authSwitchToSignIn => 'Vous avez déjà un compte ? Connectez-vous';

  @override
  String get authSwitchToSignUp => 'Pas encore de compte ? Inscrivez-vous';

  @override
  String get authNetworkError =>
      'Connexion impossible pour le moment. Veuillez réessayer.';

  @override
  String get authInvalidCredentials =>
      'L’e-mail ou le mot de passe est incorrect.';

  @override
  String get authEmailAlreadyRegistered =>
      'Cette adresse e-mail est déjà enregistrée.';

  @override
  String get authEmailNotConfirmed =>
      'Confirmez votre e-mail avant de vous connecter.';

  @override
  String get authWeakPassword =>
      'Ce mot de passe ne respecte pas les exigences de sécurité.';

  @override
  String get onboardingBackToSignIn => 'Retour à la connexion';

  @override
  String get onboardingNameLength =>
      'Le nom doit contenir entre 2 et 80 caractères.';

  @override
  String get onboardingFallbackName => 'Ami·e de Muse';

  @override
  String get onboardingSaveFailed =>
      'Impossible d’enregistrer. Vérifiez votre connexion et réessayez.';

  @override
  String get onboardingStartWithMuse => 'Commencer avec Muse';

  @override
  String get onboardingWelcomeHeadline =>
      'Un espace pour vous écouter,\navec un peu plus de douceur.';

  @override
  String get onboardingEmotionTitle => 'Nommer vos émotions';

  @override
  String get onboardingEmotionDescription =>
      'Observez ce que vous ressentez aujourd’hui.';

  @override
  String get onboardingPrivateWritingTitle => 'Écrire rien que pour vous';

  @override
  String get onboardingPrivateWritingDescription =>
      'Une page paisible pour déposer ce qui est difficile à dire.';

  @override
  String get onboardingSmallStepsTitle => 'Prendre soin de soi pas à pas';

  @override
  String get onboardingSmallStepsDescription =>
      'Des gestes doux et accessibles pour rendre cette journée un peu plus légère.';

  @override
  String get onboardingPrivacyHeadline =>
      'Ce qui est intime pour vous\ndoit rester à vous.';

  @override
  String get onboardingPrivacyBody =>
      'MuseMend est conçu autour de votre vie privée et de vos choix.';

  @override
  String get onboardingDeviceJournalTitle =>
      'Journal conservé sur votre appareil';

  @override
  String get onboardingDeviceJournalDescription =>
      'Vos pensées personnelles restent ici, en sécurité avec vous.';

  @override
  String get onboardingOfflineTitle => 'Disponible hors ligne';

  @override
  String get onboardingOfflineDescription =>
      'Même sans connexion, Muse reste à vos côtés.';

  @override
  String get onboardingOptionalBackupTitle => 'La sauvegarde reste facultative';

  @override
  String get onboardingOptionalBackupDescription =>
      'Synchronisez seulement lorsque vous le souhaitez vraiment.';

  @override
  String get onboardingNamePrompt => 'Comment Muse doit-elle vous appeler ?';

  @override
  String get onboardingNameCanChange =>
      'Vous pourrez modifier ce choix à tout moment dans votre profil.';

  @override
  String get onboardingDisplayNameLabel => 'Nom à afficher';

  @override
  String get onboardingNameHint => 'Saisissez un nom ou laissez ce champ vide';

  @override
  String get onboardingAddressLabel => 'La façon dont Muse s’adresse à vous';

  @override
  String onboardingGreeting(String name) {
    return 'Bonjour $name, je suis heureuse de vous accompagner !';
  }

  @override
  String get onboardingLoadFailed =>
      'Muse n’a pas encore pu préparer votre accueil.';

  @override
  String get preferredAddressCauMinh => 'entre proches';

  @override
  String get preferredAddressBanMinh => 'vous / moi';

  @override
  String get preferredAddressAnhEm => 'grand frère / cadet·te';

  @override
  String get preferredAddressChiEm => 'grande sœur / cadet·te';

  @override
  String get preferredAddressNameOnly => 'prénom uniquement';

  @override
  String get profileTagline =>
      'Un coin paisible pour votre compte et votre vie privée.';

  @override
  String get profileLoadFailed => 'Impossible de charger votre profil';

  @override
  String get profileMuseFriend => 'Ami·e de Muse';

  @override
  String get profileProtectedEmail => 'Adresse e-mail protégée';

  @override
  String get profileCloudNameTitle => 'Nom de votre nuage';

  @override
  String get profileFutureLetterReminder =>
      'Me rappeler les lettres futures sur cet appareil';

  @override
  String get profileEditSettings => 'Modifier le profil et les réglages';

  @override
  String get profileInboxTitle => 'Notifications dans l’application';

  @override
  String get profileInboxLoadFailed =>
      'Impossible de charger les notifications';

  @override
  String get profileInboxEmpty => 'Aucune nouvelle notification';

  @override
  String get profileInboxEmptyDescription =>
      'Les lettres prêtes à être ouvertes apparaîtront ici.';

  @override
  String get profilePrivacyTitle => 'Confidentialité';

  @override
  String get profilePrivacyBody =>
      'Vos journaux sont stockés de manière privée sur Supabase et protégés par la sécurité au niveau des lignes : seul votre compte peut les lire. MuseMend n’affiche jamais le contenu des lettres sur l’écran verrouillé. Le MVP ne propose pas encore de chiffrement de bout en bout ni d’export des données.';

  @override
  String get profileTermsTitle => 'Conditions et limites';

  @override
  String get profileTermsBody =>
      'MuseMend aide à prendre du recul, mais ne pose aucun diagnostic et ne remplace pas un suivi médical ou psychologique. En cas de danger immédiat, contactez les secours ou une personne de confiance.';

  @override
  String get profileSignOut => 'Se déconnecter';

  @override
  String get profileRequestDeletion => 'Demander la suppression du compte';

  @override
  String get profileDeletionRequestFailed =>
      'Impossible d’envoyer la demande de suppression.';

  @override
  String get profileDeleteTitle => 'Supprimer définitivement votre compte ?';

  @override
  String get profileDeleteBody =>
      'Cette demande verrouille immédiatement votre compte, masque vos journaux et place vos fichiers privés en attente de suppression. Elle ne peut actuellement pas être annulée.';

  @override
  String profileDeleteConfirmationPrompt(String keyword) {
    return 'Saisissez $keyword pour confirmer :';
  }

  @override
  String get profileDeleteConfirmationKeyword => 'SUPPRIMER';

  @override
  String get profileDeleteAccount => 'Supprimer le compte';

  @override
  String get profileFutureLetterDue => 'Votre lettre au futur est prête';

  @override
  String profileFutureLetterScheduled(String date) {
    return 'Prévue pour le $date';
  }

  @override
  String get moodAwful => 'EN COLÈRE';

  @override
  String get moodSad => 'VIDE';

  @override
  String get moodOkay => 'ÇA VA';

  @override
  String get moodGood => 'DÉTENDU·E';

  @override
  String get moodGreat => 'EN GUÉRISON';

  @override
  String moodRecorded(String mood) {
    return 'Votre ressenti « $mood » a été noté.';
  }

  @override
  String get moodSaveFailed =>
      'Impossible d’enregistrer votre ressenti. Réessayez.';

  @override
  String get moodPickerPrompt => 'Comment se sent votre nuage aujourd’hui ?';

  @override
  String get moodCloudSemantics =>
      'Nuage des émotions. Touchez pour revenir au Ciel, ou maintenez pour choisir une émotion.';

  @override
  String get checkinSaved => 'Le point du jour a été enregistré.';

  @override
  String get checkinSaveFailed =>
      'Impossible d’enregistrer pour le moment. Réessayez.';

  @override
  String skyStatusSemantics(int energy, int streak) {
    return '$energy d’énergie, série de $streak jours';
  }

  @override
  String get checkinMoodPrompt =>
      'Cette journée a-t-elle été douce avec vous ?';

  @override
  String get checkinQuickSave => 'ENREGISTRER';

  @override
  String get checkinUpdateToday => 'Mettre à jour le point du jour';

  @override
  String get checkinSaveToday => 'Enregistrer rapidement le point du jour';

  @override
  String get checkinSaveAndWrite => 'ENREGISTRER ET ÉCRIRE';

  @override
  String get skyMascotSemantics => 'Nuage compagnon de MuseMend';

  @override
  String get skyCompanionSemantics => 'Votre nuage compagnon';

  @override
  String journeyProgressSemantics(String name, int current, int total) {
    return 'Voyage $name, étape $current sur $total';
  }

  @override
  String get journeyWaiting => 'en attente';

  @override
  String get journeyDefaultTitle => 'VOYAGE';

  @override
  String get checkpointLabel => 'Étape';

  @override
  String get journeyDataWaiting =>
      'Votre voyage apparaîtra dès que ses étapes seront prêtes.';

  @override
  String get quoteLoadFailed =>
      'La pensée douce du jour n’a pas pu être chargée.';

  @override
  String get shareMoments => 'Partager un moment';

  @override
  String get shareWeekTitle => 'Une semaine ressourçante';

  @override
  String get shareWeekSubtitle => 'Modèle sur 7 jours';

  @override
  String get shareMonthTitle => 'Votre mois en images';

  @override
  String get shareMonthSubtitle => 'Montage de 6 photos';

  @override
  String get shareYearTitle => 'Une année tout en douceur';

  @override
  String get shareYearSubtitle => 'Des moments à garder';

  @override
  String shareTemplateComingSoon(String title) {
    return 'Le modèle « $title » sera disponible dans une prochaine mise à jour.';
  }

  @override
  String get shareAction => 'Partager';

  @override
  String get userDataLoadFailed => 'Impossible de charger vos données.';

  @override
  String get missionLoadFailed => 'Impossible de charger vos missions.';

  @override
  String get missionToday => 'Missions du jour';

  @override
  String missionTaskCount(int count) {
    return '$count tâches';
  }

  @override
  String get missionCreateNew => 'Créer votre propre mission';

  @override
  String get missionMuseSuggestions => 'Suggestions de Muse';

  @override
  String get missionSuggestionsDescription =>
      'De petits pas adaptés à votre ressenti du jour.';

  @override
  String get missionSuggestionsEmpty =>
      'Vous avez ajouté toutes les suggestions qui vous correspondent aujourd’hui.';

  @override
  String get missionCompleteFailed =>
      'Impossible de terminer cette mission. Réessayez.';

  @override
  String get missionAlreadyCompleted => 'Cette mission avait déjà été validée.';

  @override
  String missionRewardReceived(int reward) {
    return 'Vous avez reçu $reward points d’énergie.';
  }

  @override
  String get missionSkipped => 'Mission passée, sans perte d’énergie.';

  @override
  String get missionSkipFailed => 'Impossible de passer cette mission.';

  @override
  String get missionAdded => 'Mission ajoutée.';

  @override
  String get missionAddFailed => 'Impossible d’ajouter cette mission.';

  @override
  String get missionCustomAdded =>
      'Votre mission a été ajoutée avec une récompense de 5 points d’énergie.';

  @override
  String get missionCreateFailed => 'Impossible de créer cette mission.';

  @override
  String get missionCareToday => 'Prendre soin\nd’aujourd’hui';

  @override
  String get missionGentleStep =>
      'Prenez soin de vous avec un tout petit geste.';

  @override
  String get missionTypeDaily => 'Quotidienne';

  @override
  String get missionTypeWeekly => 'Hebdomadaire';

  @override
  String get missionTypeMonthly => 'Mensuelle';

  @override
  String get missionTypeYearly => 'Annuelle';

  @override
  String get missionTypeCustom => 'Personnalisée';

  @override
  String missionGroupType(String type) {
    return 'Missions $type';
  }

  @override
  String missionSuggestionMeta(String type, int minutes, int energy) {
    return '$type · $minutes min · +$energy d’énergie';
  }

  @override
  String get missionAddTemplate => 'Ajouter la mission suggérée';

  @override
  String get missionPeriodMorning => 'Matin';

  @override
  String get missionPeriodAfternoon => 'Après-midi';

  @override
  String get missionPeriodEvening => 'Soir';

  @override
  String get missionPeriodAnytime => 'À tout moment';

  @override
  String get missionCurrentLandmarkSemantics =>
      'Illustration du lieu remarquable de l’étape actuelle';

  @override
  String missionAddToGroup(String group) {
    return 'Ajouter une mission à $group';
  }

  @override
  String get missionComplete => 'Terminer';

  @override
  String get missionOptions => 'Options de la mission';

  @override
  String get missionSkip => 'Passer la mission';

  @override
  String get missionEnergyAccumulated => 'Énergie accumulée';

  @override
  String missionEnergySummary(int current, int available) {
    return '$current au total · $available disponibles pour votre voyage';
  }

  @override
  String missionEnergyReward(int energy) {
    return '+$energy d’énergie';
  }

  @override
  String get missionEmpty =>
      'Aucune mission pour le moment. Choisissez un petit pas tout doux.';

  @override
  String get missionCustomSheetTitle => 'Votre mission';

  @override
  String get missionSuggestionSheetTitle => 'Ajouter une suggestion de Muse';

  @override
  String get close => 'Fermer';

  @override
  String get missionCustomRewardDescription =>
      'Vos missions personnelles rapportent toujours 5 points d’énergie.';

  @override
  String get missionSuggestionPrepared =>
      'Muse a préparé cette suggestion pour vous.';

  @override
  String get missionName => 'Nom de la mission';

  @override
  String get missionNameHint => 'Saisissez le nom de la mission';

  @override
  String get missionNameValidation =>
      'Le nom doit contenir entre 1 et 200 caractères.';

  @override
  String get missionNoteOptional => 'Note (facultative)';

  @override
  String get missionNoteHint => 'Ajoutez un rappel bienveillant';

  @override
  String get missionSchedule => 'Période';

  @override
  String get missionAddAction => 'Ajouter la mission';

  @override
  String get missionStart => 'Début';

  @override
  String get missionEnd => 'Fin';

  @override
  String missionDailyRenewal(String period) {
    return 'Classée dans $period et renouvelée chaque jour.';
  }

  @override
  String get missionWeeklyEnd =>
      'Se termine à 00:00 au début de la semaine suivante.';

  @override
  String get missionMonthlyEnd =>
      'Se termine à 00:00 le premier jour du mois suivant.';

  @override
  String get missionYearlyEnd =>
      'Se termine à 00:00 le premier jour de l’année suivante.';

  @override
  String get missionEndTimeAfterStart =>
      'L’heure de fin doit suivre l’heure de début le même jour.';

  @override
  String get missionEndTimeFuture => 'L’heure de fin doit être dans le futur.';

  @override
  String get missionEndDateFuture =>
      'La fin doit être future et postérieure au début.';

  @override
  String get missionTimeFormat => 'Saisissez l’heure au format HH:mm.';

  @override
  String get missionDateFormat => 'Saisissez la date au format jj/MM/aaaa.';

  @override
  String get missionDateNotPast => 'Choisissez aujourd’hui ou une date future.';

  @override
  String missionDateField(String label) {
    return '$label · date';
  }

  @override
  String missionTimeField(String label) {
    return '$label · heure';
  }

  @override
  String get missionType => 'Type de mission';

  @override
  String missionDue(String date) {
    return 'Échéance : $date';
  }

  @override
  String get journalTagline =>
      'Une petite page chaque jour pour revenir à vous.';

  @override
  String get futureLetters => 'Lettres au futur';

  @override
  String get futureLetterWriteNew => 'Écrire une nouvelle lettre';

  @override
  String get futureLettersDescription =>
      'Des mots à confier à un jour qui n’est pas encore arrivé.';

  @override
  String get journalEntryNotFound => 'Cette page de journal est introuvable.';

  @override
  String get journalMoodRequired =>
      'Choisissez votre humeur du jour avant d’écrire. Vous pourrez la modifier à tout moment.';

  @override
  String get journalChooseMood => 'Choisir une humeur';

  @override
  String get journalDeleteTitle => 'Supprimer cette page ?';

  @override
  String get journalDeleteBody =>
      'La page sera masquée immédiatement. Les fichiers associés suivront la politique de suppression différée.';

  @override
  String get keep => 'Conserver';

  @override
  String get delete => 'Supprimer';

  @override
  String get journalDeleted => 'Page de journal supprimée.';

  @override
  String get saveFailed =>
      'Impossible d’enregistrer pour le moment. Réessayez.';

  @override
  String get futureLetterOpenFailed =>
      'Impossible d’ouvrir cette lettre. Réessayez.';

  @override
  String get dailyJournal => 'Journal quotidien';

  @override
  String get journalChooseMoodFirst => 'Choisir d’abord une humeur';

  @override
  String get journalEditToday => 'Modifier aujourd’hui';

  @override
  String get journalWriteToday => 'Écrire aujourd’hui';

  @override
  String get journalPastHint =>
      'Faites défiler les mois précédents pour retrouver vos pages.';

  @override
  String get journalViewing => 'En cours';

  @override
  String journalDaySemantics(
    Object day,
    Object month,
    Object mood,
    Object written,
  ) {
    return 'Jour $day, mois $month$mood$written';
  }

  @override
  String journalMoodSemantics(Object mood) {
    return ', $mood';
  }

  @override
  String get journalWrittenSemantics => ', journal écrit';

  @override
  String get futureLettersEmpty =>
      'Aucune lettre pour le moment. Envie de laisser quelques mots à votre futur vous ?';

  @override
  String get futureLetterWriteFirst => 'Écrire votre première lettre';

  @override
  String get journalMyDay => 'Une journée à moi';

  @override
  String futureLetterScheduleState(Object date, Object state) {
    return 'Pour le $date · $state';
  }

  @override
  String get futureLetterUnopened => 'non ouverte';

  @override
  String get futureLetterOpened => 'ouverte';

  @override
  String get futureLetterOptions => 'Options de la lettre';

  @override
  String get futureLetterDelete => 'Supprimer la lettre';

  @override
  String get journalNoContent => 'Aucun contenu pour le moment';

  @override
  String get journalLoadFailed =>
      'Impossible de charger votre journal pour le moment.';

  @override
  String get futureLetterCreateTitle => 'Lettre au futur';

  @override
  String get futureLetterEditTitle => 'Modifier la lettre';

  @override
  String get journalWriteTitle => 'Écrire pour aujourd’hui';

  @override
  String get journalEditTitle => 'Modifier le journal';

  @override
  String get futureLetterTitleHint => 'Quelques mots pour les jours à venir';

  @override
  String get journalTitleHint => 'Titre';

  @override
  String get journalContentHint =>
      'Qu’aimeriez-vous vous raconter aujourd’hui ?';

  @override
  String get journalTags => 'Étiquettes';

  @override
  String get journalTagsHint => 'famille, apprentissage, gratitude';

  @override
  String get futureLetterDeviceReminder => 'Me le rappeler sur cet appareil';

  @override
  String get futureLetterReminderPrivate =>
      'La notification ne contient qu’un rappel général, jamais vos mots personnels.';

  @override
  String get futureLetterReminderDisabled =>
      'Activez d’abord les notifications dans Profil.';

  @override
  String get futureLetterDeliveryDate => 'Date de réception';

  @override
  String get futureLetterCanOpenEarly =>
      'Vous pourrez toujours ouvrir la lettre avant cette date';

  @override
  String get journalContentValidation =>
      'Écrivez quelques lignes et vérifiez les étiquettes.';

  @override
  String get futureLetterReminderFailed =>
      'La lettre est enregistrée, mais le rappel sur l’appareil n’a pas pu être activé.';

  @override
  String get journalSaveBeforeImage =>
      'Enregistrez la page avant d’ajouter une image à votre note.';

  @override
  String get journalImageSaved =>
      'Votre image a été enregistrée de façon privée.';

  @override
  String get journalImageTooLarge => 'L’image dépasse 10 Mio.';

  @override
  String get journalImageUnsupported =>
      'Seuls les formats JPG, PNG, WebP et HEIC sont acceptés.';

  @override
  String get journalImageUploadFailed =>
      'Impossible d’envoyer l’image. Réessayez.';

  @override
  String journalWritingDate(Object date) {
    return 'Écrite · $date';
  }

  @override
  String journalFullDate(Object day, Object month, Object year) {
    return '$day/$month/$year';
  }

  @override
  String get journalImageAttach => 'Joindre des images';

  @override
  String get journalImagesInEntry => 'Images de cette page';

  @override
  String get journalImageAdd => 'Ajouter une image';

  @override
  String get journalImageSwipeHint =>
      'Balayez ou faites glisser vers la gauche ou la droite pour voir les images.';

  @override
  String get journalImageAddLater =>
      'Enregistrez d’abord, puis ajoutez des images quand vous le souhaitez.';

  @override
  String journalFilmStripSemantics(Object count) {
    return 'Pellicule de $count images jointes. Faites défiler horizontalement pour les voir.';
  }

  @override
  String journalImageSemantics(Object index) {
    return 'Image jointe $index';
  }

  @override
  String get exploreTagline =>
      'Transformez chaque petit accomplissement en un voyage tout en douceur.';

  @override
  String get journeyCollection => 'Collection de voyage';

  @override
  String journeyUnlockedCount(Object count) {
    return '$count souvenirs débloqués';
  }

  @override
  String get journeyCompletedMetric => 'terminé';

  @override
  String get journeyEnergyReady => 'énergie disponible';

  @override
  String get journeySync => 'Synchroniser la progression';

  @override
  String get journeyWaitingStops => 'Prochaines étapes';

  @override
  String get journeyNextDestination => 'Aller à l’étape suivante';

  @override
  String get journeyStart => 'Commencer le voyage';

  @override
  String get journeyAllCompleted =>
      'Vous avez terminé toutes les destinations disponibles. Un nouveau voyage s’ouvrira bientôt.';

  @override
  String get journeyReady => 'Votre voyage est prêt.';

  @override
  String get journeyStartFailed =>
      'Impossible de commencer le voyage. Réessayez.';

  @override
  String get journeySyncFailed =>
      'Impossible de synchroniser la progression. Réessayez.';

  @override
  String destinationSemantics(Object description, Object name) {
    return 'Destination $name, $description';
  }

  @override
  String destinationImageSemantics(Object name) {
    return 'Image de $name';
  }

  @override
  String get destinationProvince => 'Province';

  @override
  String get destinationCity => 'Ville';

  @override
  String get destinationIsland => 'Île';

  @override
  String get destinationHeritage => 'Patrimoine';

  @override
  String get destinationRegion => 'Région';

  @override
  String get destinationDefault => 'Destination';

  @override
  String checkpointTitle(Object number, Object title) {
    return 'Étape $number · $title';
  }

  @override
  String checkpointEnergy(Object earned, Object required) {
    return '$earned/$required d’énergie';
  }

  @override
  String get journeyStartDescription =>
      'Partez à la découverte de votre première destination. Chaque étape utilise l’énergie accumulée et Muse choisit les récompenses.';

  @override
  String get journeyStatusNotStarted => 'Le monde vous attend';

  @override
  String get journeyStatusInProgress => 'En exploration';

  @override
  String get journeyStatusPaused => 'Prêt·e à continuer';

  @override
  String get journeyStatusCompleted => 'Voyage terminé';

  @override
  String get filterAll => 'Tout';

  @override
  String get collectibleLandmark => 'Lieux';

  @override
  String get collectibleFood => 'Cuisine';

  @override
  String get collectibleItem => 'Objets';

  @override
  String get newLabel => 'Nouveau';

  @override
  String get rarityCommon => 'Commun';

  @override
  String get rarityUncommon => 'Spécial';

  @override
  String get rarityRare => 'Rare';

  @override
  String get rarityEpic => 'Épique';

  @override
  String get rarityLegendary => 'Légendaire';

  @override
  String collectionFilteredEmpty(Object kind) {
    return 'Vous n’avez encore débloqué aucun élément « $kind » pendant ce voyage.';
  }

  @override
  String get collectionEmpty =>
      'Terminez une étape pour débloquer votre premier lieu, plat et objet.';

  @override
  String get journeyLoadFailed =>
      'Impossible de charger votre voyage pour le moment.';

  @override
  String get futureLetterNotificationTitle => 'Une lettre vous attend';

  @override
  String get futureLetterNotificationBody =>
      'Ouvrez MuseMend lorsque vous vous sentirez prêt·e.';

  @override
  String get futureLetterNotificationChannel => 'Lettres au futur';

  @override
  String get futureLetterNotificationChannelDescription =>
      'Rappels lorsqu’une lettre au futur est prête à être ouverte';

  @override
  String get defaultCloudName => 'Nuage';
}
