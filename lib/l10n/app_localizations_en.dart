// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ToDo Notificator';

  @override
  String get tabTasks => 'Tasks';

  @override
  String get tabTimer => 'Timer';

  @override
  String get tabProfile => 'Profile';

  @override
  String get searchHint => 'Search...';

  @override
  String get filterAll => 'All';

  @override
  String get filterNotDone => 'Not Done';

  @override
  String get filterDone => 'Done';

  @override
  String get filterBurned => 'Burned';

  @override
  String get allCategories => 'All Categories';

  @override
  String get taskTitleHint => 'Task Title';

  @override
  String get noteHint => 'Extra thoughts can be recorded here...';

  @override
  String get checklist => 'Checklist';

  @override
  String get addChecklistItem => 'Add item';

  @override
  String get category => 'Category';

  @override
  String get reminder => 'Reminder';

  @override
  String get manageCategories => 'Manage Categories';

  @override
  String get resurrect => 'Resurrect';

  @override
  String get deleteTask => 'Delete Task?';

  @override
  String get deleteConfirm => 'This action cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get done => 'Done';

  @override
  String get burned => 'Burned';

  @override
  String get timerPenalty => 'Penalty';

  @override
  String get timerFocus => 'Focus';

  @override
  String get timerRest => 'Rest';

  @override
  String get emptyTasks =>
      'Ready for new achievements?\nThe first task is the most important!';

  @override
  String get loadErrorTitle => 'Loading Error';

  @override
  String get retry => 'Retry';

  @override
  String get taskHardcoreBonus => 'Hardcore: x1.5 XP';

  @override
  String taskResurrected(Object title) {
    return 'Task \"$title\" resurrected as Hardcore!';
  }

  @override
  String get appNote => 'Note';

  @override
  String get taskBurnedStatus => 'Burned Task';

  @override
  String get addCategory => '+ Add';

  @override
  String get newCategory => 'New Category';

  @override
  String get existingCategories => 'Existing';

  @override
  String get noCategory => 'No Category';

  @override
  String get selectCategory => 'Select Category';

  @override
  String get addReminder => 'Add Reminder';

  @override
  String get frequency => 'Frequency';

  @override
  String get time => 'Time';

  @override
  String get noReminder => 'No Reminder';

  @override
  String get ready => 'Ready';

  @override
  String get once => 'Once';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get custom => 'Custom';

  @override
  String notesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
      zero: 'no notes',
    );
    return '$_temp0';
  }

  @override
  String get taskLoadError => 'Failed to open note. Please try again.';

  @override
  String get enterTitle => 'Please enter a task title.';

  @override
  String get categoryNameHint => 'Name';

  @override
  String get alreadyDone => 'Task is already done.';

  @override
  String get sessionInterrupted => 'Session Interrupted!';

  @override
  String get strictModeViolationDesc =>
      'You violated \"Strict Mode\" by switching from the app for more than 10 seconds. The current session has been annulled.';

  @override
  String get gotIt => 'Got it';

  @override
  String get didYouCompleteTask => 'Did you complete the task?';

  @override
  String get sessionFinishedDesc =>
      'Session finished. Mark your progress to save statistics.';

  @override
  String get yesIHandledIt => 'Yes, I handled it!';

  @override
  String get noGiveUp => 'No, give up';

  @override
  String get backToWork => 'Back to work';

  @override
  String get dontGiveUp => 'Don\'t give up, you\'re almost there!';

  @override
  String get penaltyDesc =>
      'If you give up now, you will receive a penalty to your experience points. There\'s only a little time left.';

  @override
  String get surrenderAnyway => 'Surrender anyway';

  @override
  String get freeMode => 'Free Mode';

  @override
  String get noTitle => 'No Title';

  @override
  String get addNoteDescriptionHint => 'Add a note description...';

  @override
  String get completed => 'Completed';

  @override
  String get completedToday => 'Today';

  @override
  String get focusToday => 'Focus today';

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String pomodoroCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Pomodoros',
      one: '1 Pomodoro',
      zero: 'no Pomodoros',
    );
    return '$_temp0';
  }

  @override
  String get focus => 'Focus';

  @override
  String get penaltyFocus => 'Penalty Focus';

  @override
  String get timeToRest => 'Time to rest';

  @override
  String get timeToSeriousRest => 'Time for a serious rest';

  @override
  String get remainToFocus => 'Remaining to focus!';

  @override
  String get freeFocusMode => 'Free focus mode';

  @override
  String get debugMode => 'Debug (sec instead of min):';

  @override
  String get start => 'Start';

  @override
  String get pause => 'Pause';

  @override
  String get finish => 'Finish';

  @override
  String get resume => 'Resume';

  @override
  String get logoutConfirmTitle => 'Logout Confirmation';

  @override
  String get logoutConfirmDesc =>
      'Are you sure you want to log out?\nYou will be taken to the login screen.';

  @override
  String get user => 'User';

  @override
  String levelLabel(int level, int xp) {
    return 'Level $level  |  $xp XP';
  }

  @override
  String xpToNextLevel(int current, int next, int level) {
    return '$current / $next XP to level $level';
  }

  @override
  String get statStreak => 'streak';

  @override
  String get statCompleted => 'completed';

  @override
  String get statBurned => 'burned';

  @override
  String get achievements => 'Achievements';

  @override
  String unlockedCount(int unlocked, int total) {
    return '$unlocked / $total unlocked';
  }

  @override
  String get dailyGoal => 'Daily Goal';

  @override
  String get intervals => 'Intervals';

  @override
  String get tasks => 'Tasks';

  @override
  String get progress => 'Progress';

  @override
  String get passed => 'Passed';

  @override
  String get left => 'Left';

  @override
  String get logout => 'Logout';

  @override
  String get settings => 'Settings';

  @override
  String get appSettings => 'APP SETTINGS';

  @override
  String get statusHeader => 'STATUS';

  @override
  String get accountHeader => 'ACCOUNT';

  @override
  String get notifications => 'Notifications';

  @override
  String get categories => 'Categories';

  @override
  String get strictMode => 'Strict Mode';

  @override
  String get strictModeDesc => 'Penalty for minimizing the app';

  @override
  String get goal => 'Goal';

  @override
  String get currentActivityDesc => 'Your current activity';

  @override
  String get support => 'Support';

  @override
  String get changePassword => 'Change Password';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String versionLabel(Object version) {
    return 'Version: $version';
  }

  @override
  String get areYouSure => 'Are you sure?';

  @override
  String get deleteAccountDesc =>
      'Do you really want to delete your account?\nThis action cannot be undone.\nAll your information will be deleted from our servers.';

  @override
  String deleteTimer(Object seconds) {
    return 'Delete ($seconds)';
  }

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get nickname => 'Nickname';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get createAccount => 'Create Account';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get graveyard => 'Graveyard';

  @override
  String get noBurnedTasks => 'No burned tasks yet';

  @override
  String get locked => 'Locked';

  @override
  String get unlocked => 'Unlocked';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get dailyReminder => 'Daily Reminder';

  @override
  String get sessionReminder => 'Session Reminder';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get language => 'Language';

  @override
  String get russian => 'Russian';

  @override
  String get english => 'English';

  @override
  String get noCategories => 'No categories yet';

  @override
  String get deleteCategory => 'Delete category?';

  @override
  String get migrateTo => 'Or migrate to:';

  @override
  String get leaveCategoryless => 'Leave without category';

  @override
  String notesCountShort(Object count) {
    return 'Notes: $count';
  }

  @override
  String get editCategory => 'Edit Category';

  @override
  String get more => 'More...';

  @override
  String get dataBackup => 'Data Backup';

  @override
  String get exportData => 'Export Data';

  @override
  String get importData => 'Import Data';

  @override
  String get importSuccess => 'Data restored successfully';

  @override
  String get importFailure => 'Failed to read file or invalid format';

  @override
  String get exportFailure => 'Failed to export data';

  @override
  String get choosePace => 'Choose your pace';

  @override
  String get paceDescription => 'Adjust focus for your tasks';

  @override
  String get paceEasyTitle => 'EASY';

  @override
  String get paceEasyDesc => 'Smooth immersion into work';

  @override
  String get paceToneTitle => 'IN TONE';

  @override
  String get paceToneDesc => 'Optimal balance of strength';

  @override
  String get paceRoastTitle => 'ROAST';

  @override
  String get paceRoastDesc => 'Maximum concentration';

  @override
  String get letsGo => 'Let\'s go!';

  @override
  String get errorNicknameShort => 'Minimum 3 characters';

  @override
  String get errorInvalidEmail => 'Enter a valid email';

  @override
  String get errorPasswordShort => 'Minimum 8 characters';

  @override
  String get errorPasswordsDontMatch => 'Passwords do not match';

  @override
  String get errorPolicyNotAccepted => 'Please accept the agreement';

  @override
  String get errorEmailExists => 'Email already exists';

  @override
  String get errorNicknameExists => 'Nickname already exists';

  @override
  String get errorServer => 'Server error';

  @override
  String get fieldRequired => 'Required field';

  @override
  String get errorInvalidCredentials => 'Invalid login or password';

  @override
  String get errorWrongPassword => 'Incorrect current password';
}
