// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'ToDo Notificator';

  @override
  String get tabTasks => 'Задачи';

  @override
  String get tabTimer => 'Таймер';

  @override
  String get tabProfile => 'Профиль';

  @override
  String get searchHint => 'Поиск...';

  @override
  String get filterAll => 'Все';

  @override
  String get filterNotDone => 'Не сделано';

  @override
  String get filterDone => 'Сделано';

  @override
  String get filterBurned => 'Сгорело';

  @override
  String get allCategories => 'Все категории';

  @override
  String get taskTitleHint => 'Название задачи';

  @override
  String get noteHint => 'Дополнительные мысли можно записывать здесь...';

  @override
  String get checklist => 'Чеклист';

  @override
  String get addChecklistItem => 'Добавить пункт';

  @override
  String get category => 'Категория';

  @override
  String get reminder => 'Напомнить';

  @override
  String get manageCategories => 'Управление категориями';

  @override
  String get resurrect => 'Воскресить';

  @override
  String get deleteTask => 'Удалить заметку?';

  @override
  String get deleteConfirm => 'Это действие нельзя отменить.';

  @override
  String get cancel => 'Отмена';

  @override
  String get delete => 'Удалить';

  @override
  String get save => 'Сохранить';

  @override
  String get edit => 'Изменить';

  @override
  String get done => 'Готово';

  @override
  String get burned => 'Сгорела';

  @override
  String get timerPenalty => 'Штраф';

  @override
  String get timerFocus => 'Фокус';

  @override
  String get timerRest => 'Отдых';

  @override
  String get emptyTasks =>
      'Готовы к новым свершениям?\nПервая задача самая важная!';

  @override
  String get loadErrorTitle => 'Ошибка загрузки';

  @override
  String get retry => 'Повторить попытку';

  @override
  String get taskHardcoreBonus => 'Hardcore: x1.5 XP';

  @override
  String taskResurrected(Object title) {
    return 'Задача \"$title\" воскрешена как Hardcore!';
  }

  @override
  String get appNote => 'Заметка';

  @override
  String get taskBurnedStatus => 'Сгоревшая задача';

  @override
  String get addCategory => '+ Добавить';

  @override
  String get newCategory => 'Новая категория';

  @override
  String get existingCategories => 'Существующие';

  @override
  String get noCategory => 'Без категории';

  @override
  String get selectCategory => 'Выбор категории';

  @override
  String get addReminder => 'Добавить напоминание';

  @override
  String get frequency => 'Частота';

  @override
  String get time => 'Время';

  @override
  String get noReminder => 'Без напоминания';

  @override
  String get ready => 'Готово';

  @override
  String get once => 'Один раз';

  @override
  String get daily => 'Каждый день';

  @override
  String get weekly => 'Каждую неделю';

  @override
  String get custom => 'Настроить';

  @override
  String notesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count заметок',
      few: '$count заметки',
      one: '1 заметка',
      zero: 'нет заметок',
    );
    return '$_temp0';
  }

  @override
  String get taskLoadError => 'Не удалось открыть заметку. Попробуйте еще раз.';

  @override
  String get enterTitle => 'Введите название заметки.';

  @override
  String get categoryNameHint => 'Название';

  @override
  String get alreadyDone => 'Задача уже выполнена.';

  @override
  String get sessionInterrupted => 'Сессия прервана!';

  @override
  String get strictModeViolationDesc =>
      'Вы нарушили \"Строгий режим\", свернув приложение более чем на 10 секунд. Текущая сессия аннулирована.';

  @override
  String get gotIt => 'Понятно';

  @override
  String get didYouCompleteTask => 'Вы выполнили задачу?';

  @override
  String get sessionFinishedDesc =>
      'Сессия завершена. Отметьте прогресс для сохранения статистики.';

  @override
  String get yesIHandledIt => 'Да, я справился!';

  @override
  String get noGiveUp => 'Нет, сдаться';

  @override
  String get backToWork => 'Вернуться к работе';

  @override
  String get dontGiveUp => 'Не сдавайся, ты почти у цели!';

  @override
  String get penaltyDesc =>
      'В случае сдачи вы получите штраф к очкам опыта. Осталось совсем немного до конца таймера.';

  @override
  String get surrenderAnyway => 'Все равно сдаться';

  @override
  String get freeMode => 'Свободный режим';

  @override
  String get noTitle => 'Без названия';

  @override
  String get addNoteDescriptionHint => 'Добавьте описание заметки...';

  @override
  String get completed => 'Выполнено';

  @override
  String get completedToday => 'Сегодня';

  @override
  String get focusToday => 'Фокус сегодня';

  @override
  String minutesShort(int count) {
    return '$count мин';
  }

  @override
  String pomodoroCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Помодоро',
      one: '1 Помодоро',
      zero: 'нет Помодоро',
    );
    return '$_temp0';
  }

  @override
  String get focus => 'Фокус';

  @override
  String get penaltyFocus => 'Штрафной фокус';

  @override
  String get timeToRest => 'Пора отдохнуть';

  @override
  String get timeToSeriousRest => 'Пора серьезно отдохнуть';

  @override
  String get remainToFocus => 'Осталось сфокусироваться!';

  @override
  String get freeFocusMode => 'Свободный режим фокуса';

  @override
  String get debugMode => 'Дебаг (сек вместо мин):';

  @override
  String get start => 'Начать';

  @override
  String get pause => 'Приостановить';

  @override
  String get finish => 'Закончить';

  @override
  String get resume => 'Продолжить';

  @override
  String get logoutConfirmTitle => 'Подтверждение выхода';

  @override
  String get logoutConfirmDesc =>
      'Действительно выйти из аккаунта?\nВы перейдете на экран входа';

  @override
  String get user => 'Пользователь';

  @override
  String levelLabel(int level, int xp) {
    return 'Уровень $level  |  $xp XP';
  }

  @override
  String xpToNextLevel(int current, int next, int level) {
    return '$current / $next XP до ур. $level';
  }

  @override
  String get statStreak => 'серия';

  @override
  String get statCompleted => 'выполнено';

  @override
  String get statBurned => 'сгорело';

  @override
  String get achievements => 'Достижения';

  @override
  String unlockedCount(int unlocked, int total) {
    return '$unlocked / $total разблокировано';
  }

  @override
  String get dailyGoal => 'Цель дня';

  @override
  String get intervals => 'Интервалы';

  @override
  String get tasks => 'Задачи';

  @override
  String get progress => 'Прогресс';

  @override
  String get passed => 'Пройдено';

  @override
  String get left => 'Осталось';

  @override
  String get logout => 'Выйти';

  @override
  String get settings => 'Настройки';

  @override
  String get appSettings => 'НАСТРОЙКИ ПРИЛОЖЕНИЯ';

  @override
  String get statusHeader => 'СТАТУС';

  @override
  String get accountHeader => 'АККАУНТ';

  @override
  String get notifications => 'Уведомления';

  @override
  String get categories => 'Категории';

  @override
  String get strictMode => 'Строгий режим';

  @override
  String get strictModeDesc => 'Штраф за сворачивание приложения';

  @override
  String get goal => 'Цель';

  @override
  String get currentActivityDesc => 'Ваша текущая активность';

  @override
  String get support => 'Связь с поддержкой';

  @override
  String get changePassword => 'Сменить пароль';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String versionLabel(Object version) {
    return 'Версия: $version';
  }

  @override
  String get areYouSure => 'Вы уверены?';

  @override
  String get deleteAccountDesc =>
      'Вы действительно хотите удалить аккаунт?\nОтменить данное действие невозможно.\nПосле подтверждения вся сохраненная о Вас информация будет удалена с наших серверов.';

  @override
  String deleteTimer(Object seconds) {
    return 'Удалить ($seconds)';
  }

  @override
  String get login => 'Войти';

  @override
  String get register => 'Регистрация';

  @override
  String get email => 'Email';

  @override
  String get password => 'Пароль';

  @override
  String get nickname => 'Никнейм';

  @override
  String get welcomeBack => 'С возвращением';

  @override
  String get createAccount => 'Создать аккаунт';

  @override
  String get noAccount => 'Нет аккаунта?';

  @override
  String get haveAccount => 'Уже есть аккаунт?';

  @override
  String get graveyard => 'Кладбище';

  @override
  String get noBurnedTasks => 'Пока нет сгоревших задач';

  @override
  String get locked => 'Заблокировано';

  @override
  String get unlocked => 'Разблокировано';

  @override
  String get notificationSettings => 'Настройки уведомлений';

  @override
  String get dailyReminder => 'Ежедневное напоминание';

  @override
  String get sessionReminder => 'Напоминание о сессии';

  @override
  String get saveChanges => 'Сохранить изменения';

  @override
  String get error => 'Ошибка';

  @override
  String get success => 'Успех';

  @override
  String get language => 'Язык';

  @override
  String get russian => 'Русский';

  @override
  String get english => 'English';

  @override
  String get noCategories => 'Категорий пока нет';

  @override
  String get deleteCategory => 'Удалить категорию?';

  @override
  String get migrateTo => 'Или перенести в:';

  @override
  String get leaveCategoryless => 'Оставить без категории';

  @override
  String notesCountShort(Object count) {
    return 'Заметок: $count';
  }

  @override
  String get editCategory => 'Редактировать';

  @override
  String get more => 'Ещё...';

  @override
  String get dataBackup => 'Резервное копирование';

  @override
  String get exportData => 'Экспорт данных';

  @override
  String get importData => 'Импорт данных';

  @override
  String get importSuccess => 'Данные успешно восстановлены';

  @override
  String get importFailure => 'Ошибка при чтении файла или неверный формат';

  @override
  String get exportFailure => 'Не удалось экспортировать данные';

  @override
  String get choosePace => 'Выберите темп';

  @override
  String get paceDescription => 'Настройте фокус под свои задачи';

  @override
  String get paceEasyTitle => 'ЛЕГКИЙ';

  @override
  String get paceEasyDesc => 'Плавное погружение в работу';

  @override
  String get paceToneTitle => 'В ТОНУСЕ';

  @override
  String get paceToneDesc => 'Оптимальный баланс сил';

  @override
  String get paceRoastTitle => 'ПРОЖАРКА';

  @override
  String get paceRoastDesc => 'Максимальная концентрация';

  @override
  String get letsGo => 'Погнали!';
}
