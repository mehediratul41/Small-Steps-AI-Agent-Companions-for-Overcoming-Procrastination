import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
    Locale('ja'),
  ];

  /// No description provided for @afterQuietHours_ffb6ab.
  ///
  /// In en, this message translates to:
  /// **' after quiet hours'**
  String get afterQuietHours_ffb6ab;

  /// No description provided for @addTask_d417d7.
  ///
  /// In en, this message translates to:
  /// **'+ Add task'**
  String get addTask_d417d7;

  /// No description provided for @aBigTaskDoesnTNeed_3e219b.
  ///
  /// In en, this message translates to:
  /// **'A big task doesn’t need a big first step.'**
  String get aBigTaskDoesnTNeed_3e219b;

  /// No description provided for @aGentleCompanionForMeaningfulManageable_d4b672.
  ///
  /// In en, this message translates to:
  /// **'A gentle companion for meaningful, manageable progress.'**
  String get aGentleCompanionForMeaningfulManageable_d4b672;

  /// No description provided for @aLongerTermGoal_9c0345.
  ///
  /// In en, this message translates to:
  /// **'A longer-term goal'**
  String get aLongerTermGoal_9c0345;

  /// No description provided for @aMomentToReflect_bec4d1.
  ///
  /// In en, this message translates to:
  /// **'A moment to reflect'**
  String get aMomentToReflect_bec4d1;

  /// No description provided for @aShortVoluntaryCheckIn_881d40.
  ///
  /// In en, this message translates to:
  /// **'A short voluntary check-in'**
  String get aShortVoluntaryCheckIn_881d40;

  /// No description provided for @aSmallInvitation_67a1b1.
  ///
  /// In en, this message translates to:
  /// **'A small invitation'**
  String get aSmallInvitation_67a1b1;

  /// No description provided for @aTitleIsEnoughToBegin_c03561.
  ///
  /// In en, this message translates to:
  /// **'A title is enough to begin. Dates and other details are optional.'**
  String get aTitleIsEnoughToBegin_c03561;

  /// No description provided for @aMinuteWorkSession_e980c5.
  ///
  /// In en, this message translates to:
  /// **'A {p0}-minute work session.'**
  String aMinuteWorkSession_e980c5(String p0);

  /// No description provided for @about_30ae27.
  ///
  /// In en, this message translates to:
  /// **'About: {p0}'**
  String about_30ae27(String p0);

  /// No description provided for @acceptCorrection_9acb19.
  ///
  /// In en, this message translates to:
  /// **'Accept correction'**
  String get acceptCorrection_9acb19;

  /// No description provided for @acceptTheseSteps_f68c84.
  ///
  /// In en, this message translates to:
  /// **'Accept these steps'**
  String get acceptTheseSteps_f68c84;

  /// No description provided for @accountChangedDuringExportTryAgain_de4c4e.
  ///
  /// In en, this message translates to:
  /// **'Account changed during export. Try again.'**
  String get accountChangedDuringExportTryAgain_de4c4e;

  /// No description provided for @active_a733b8.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active_a733b8;

  /// No description provided for @activityRecorded_c5d39b.
  ///
  /// In en, this message translates to:
  /// **'Activity recorded'**
  String get activityRecorded_c5d39b;

  /// No description provided for @addAStep_90d24a.
  ///
  /// In en, this message translates to:
  /// **'Add a step'**
  String get addAStep_90d24a;

  /// No description provided for @addATaskWheneverYouAre_259006.
  ///
  /// In en, this message translates to:
  /// **'Add a task whenever you are ready.'**
  String get addATaskWheneverYouAre_259006;

  /// No description provided for @addAnOptionalCheckIn_1bec0f.
  ///
  /// In en, this message translates to:
  /// **'Add an optional check-in'**
  String get addAnOptionalCheckIn_1bec0f;

  /// No description provided for @addTask_24700e.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get addTask_24700e;

  /// No description provided for @additionalTypesAreOffUntilYou_bfe80c.
  ///
  /// In en, this message translates to:
  /// **'Additional types are off until you choose them. Limits apply to all types together, including manual reminders. Quiet hours can delay a slot; conflicting slots are skipped. A reserved slot is not evidence of delivery.'**
  String get additionalTypesAreOffUntilYou_bfe80c;

  /// No description provided for @adjustMyPlan_a2c8a9.
  ///
  /// In en, this message translates to:
  /// **'Adjust my plan'**
  String get adjustMyPlan_a2c8a9;

  /// No description provided for @adjustTheAppearanceAndExploreThe_cbc0ad.
  ///
  /// In en, this message translates to:
  /// **'Adjust the appearance and explore the demo.'**
  String get adjustTheAppearanceAndExploreThe_cbc0ad;

  /// No description provided for @adjustThePlan_9b154f.
  ///
  /// In en, this message translates to:
  /// **'Adjust the plan'**
  String get adjustThePlan_9b154f;

  /// No description provided for @afterSession_57c83e.
  ///
  /// In en, this message translates to:
  /// **'After session'**
  String get afterSession_57c83e;

  /// No description provided for @agent_5ce2e6.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get agent_5ce2e6;

  /// No description provided for @agentIsComposingADemoResponse_66b3f0.
  ///
  /// In en, this message translates to:
  /// **'Agent is composing a demo response…'**
  String get agentIsComposingADemoResponse_66b3f0;

  /// No description provided for @agentIsComposingAResponse_ec1bc2.
  ///
  /// In en, this message translates to:
  /// **'Agent is composing a response…'**
  String get agentIsComposingAResponse_ec1bc2;

  /// No description provided for @agreeContinue_684047.
  ///
  /// In en, this message translates to:
  /// **'Agree & continue'**
  String get agreeContinue_684047;

  /// No description provided for @allowTaskNotifications_1e16ea.
  ///
  /// In en, this message translates to:
  /// **'Allow task notifications'**
  String get allowTaskNotifications_1e16ea;

  /// No description provided for @anAuthenticatedBackendAssignmentAndApproved_69d5f6.
  ///
  /// In en, this message translates to:
  /// **'An authenticated backend assignment and approved consent materials must be connected before participant use. Demo records are never loaded in participant mode.'**
  String get anAuthenticatedBackendAssignmentAndApproved_69d5f6;

  /// No description provided for @appSelectedActionUsingYourTask_428a07.
  ///
  /// In en, this message translates to:
  /// **'App-selected action using your task context. Review before making changes.'**
  String get appSelectedActionUsingYourTask_428a07;

  /// No description provided for @appearance_41def7.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance_41def7;

  /// No description provided for @approvedStudyInstrumentsAreNotConnected_dba2f4.
  ///
  /// In en, this message translates to:
  /// **'Approved study instruments are not connected.'**
  String get approvedStudyInstrumentsAreNotConnected_dba2f4;

  /// No description provided for @archivedTaskConversation_426aa2.
  ///
  /// In en, this message translates to:
  /// **'Archived task conversation'**
  String get archivedTaskConversation_426aa2;

  /// No description provided for @assignedByTheStudyBackendAgent_fcf49b.
  ///
  /// In en, this message translates to:
  /// **'Assigned by the study backend. Agent switching is locked for this account.'**
  String get assignedByTheStudyBackendAgent_fcf49b;

  /// No description provided for @assignedCondition_06173e.
  ///
  /// In en, this message translates to:
  /// **'Assigned condition: {p0}'**
  String assignedCondition_06173e(String p0);

  /// No description provided for @awaitingStudyConfiguration_2a3a93.
  ///
  /// In en, this message translates to:
  /// **'Awaiting study configuration'**
  String get awaitingStudyConfiguration_2a3a93;

  /// No description provided for @backendAiProposal_b046ad.
  ///
  /// In en, this message translates to:
  /// **'Backend AI proposal'**
  String get backendAiProposal_b046ad;

  /// No description provided for @backendUrl_61290c.
  ///
  /// In en, this message translates to:
  /// **'Backend URL'**
  String get backendUrl_61290c;

  /// No description provided for @baselineDemo_33ca1d.
  ///
  /// In en, this message translates to:
  /// **'Baseline demo'**
  String get baselineDemo_33ca1d;

  /// No description provided for @beforeSession_771478.
  ///
  /// In en, this message translates to:
  /// **'Before session'**
  String get beforeSession_771478;

  /// No description provided for @beforeYouBegin_b4738e.
  ///
  /// In en, this message translates to:
  /// **'Before you begin'**
  String get beforeYouBegin_b4738e;

  /// No description provided for @breakItDown_5798bd.
  ///
  /// In en, this message translates to:
  /// **'Break it down'**
  String get breakItDown_5798bd;

  /// No description provided for @currentStep_57706f.
  ///
  /// In en, this message translates to:
  /// **'CURRENT STEP'**
  String get currentStep_57706f;

  /// No description provided for @cancel_77dfd2.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel_77dfd2;

  /// No description provided for @cancelRetry_09ba40.
  ///
  /// In en, this message translates to:
  /// **'Cancel retry'**
  String get cancelRetry_09ba40;

  /// No description provided for @changeTask_c89335.
  ///
  /// In en, this message translates to:
  /// **'Change task'**
  String get changeTask_c89335;

  /// No description provided for @chat_2ced57.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat_2ced57;

  /// No description provided for @chatIsUnavailableInThisCondition_fbd25e.
  ///
  /// In en, this message translates to:
  /// **'Chat is unavailable in this condition.'**
  String get chatIsUnavailableInThisCondition_fbd25e;

  /// No description provided for @chatIsUnavailable_892e02.
  ///
  /// In en, this message translates to:
  /// **'Chat is unavailable.'**
  String get chatIsUnavailable_892e02;

  /// No description provided for @checkAgain_e18504.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get checkAgain_e18504;

  /// No description provided for @checkInSavedAsANew_976966.
  ///
  /// In en, this message translates to:
  /// **'Check-in saved as a new entry.'**
  String get checkInSavedAsANew_976966;

  /// No description provided for @checkInsAndPreferencesWheneverYou_c58ac3.
  ///
  /// In en, this message translates to:
  /// **'Check-ins and preferences, whenever you want.'**
  String get checkInsAndPreferencesWheneverYou_c58ac3;

  /// No description provided for @checkInsAreVoluntaryYourTask_87f153.
  ///
  /// In en, this message translates to:
  /// **'Check-ins are voluntary. Your task tools work without them.'**
  String get checkInsAreVoluntaryYourTask_87f153;

  /// No description provided for @checkingReminders_651066.
  ///
  /// In en, this message translates to:
  /// **'Checking reminders'**
  String get checkingReminders_651066;

  /// No description provided for @chooseTodayToReturnToYour_b02c03.
  ///
  /// In en, this message translates to:
  /// **'Choose Today to return to your tasks.'**
  String get chooseTodayToReturnToYour_b02c03;

  /// No description provided for @chooseADurationThenStartWhen_6c8fb1.
  ///
  /// In en, this message translates to:
  /// **'Choose a duration, then start when you are ready. Task completion remains your choice.'**
  String get chooseADurationThenStartWhen_6c8fb1;

  /// No description provided for @chooseAFocusDurationFor_65e4a6.
  ///
  /// In en, this message translates to:
  /// **'Choose a focus duration for {p0}'**
  String chooseAFocusDurationFor_65e4a6(String p0);

  /// No description provided for @chooseAFocusSession_41945f.
  ///
  /// In en, this message translates to:
  /// **'Choose a focus session'**
  String get chooseAFocusSession_41945f;

  /// No description provided for @chooseAFutureReminderTimeOn_f01a16.
  ///
  /// In en, this message translates to:
  /// **'Choose a future reminder time on an active task.'**
  String get chooseAFutureReminderTimeOn_f01a16;

  /// No description provided for @chooseAFutureReminderTime_a80a33.
  ///
  /// In en, this message translates to:
  /// **'Choose a future reminder time.'**
  String get chooseAFutureReminderTime_a80a33;

  /// No description provided for @chooseANewPlannedStart_579a1a.
  ///
  /// In en, this message translates to:
  /// **'Choose a new planned start.'**
  String get chooseANewPlannedStart_579a1a;

  /// No description provided for @chooseAReminderTime_785b09.
  ///
  /// In en, this message translates to:
  /// **'Choose a reminder time'**
  String get chooseAReminderTime_785b09;

  /// No description provided for @chooseASmallerStep_58fb38.
  ///
  /// In en, this message translates to:
  /// **'Choose a smaller step'**
  String get chooseASmallerStep_58fb38;

  /// No description provided for @chooseAStartingPointThatFeels_4992dc.
  ///
  /// In en, this message translates to:
  /// **'Choose a starting point that feels manageable.'**
  String get chooseAStartingPointThatFeels_4992dc;

  /// No description provided for @chooseATask_7d6823.
  ///
  /// In en, this message translates to:
  /// **'Choose a task'**
  String get chooseATask_7d6823;

  /// No description provided for @chooseATaskToBeginA_5c965f.
  ///
  /// In en, this message translates to:
  /// **'Choose a task to begin a focus session.'**
  String get chooseATaskToBeginA_5c965f;

  /// No description provided for @chooseATime_09efe8.
  ///
  /// In en, this message translates to:
  /// **'Choose a time'**
  String get chooseATime_09efe8;

  /// No description provided for @chooseAnActiveTaskForToday_b7cc31.
  ///
  /// In en, this message translates to:
  /// **'Choose an active task for Today.'**
  String get chooseAnActiveTaskForToday_b7cc31;

  /// No description provided for @chooseAnActiveTaskInAn_cefd8f.
  ///
  /// In en, this message translates to:
  /// **'Choose an active task in an AI condition.'**
  String get chooseAnActiveTaskInAn_cefd8f;

  /// No description provided for @chooseAnAvailableSessionDuration_bec72a.
  ///
  /// In en, this message translates to:
  /// **'Choose an available session duration.'**
  String get chooseAnAvailableSessionDuration_bec72a;

  /// No description provided for @chooseAnotherFilterOrAddA_91fbc4.
  ///
  /// In en, this message translates to:
  /// **'Choose another filter or add a small step.'**
  String get chooseAnotherFilterOrAddA_91fbc4;

  /// No description provided for @chooseAnotherStartTime_7d26d3.
  ///
  /// In en, this message translates to:
  /// **'Choose another start time'**
  String get chooseAnotherStartTime_7d26d3;

  /// No description provided for @chooseBetweenAndMinutes_221d3b.
  ///
  /// In en, this message translates to:
  /// **'Choose between 1 and 480 minutes.'**
  String get chooseBetweenAndMinutes_221d3b;

  /// No description provided for @chooseDifferentStartAndEndTimes_8cf782.
  ///
  /// In en, this message translates to:
  /// **'Choose different start and end times.'**
  String get chooseDifferentStartAndEndTimes_8cf782;

  /// No description provided for @chooseOneTask_dd61ed.
  ///
  /// In en, this message translates to:
  /// **'Choose one task'**
  String get chooseOneTask_dd61ed;

  /// No description provided for @chooseWhatFitsYourOwnGoals_44f6d5.
  ///
  /// In en, this message translates to:
  /// **'Choose what fits your own goals and future preparation.'**
  String get chooseWhatFitsYourOwnGoals_44f6d5;

  /// No description provided for @chooseWhetherYourPhoneNotifiesYou_21a270.
  ///
  /// In en, this message translates to:
  /// **'Choose whether your phone notifies you. The same reminder types and limits are available in every condition. Each connected account has its own opt-in setting.'**
  String get chooseWhetherYourPhoneNotifiesYou_21a270;

  /// No description provided for @clarifyThisTask_c41598.
  ///
  /// In en, this message translates to:
  /// **'Clarify this task'**
  String get clarifyThisTask_c41598;

  /// No description provided for @clear_719ea3.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear_719ea3;

  /// No description provided for @clearTheseFields_c6e6cd.
  ///
  /// In en, this message translates to:
  /// **'Clear these fields'**
  String get clearTheseFields_c6e6cd;

  /// No description provided for @close_bbfa77.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close_bbfa77;

  /// No description provided for @completeATaskOrStartA_8176cf.
  ///
  /// In en, this message translates to:
  /// **'Complete a task or start a session to see it here.'**
  String get completeATaskOrStartA_8176cf;

  /// No description provided for @completeDemoOnboardingBeforeEnablingNotifications_5ff178.
  ///
  /// In en, this message translates to:
  /// **'Complete demo onboarding before enabling notifications.'**
  String get completeDemoOnboardingBeforeEnablingNotifications_5ff178;

  /// No description provided for @completeDemoOnboardingBeforeEnablingPhone_f92eeb.
  ///
  /// In en, this message translates to:
  /// **'Complete demo onboarding before enabling phone notifications.'**
  String get completeDemoOnboardingBeforeEnablingPhone_f92eeb;

  /// No description provided for @completeOnboarding_27cb36.
  ///
  /// In en, this message translates to:
  /// **'Complete onboarding'**
  String get completeOnboarding_27cb36;

  /// No description provided for @complete_3d1040.
  ///
  /// In en, this message translates to:
  /// **'Complete {p0}'**
  String complete_3d1040(String p0);

  /// No description provided for @completed_1798b3.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed_1798b3;

  /// No description provided for @confirm_04a212.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm_04a212;

  /// No description provided for @connect_b65463.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect_b65463;

  /// No description provided for @connectSmallSteps_f9ba22.
  ///
  /// In en, this message translates to:
  /// **'Connect Small Steps'**
  String get connectSmallSteps_f9ba22;

  /// No description provided for @connectToDevelopmentBackend_3ac1a0.
  ///
  /// In en, this message translates to:
  /// **'Connect to development backend'**
  String get connectToDevelopmentBackend_3ac1a0;

  /// No description provided for @connectToTheDevelopmentBackendFirst_656c65.
  ///
  /// In en, this message translates to:
  /// **'Connect to the development backend first.'**
  String get connectToTheDevelopmentBackendFirst_656c65;

  /// No description provided for @connectedAs_41c3bd.
  ///
  /// In en, this message translates to:
  /// **'Connected as {p0}'**
  String connectedAs_41c3bd(String p0);

  /// No description provided for @connectedDevelopmentAccountFictionalDataOnly_0991c1.
  ///
  /// In en, this message translates to:
  /// **'Connected development account · fictional data only'**
  String get connectedDevelopmentAccountFictionalDataOnly_0991c1;

  /// No description provided for @connectedDevelopmentUsesASyntheticAccount_13f12b.
  ///
  /// In en, this message translates to:
  /// **'Connected development uses a synthetic account and versioned demonstration acknowledgment. It is not approved informed consent. Data entered while connected goes to the backend; AI calls send relevant text to Google Gemini. Local demo records remain separate. Pending development reports, unsent messages and timer state may be cached unencrypted on this device. Disconnect removes the in-memory token but does not erase server data.'**
  String get connectedDevelopmentUsesASyntheticAccount_13f12b;

  /// No description provided for @connectedDevelopmentAiRepliesMayBe_ab7a5a.
  ///
  /// In en, this message translates to:
  /// **'Connected development · AI replies may be inaccurate'**
  String get connectedDevelopmentAiRepliesMayBe_ab7a5a;

  /// No description provided for @connectedReminderTimesAreSavedAs_5a3346.
  ///
  /// In en, this message translates to:
  /// **'Connected reminder times are saved as instants. Reopen the app after changing time zone. Signing out clears this account’s device schedule.'**
  String get connectedReminderTimesAreSavedAs_5a3346;

  /// No description provided for @copyCompleteServerExport_db2f88.
  ///
  /// In en, this message translates to:
  /// **'Copy complete server export'**
  String get copyCompleteServerExport_db2f88;

  /// No description provided for @copyDemoJson_fc2b92.
  ///
  /// In en, this message translates to:
  /// **'Copy demo JSON'**
  String get copyDemoJson_fc2b92;

  /// No description provided for @copyRetrievesTheCompleteServerExport_08b93d.
  ///
  /// In en, this message translates to:
  /// **'Copy retrieves the complete server export, including audit records, plus unsynchronized device reports. The expandable preview below is only the loaded state. Contains raw text; review before sharing.'**
  String get copyRetrievesTheCompleteServerExport_08b93d;

  /// No description provided for @correctThisTask_ef9d4d.
  ///
  /// In en, this message translates to:
  /// **'Correct this task'**
  String get correctThisTask_ef9d4d;

  /// No description provided for @couldNotSavePendingDevelopmentReports_1aab13.
  ///
  /// In en, this message translates to:
  /// **'Could not save pending development reports on this device.'**
  String get couldNotSavePendingDevelopmentReports_1aab13;

  /// No description provided for @couldNotUpdateReminders_92128b.
  ///
  /// In en, this message translates to:
  /// **'Could not update reminders'**
  String get couldNotUpdateReminders_92128b;

  /// No description provided for @couldNotUpdateTheLocalSynchronization_8d565f.
  ///
  /// In en, this message translates to:
  /// **'Could not update the local synchronization record.'**
  String get couldNotUpdateTheLocalSynchronization_8d565f;

  /// No description provided for @countsReflectLocalDemoInteractionsReported_7ada41.
  ///
  /// In en, this message translates to:
  /// **'Counts reflect local demo interactions. Reported task starts come from “I am starting this task”; focus starts count timer use. Neither verifies work. Completion is self-reported.'**
  String get countsReflectLocalDemoInteractionsReported_7ada41;

  /// No description provided for @daily_728298.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily_728298;

  /// No description provided for @dataStudyInformation_2cc532.
  ///
  /// In en, this message translates to:
  /// **'Data & study information'**
  String get dataStudyInformation_2cc532;

  /// No description provided for @datedDemoResponsesNotValidatedScores_77dd4f.
  ///
  /// In en, this message translates to:
  /// **'Dated demo responses, not validated scores or evidence of improvement.'**
  String get datedDemoResponsesNotValidatedScores_77dd4f;

  /// No description provided for @deadlineOptional_34fb64.
  ///
  /// In en, this message translates to:
  /// **'Deadline · optional'**
  String get deadlineOptional_34fb64;

  /// No description provided for @deleteTask_9ad9dc.
  ///
  /// In en, this message translates to:
  /// **'Delete task'**
  String get deleteTask_9ad9dc;

  /// No description provided for @deleteTask_b50826.
  ///
  /// In en, this message translates to:
  /// **'Delete task?'**
  String get deleteTask_b50826;

  /// No description provided for @deletedTask_824510.
  ///
  /// In en, this message translates to:
  /// **'Deleted task'**
  String get deletedTask_824510;

  /// No description provided for @demoAgentChanged_5f2cb7.
  ///
  /// In en, this message translates to:
  /// **'Demo agent changed'**
  String get demoAgentChanged_5f2cb7;

  /// No description provided for @demoQuestionsOnlyNotAValidated_d3799c.
  ///
  /// In en, this message translates to:
  /// **'Demo questions only · not a validated questionnaire. These answers are saved locally as separate dated entries. There is no score or diagnosis. Use fictional information in this prototype.'**
  String get demoQuestionsOnlyNotAValidated_d3799c;

  /// No description provided for @demoResearchIdDemoP_992c84.
  ///
  /// In en, this message translates to:
  /// **'Demo research ID · DEMO-P001'**
  String get demoResearchIdDemoP_992c84;

  /// No description provided for @demonstrationQuestionsNotAValidatedInstrument_ebaf67.
  ///
  /// In en, this message translates to:
  /// **'Demonstration questions, not a validated instrument. Answers are stored as separate dated entries on the development backend. Use fictional information.'**
  String get demonstrationQuestionsNotAValidatedInstrument_ebaf67;

  /// No description provided for @demonstrationResponsesNotALiveAi_83abaf.
  ///
  /// In en, this message translates to:
  /// **'Demonstration responses · not a live AI service'**
  String get demonstrationResponsesNotALiveAi_83abaf;

  /// No description provided for @descriptionOptional_388de6.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional_388de6;

  /// No description provided for @developmentId_163c4e.
  ///
  /// In en, this message translates to:
  /// **'Development ID · {p0}'**
  String developmentId_163c4e(String p0);

  /// No description provided for @developmentJsonCopiedToYourClipboard_27d777.
  ///
  /// In en, this message translates to:
  /// **'Development JSON copied to your clipboard.'**
  String get developmentJsonCopiedToYourClipboard_27d777;

  /// No description provided for @developmentBackend_6d6dad.
  ///
  /// In en, this message translates to:
  /// **'Development backend'**
  String get developmentBackend_6d6dad;

  /// No description provided for @developmentBackend_3f59e0.
  ///
  /// In en, this message translates to:
  /// **'Development backend · {p0}'**
  String developmentBackend_3f59e0(String p0);

  /// No description provided for @developmentParticipantToken_df51bc.
  ///
  /// In en, this message translates to:
  /// **'Development participant token'**
  String get developmentParticipantToken_df51bc;

  /// No description provided for @didNotUseSupport_6bf13f.
  ///
  /// In en, this message translates to:
  /// **'Did not use support'**
  String get didNotUseSupport_6bf13f;

  /// No description provided for @didTheSupportYouUsedFeel_a29436.
  ///
  /// In en, this message translates to:
  /// **'Did the support you used feel helpful?'**
  String get didTheSupportYouUsedFeel_a29436;

  /// No description provided for @difficult_54d8b6.
  ///
  /// In en, this message translates to:
  /// **'Difficult'**
  String get difficult_54d8b6;

  /// No description provided for @disconnectAndReturnToLocalDemo_91878e.
  ///
  /// In en, this message translates to:
  /// **'Disconnect and return to local demo'**
  String get disconnectAndReturnToLocalDemo_91878e;

  /// No description provided for @disconnectBeforeClearingSavedDevelopmentData_84a59d.
  ///
  /// In en, this message translates to:
  /// **'Disconnect before clearing saved development data.'**
  String get disconnectBeforeClearingSavedDevelopmentData_84a59d;

  /// No description provided for @disconnectBeforeResettingTheLocalDemo_179c40.
  ///
  /// In en, this message translates to:
  /// **'Disconnect before resetting the local demo.'**
  String get disconnectBeforeResettingTheLocalDemo_179c40;

  /// No description provided for @dismiss_70afe9.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss_70afe9;

  /// No description provided for @doYouFeelFreeToChoose_ad8869.
  ///
  /// In en, this message translates to:
  /// **'Do you feel free to choose your next step?'**
  String get doYouFeelFreeToChoose_ad8869;

  /// No description provided for @doesYourNextStepFitYour_e7ebd0.
  ///
  /// In en, this message translates to:
  /// **'Does your next step fit your own goals?'**
  String get doesYourNextStepFitYour_e7ebd0;

  /// No description provided for @due_483844.
  ///
  /// In en, this message translates to:
  /// **'Due {p0}'**
  String due_483844(String p0);

  /// No description provided for @duringSession_97d9d3.
  ///
  /// In en, this message translates to:
  /// **'During session'**
  String get duringSession_97d9d3;

  /// No description provided for @eeeeDMmmm_e95a9d.
  ///
  /// In en, this message translates to:
  /// **'EEEE, d MMMM'**
  String get eeeeDMmmm_e95a9d;

  /// No description provided for @easy_00f031.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get easy_00f031;

  /// No description provided for @editMessage_96116a.
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get editMessage_96116a;

  /// No description provided for @editMySmallSteps_e1eb3a.
  ///
  /// In en, this message translates to:
  /// **'Edit my small steps'**
  String get editMySmallSteps_e1eb3a;

  /// No description provided for @editOrReschedule_613c15.
  ///
  /// In en, this message translates to:
  /// **'Edit or reschedule'**
  String get editOrReschedule_613c15;

  /// No description provided for @editYourTask_52ff42.
  ///
  /// In en, this message translates to:
  /// **'Edit your task'**
  String get editYourTask_52ff42;

  /// No description provided for @empathyGentleSupport_69b918.
  ///
  /// In en, this message translates to:
  /// **'Empathy & gentle support'**
  String get empathyGentleSupport_69b918;

  /// No description provided for @enableNotifications_da3967.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get enableNotifications_da3967;

  /// No description provided for @endSession_8c0f4c.
  ///
  /// In en, this message translates to:
  /// **'End session'**
  String get endSession_8c0f4c;

  /// No description provided for @endTheCurrentFocusSessionBefore_94642b.
  ///
  /// In en, this message translates to:
  /// **'End the current focus session before deleting its task.'**
  String get endTheCurrentFocusSessionBefore_94642b;

  /// No description provided for @energyOrTimeIsLimited_019424.
  ///
  /// In en, this message translates to:
  /// **'Energy or time is limited'**
  String get energyOrTimeIsLimited_019424;

  /// No description provided for @enterADevelopmentParticipantToken_c7a3a6.
  ///
  /// In en, this message translates to:
  /// **'Enter a development participant token.'**
  String get enterADevelopmentParticipantToken_c7a3a6;

  /// No description provided for @eraseDevelopmentData_da3da0.
  ///
  /// In en, this message translates to:
  /// **'Erase development data?'**
  String get eraseDevelopmentData_da3da0;

  /// No description provided for @eraseThisDevelopmentAccountSData_d44c64.
  ///
  /// In en, this message translates to:
  /// **'Erase this development account’s data'**
  String get eraseThisDevelopmentAccountSData_d44c64;

  /// No description provided for @estimatedDurationMinutes_546aa1.
  ///
  /// In en, this message translates to:
  /// **'Estimated duration (minutes)'**
  String get estimatedDurationMinutes_546aa1;

  /// No description provided for @estimatedMinutes_a5485e.
  ///
  /// In en, this message translates to:
  /// **'Estimated minutes · 1–1440'**
  String get estimatedMinutes_a5485e;

  /// No description provided for @experimentalCondition_7873b9.
  ///
  /// In en, this message translates to:
  /// **'Experimental condition'**
  String get experimentalCondition_7873b9;

  /// No description provided for @exploreASmallerStep_34fb75.
  ///
  /// In en, this message translates to:
  /// **'Explore a smaller step'**
  String get exploreASmallerStep_34fb75;

  /// No description provided for @exploreTheResearchDemo_beb40f.
  ///
  /// In en, this message translates to:
  /// **'Explore the research demo'**
  String get exploreTheResearchDemo_beb40f;

  /// No description provided for @findATask_fcbde8.
  ///
  /// In en, this message translates to:
  /// **'Find a task'**
  String get findATask_fcbde8;

  /// No description provided for @finishReflect_fd1c04.
  ///
  /// In en, this message translates to:
  /// **'Finish & reflect'**
  String get finishReflect_fd1c04;

  /// No description provided for @finishOrEndTheCurrentSession_fe8406.
  ///
  /// In en, this message translates to:
  /// **'Finish or end the current session/request before disconnecting.'**
  String get finishOrEndTheCurrentSession_fe8406;

  /// No description provided for @finishTheCurrentFocusSessionBefore_674a75.
  ///
  /// In en, this message translates to:
  /// **'Finish the current focus session before changing this plan.'**
  String get finishTheCurrentFocusSessionBefore_674a75;

  /// No description provided for @finishTheCurrentRequestBeforeChanging_aff46f.
  ///
  /// In en, this message translates to:
  /// **'Finish the current request before changing demo conditions.'**
  String get finishTheCurrentRequestBeforeChanging_aff46f;

  /// No description provided for @finishTheCurrentRequestBeforeDisconnecting_647f96.
  ///
  /// In en, this message translates to:
  /// **'Finish the current request before disconnecting.'**
  String get finishTheCurrentRequestBeforeDisconnecting_647f96;

  /// No description provided for @finishTheCurrentSessionOrRequest_55f8af.
  ///
  /// In en, this message translates to:
  /// **'Finish the current session or request before connecting.'**
  String get finishTheCurrentSessionOrRequest_55f8af;

  /// No description provided for @finishTheCurrentSessionOrRequest_e53a0a.
  ///
  /// In en, this message translates to:
  /// **'Finish the current session or request before erasing data.'**
  String get finishTheCurrentSessionOrRequest_e53a0a;

  /// No description provided for @finishThisSession_e68101.
  ///
  /// In en, this message translates to:
  /// **'Finish this session?'**
  String get finishThisSession_e68101;

  /// No description provided for @fixedGentleTemplatesNoAiCall_56fe14.
  ///
  /// In en, this message translates to:
  /// **'Fixed, gentle templates. No AI call or task content on the lock screen.'**
  String get fixedGentleTemplatesNoAiCall_56fe14;

  /// No description provided for @focusOnThisTask_1ad73f.
  ///
  /// In en, this message translates to:
  /// **'Focus on this task'**
  String get focusOnThisTask_1ad73f;

  /// No description provided for @focusPaused_93230c.
  ///
  /// In en, this message translates to:
  /// **'Focus paused'**
  String get focusPaused_93230c;

  /// No description provided for @focusResumed_dcbc1a.
  ///
  /// In en, this message translates to:
  /// **'Focus resumed'**
  String get focusResumed_dcbc1a;

  /// No description provided for @focusSession_3ee7c5.
  ///
  /// In en, this message translates to:
  /// **'Focus session'**
  String get focusSession_3ee7c5;

  /// No description provided for @focusStarted_37a5b7.
  ///
  /// In en, this message translates to:
  /// **'Focus started'**
  String get focusStarted_37a5b7;

  /// No description provided for @focusStarts_c5929a.
  ///
  /// In en, this message translates to:
  /// **'Focus starts'**
  String get focusStarts_c5929a;

  /// No description provided for @forDemonstrationOnlyParticipantBuildsDo_142767.
  ///
  /// In en, this message translates to:
  /// **'For demonstration only. Participant builds do not expose these controls. Switching conditions preserves demo tasks; chat histories stay separate.'**
  String get forDemonstrationOnlyParticipantBuildsDo_142767;

  /// No description provided for @forExampleCuriosityBalanceIndependence_47cf1f.
  ///
  /// In en, this message translates to:
  /// **'For example: curiosity, balance, independence'**
  String get forExampleCuriosityBalanceIndependence_47cf1f;

  /// No description provided for @forExampleExplainMyResearchClearly_753e5a.
  ///
  /// In en, this message translates to:
  /// **'For example: explain my research clearly'**
  String get forExampleExplainMyResearchClearly_753e5a;

  /// No description provided for @forgetSavedDevelopmentAccountsOnThis_b3e68b.
  ///
  /// In en, this message translates to:
  /// **'Forget saved development accounts on this device'**
  String get forgetSavedDevelopmentAccountsOnThis_b3e68b;

  /// No description provided for @forgetSavedDevelopmentData_cc5ca3.
  ///
  /// In en, this message translates to:
  /// **'Forget saved development data?'**
  String get forgetSavedDevelopmentData_cc5ca3;

  /// No description provided for @friendAgent_7c1d9d.
  ///
  /// In en, this message translates to:
  /// **'Friend-Agent'**
  String get friendAgent_7c1d9d;

  /// No description provided for @from_80d3ab.
  ///
  /// In en, this message translates to:
  /// **'From {p0}'**
  String from_80d3ab(String p0);

  /// No description provided for @generalConversation_90962d.
  ///
  /// In en, this message translates to:
  /// **'General conversation'**
  String get generalConversation_90962d;

  /// No description provided for @getStarted_bd2cb0.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted_bd2cb0;

  /// No description provided for @giveEveryStepATitleBefore_cbfc40.
  ///
  /// In en, this message translates to:
  /// **'Give every step a title before accepting.'**
  String get giveEveryStepATitleBefore_cbfc40;

  /// No description provided for @giveYourTaskATitle_a8a393.
  ///
  /// In en, this message translates to:
  /// **'Give your task a title.'**
  String get giveYourTaskATitle_a8a393;

  /// No description provided for @goToToday_d56ae4.
  ///
  /// In en, this message translates to:
  /// **'Go to Today'**
  String get goToToday_d56ae4;

  /// No description provided for @good_b4f086.
  ///
  /// In en, this message translates to:
  /// **'Good {p0}!'**
  String good_b4f086(String p0);

  /// No description provided for @heavy_84d7ad.
  ///
  /// In en, this message translates to:
  /// **'Heavy'**
  String get heavy_84d7ad;

  /// No description provided for @helpMeReflectOnMyGoal_d4b855.
  ///
  /// In en, this message translates to:
  /// **'Help me reflect on my goal.'**
  String get helpMeReflectOnMyGoal_d4b855;

  /// No description provided for @helpful_45e36d.
  ///
  /// In en, this message translates to:
  /// **'Helpful'**
  String get helpful_45e36d;

  /// No description provided for @high_b1a595.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high_b1a595;

  /// No description provided for @howClearIsWhatIsHolding_51d8ab.
  ///
  /// In en, this message translates to:
  /// **'How clear is what is holding you back?'**
  String get howClearIsWhatIsHolding_51d8ab;

  /// No description provided for @howDifficultDoesStartingFeel_3af19b.
  ///
  /// In en, this message translates to:
  /// **'How difficult does starting feel?'**
  String get howDifficultDoesStartingFeel_3af19b;

  /// No description provided for @howDoesStartingFeel_4c40aa.
  ///
  /// In en, this message translates to:
  /// **'How does starting feel?'**
  String get howDoesStartingFeel_4c40aa;

  /// No description provided for @howHeavyDidTasksFeel_6c29b8.
  ///
  /// In en, this message translates to:
  /// **'How heavy did tasks feel?'**
  String get howHeavyDidTasksFeel_6c29b8;

  /// No description provided for @howHeavyDoYourTasksFeel_4db047.
  ///
  /// In en, this message translates to:
  /// **'How heavy do your tasks feel right now?'**
  String get howHeavyDoYourTasksFeel_4db047;

  /// No description provided for @howMotivatedDoYouFeel_78d035.
  ///
  /// In en, this message translates to:
  /// **'How motivated do you feel?'**
  String get howMotivatedDoYouFeel_78d035;

  /// No description provided for @howOftenHaveYouDelayedTasks_50a43a.
  ///
  /// In en, this message translates to:
  /// **'How often have you delayed tasks you intended to start?'**
  String get howOftenHaveYouDelayedTasks_50a43a;

  /// No description provided for @howReadyDoYouFeelTo_82c0fb.
  ///
  /// In en, this message translates to:
  /// **'How ready do you feel to take a small step?'**
  String get howReadyDoYouFeelTo_82c0fb;

  /// No description provided for @iAmStartingThisTask_bb9a50.
  ///
  /// In en, this message translates to:
  /// **'I am starting this task'**
  String get iAmStartingThisTask_bb9a50;

  /// No description provided for @iDidNotFeelReady_4385f4.
  ///
  /// In en, this message translates to:
  /// **'I did not feel ready'**
  String get iDidNotFeelReady_4385f4;

  /// No description provided for @iHaveReadAndUnderstandThe_52762c.
  ///
  /// In en, this message translates to:
  /// **'I have read and understand the demo study details.'**
  String get iHaveReadAndUnderstandThe_52762c;

  /// No description provided for @iWillUseFictionalDataConnected_750258.
  ///
  /// In en, this message translates to:
  /// **'I will use fictional data. Connected tasks, check-ins and messages go to this backend; AI requests also send relevant text to Google Gemini.'**
  String get iWillUseFictionalDataConnected_750258;

  /// No description provided for @ifFeelsDifficultWouldASmaller_44870d.
  ///
  /// In en, this message translates to:
  /// **'If “{p0}” feels difficult, would a smaller step help? You can change your plan.'**
  String ifFeelsDifficultWouldASmaller_44870d(String p0);

  /// No description provided for @inProgress_b6bd42.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgress_b6bd42;

  /// No description provided for @inMinutes_3400a8.
  ///
  /// In en, this message translates to:
  /// **'In {p0} minutes'**
  String inMinutes_3400a8(String p0);

  /// No description provided for @insights_b45103.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights_b45103;

  /// No description provided for @invitationsAreOffByDefaultThey_963d6c.
  ///
  /// In en, this message translates to:
  /// **'Invitations are off by default. They do not send personalized push messages or change your tasks.'**
  String get invitationsAreOffByDefaultThey_963d6c;

  /// No description provided for @itMayHaveBeenDeleted_8b326e.
  ///
  /// In en, this message translates to:
  /// **'It may have been deleted.'**
  String get itMayHaveBeenDeleted_8b326e;

  /// No description provided for @justOneStepNoNeedTo_2e292d.
  ///
  /// In en, this message translates to:
  /// **'Just one step. No need to rush.'**
  String get justOneStepNoNeedTo_2e292d;

  /// No description provided for @keepMyPlan_b160c2.
  ///
  /// In en, this message translates to:
  /// **'Keep my plan'**
  String get keepMyPlan_b160c2;

  /// No description provided for @keepSession_32239a.
  ///
  /// In en, this message translates to:
  /// **'Keep session'**
  String get keepSession_32239a;

  /// No description provided for @lastDaysDevelopmentAccount_9b1ce3.
  ///
  /// In en, this message translates to:
  /// **'LAST 7 DAYS · DEVELOPMENT ACCOUNT'**
  String get lastDaysDevelopmentAccount_9b1ce3;

  /// No description provided for @lastDaysLocalDemo_3f1c63.
  ///
  /// In en, this message translates to:
  /// **'LAST 7 DAYS · LOCAL DEMO'**
  String get lastDaysLocalDemo_3f1c63;

  /// No description provided for @light_a36ef8.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light_a36ef8;

  /// No description provided for @localClockTimeWhenYouReopen_6f9b9e.
  ///
  /// In en, this message translates to:
  /// **'Local clock time{p0}. When you reopen the app after a time-zone change, reminders are updated. Phone battery settings may delay delivery; scheduled does not mean delivered.'**
  String localClockTimeWhenYouReopen_6f9b9e(String p0);

  /// No description provided for @localDemoOnlyUseFictionalInformation_9010f0.
  ///
  /// In en, this message translates to:
  /// **'Local demo only. Use fictional information. These preferences personalize scripted examples; they are not a live AI profile or a study assignment. Do not enter another person’s private information.'**
  String get localDemoOnlyUseFictionalInformation_9010f0;

  /// No description provided for @low_a12494.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low_a12494;

  /// No description provided for @makeItManageable_1208ae.
  ///
  /// In en, this message translates to:
  /// **'Make it manageable'**
  String get makeItManageable_1208ae;

  /// No description provided for @makeItYours_541351.
  ///
  /// In en, this message translates to:
  /// **'Make it yours'**
  String get makeItYours_541351;

  /// No description provided for @makeRoomForASmallStart_9f05fd.
  ///
  /// In en, this message translates to:
  /// **'Make room for a small start'**
  String get makeRoomForASmallStart_9f05fd;

  /// No description provided for @makeRoomForWhatMattersOne_93e5ec.
  ///
  /// In en, this message translates to:
  /// **'Make room for what matters, one task at a time.'**
  String get makeRoomForWhatMattersOne_93e5ec;

  /// No description provided for @manualReminder_278de1.
  ///
  /// In en, this message translates to:
  /// **'Manual reminder'**
  String get manualReminder_278de1;

  /// No description provided for @markAsToDo_8ee8bd.
  ///
  /// In en, this message translates to:
  /// **'Mark as to do'**
  String get markAsToDo_8ee8bd;

  /// No description provided for @markComplete_0c0184.
  ///
  /// In en, this message translates to:
  /// **'Mark complete'**
  String get markComplete_0c0184;

  /// No description provided for @maximumScheduledSlotsPerDay_23ac4f.
  ///
  /// In en, this message translates to:
  /// **'Maximum scheduled slots per day'**
  String get maximumScheduledSlotsPerDay_23ac4f;

  /// No description provided for @messageYour_e972d5.
  ///
  /// In en, this message translates to:
  /// **'Message your {p0}…'**
  String messageYour_e972d5(String p0);

  /// No description provided for @messagesAndRetriesStayLinkedTo_f396c0.
  ///
  /// In en, this message translates to:
  /// **'Messages and retries stay linked to this conversation.'**
  String get messagesAndRetriesStayLinkedTo_f396c0;

  /// No description provided for @minimumTimeBetweenSlots_28a254.
  ///
  /// In en, this message translates to:
  /// **'Minimum time between slots'**
  String get minimumTimeBetweenSlots_28a254;

  /// No description provided for @mixed_c0dcb8.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get mixed_c0dcb8;

  /// No description provided for @moreDetailsAndScheduling_89bad4.
  ///
  /// In en, this message translates to:
  /// **'More details and scheduling'**
  String get moreDetailsAndScheduling_89bad4;

  /// No description provided for @moreReflectionOptional_835ed9.
  ///
  /// In en, this message translates to:
  /// **'More reflection · optional'**
  String get moreReflectionOptional_835ed9;

  /// No description provided for @moveRemindersInThisPeriodTo_644d2e.
  ///
  /// In en, this message translates to:
  /// **'Move reminders in this period to its end.'**
  String get moveRemindersInThisPeriodTo_644d2e;

  /// No description provided for @newRecordsHaveIdsUtcTimestamps_c6e6f7.
  ///
  /// In en, this message translates to:
  /// **'New records have IDs, UTC timestamps and local offsets. Legacy records without a known condition or offset remain marked as unknown. Timer activity and self-reported work are recorded separately; notification scheduling is not evidence of delivery.'**
  String get newRecordsHaveIdsUtcTimestamps_c6e6f7;

  /// No description provided for @nextSmallStep_c296c8.
  ///
  /// In en, this message translates to:
  /// **'Next small step: {p0}'**
  String nextSmallStep_c296c8(String p0);

  /// No description provided for @noActiveReminder_48abe9.
  ///
  /// In en, this message translates to:
  /// **'No active reminder'**
  String get noActiveReminder_48abe9;

  /// No description provided for @noActiveSession_efed39.
  ///
  /// In en, this message translates to:
  /// **'No active session'**
  String get noActiveSession_efed39;

  /// No description provided for @noActiveTasks_405725.
  ///
  /// In en, this message translates to:
  /// **'No active tasks'**
  String get noActiveTasks_405725;

  /// No description provided for @noCheckInsYet_b49f04.
  ///
  /// In en, this message translates to:
  /// **'No check-ins yet'**
  String get noCheckInsYet_b49f04;

  /// No description provided for @noDatesSet_7854aa.
  ///
  /// In en, this message translates to:
  /// **'No dates set'**
  String get noDatesSet_7854aa;

  /// No description provided for @noDeadline_c4a597.
  ///
  /// In en, this message translates to:
  /// **'No deadline'**
  String get noDeadline_c4a597;

  /// No description provided for @noDescriptionAdded_0dc3da.
  ///
  /// In en, this message translates to:
  /// **'No description added.'**
  String get noDescriptionAdded_0dc3da;

  /// No description provided for @noDevelopmentAccountIsConnected_43c42f.
  ///
  /// In en, this message translates to:
  /// **'No development account is connected.'**
  String get noDevelopmentAccountIsConnected_43c42f;

  /// No description provided for @noPlannedStart_0813ca.
  ///
  /// In en, this message translates to:
  /// **'No planned start'**
  String get noPlannedStart_0813ca;

  /// No description provided for @noServerSuggestionIsAvailableTo_d651d2.
  ///
  /// In en, this message translates to:
  /// **'No server suggestion is available to reject.'**
  String get noServerSuggestionIsAvailableTo_d651d2;

  /// No description provided for @noSmallStepsAddedYet_45e2ff.
  ///
  /// In en, this message translates to:
  /// **'No small steps added yet.'**
  String get noSmallStepsAddedYet_45e2ff;

  /// No description provided for @noTasksInThisView_5d338c.
  ///
  /// In en, this message translates to:
  /// **'No tasks in this view'**
  String get noTasksInThisView_5d338c;

  /// No description provided for @noTasksPlannedForToday_3117fd.
  ///
  /// In en, this message translates to:
  /// **'No tasks planned for today.'**
  String get noTasksPlannedForToday_3117fd;

  /// No description provided for @noUpcomingReminders_114a7c.
  ///
  /// In en, this message translates to:
  /// **'No upcoming reminders'**
  String get noUpcomingReminders_114a7c;

  /// No description provided for @normal_45e118.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal_45e118;

  /// No description provided for @notDifficult_db370f.
  ///
  /// In en, this message translates to:
  /// **'Not difficult'**
  String get notDifficult_db370f;

  /// No description provided for @notHelpful_85efce.
  ///
  /// In en, this message translates to:
  /// **'Not helpful'**
  String get notHelpful_85efce;

  /// No description provided for @notMuch_e718f6.
  ///
  /// In en, this message translates to:
  /// **'Not much'**
  String get notMuch_e718f6;

  /// No description provided for @notReady_2b50ff.
  ///
  /// In en, this message translates to:
  /// **'Not ready'**
  String get notReady_2b50ff;

  /// No description provided for @notSet_93039e.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet_93039e;

  /// No description provided for @notYet_8de95f.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get notYet_8de95f;

  /// No description provided for @noticeYourPatternsWithCompassion_1a39b5.
  ///
  /// In en, this message translates to:
  /// **'Notice your patterns with compassion.'**
  String get noticeYourPatternsWithCompassion_1a39b5;

  /// No description provided for @notificationPreferences_0ead6c.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences'**
  String get notificationPreferences_0ead6c;

  /// No description provided for @notificationsOff_0b58a9.
  ///
  /// In en, this message translates to:
  /// **'Notifications off'**
  String get notificationsOff_0b58a9;

  /// No description provided for @often_bb5857.
  ///
  /// In en, this message translates to:
  /// **'Often'**
  String get often_bb5857;

  /// No description provided for @okay_d54455.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get okay_d54455;

  /// No description provided for @oneTaskAtYourOwnPace_d49f69.
  ///
  /// In en, this message translates to:
  /// **'One task, at your own pace.'**
  String get oneTaskAtYourOwnPace_d49f69;

  /// No description provided for @onlyTheTitleDescriptionAndEstimate_1dfeda.
  ///
  /// In en, this message translates to:
  /// **'Only the title, description and estimate can change. Dates, reminders and existing steps are kept.'**
  String get onlyTheTitleDescriptionAndEstimate_1dfeda;

  /// No description provided for @optionalBaselineDemo_dbf225.
  ///
  /// In en, this message translates to:
  /// **'Optional baseline demo'**
  String get optionalBaselineDemo_dbf225;

  /// No description provided for @optionalCheckIn_3f57e8.
  ///
  /// In en, this message translates to:
  /// **'Optional check-in'**
  String get optionalCheckIn_3f57e8;

  /// No description provided for @optionalReason_b2c92f.
  ///
  /// In en, this message translates to:
  /// **'Optional reason'**
  String get optionalReason_b2c92f;

  /// No description provided for @optionalReflection_a4797d.
  ///
  /// In en, this message translates to:
  /// **'Optional reflection'**
  String get optionalReflection_a4797d;

  /// No description provided for @optionalResponse_e43a2e.
  ///
  /// In en, this message translates to:
  /// **'Optional response'**
  String get optionalResponse_e43a2e;

  /// No description provided for @optionalSessionCheckIn_124d0d.
  ///
  /// In en, this message translates to:
  /// **'Optional session check-in'**
  String get optionalSessionCheckIn_124d0d;

  /// No description provided for @optionalSuggestionsOnTodayWhenA_ed4750.
  ///
  /// In en, this message translates to:
  /// **'Optional suggestions on Today when a task has no steps or its planned start has passed. You choose whether to act.'**
  String get optionalSuggestionsOnTodayWhenA_ed4750;

  /// No description provided for @optionalSupport_f28163.
  ///
  /// In en, this message translates to:
  /// **'Optional support'**
  String get optionalSupport_f28163;

  /// No description provided for @originalMinutes_bd2d00.
  ///
  /// In en, this message translates to:
  /// **'Original: {p0} · {p1} minutes'**
  String originalMinutes_bd2d00(String p0, String p1);

  /// No description provided for @otherTasks_c7690d.
  ///
  /// In en, this message translates to:
  /// **'Other tasks'**
  String get otherTasks_c7690d;

  /// No description provided for @pageNotFound_bc3023.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound_bc3023;

  /// No description provided for @participantEnrollmentIsDisabledNoReal_2d5279.
  ///
  /// In en, this message translates to:
  /// **'Participant enrollment is disabled. No real study consent, official questionnaires, researcher contact or withdrawal endpoint has been connected. Resetting this demo is not a request to withdraw from a research study. Approved materials must be supplied before participant use.'**
  String get participantEnrollmentIsDisabledNoReal_2d5279;

  /// No description provided for @participantEnrollmentIsNotEnabled_61c91c.
  ///
  /// In en, this message translates to:
  /// **'Participant enrollment is not enabled.'**
  String get participantEnrollmentIsNotEnabled_61c91c;

  /// No description provided for @participationIsVoluntaryThisIsA_11d758.
  ///
  /// In en, this message translates to:
  /// **'Participation is voluntary.\n\nThis is a local demonstration, not research enrollment. No responses are sent to a research server. Please use fictional information.'**
  String get participationIsVoluntaryThisIsA_11d758;

  /// No description provided for @partly_ed03c6.
  ///
  /// In en, this message translates to:
  /// **'Partly'**
  String get partly_ed03c6;

  /// No description provided for @partlyClear_d2d367.
  ///
  /// In en, this message translates to:
  /// **'Partly clear'**
  String get partlyClear_d2d367;

  /// No description provided for @pauseSession_c5eb7f.
  ///
  /// In en, this message translates to:
  /// **'Pause session'**
  String get pauseSession_c5eb7f;

  /// No description provided for @pauseThisTask_993399.
  ///
  /// In en, this message translates to:
  /// **'Pause this task'**
  String get pauseThisTask_993399;

  /// No description provided for @paused_c7dfb6.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused_c7dfb6;

  /// No description provided for @pendingReportsUnsentMessagesAndThe_650fbe.
  ///
  /// In en, this message translates to:
  /// **'Pending reports, unsent messages and the focus timer may be cached unencrypted on this device, separately for this server/account. Phone notifications are off until you enable them for this account in Settings. Browser previews do not deliver notifications.'**
  String get pendingReportsUnsentMessagesAndThe_650fbe;

  /// No description provided for @permanentlyEraseThisAccountSTasks_aa06c1.
  ///
  /// In en, this message translates to:
  /// **'Permanently erase this account’s tasks, conversations, check-ins and reports from the development database and revoke its token. Device pending reports are removed. Backups and prior exports are not erased. An inactive account marker remains. This is not the approved research withdrawal process.'**
  String get permanentlyEraseThisAccountSTasks_aa06c1;

  /// No description provided for @permissionNeeded_7c7a8e.
  ///
  /// In en, this message translates to:
  /// **'Permission needed'**
  String get permissionNeeded_7c7a8e;

  /// No description provided for @phoneRemindersUnavailable_3844a0.
  ///
  /// In en, this message translates to:
  /// **'Phone reminders unavailable'**
  String get phoneRemindersUnavailable_3844a0;

  /// No description provided for @planAdjusted_290c9a.
  ///
  /// In en, this message translates to:
  /// **'Plan adjusted'**
  String get planAdjusted_290c9a;

  /// No description provided for @planToStart_abd52d.
  ///
  /// In en, this message translates to:
  /// **'Plan to start {p0}'**
  String planToStart_abd52d(String p0);

  /// No description provided for @plannedStart_10db53.
  ///
  /// In en, this message translates to:
  /// **'Planned start'**
  String get plannedStart_10db53;

  /// No description provided for @plannedStart_6b09db.
  ///
  /// In en, this message translates to:
  /// **'Planned start {p0}'**
  String plannedStart_6b09db(String p0);

  /// No description provided for @plannedStartOptional_db8dd7.
  ///
  /// In en, this message translates to:
  /// **'Planned start · optional'**
  String get plannedStartOptional_db8dd7;

  /// No description provided for @plansChangeChooseWhatWorksFor_80a848.
  ///
  /// In en, this message translates to:
  /// **'Plans change. Choose what works for you now.'**
  String get plansChangeChooseWhatWorksFor_80a848;

  /// No description provided for @pleaseLetTheAccountConnectionFinish_8f3cae.
  ///
  /// In en, this message translates to:
  /// **'Please let the account connection finish first.'**
  String get pleaseLetTheAccountConnectionFinish_8f3cae;

  /// No description provided for @pleaseLetTheCurrentTaskOr_16adc6.
  ///
  /// In en, this message translates to:
  /// **'Please let the current task or account request finish.'**
  String get pleaseLetTheCurrentTaskOr_16adc6;

  /// No description provided for @pleaseReadTheInformationBelow_5fd5af.
  ///
  /// In en, this message translates to:
  /// **'Please read the information below.'**
  String get pleaseReadTheInformationBelow_5fd5af;

  /// No description provided for @pleaseWaitForTheCurrentReply_088243.
  ///
  /// In en, this message translates to:
  /// **'Please wait for the current reply before sending another message.'**
  String get pleaseWaitForTheCurrentReply_088243;

  /// No description provided for @pleaseWaitWhileThisPhoneChecks_26f534.
  ///
  /// In en, this message translates to:
  /// **'Please wait while this phone checks its reminder schedule.'**
  String get pleaseWaitWhileThisPhoneChecks_26f534;

  /// No description provided for @preferNotToAnswer_bdac46.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to answer'**
  String get preferNotToAnswer_bdac46;

  /// No description provided for @preferShorterResponses_f32f83.
  ///
  /// In en, this message translates to:
  /// **'Prefer shorter responses'**
  String get preferShorterResponses_f32f83;

  /// No description provided for @preferencesSaved_0b7d6e.
  ///
  /// In en, this message translates to:
  /// **'Preferences saved.'**
  String get preferencesSaved_0b7d6e;

  /// No description provided for @previousEntries_7d8403.
  ///
  /// In en, this message translates to:
  /// **'Previous entries'**
  String get previousEntries_7d8403;

  /// No description provided for @prioritiesChanged_9ac062.
  ///
  /// In en, this message translates to:
  /// **'Priorities changed'**
  String get prioritiesChanged_9ac062;

  /// No description provided for @priority_886cbf.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority_886cbf;

  /// No description provided for @privacyDemonstrationConsent_84c5c7.
  ///
  /// In en, this message translates to:
  /// **'Privacy & demonstration consent'**
  String get privacyDemonstrationConsent_84c5c7;

  /// No description provided for @progressNotPressure_6bc048.
  ///
  /// In en, this message translates to:
  /// **'Progress, not pressure.'**
  String get progressNotPressure_6bc048;

  /// No description provided for @quietHours_706b24.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get quietHours_706b24;

  /// No description provided for @quietHoursScheduledFor_d7c9f9.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours: scheduled for {p0}'**
  String quietHoursScheduledFor_d7c9f9(String p0);

  /// No description provided for @rarely_01d2ae.
  ///
  /// In en, this message translates to:
  /// **'Rarely'**
  String get rarely_01d2ae;

  /// No description provided for @readPrivacyAndConsentDetails_b80cfd.
  ///
  /// In en, this message translates to:
  /// **'Read privacy and consent details'**
  String get readPrivacyAndConsentDetails_b80cfd;

  /// No description provided for @ready_20c7c5.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready_20c7c5;

  /// No description provided for @recentlyHowEasyHasFollowingYour_7bf490.
  ///
  /// In en, this message translates to:
  /// **'Recently, how easy has following your plans felt?'**
  String get recentlyHowEasyHasFollowingYour_7bf490;

  /// No description provided for @refinementIsUnavailable_0e3812.
  ///
  /// In en, this message translates to:
  /// **'Refinement is unavailable.'**
  String get refinementIsUnavailable_0e3812;

  /// No description provided for @reflectOnMyGoal_6d1d30.
  ///
  /// In en, this message translates to:
  /// **'Reflect on my goal'**
  String get reflectOnMyGoal_6d1d30;

  /// No description provided for @reflectionAutonomy_27a6a7.
  ///
  /// In en, this message translates to:
  /// **'Reflection & autonomy'**
  String get reflectionAutonomy_27a6a7;

  /// No description provided for @refreshServerData_7b6b1d.
  ///
  /// In en, this message translates to:
  /// **'Refresh server data'**
  String get refreshServerData_7b6b1d;

  /// No description provided for @regenerateAServerSuggestionBeforeAccepting_0d3d9c.
  ///
  /// In en, this message translates to:
  /// **'Regenerate a server suggestion before accepting.'**
  String get regenerateAServerSuggestionBeforeAccepting_0d3d9c;

  /// No description provided for @regenerateSuggestions_986faf.
  ///
  /// In en, this message translates to:
  /// **'Regenerate suggestions'**
  String get regenerateSuggestions_986faf;

  /// No description provided for @rejectCorrection_03abed.
  ///
  /// In en, this message translates to:
  /// **'Reject correction'**
  String get rejectCorrection_03abed;

  /// No description provided for @rejectSuggestionsNotNow_9bb5e5.
  ///
  /// In en, this message translates to:
  /// **'Reject suggestions · Not now'**
  String get rejectSuggestionsNotNow_9bb5e5;

  /// No description provided for @remindAtDeadline_bbd863.
  ///
  /// In en, this message translates to:
  /// **'Remind at deadline'**
  String get remindAtDeadline_bbd863;

  /// No description provided for @remindAtPlannedStart_0f1513.
  ///
  /// In en, this message translates to:
  /// **'Remind at planned start'**
  String get remindAtPlannedStart_0f1513;

  /// No description provided for @remindMeLater_bebc1c.
  ///
  /// In en, this message translates to:
  /// **'Remind me later'**
  String get remindMeLater_bebc1c;

  /// No description provided for @reminderSchedulingNeedsAttention_0f940a.
  ///
  /// In en, this message translates to:
  /// **'Reminder scheduling needs attention.'**
  String get reminderSchedulingNeedsAttention_0f940a;

  /// No description provided for @reminderTimeChosen_8c748f.
  ///
  /// In en, this message translates to:
  /// **'Reminder time chosen'**
  String get reminderTimeChosen_8c748f;

  /// No description provided for @reminderTimeSavedDeliveryDependsOn_26ca16.
  ///
  /// In en, this message translates to:
  /// **'Reminder time saved: {p0}. Delivery depends on notification settings.'**
  String reminderTimeSavedDeliveryDependsOn_26ca16(String p0);

  /// No description provided for @reminderTime_bbde4a.
  ///
  /// In en, this message translates to:
  /// **'Reminder time · {p0}'**
  String reminderTime_bbde4a(String p0);

  /// No description provided for @reminderTimesFollowTheLocalClock_83f93e.
  ///
  /// In en, this message translates to:
  /// **'Reminder times follow the local clock. Enable phone notifications and choose quiet hours in Settings. Delivery may be delayed by your phone.'**
  String get reminderTimesFollowTheLocalClock_83f93e;

  /// No description provided for @reminderTypesLimits_feea2b.
  ///
  /// In en, this message translates to:
  /// **'Reminder types & limits'**
  String get reminderTypesLimits_feea2b;

  /// No description provided for @reminders_ae8c39.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders_ae8c39;

  /// No description provided for @removeAllConnectedAccountPendingReports_ed9e78.
  ///
  /// In en, this message translates to:
  /// **'Remove all connected-account pending reports, unsent messages, timers and notification preferences cached on this device. Unsynchronized records will be lost. Server records and the local demo remain unchanged.'**
  String get removeAllConnectedAccountPendingReports_ed9e78;

  /// No description provided for @removeDeadline_75e430.
  ///
  /// In en, this message translates to:
  /// **'Remove deadline'**
  String get removeDeadline_75e430;

  /// No description provided for @removePlannedStart_f74604.
  ///
  /// In en, this message translates to:
  /// **'Remove planned start'**
  String get removePlannedStart_f74604;

  /// No description provided for @removeReminder_ccd793.
  ///
  /// In en, this message translates to:
  /// **'Remove reminder'**
  String get removeReminder_ccd793;

  /// No description provided for @removeStep_1d868a.
  ///
  /// In en, this message translates to:
  /// **'Remove step {p0}'**
  String removeStep_1d868a(String p0);

  /// No description provided for @reopenOrResumeTheTaskBefore_a0556d.
  ///
  /// In en, this message translates to:
  /// **'Reopen or resume the task before focusing.'**
  String get reopenOrResumeTheTaskBefore_a0556d;

  /// No description provided for @reopenOrResumeThisTaskBefore_621cf3.
  ///
  /// In en, this message translates to:
  /// **'Reopen or resume this task before setting a reminder.'**
  String get reopenOrResumeThisTaskBefore_621cf3;

  /// No description provided for @reopenThisTaskBeforeRequestingA_0d5d58.
  ///
  /// In en, this message translates to:
  /// **'Reopen this task before requesting a breakdown.'**
  String get reopenThisTaskBeforeRequestingA_0d5d58;

  /// No description provided for @reopenThisTaskBeforeStartingIt_3bf99b.
  ///
  /// In en, this message translates to:
  /// **'Reopen this task before starting it.'**
  String get reopenThisTaskBeforeStartingIt_3bf99b;

  /// No description provided for @reopenThisTaskToChangeIts_00bc3a.
  ///
  /// In en, this message translates to:
  /// **'Reopen this task to change its plan.'**
  String get reopenThisTaskToChangeIts_00bc3a;

  /// No description provided for @reportedTaskStarts_56b2db.
  ///
  /// In en, this message translates to:
  /// **'Reported task starts'**
  String get reportedTaskStarts_56b2db;

  /// No description provided for @requestAServerProposalFirst_b8297d.
  ///
  /// In en, this message translates to:
  /// **'Request a server proposal first.'**
  String get requestAServerProposalFirst_b8297d;

  /// No description provided for @requestPermission_b49ac3.
  ///
  /// In en, this message translates to:
  /// **'Request permission'**
  String get requestPermission_b49ac3;

  /// No description provided for @researchOnboarding_e8a35e.
  ///
  /// In en, this message translates to:
  /// **'Research onboarding'**
  String get researchOnboarding_e8a35e;

  /// No description provided for @researchPrototypeShimaneUniversityUseFictional_78a317.
  ///
  /// In en, this message translates to:
  /// **'Research prototype · Shimane University\n\nUse fictional data only. This build does not collect real participant research data. Phone reminders require your permission. Reminder taps only open a task; they do not start a session or mark it complete.'**
  String get researchPrototypeShimaneUniversityUseFictional_78a317;

  /// No description provided for @researcherDemoMode_44c8be.
  ///
  /// In en, this message translates to:
  /// **'Researcher Demo Mode'**
  String get researcherDemoMode_44c8be;

  /// No description provided for @researcherDemoSeparateAgentHistories_2e583b.
  ///
  /// In en, this message translates to:
  /// **'Researcher demo · separate agent histories'**
  String get researcherDemoSeparateAgentHistories_2e583b;

  /// No description provided for @resetLocalDemo_c6435b.
  ///
  /// In en, this message translates to:
  /// **'Reset local demo'**
  String get resetLocalDemo_c6435b;

  /// No description provided for @resetLocalDemo_fc75d3.
  ///
  /// In en, this message translates to:
  /// **'Reset local demo?'**
  String get resetLocalDemo_fc75d3;

  /// No description provided for @responseRetryCancelledMessageKeptIn_33e3a4.
  ///
  /// In en, this message translates to:
  /// **'Response retry cancelled. Message kept in history.'**
  String get responseRetryCancelledMessageKeptIn_33e3a4;

  /// No description provided for @resumeSession_bcc407.
  ///
  /// In en, this message translates to:
  /// **'Resume session'**
  String get resumeSession_bcc407;

  /// No description provided for @resumeThisTask_a4926e.
  ///
  /// In en, this message translates to:
  /// **'Resume this task'**
  String get resumeThisTask_a4926e;

  /// No description provided for @retry_9f5cd8.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry_9f5cd8;

  /// No description provided for @returnToFocusSession_f18054.
  ///
  /// In en, this message translates to:
  /// **'Return to focus session'**
  String get returnToFocusSession_f18054;

  /// No description provided for @review_e29a79.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review_e29a79;

  /// No description provided for @reviewADifferentPlan_64fb85.
  ///
  /// In en, this message translates to:
  /// **'Review a different plan'**
  String get reviewADifferentPlan_64fb85;

  /// No description provided for @reviewATaskBreakdown_359f9f.
  ///
  /// In en, this message translates to:
  /// **'Review a task breakdown'**
  String get reviewATaskBreakdown_359f9f;

  /// No description provided for @reviewExportContents_614fb9.
  ///
  /// In en, this message translates to:
  /// **'Review export contents'**
  String get reviewExportContents_614fb9;

  /// No description provided for @reviewLoadedStatePartial_314c03.
  ///
  /// In en, this message translates to:
  /// **'Review loaded state (partial)'**
  String get reviewLoadedStatePartial_314c03;

  /// No description provided for @reviewNotificationPreferences_9a963c.
  ///
  /// In en, this message translates to:
  /// **'Review notification preferences'**
  String get reviewNotificationPreferences_9a963c;

  /// No description provided for @reviewSuggestion_bcac70.
  ///
  /// In en, this message translates to:
  /// **'Review suggestion'**
  String get reviewSuggestion_bcac70;

  /// No description provided for @reviewTaskCorrection_1ccbf7.
  ///
  /// In en, this message translates to:
  /// **'Review task correction'**
  String get reviewTaskCorrection_1ccbf7;

  /// No description provided for @reviewTaskStatus_6f6ec9.
  ///
  /// In en, this message translates to:
  /// **'Review task status'**
  String get reviewTaskStatus_6f6ec9;

  /// No description provided for @selfReflection_4445e0.
  ///
  /// In en, this message translates to:
  /// **'SELF-REFLECTION'**
  String get selfReflection_4445e0;

  /// No description provided for @smallSteps_01d07f.
  ///
  /// In en, this message translates to:
  /// **'SMALL STEPS'**
  String get smallSteps_01d07f;

  /// No description provided for @supportiveChat_6a8335.
  ///
  /// In en, this message translates to:
  /// **'SUPPORTIVE CHAT'**
  String get supportiveChat_6a8335;

  /// No description provided for @saveCheckIn_1894e2.
  ///
  /// In en, this message translates to:
  /// **'Save & check in'**
  String get saveCheckIn_1894e2;

  /// No description provided for @saveCheckIn_6dfe99.
  ///
  /// In en, this message translates to:
  /// **'Save check-in'**
  String get saveCheckIn_6dfe99;

  /// No description provided for @savePreferences_d8ab74.
  ///
  /// In en, this message translates to:
  /// **'Save preferences'**
  String get savePreferences_d8ab74;

  /// No description provided for @saveSession_8c7478.
  ///
  /// In en, this message translates to:
  /// **'Save session'**
  String get saveSession_8c7478;

  /// No description provided for @saveSteps_802b24.
  ///
  /// In en, this message translates to:
  /// **'Save steps'**
  String get saveSteps_802b24;

  /// No description provided for @saveTask_e84d4a.
  ///
  /// In en, this message translates to:
  /// **'Save task'**
  String get saveTask_e84d4a;

  /// No description provided for @savedLocally_fd07a5.
  ///
  /// In en, this message translates to:
  /// **'Saved locally: {p0}'**
  String savedLocally_fd07a5(String p0);

  /// No description provided for @savedToDevelopmentAccount_cd928e.
  ///
  /// In en, this message translates to:
  /// **'Saved to development account: {p0}'**
  String savedToDevelopmentAccount_cd928e(String p0);

  /// No description provided for @scheduledOnThisPhone_441ddb.
  ///
  /// In en, this message translates to:
  /// **'Scheduled on this phone'**
  String get scheduledOnThisPhone_441ddb;

  /// No description provided for @scriptedDemoProposal_7bb294.
  ///
  /// In en, this message translates to:
  /// **'Scripted demo proposal'**
  String get scriptedDemoProposal_7bb294;

  /// No description provided for @selfAgent_fa69bf.
  ///
  /// In en, this message translates to:
  /// **'Self-Agent'**
  String get selfAgent_fa69bf;

  /// No description provided for @sendMessage_c70a89.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessage_c70a89;

  /// No description provided for @sessionEndedEarly_da9211.
  ///
  /// In en, this message translates to:
  /// **'Session ended early'**
  String get sessionEndedEarly_da9211;

  /// No description provided for @sessionTimeElapsed_dd08a1.
  ///
  /// In en, this message translates to:
  /// **'Session time elapsed'**
  String get sessionTimeElapsed_dd08a1;

  /// No description provided for @settings_c7f73b.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_c7f73b;

  /// No description provided for @shimaneUniversityHaiResearchPrototype_6f7a11.
  ///
  /// In en, this message translates to:
  /// **'Shimane University · HAI research prototype'**
  String get shimaneUniversityHaiResearchPrototype_6f7a11;

  /// No description provided for @showSmallStepInvitations_5e4106.
  ///
  /// In en, this message translates to:
  /// **'Show small-step invitations'**
  String get showSmallStepInvitations_5e4106;

  /// No description provided for @simulateNextRequestFailure_aa9665.
  ///
  /// In en, this message translates to:
  /// **'Simulate next request failure'**
  String get simulateNextRequestFailure_aa9665;

  /// No description provided for @skipAnyQuestionOrLeaveWithout_7a8ae8.
  ///
  /// In en, this message translates to:
  /// **'Skip any question, or leave without saving.'**
  String get skipAnyQuestionOrLeaveWithout_7a8ae8;

  /// No description provided for @skipForNow_6fc096.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow_6fc096;

  /// No description provided for @smallSteps_5b77d5.
  ///
  /// In en, this message translates to:
  /// **'Small Steps'**
  String get smallSteps_5b77d5;

  /// No description provided for @smallStepsConnectedDevelopment_b3aebd.
  ///
  /// In en, this message translates to:
  /// **'Small Steps · Connected development'**
  String get smallStepsConnectedDevelopment_b3aebd;

  /// No description provided for @smallStepsDemo_989b13.
  ///
  /// In en, this message translates to:
  /// **'Small Steps · Demo'**
  String get smallStepsDemo_989b13;

  /// No description provided for @smallSteps_937996.
  ///
  /// In en, this message translates to:
  /// **'Small steps ({p0}/{p1})'**
  String smallSteps_937996(String p0, String p1);

  /// No description provided for @smallStepInvitationOpened_231b06.
  ///
  /// In en, this message translates to:
  /// **'Small-step invitation opened'**
  String get smallStepInvitationOpened_231b06;

  /// No description provided for @someDeviceDataCouldNotBe_9b2e00.
  ///
  /// In en, this message translates to:
  /// **'Some device data could not be cleared. Try again or clear app storage.'**
  String get someDeviceDataCouldNotBe_9b2e00;

  /// No description provided for @sometimes_1bc4d6.
  ///
  /// In en, this message translates to:
  /// **'Sometimes'**
  String get sometimes_1bc4d6;

  /// No description provided for @somewhat_8412ec.
  ///
  /// In en, this message translates to:
  /// **'Somewhat'**
  String get somewhat_8412ec;

  /// No description provided for @somewhatDifficult_b0b36f.
  ///
  /// In en, this message translates to:
  /// **'Somewhat difficult'**
  String get somewhatDifficult_b0b36f;

  /// No description provided for @somewhatReady_1cc0ee.
  ///
  /// In en, this message translates to:
  /// **'Somewhat ready'**
  String get somewhatReady_1cc0ee;

  /// No description provided for @standardReminders_ccd7cf.
  ///
  /// In en, this message translates to:
  /// **'Standard reminders'**
  String get standardReminders_ccd7cf;

  /// No description provided for @standardTaskSupport_4fe425.
  ///
  /// In en, this message translates to:
  /// **'Standard task support'**
  String get standardTaskSupport_4fe425;

  /// No description provided for @startAFocusSession_c5dc51.
  ///
  /// In en, this message translates to:
  /// **'Start a focus session'**
  String get startAFocusSession_c5dc51;

  /// No description provided for @startSession_76684e.
  ///
  /// In en, this message translates to:
  /// **'Start session'**
  String get startSession_76684e;

  /// No description provided for @startTheBackendThenEnterA_26d501.
  ///
  /// In en, this message translates to:
  /// **'Start the backend, then enter a synthetic participant token from the backend account file. This is a participant access token, never your Gemini API key. Local demo tasks and chat history are not uploaded.'**
  String get startTheBackendThenEnterA_26d501;

  /// No description provided for @startingCanFeelDifficultSometimesWould_46ec3d.
  ///
  /// In en, this message translates to:
  /// **'Starting can feel difficult sometimes.\n\nWould you like to talk about what feels hard, or try one small step together?'**
  String get startingCanFeelDifficultSometimesWould_46ec3d;

  /// No description provided for @status_185ea7.
  ///
  /// In en, this message translates to:
  /// **'Status: {p0}'**
  String status_185ea7(String p0);

  /// No description provided for @step_203035.
  ///
  /// In en, this message translates to:
  /// **'Step {p0}'**
  String step_203035(String p0);

  /// No description provided for @stepEditable_ca61e8.
  ///
  /// In en, this message translates to:
  /// **'Step {p0} · editable'**
  String stepEditable_ca61e8(String p0);

  /// No description provided for @storageUnavailable_c629ac.
  ///
  /// In en, this message translates to:
  /// **'Storage unavailable'**
  String get storageUnavailable_c629ac;

  /// No description provided for @studyAssignmentIsControlledByThe_9020ed.
  ///
  /// In en, this message translates to:
  /// **'Study assignment is controlled by the backend.'**
  String get studyAssignmentIsControlledByThe_9020ed;

  /// No description provided for @studyPreferencesAreNotConnected_9d5716.
  ///
  /// In en, this message translates to:
  /// **'Study preferences are not connected.'**
  String get studyPreferencesAreNotConnected_9d5716;

  /// No description provided for @studyServiceRequired_fa898d.
  ///
  /// In en, this message translates to:
  /// **'Study service required'**
  String get studyServiceRequired_fa898d;

  /// No description provided for @studySetup_99dc41.
  ///
  /// In en, this message translates to:
  /// **'Study setup'**
  String get studySetup_99dc41;

  /// No description provided for @suggestedBreakdownBackendAi_ad7b42.
  ///
  /// In en, this message translates to:
  /// **'Suggested breakdown · Backend AI'**
  String get suggestedBreakdownBackendAi_ad7b42;

  /// No description provided for @suggestedBreakdownDemoService_329994.
  ///
  /// In en, this message translates to:
  /// **'Suggested breakdown · Demo service'**
  String get suggestedBreakdownDemoService_329994;

  /// No description provided for @suggestedDescriptionEditable_fe6d8a.
  ///
  /// In en, this message translates to:
  /// **'Suggested description · editable'**
  String get suggestedDescriptionEditable_fe6d8a;

  /// No description provided for @suggestedStepsAccepted_b67ab6.
  ///
  /// In en, this message translates to:
  /// **'Suggested steps accepted'**
  String get suggestedStepsAccepted_b67ab6;

  /// No description provided for @suggestedTitleEditable_aa86af.
  ///
  /// In en, this message translates to:
  /// **'Suggested title · editable'**
  String get suggestedTitleEditable_aa86af;

  /// No description provided for @suggestionDismissed_c4ed78.
  ///
  /// In en, this message translates to:
  /// **'Suggestion dismissed'**
  String get suggestionDismissed_c4ed78;

  /// No description provided for @suggestionReviewOpened_40a73a.
  ///
  /// In en, this message translates to:
  /// **'Suggestion review opened'**
  String get suggestionReviewOpened_40a73a;

  /// No description provided for @suggestionShown_f317b4.
  ///
  /// In en, this message translates to:
  /// **'Suggestion shown'**
  String get suggestionShown_f317b4;

  /// No description provided for @suggestionsDeclined_5af8e5.
  ///
  /// In en, this message translates to:
  /// **'Suggestions declined'**
  String get suggestionsDeclined_5af8e5;

  /// No description provided for @suggestionsRemainADraftUntilYou_4b4705.
  ///
  /// In en, this message translates to:
  /// **'Suggestions remain a draft until you accept them. Existing steps are kept.'**
  String get suggestionsRemainADraftUntilYou_4b4705;

  /// No description provided for @suggestionsRequested_1fa652.
  ///
  /// In en, this message translates to:
  /// **'Suggestions requested'**
  String get suggestionsRequested_1fa652;

  /// No description provided for @switch_3e44c9.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get switch_3e44c9;

  /// No description provided for @switchTo_ce5010.
  ///
  /// In en, this message translates to:
  /// **'Switch to {p0}'**
  String switchTo_ce5010(String p0);

  /// No description provided for @syntheticAccountsOnly_9fd71e.
  ///
  /// In en, this message translates to:
  /// **'Synthetic accounts only'**
  String get syntheticAccountsOnly_9fd71e;

  /// No description provided for @talkAboutThisTask_b85110.
  ///
  /// In en, this message translates to:
  /// **'Talk about this task'**
  String get talkAboutThisTask_b85110;

  /// No description provided for @taskSessionHistory_6df948.
  ///
  /// In en, this message translates to:
  /// **'Task & session history'**
  String get taskSessionHistory_6df948;

  /// No description provided for @taskAdded_6bb7dd.
  ///
  /// In en, this message translates to:
  /// **'Task added'**
  String get taskAdded_6bb7dd;

  /// No description provided for @taskCompletionUndone_b6f2c6.
  ///
  /// In en, this message translates to:
  /// **'Task completion undone'**
  String get taskCompletionUndone_b6f2c6;

  /// No description provided for @taskContext_0eecee.
  ///
  /// In en, this message translates to:
  /// **'Task context'**
  String get taskContext_0eecee;

  /// No description provided for @taskCorrectionAccepted_402281.
  ///
  /// In en, this message translates to:
  /// **'Task correction accepted'**
  String get taskCorrectionAccepted_402281;

  /// No description provided for @taskCorrectionIsUnavailable_cc083b.
  ///
  /// In en, this message translates to:
  /// **'Task correction is unavailable.'**
  String get taskCorrectionIsUnavailable_cc083b;

  /// No description provided for @taskCorrectionProposed_2cad2b.
  ///
  /// In en, this message translates to:
  /// **'Task correction proposed'**
  String get taskCorrectionProposed_2cad2b;

  /// No description provided for @taskCorrectionRejected_08118f.
  ///
  /// In en, this message translates to:
  /// **'Task correction rejected'**
  String get taskCorrectionRejected_08118f;

  /// No description provided for @taskDeleted_d3c52b.
  ///
  /// In en, this message translates to:
  /// **'Task deleted'**
  String get taskDeleted_d3c52b;

  /// No description provided for @taskInvitationsAreOff_963123.
  ///
  /// In en, this message translates to:
  /// **'Task invitations are off.'**
  String get taskInvitationsAreOff_963123;

  /// No description provided for @taskMarkedComplete_c1e013.
  ///
  /// In en, this message translates to:
  /// **'Task marked complete'**
  String get taskMarkedComplete_c1e013;

  /// No description provided for @taskMarkedComplete_1999ee.
  ///
  /// In en, this message translates to:
  /// **'Task marked complete.'**
  String get taskMarkedComplete_1999ee;

  /// No description provided for @taskNoLongerAvailable_73d64f.
  ///
  /// In en, this message translates to:
  /// **'Task no longer available'**
  String get taskNoLongerAvailable_73d64f;

  /// No description provided for @taskNotFound_69113b.
  ///
  /// In en, this message translates to:
  /// **'Task not found'**
  String get taskNotFound_69113b;

  /// No description provided for @taskPlanning_fe486a.
  ///
  /// In en, this message translates to:
  /// **'Task planning'**
  String get taskPlanning_fe486a;

  /// No description provided for @taskRefinementIsUnavailableInThis_d4c9b4.
  ///
  /// In en, this message translates to:
  /// **'Task refinement is unavailable in this condition.'**
  String get taskRefinementIsUnavailableInThis_d4c9b4;

  /// No description provided for @taskRefinementIsUnavailable_aa2603.
  ///
  /// In en, this message translates to:
  /// **'Task refinement is unavailable.'**
  String get taskRefinementIsUnavailable_aa2603;

  /// No description provided for @taskReminders_ca6754.
  ///
  /// In en, this message translates to:
  /// **'Task reminders'**
  String get taskReminders_ca6754;

  /// No description provided for @taskResumed_cb663d.
  ///
  /// In en, this message translates to:
  /// **'Task resumed'**
  String get taskResumed_cb663d;

  /// No description provided for @taskStartReported_c445cb.
  ///
  /// In en, this message translates to:
  /// **'Task start reported'**
  String get taskStartReported_c445cb;

  /// No description provided for @taskTitle_624d94.
  ///
  /// In en, this message translates to:
  /// **'Task title'**
  String get taskTitle_624d94;

  /// No description provided for @taskUnavailable_cfd1de.
  ///
  /// In en, this message translates to:
  /// **'Task unavailable'**
  String get taskUnavailable_cfd1de;

  /// No description provided for @taskUpdated_f1e9a1.
  ///
  /// In en, this message translates to:
  /// **'Task updated'**
  String get taskUpdated_f1e9a1;

  /// No description provided for @tasks_090ec5.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks_090ec5;

  /// No description provided for @tasksAndConversationsAreStoredOn_b5abfb.
  ///
  /// In en, this message translates to:
  /// **'Tasks and conversations are stored on the development server. Your token stays in memory and must be entered again after restarting the app.'**
  String get tasksAndConversationsAreStoredOn_b5abfb;

  /// No description provided for @tasksCompleted_e0803f.
  ///
  /// In en, this message translates to:
  /// **'Tasks completed'**
  String get tasksCompleted_e0803f;

  /// No description provided for @theDemoRequestDidNotFinish_8eef45.
  ///
  /// In en, this message translates to:
  /// **'The demo request did not finish. Please try again.'**
  String get theDemoRequestDidNotFinish_8eef45;

  /// No description provided for @theExportDoesNotMatchThis_f2ca2a.
  ///
  /// In en, this message translates to:
  /// **'The export does not match this account. Nothing was copied.'**
  String get theExportDoesNotMatchThis_f2ca2a;

  /// No description provided for @theExportIncludesLocalTaskText_7ad752.
  ///
  /// In en, this message translates to:
  /// **'The export includes local task text, conversations, preferences and reflections. Review it before copying or sharing. It is demo data, not an anonymized research dataset.'**
  String get theExportIncludesLocalTaskText_7ad752;

  /// No description provided for @theNextDemoRequestWillFail_325484.
  ///
  /// In en, this message translates to:
  /// **'The next demo request will fail once, so you can test retry.'**
  String get theNextDemoRequestWillFail_325484;

  /// No description provided for @theNextRemindersAreScheduledReopen_cc8080.
  ///
  /// In en, this message translates to:
  /// **'The next {p0} reminders are scheduled. Reopen the app to fill available slots.'**
  String theNextRemindersAreScheduledReopen_cc8080(String p0);

  /// No description provided for @theResponseDidNotArriveYou_c601c2.
  ///
  /// In en, this message translates to:
  /// **'The response did not arrive. You can retry, edit this message, or leave it and continue.'**
  String get theResponseDidNotArriveYou_c601c2;

  /// No description provided for @theServerAssignmentChangedDisconnectAnd_a424f3.
  ///
  /// In en, this message translates to:
  /// **'The server assignment changed. Disconnect and sign in again.'**
  String get theServerAssignmentChangedDisconnectAnd_a424f3;

  /// No description provided for @theServerDidNotConfirmErasure_0aa3fe.
  ///
  /// In en, this message translates to:
  /// **'The server did not confirm erasure. Your device data was retained.'**
  String get theServerDidNotConfirmErasure_0aa3fe;

  /// No description provided for @theSessionWillBeSavedSeparately_4a1171.
  ///
  /// In en, this message translates to:
  /// **'The session will be saved separately from task completion. You decide when your task is complete.'**
  String get theSessionWillBeSavedSeparately_4a1171;

  /// No description provided for @theStudyServiceResponseDoesNot_9cf42f.
  ///
  /// In en, this message translates to:
  /// **'The study service response does not match the API contract.'**
  String get theStudyServiceResponseDoesNot_9cf42f;

  /// No description provided for @theStudyServiceReturnedAnUnexpected_ca8cc2.
  ///
  /// In en, this message translates to:
  /// **'The study service returned an unexpected response.'**
  String get theStudyServiceReturnedAnUnexpected_ca8cc2;

  /// No description provided for @theTaskFeelsTooLarge_80804b.
  ///
  /// In en, this message translates to:
  /// **'The task feels too large'**
  String get theTaskFeelsTooLarge_80804b;

  /// No description provided for @thereIsNoFailedMessageTo_b15628.
  ///
  /// In en, this message translates to:
  /// **'There is no failed message to retry.'**
  String get thereIsNoFailedMessageTo_b15628;

  /// No description provided for @thereIsNoUndecidedSuggestionTo_fdbe44.
  ///
  /// In en, this message translates to:
  /// **'There is no undecided suggestion to reject.'**
  String get thereIsNoUndecidedSuggestionTo_fdbe44;

  /// No description provided for @theseDetailsAreOptionalYouCan_c938a9.
  ///
  /// In en, this message translates to:
  /// **'These details are optional. You can change or clear them at any time.'**
  String get theseDetailsAreOptionalYouCan_c938a9;

  /// No description provided for @thesePreferencesAreSavedOnThe_4453aa.
  ///
  /// In en, this message translates to:
  /// **'These preferences are saved on the development backend and supplied as context for AI requests. Use fictional information. They do not change your assigned condition.'**
  String get thesePreferencesAreSavedOnThe_4453aa;

  /// No description provided for @thisAcknowledgmentDemonstratesTheOnboardingInteraction_7acce1.
  ///
  /// In en, this message translates to:
  /// **'This acknowledgment demonstrates the onboarding interaction. It is not legally or ethically sufficient research consent.\n\nDemo tasks, chats, reflections and preferences are stored locally in unencrypted app preferences. Use fictional, non-sensitive data. Settings → Reset demo removes this data.\n\nReal participation requires approved study information, withdrawal rules, retention details, researcher contact information, authentication and backend assignment. These are not yet connected.'**
  String get thisAcknowledgmentDemonstratesTheOnboardingInteraction_7acce1;

  /// No description provided for @thisChangesTheReminderOnlyYour_5da181.
  ///
  /// In en, this message translates to:
  /// **'This changes the reminder only. Your planned start and deadline stay as you set them.'**
  String get thisChangesTheReminderOnlyYour_5da181;

  /// No description provided for @thisConnectionSupportsSyntheticDevelopmentAccounts_712b2c.
  ///
  /// In en, this message translates to:
  /// **'This connection supports synthetic development accounts only.'**
  String get thisConnectionSupportsSyntheticDevelopmentAccounts_712b2c;

  /// No description provided for @thisInstallationIsALocalDemonstration_df04cf.
  ///
  /// In en, this message translates to:
  /// **'This installation is a local demonstration.'**
  String get thisInstallationIsALocalDemonstration_df04cf;

  /// No description provided for @thisIsAConnectedDevelopmentDemonstration_759c09.
  ///
  /// In en, this message translates to:
  /// **'This is a connected development demonstration, not research enrollment. Fictional tasks and messages are stored on your backend; relevant AI request text is sent to Google Gemini. You can disconnect in Settings. The token stays in memory. Pending reports and the focus timer may be cached unencrypted on this device.'**
  String get thisIsAConnectedDevelopmentDemonstration_759c09;

  /// No description provided for @thisPhoneHasNotAllowedNotifications_e79c77.
  ///
  /// In en, this message translates to:
  /// **'This phone has not allowed notifications. Request permission below. If no prompt appears, allow notifications in phone Settings, then check again.'**
  String get thisPhoneHasNotAllowedNotifications_e79c77;

  /// No description provided for @thisPreviewCannotSendNotificationsYou_01e75e.
  ///
  /// In en, this message translates to:
  /// **'This preview cannot send notifications. You can still save reminder times for your tasks.'**
  String get thisPreviewCannotSendNotificationsYou_01e75e;

  /// No description provided for @thisPreviewSavesTheTimeBut_95d4b4.
  ///
  /// In en, this message translates to:
  /// **'This preview saves the time but cannot send notifications. Set or sync this reminder in the Android or iPhone app.'**
  String get thisPreviewSavesTheTimeBut_95d4b4;

  /// No description provided for @thisProposalChangedOrWasAlready_d62eba.
  ///
  /// In en, this message translates to:
  /// **'This proposal changed or was already decided. Request a new one.'**
  String get thisProposalChangedOrWasAlready_d62eba;

  /// No description provided for @thisRemovesDemoTasksConversationsReflections_707870.
  ///
  /// In en, this message translates to:
  /// **'This removes demo tasks, conversations, reflections and settings from this device.'**
  String get thisRemovesDemoTasksConversationsReflections_707870;

  /// No description provided for @thisRemovesTheTaskAndIts_97c470.
  ///
  /// In en, this message translates to:
  /// **'This removes the task and its small steps. Session history is retained.'**
  String get thisRemovesTheTaskAndIts_97c470;

  /// No description provided for @thisTaskChangedRegenerateSuggestionsBefore_651394.
  ///
  /// In en, this message translates to:
  /// **'This task changed. Regenerate suggestions before accepting.'**
  String get thisTaskChangedRegenerateSuggestionsBefore_651394;

  /// No description provided for @thisTaskChangedReopenTheSteps_fbdb92.
  ///
  /// In en, this message translates to:
  /// **'This task changed. Reopen the steps editor.'**
  String get thisTaskChangedReopenTheSteps_fbdb92;

  /// No description provided for @thisTaskChangedReviewItsCurrent_ac32ad.
  ///
  /// In en, this message translates to:
  /// **'This task changed. Review its current status before trying again.'**
  String get thisTaskChangedReviewItsCurrent_ac32ad;

  /// No description provided for @thisTaskIsBeingSavedPlease_b283f3.
  ///
  /// In en, this message translates to:
  /// **'This task is being saved. Please wait for it to finish.'**
  String get thisTaskIsBeingSavedPlease_b283f3;

  /// No description provided for @thisTaskIsCompleteItsReminders_f3d943.
  ///
  /// In en, this message translates to:
  /// **'This task is complete. Its reminders are cancelled.'**
  String get thisTaskIsCompleteItsReminders_f3d943;

  /// No description provided for @thisTaskIsNotCurrentlyScheduled_6cb52b.
  ///
  /// In en, this message translates to:
  /// **'This task is not currently scheduled on this phone. Review its time, daily limit, cooldown or reminder settings.'**
  String get thisTaskIsNotCurrentlyScheduled_6cb52b;

  /// No description provided for @thisTaskIsPausedResumeIt_27db0a.
  ///
  /// In en, this message translates to:
  /// **'This task is paused. Resume it before choosing a reminder.'**
  String get thisTaskIsPausedResumeIt_27db0a;

  /// No description provided for @thisTaskOrAccountChangedNothing_b7bcf4.
  ///
  /// In en, this message translates to:
  /// **'This task or account changed. Nothing was undone.'**
  String get thisTaskOrAccountChangedNothing_b7bcf4;

  /// No description provided for @thisTaskWasDeletedCancelThis_643d87.
  ///
  /// In en, this message translates to:
  /// **'This task was deleted. Cancel this failed message before starting a new conversation.'**
  String get thisTaskWasDeletedCancelThis_643d87;

  /// No description provided for @thisTaskWasDeletedItsConversation_35be64.
  ///
  /// In en, this message translates to:
  /// **'This task was deleted. Its conversation is kept as read-only history.'**
  String get thisTaskWasDeletedItsConversation_35be64;

  /// No description provided for @timeSaved_bf2a1a.
  ///
  /// In en, this message translates to:
  /// **'Time saved'**
  String get timeSaved_bf2a1a;

  /// No description provided for @toDo_8665ae.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get toDo_8665ae;

  /// No description provided for @today_24345a.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today_24345a;

  /// No description provided for @todaySReminders_9b690a.
  ///
  /// In en, this message translates to:
  /// **'Today’s reminders'**
  String get todaySReminders_9b690a;

  /// No description provided for @tryABaselineCheckIn_a2c0b4.
  ///
  /// In en, this message translates to:
  /// **'Try a baseline check-in'**
  String get tryABaselineCheckIn_a2c0b4;

  /// No description provided for @tryAFiveMinuteStart_c99d07.
  ///
  /// In en, this message translates to:
  /// **'Try a five-minute start'**
  String get tryAFiveMinuteStart_c99d07;

  /// No description provided for @tryAgain_042c86.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain_042c86;

  /// No description provided for @unclear_ff75e0.
  ///
  /// In en, this message translates to:
  /// **'Unclear'**
  String get unclear_ff75e0;

  /// No description provided for @undo_39fc72.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo_39fc72;

  /// No description provided for @unknownNotificationReport_f6a1b9.
  ///
  /// In en, this message translates to:
  /// **'Unknown notification report.'**
  String get unknownNotificationReport_f6a1b9;

  /// No description provided for @unknownRecoveryAction_ff0861.
  ///
  /// In en, this message translates to:
  /// **'Unknown recovery action.'**
  String get unknownRecoveryAction_ff0861;

  /// No description provided for @until_7472c2.
  ///
  /// In en, this message translates to:
  /// **'Until {p0}'**
  String until_7472c2(String p0);

  /// No description provided for @upNext_567bfc.
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get upNext_567bfc;

  /// No description provided for @upToScheduledSlotsPerDay_77771e.
  ///
  /// In en, this message translates to:
  /// **'Up to {p0} scheduled slots per day · {p1} min apart'**
  String upToScheduledSlotsPerDay_77771e(String p0, String p1);

  /// No description provided for @updatingReminders_d06961.
  ///
  /// In en, this message translates to:
  /// **'Updating reminders'**
  String get updatingReminders_d06961;

  /// No description provided for @useALocalhostEmulatorHttpAddress_92a22a.
  ///
  /// In en, this message translates to:
  /// **'Use a localhost/emulator HTTP address or an HTTPS backend URL.'**
  String get useALocalhostEmulatorHttpAddress_92a22a;

  /// No description provided for @useAssignedAgentWording_104d77.
  ///
  /// In en, this message translates to:
  /// **'Use assigned agent wording'**
  String get useAssignedAgentWording_104d77;

  /// No description provided for @useTheRunningFastapiServiceAnd_911b62.
  ///
  /// In en, this message translates to:
  /// **'Use the running FastAPI service and its assigned agent.'**
  String get useTheRunningFastapiServiceAnd_911b62;

  /// No description provided for @veryDifficult_cc7a51.
  ///
  /// In en, this message translates to:
  /// **'Very difficult'**
  String get veryDifficult_cc7a51;

  /// No description provided for @veryEasy_9b1240.
  ///
  /// In en, this message translates to:
  /// **'Very easy'**
  String get veryEasy_9b1240;

  /// No description provided for @veryOften_ddf202.
  ///
  /// In en, this message translates to:
  /// **'Very often'**
  String get veryOften_ddf202;

  /// No description provided for @viewAllTasks_806e80.
  ///
  /// In en, this message translates to:
  /// **'View all tasks'**
  String get viewAllTasks_806e80;

  /// No description provided for @viewTask_39e023.
  ///
  /// In en, this message translates to:
  /// **'View task'**
  String get viewTask_39e023;

  /// No description provided for @weAreExploringHowDifferentTypes_6e615d.
  ///
  /// In en, this message translates to:
  /// **'We are exploring how different types of task support influence motivation, self-control and everyday progress.'**
  String get weAreExploringHowDifferentTypes_6e615d;

  /// No description provided for @weCanKeepThisManageableYou_ab5784.
  ///
  /// In en, this message translates to:
  /// **'We can keep this manageable. You choose what feels useful.'**
  String get weCanKeepThisManageableYou_ab5784;

  /// No description provided for @welcomeToTheStudy_3de6d2.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the study'**
  String get welcomeToTheStudy_3de6d2;

  /// No description provided for @whatAreWeStudying_505e74.
  ///
  /// In en, this message translates to:
  /// **'What are we studying?'**
  String get whatAreWeStudying_505e74;

  /// No description provided for @whatMadeItEasierOrHarder_6dc655.
  ///
  /// In en, this message translates to:
  /// **'What made it easier or harder to begin? What would you like to try next time?'**
  String get whatMadeItEasierOrHarder_6dc655;

  /// No description provided for @whatMattersToMe_7344b1.
  ///
  /// In en, this message translates to:
  /// **'What matters to me'**
  String get whatMattersToMe_7344b1;

  /// No description provided for @whatMattersToYouAboutThe_cb956d.
  ///
  /// In en, this message translates to:
  /// **'What matters to you about the task you would like to begin?\n\nYou can choose a small step that fits your goals.'**
  String get whatMattersToYouAboutThe_cb956d;

  /// No description provided for @whatMattersToYou_0337b3.
  ///
  /// In en, this message translates to:
  /// **'What matters to you?'**
  String get whatMattersToYou_0337b3;

  /// No description provided for @whatWouldAManageableStartOn_e2d547.
  ///
  /// In en, this message translates to:
  /// **'What would a manageable start on “{p0}” mean for your own goals?'**
  String whatWouldAManageableStartOn_e2d547(String p0);

  /// No description provided for @writeEditOrRemoveYourOwn_c6e042.
  ///
  /// In en, this message translates to:
  /// **'Write, edit or remove your own steps.'**
  String get writeEditOrRemoveYourOwn_c6e042;

  /// No description provided for @yourOriginalGoal_3efaa8.
  ///
  /// In en, this message translates to:
  /// **'YOUR ORIGINAL GOAL'**
  String get yourOriginalGoal_3efaa8;

  /// No description provided for @yes_5397e0.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes_5397e0;

  /// No description provided for @you_905cb3.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you_905cb3;

  /// No description provided for @youCanChangeYourPlanAt_7e2939.
  ///
  /// In en, this message translates to:
  /// **'You can change your plan at any time.'**
  String get youCanChangeYourPlanAt_7e2939;

  /// No description provided for @youCanLeaveThisScreenA_4d2f96.
  ///
  /// In en, this message translates to:
  /// **'You can leave this screen. A running session uses its saved end time; a paused session keeps its remaining time.'**
  String get youCanLeaveThisScreenA_4d2f96;

  /// No description provided for @youCanTurnNotificationsOffThis_83fe52.
  ///
  /// In en, this message translates to:
  /// **'You can turn notifications off. This chat has not changed your settings.'**
  String get youCanTurnNotificationsOffThis_83fe52;

  /// No description provided for @youDecideWhetherThisPhoneSends_fdb337.
  ///
  /// In en, this message translates to:
  /// **'You decide whether this phone sends task reminders.'**
  String get youDecideWhetherThisPhoneSends_fdb337;

  /// No description provided for @youStayInControl_277bc5.
  ///
  /// In en, this message translates to:
  /// **'You stay in control'**
  String get youStayInControl_277bc5;

  /// No description provided for @yourCheckInHistory_fc0caa.
  ///
  /// In en, this message translates to:
  /// **'Your check-in history'**
  String get yourCheckInHistory_fc0caa;

  /// No description provided for @yourData_48cd18.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get yourData_48cd18;

  /// No description provided for @yourExperience_15ee78.
  ///
  /// In en, this message translates to:
  /// **'Your experience'**
  String get yourExperience_15ee78;

  /// No description provided for @yourFocusSession_584cf8.
  ///
  /// In en, this message translates to:
  /// **'Your focus session'**
  String get yourFocusSession_584cf8;

  /// No description provided for @yourGoalsPreferences_e71b24.
  ///
  /// In en, this message translates to:
  /// **'Your goals & preferences'**
  String get yourGoalsPreferences_e71b24;

  /// No description provided for @yourHistoryStartsHere_31333c.
  ///
  /// In en, this message translates to:
  /// **'Your history starts here'**
  String get yourHistoryStartsHere_31333c;

  /// No description provided for @yourParticipation_1dcf8a.
  ///
  /// In en, this message translates to:
  /// **'Your participation'**
  String get yourParticipation_1dcf8a;

  /// No description provided for @yourPlanHasBeenUpdated_3e0c3d.
  ///
  /// In en, this message translates to:
  /// **'Your plan has been updated.'**
  String get yourPlanHasBeenUpdated_3e0c3d;

  /// No description provided for @yourPlannedStartIsAfterYour_6aac64.
  ///
  /// In en, this message translates to:
  /// **'Your planned start is after your deadline. You can adjust either date.'**
  String get yourPlannedStartIsAfterYour_6aac64;

  /// No description provided for @yourPreferences_41bc34.
  ///
  /// In en, this message translates to:
  /// **'Your preferences'**
  String get yourPreferences_41bc34;

  /// No description provided for @yourProgress_44a680.
  ///
  /// In en, this message translates to:
  /// **'Your progress'**
  String get yourProgress_44a680;

  /// No description provided for @yourReminderTimeIsSavedTurn_a05f65.
  ///
  /// In en, this message translates to:
  /// **'Your reminder time is saved. Turn on phone notifications for this account to schedule it.'**
  String get yourReminderTimeIsSavedTurn_a05f65;

  /// No description provided for @yourSessionTimeHasElapsedYour_f295ed.
  ///
  /// In en, this message translates to:
  /// **'Your session time has elapsed. Your task has not been marked complete.'**
  String get yourSessionTimeHasElapsedYour_f295ed;

  /// No description provided for @yourSmallSteps_dcbeb9.
  ///
  /// In en, this message translates to:
  /// **'Your small steps'**
  String get yourSmallSteps_dcbeb9;

  /// No description provided for @yourTask_3aec10.
  ///
  /// In en, this message translates to:
  /// **'Your task'**
  String get yourTask_3aec10;

  /// No description provided for @yourTaskRemindersAndNotificationStatus_7b490a.
  ///
  /// In en, this message translates to:
  /// **'Your task reminders and notification status.'**
  String get yourTaskRemindersAndNotificationStatus_7b490a;

  /// No description provided for @youVeGotThis_ecf44a.
  ///
  /// In en, this message translates to:
  /// **'You’ve got this.'**
  String get youVeGotThis_ecf44a;

  /// No description provided for @dark_3d09ba.
  ///
  /// In en, this message translates to:
  /// **'dark'**
  String get dark_3d09ba;

  /// No description provided for @leaveMe_e45a0c.
  ///
  /// In en, this message translates to:
  /// **'leave me'**
  String get leaveMe_e45a0c;

  /// No description provided for @light_dfccc0.
  ///
  /// In en, this message translates to:
  /// **'light'**
  String get light_dfccc0;

  /// No description provided for @mostImportant_384d4b.
  ///
  /// In en, this message translates to:
  /// **'most important'**
  String get mostImportant_384d4b;

  /// No description provided for @noMore_758833.
  ///
  /// In en, this message translates to:
  /// **'no more'**
  String get noMore_758833;

  /// No description provided for @ofAMinuteSession_4129d6.
  ///
  /// In en, this message translates to:
  /// **'of a {p0}-minute session'**
  String ofAMinuteSession_4129d6(String p0);

  /// No description provided for @system_317f1e.
  ///
  /// In en, this message translates to:
  /// **'system'**
  String get system_317f1e;

  /// No description provided for @turnOff_ff5e95.
  ///
  /// In en, this message translates to:
  /// **'turn off'**
  String get turnOff_ff5e95;

  /// No description provided for @whatShould_f11411.
  ///
  /// In en, this message translates to:
  /// **'what should'**
  String get whatShould_f11411;

  /// No description provided for @value_114413.
  ///
  /// In en, this message translates to:
  /// **'{p0}'**
  String value_114413(String p0);

  /// No description provided for @completedRemaining_d56a0c.
  ///
  /// In en, this message translates to:
  /// **'{p0} completed · {p1} remaining'**
  String completedRemaining_d56a0c(String p0, String p1);

  /// No description provided for @minutes_8d40d2.
  ///
  /// In en, this message translates to:
  /// **'{p0} minutes'**
  String minutes_8d40d2(String p0);

  /// No description provided for @moreWaitingForASchedulingSlot_bf9d6a.
  ///
  /// In en, this message translates to:
  /// **'{p0} more waiting for a scheduling slot. Reopen the app to fill available slots.'**
  String moreWaitingForASchedulingSlot_bf9d6a(String p0);

  /// No description provided for @ofTasksCompleted_d52ed6.
  ///
  /// In en, this message translates to:
  /// **'{p0} of {p1} tasks completed'**
  String ofTasksCompleted_d52ed6(String p0, String p1);

  /// No description provided for @ofTasksMarkedComplete_37d578.
  ///
  /// In en, this message translates to:
  /// **'{p0} of {p1} tasks marked complete'**
  String ofTasksMarkedComplete_37d578(String p0, String p1);

  /// No description provided for @priorityMinutes_4b3956.
  ///
  /// In en, this message translates to:
  /// **'{p0} priority · {p1} minutes'**
  String priorityMinutes_4b3956(String p0, String p1);

  /// No description provided for @tasksActivityRecordsCheckIns_8accaa.
  ///
  /// In en, this message translates to:
  /// **'{p0} tasks · {p1} activity records · {p2} check-ins'**
  String tasksActivityRecordsCheckIns_8accaa(String p0, String p1, String p2);

  /// No description provided for @upcomingReminderYourPhoneMayDelay_322859.
  ///
  /// In en, this message translates to:
  /// **'{p0} upcoming reminder{p1}. Your phone may delay delivery.'**
  String upcomingReminderYourPhoneMayDelay_322859(String p0, String p1);

  /// No description provided for @value_948253.
  ///
  /// In en, this message translates to:
  /// **'{p0} · {p1}'**
  String value_948253(String p0, String p1);

  /// No description provided for @min_548460.
  ///
  /// In en, this message translates to:
  /// **'{p0} · {p1} min\n{p2}'**
  String min_548460(String p0, String p1, String p2);

  /// No description provided for @priority_18c496.
  ///
  /// In en, this message translates to:
  /// **'{p0} · {p1} priority{p2}'**
  String priority_18c496(String p0, String p1, String p2);

  /// No description provided for @yourPhoneMayDelayDelivery_f30906.
  ///
  /// In en, this message translates to:
  /// **'{p0}. Your phone may delay delivery.'**
  String yourPhoneMayDelayDelivery_f30906(String p0);

  /// No description provided for @focusStarts_8ede1c.
  ///
  /// In en, this message translates to:
  /// **'{p0}: {p1} focus starts'**
  String focusStarts_8ede1c(String p0, String p1);

  /// No description provided for @value_ebc826.
  ///
  /// In en, this message translates to:
  /// **'{p0}:{p1}'**
  String value_ebc826(String p0, String p1);

  /// No description provided for @value_c16121.
  ///
  /// In en, this message translates to:
  /// **'{p0}{p1}'**
  String value_c16121(String p0, String p1);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get chooseLanguage;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'morning'**
  String get morning;

  /// No description provided for @afternoon.
  ///
  /// In en, this message translates to:
  /// **'afternoon'**
  String get afternoon;

  /// No description provided for @evening.
  ///
  /// In en, this message translates to:
  /// **'evening'**
  String get evening;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @nextStep.
  ///
  /// In en, this message translates to:
  /// **'Next step: {p0}'**
  String nextStep(String p0);

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @notStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get notStarted;

  /// No description provided for @pluralSuffix.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get pluralSuffix;

  /// No description provided for @errorTokenExpired.
  ///
  /// In en, this message translates to:
  /// **'Your development token is invalid or expired. Disconnect and sign in again.'**
  String get errorTokenExpired;

  /// No description provided for @errorAssignment.
  ///
  /// In en, this message translates to:
  /// **'This action is not available for your study assignment.'**
  String get errorAssignment;

  /// No description provided for @errorMissingRecord.
  ///
  /// In en, this message translates to:
  /// **'The requested study record is no longer available.'**
  String get errorMissingRecord;

  /// No description provided for @errorStaleRecord.
  ///
  /// In en, this message translates to:
  /// **'This record has changed. Refresh before trying again.'**
  String get errorStaleRecord;

  /// No description provided for @errorInvalidDetails.
  ///
  /// In en, this message translates to:
  /// **'The study service could not accept these details.'**
  String get errorInvalidDetails;

  /// No description provided for @errorBusyService.
  ///
  /// In en, this message translates to:
  /// **'The study service is busy. Please wait before trying again.'**
  String get errorBusyService;

  /// No description provided for @errorUnavailableAI.
  ///
  /// In en, this message translates to:
  /// **'The AI or study service is unavailable. Your task was not changed by the AI request.'**
  String get errorUnavailableAI;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the study service. Please try again.'**
  String get errorNetwork;

  /// No description provided for @errorUnresolvedAI.
  ///
  /// In en, this message translates to:
  /// **'This AI attempt failed or is still pending. Cancel the message before explicitly sending a new attempt.'**
  String get errorUnresolvedAI;

  /// No description provided for @errorDeviceSchedule.
  ///
  /// In en, this message translates to:
  /// **'Could not update device reminders. Your tasks are saved. Retry to check notification permission and scheduling.'**
  String get errorDeviceSchedule;

  /// No description provided for @errorNotificationReport.
  ///
  /// In en, this message translates to:
  /// **'Could not save the notification interaction report.'**
  String get errorNotificationReport;

  /// No description provided for @errorCorrection.
  ///
  /// In en, this message translates to:
  /// **'Invalid task correction'**
  String get errorCorrection;

  /// No description provided for @errorQuietHours.
  ///
  /// In en, this message translates to:
  /// **'Invalid quiet hours'**
  String get errorQuietHours;

  /// No description provided for @errorNotificationLimits.
  ///
  /// In en, this message translates to:
  /// **'Invalid notification limits'**
  String get errorNotificationLimits;

  /// No description provided for @errorNotificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Invalid notification preferences'**
  String get errorNotificationPreferences;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start {p0}'**
  String startDate(String p0);

  /// No description provided for @nextStepLine.
  ///
  /// In en, this message translates to:
  /// **'\nNext step: {p0}'**
  String nextStepLine(String p0);

  /// No description provided for @deadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get deadline;

  /// No description provided for @burdenCode.
  ///
  /// In en, this message translates to:
  /// **'burden'**
  String get burdenCode;

  /// No description provided for @readinessCode.
  ///
  /// In en, this message translates to:
  /// **'readiness'**
  String get readinessCode;

  /// No description provided for @startingDifficultyCode.
  ///
  /// In en, this message translates to:
  /// **'starting difficulty'**
  String get startingDifficultyCode;

  /// No description provided for @motivationCode.
  ///
  /// In en, this message translates to:
  /// **'motivation'**
  String get motivationCode;

  /// No description provided for @alignmentCode.
  ///
  /// In en, this message translates to:
  /// **'alignment'**
  String get alignmentCode;

  /// No description provided for @awarenessCode.
  ///
  /// In en, this message translates to:
  /// **'awareness'**
  String get awarenessCode;

  /// No description provided for @autonomyCode.
  ///
  /// In en, this message translates to:
  /// **'autonomy'**
  String get autonomyCode;

  /// No description provided for @supportCode.
  ///
  /// In en, this message translates to:
  /// **'support'**
  String get supportCode;

  /// No description provided for @followingPlansCode.
  ///
  /// In en, this message translates to:
  /// **'following plans'**
  String get followingPlansCode;

  /// No description provided for @unwantedDelayCode.
  ///
  /// In en, this message translates to:
  /// **'unwanted delay'**
  String get unwantedDelayCode;

  /// No description provided for @supportPlan.
  ///
  /// In en, this message translates to:
  /// **'My start plan'**
  String get supportPlan;

  /// No description provided for @supportPlanHint.
  ///
  /// In en, this message translates to:
  /// **'Optional. Choose a situation and one small action. Nothing changes until you save.'**
  String get supportPlanHint;

  /// No description provided for @startCue.
  ///
  /// In en, this message translates to:
  /// **'When / where (for example, after lunch at my desk)'**
  String get startCue;

  /// No description provided for @startAction.
  ///
  /// In en, this message translates to:
  /// **'Then I will… (for example, open the slides)'**
  String get startAction;

  /// No description provided for @futureNote.
  ///
  /// In en, this message translates to:
  /// **'What would starting today make easier tomorrow?'**
  String get futureNote;

  /// No description provided for @futureNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Optional note for Self-Agent. It is not shared with Friend-Agent.'**
  String get futureNoteHint;

  /// No description provided for @saveSupport.
  ///
  /// In en, this message translates to:
  /// **'Save my plan'**
  String get saveSupport;

  /// No description provided for @supportSaved.
  ///
  /// In en, this message translates to:
  /// **'Your plan is saved. Reminders are unchanged.'**
  String get supportSaved;

  /// No description provided for @supportIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Enter both a situation and an action, or clear both.'**
  String get supportIncomplete;

  /// No description provided for @difficultyQuestion.
  ///
  /// In en, this message translates to:
  /// **'What is making this difficult?'**
  String get difficultyQuestion;

  /// No description provided for @difficultyOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional. You can skip this or clear your choice.'**
  String get difficultyOptional;

  /// No description provided for @difficultyUnclear.
  ///
  /// In en, this message translates to:
  /// **'Unclear'**
  String get difficultyUnclear;

  /// No description provided for @difficultyOverwhelming.
  ///
  /// In en, this message translates to:
  /// **'Overwhelming'**
  String get difficultyOverwhelming;

  /// No description provided for @difficultyWorried.
  ///
  /// In en, this message translates to:
  /// **'Worried'**
  String get difficultyWorried;

  /// No description provided for @difficultyDistracted.
  ///
  /// In en, this message translates to:
  /// **'Distracted'**
  String get difficultyDistracted;

  /// No description provided for @difficultyTired.
  ///
  /// In en, this message translates to:
  /// **'Tired'**
  String get difficultyTired;

  /// No description provided for @supportUnclear.
  ///
  /// In en, this message translates to:
  /// **'Choose one concrete next action. You can write it in your small steps.'**
  String get supportUnclear;

  /// No description provided for @supportOverwhelming.
  ///
  /// In en, this message translates to:
  /// **'Keep just one manageable step. You can leave the rest for later.'**
  String get supportOverwhelming;

  /// No description provided for @supportWorried.
  ///
  /// In en, this message translates to:
  /// **'An imperfect first attempt is an option. You can also choose another time.'**
  String get supportWorried;

  /// No description provided for @supportDistracted.
  ///
  /// In en, this message translates to:
  /// **'If helpful, put one distraction aside before a short session.'**
  String get supportDistracted;

  /// No description provided for @supportTired.
  ///
  /// In en, this message translates to:
  /// **'Rest or choose another time. Starting now is optional.'**
  String get supportTired;

  /// No description provided for @pauseToday.
  ///
  /// In en, this message translates to:
  /// **'Pause reminders today'**
  String get pauseToday;

  /// No description provided for @resumeReminders.
  ///
  /// In en, this message translates to:
  /// **'Resume reminders'**
  String get resumeReminders;

  /// No description provided for @pauseHint.
  ///
  /// In en, this message translates to:
  /// **'No reminders before tomorrow. Suppressed reminders will not be replayed.'**
  String get pauseHint;

  /// No description provided for @supportSmallStep.
  ///
  /// In en, this message translates to:
  /// **'Edit a smaller step'**
  String get supportSmallStep;

  /// No description provided for @supportNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now / adjust plan'**
  String get supportNotNow;

  /// No description provided for @scriptedDemoExplanation.
  ///
  /// In en, this message translates to:
  /// **'Scripted demo: replies are examples, not live AI.'**
  String get scriptedDemoExplanation;

  /// No description provided for @connectRealChat.
  ///
  /// In en, this message translates to:
  /// **'Connect AI backend'**
  String get connectRealChat;

  /// No description provided for @linkedAgentAccounts.
  ///
  /// In en, this message translates to:
  /// **'Researcher live demo: switching opens a separate synthetic account, with its own tasks and history. Study assignments stay unchanged.'**
  String get linkedAgentAccounts;

  /// No description provided for @addAgentAccount.
  ///
  /// In en, this message translates to:
  /// **'Link the other agent account'**
  String get addAgentAccount;

  /// No description provided for @forgetAgentLogins.
  ///
  /// In en, this message translates to:
  /// **'Forget saved agent logins'**
  String get forgetAgentLogins;

  /// No description provided for @rememberAgentLogin.
  ///
  /// In en, this message translates to:
  /// **'Remember this synthetic agent account'**
  String get rememberAgentLogin;

  /// No description provided for @rememberAgentHint.
  ///
  /// In en, this message translates to:
  /// **'DEV- accounts only. Android/iOS use secure device storage. Browser previews remember only for this session.'**
  String get rememberAgentHint;
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
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
