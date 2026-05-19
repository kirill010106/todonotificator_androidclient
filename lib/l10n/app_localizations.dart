import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ToDo Notificator'**
  String get appTitle;

  /// No description provided for @tabTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tabTasks;

  /// No description provided for @tabTimer.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get tabTimer;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHint;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterNotDone.
  ///
  /// In en, this message translates to:
  /// **'Not Done'**
  String get filterNotDone;

  /// No description provided for @filterDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get filterDone;

  /// No description provided for @filterBurned.
  ///
  /// In en, this message translates to:
  /// **'Burned'**
  String get filterBurned;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @taskTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Task Title'**
  String get taskTitleHint;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'Extra thoughts can be recorded here...'**
  String get noteHint;

  /// No description provided for @checklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get checklist;

  /// No description provided for @addChecklistItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addChecklistItem;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @manageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get manageCategories;

  /// No description provided for @resurrect.
  ///
  /// In en, this message translates to:
  /// **'Resurrect'**
  String get resurrect;

  /// No description provided for @deleteTask.
  ///
  /// In en, this message translates to:
  /// **'Delete Task?'**
  String get deleteTask;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @burned.
  ///
  /// In en, this message translates to:
  /// **'Burned'**
  String get burned;

  /// No description provided for @timerPenalty.
  ///
  /// In en, this message translates to:
  /// **'Penalty'**
  String get timerPenalty;

  /// No description provided for @timerFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get timerFocus;

  /// No description provided for @timerRest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get timerRest;

  /// No description provided for @emptyTasks.
  ///
  /// In en, this message translates to:
  /// **'Ready for new achievements?\nThe first task is the most important!'**
  String get emptyTasks;

  /// No description provided for @loadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading Error'**
  String get loadErrorTitle;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @taskHardcoreBonus.
  ///
  /// In en, this message translates to:
  /// **'Hardcore: x1.5 XP'**
  String get taskHardcoreBonus;

  /// No description provided for @taskResurrected.
  ///
  /// In en, this message translates to:
  /// **'Task \"{title}\" resurrected as Hardcore!'**
  String taskResurrected(Object title);

  /// No description provided for @appNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get appNote;

  /// No description provided for @taskBurnedStatus.
  ///
  /// In en, this message translates to:
  /// **'Burned Task'**
  String get taskBurnedStatus;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'+ Add'**
  String get addCategory;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get newCategory;

  /// No description provided for @existingCategories.
  ///
  /// In en, this message translates to:
  /// **'Existing'**
  String get existingCategories;

  /// No description provided for @noCategory.
  ///
  /// In en, this message translates to:
  /// **'No Category'**
  String get noCategory;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @addReminder.
  ///
  /// In en, this message translates to:
  /// **'Add Reminder'**
  String get addReminder;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @noReminder.
  ///
  /// In en, this message translates to:
  /// **'No Reminder'**
  String get noReminder;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @once.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get once;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @notesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no notes} =1{1 note} other{{count} notes}}'**
  String notesCount(num count);

  /// No description provided for @taskLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to open note. Please try again.'**
  String get taskLoadError;

  /// No description provided for @enterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a task title.'**
  String get enterTitle;

  /// No description provided for @categoryNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get categoryNameHint;

  /// No description provided for @alreadyDone.
  ///
  /// In en, this message translates to:
  /// **'Task is already done.'**
  String get alreadyDone;

  /// No description provided for @sessionInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Session Interrupted!'**
  String get sessionInterrupted;

  /// No description provided for @strictModeViolationDesc.
  ///
  /// In en, this message translates to:
  /// **'You violated \"Strict Mode\" by switching from the app for more than 10 seconds. The current session has been annulled.'**
  String get strictModeViolationDesc;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @didYouCompleteTask.
  ///
  /// In en, this message translates to:
  /// **'Did you complete the task?'**
  String get didYouCompleteTask;

  /// No description provided for @sessionFinishedDesc.
  ///
  /// In en, this message translates to:
  /// **'Session finished. Mark your progress to save statistics.'**
  String get sessionFinishedDesc;

  /// No description provided for @yesIHandledIt.
  ///
  /// In en, this message translates to:
  /// **'Yes, I handled it!'**
  String get yesIHandledIt;

  /// No description provided for @noGiveUp.
  ///
  /// In en, this message translates to:
  /// **'No, give up'**
  String get noGiveUp;

  /// No description provided for @backToWork.
  ///
  /// In en, this message translates to:
  /// **'Back to work'**
  String get backToWork;

  /// No description provided for @dontGiveUp.
  ///
  /// In en, this message translates to:
  /// **'Don\'t give up, you\'re almost there!'**
  String get dontGiveUp;

  /// No description provided for @penaltyDesc.
  ///
  /// In en, this message translates to:
  /// **'If you give up now, you will receive a penalty to your experience points. There\'s only a little time left.'**
  String get penaltyDesc;

  /// No description provided for @surrenderAnyway.
  ///
  /// In en, this message translates to:
  /// **'Surrender anyway'**
  String get surrenderAnyway;

  /// No description provided for @freeMode.
  ///
  /// In en, this message translates to:
  /// **'Free Mode'**
  String get freeMode;

  /// No description provided for @noTitle.
  ///
  /// In en, this message translates to:
  /// **'No Title'**
  String get noTitle;

  /// No description provided for @addNoteDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Add a note description...'**
  String get addNoteDescriptionHint;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @completedToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get completedToday;

  /// No description provided for @focusToday.
  ///
  /// In en, this message translates to:
  /// **'Focus today'**
  String get focusToday;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutesShort(int count);

  /// No description provided for @pomodoroCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no Pomodoros} =1{1 Pomodoro} other{{count} Pomodoros}}'**
  String pomodoroCount(num count);

  /// No description provided for @focus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focus;

  /// No description provided for @penaltyFocus.
  ///
  /// In en, this message translates to:
  /// **'Penalty Focus'**
  String get penaltyFocus;

  /// No description provided for @timeToRest.
  ///
  /// In en, this message translates to:
  /// **'Time to rest'**
  String get timeToRest;

  /// No description provided for @timeToSeriousRest.
  ///
  /// In en, this message translates to:
  /// **'Time for a serious rest'**
  String get timeToSeriousRest;

  /// No description provided for @remainToFocus.
  ///
  /// In en, this message translates to:
  /// **'Remaining to focus!'**
  String get remainToFocus;

  /// No description provided for @freeFocusMode.
  ///
  /// In en, this message translates to:
  /// **'Free focus mode'**
  String get freeFocusMode;

  /// No description provided for @debugMode.
  ///
  /// In en, this message translates to:
  /// **'Debug (sec instead of min):'**
  String get debugMode;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout Confirmation'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?\nYou will be taken to the login screen.'**
  String get logoutConfirmDesc;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @levelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}  |  {xp} XP'**
  String levelLabel(int level, int xp);

  /// No description provided for @xpToNextLevel.
  ///
  /// In en, this message translates to:
  /// **'{current} / {next} XP to level {level}'**
  String xpToNextLevel(int current, int next, int level);

  /// No description provided for @statStreak.
  ///
  /// In en, this message translates to:
  /// **'streak'**
  String get statStreak;

  /// No description provided for @statCompleted.
  ///
  /// In en, this message translates to:
  /// **'completed'**
  String get statCompleted;

  /// No description provided for @statBurned.
  ///
  /// In en, this message translates to:
  /// **'burned'**
  String get statBurned;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @unlockedCount.
  ///
  /// In en, this message translates to:
  /// **'{unlocked} / {total} unlocked'**
  String unlockedCount(int unlocked, int total);

  /// No description provided for @dailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily Goal'**
  String get dailyGoal;

  /// No description provided for @intervals.
  ///
  /// In en, this message translates to:
  /// **'Intervals'**
  String get intervals;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @passed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get passed;

  /// No description provided for @left.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get left;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'APP SETTINGS'**
  String get appSettings;

  /// No description provided for @statusHeader.
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get statusHeader;

  /// No description provided for @accountHeader.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get accountHeader;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @strictMode.
  ///
  /// In en, this message translates to:
  /// **'Strict Mode'**
  String get strictMode;

  /// No description provided for @strictModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Penalty for minimizing the app'**
  String get strictModeDesc;

  /// No description provided for @goal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goal;

  /// No description provided for @currentActivityDesc.
  ///
  /// In en, this message translates to:
  /// **'Your current activity'**
  String get currentActivityDesc;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version: {version}'**
  String versionLabel(Object version);

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @deleteAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete your account?\nThis action cannot be undone.\nAll your information will be deleted from our servers.'**
  String get deleteAccountDesc;

  /// No description provided for @deleteTimer.
  ///
  /// In en, this message translates to:
  /// **'Delete ({seconds})'**
  String deleteTimer(Object seconds);

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

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

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nickname;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccount;

  /// No description provided for @graveyard.
  ///
  /// In en, this message translates to:
  /// **'Graveyard'**
  String get graveyard;

  /// No description provided for @noBurnedTasks.
  ///
  /// In en, this message translates to:
  /// **'No burned tasks yet'**
  String get noBurnedTasks;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @unlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get unlocked;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @dailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder'**
  String get dailyReminder;

  /// No description provided for @sessionReminder.
  ///
  /// In en, this message translates to:
  /// **'Session Reminder'**
  String get sessionReminder;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @russian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get russian;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get noCategories;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete category?'**
  String get deleteCategory;

  /// No description provided for @migrateTo.
  ///
  /// In en, this message translates to:
  /// **'Or migrate to:'**
  String get migrateTo;

  /// No description provided for @leaveCategoryless.
  ///
  /// In en, this message translates to:
  /// **'Leave without category'**
  String get leaveCategoryless;

  /// No description provided for @notesCountShort.
  ///
  /// In en, this message translates to:
  /// **'Notes: {count}'**
  String notesCountShort(Object count);

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More...'**
  String get more;

  /// No description provided for @dataBackup.
  ///
  /// In en, this message translates to:
  /// **'Data Backup'**
  String get dataBackup;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get importData;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data restored successfully'**
  String get importSuccess;

  /// No description provided for @importFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed to read file or invalid format'**
  String get importFailure;

  /// No description provided for @exportFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed to export data'**
  String get exportFailure;

  /// No description provided for @choosePace.
  ///
  /// In en, this message translates to:
  /// **'Choose your pace'**
  String get choosePace;

  /// No description provided for @paceDescription.
  ///
  /// In en, this message translates to:
  /// **'Adjust focus for your tasks'**
  String get paceDescription;

  /// No description provided for @paceEasyTitle.
  ///
  /// In en, this message translates to:
  /// **'EASY'**
  String get paceEasyTitle;

  /// No description provided for @paceEasyDesc.
  ///
  /// In en, this message translates to:
  /// **'Smooth immersion into work'**
  String get paceEasyDesc;

  /// No description provided for @paceToneTitle.
  ///
  /// In en, this message translates to:
  /// **'IN TONE'**
  String get paceToneTitle;

  /// No description provided for @paceToneDesc.
  ///
  /// In en, this message translates to:
  /// **'Optimal balance of strength'**
  String get paceToneDesc;

  /// No description provided for @paceRoastTitle.
  ///
  /// In en, this message translates to:
  /// **'ROAST'**
  String get paceRoastTitle;

  /// No description provided for @paceRoastDesc.
  ///
  /// In en, this message translates to:
  /// **'Maximum concentration'**
  String get paceRoastDesc;

  /// No description provided for @letsGo.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go!'**
  String get letsGo;
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
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
