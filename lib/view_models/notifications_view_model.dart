import 'package:flutter/material.dart';
import '../data/repositories.dart';
import '../services/notification_service.dart';

class NotificationsViewModel extends ChangeNotifier {
  NotificationsViewModel({
    required SettingsRepository settingsRepository,
    required NotificationService notificationService,
  })  : _settings = settingsRepository,
        _notifications = notificationService;

  final SettingsRepository _settings;
  final NotificationService _notifications;

  bool _timerEnd = true;
  bool _breakStart = true;
  bool _dailyReminders = false;
  bool _quietMode = true;

  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 7, minute: 0);

  List<bool> _days = [true, false, true, false, true, false, false];
  final List<String> _dayLabels = ['П', 'В', 'С', 'Ч', 'П', 'С', 'В'];

  bool get timerEnd => _timerEnd;
  bool get breakStart => _breakStart;
  bool get dailyReminders => _dailyReminders;
  bool get quietMode => _quietMode;
  TimeOfDay get quietStart => _quietStart;
  TimeOfDay get quietEnd => _quietEnd;
  List<bool> get days => _days;
  List<String> get dayLabels => _dayLabels;

  Future<void> load() async {
    _timerEnd = await _settings.isNotificationEnabled('timer_end', defaultValue: true);
    _breakStart = await _settings.isNotificationEnabled('break_start', defaultValue: true);
    _dailyReminders = await _settings.isNotificationEnabled('daily_reminders', defaultValue: false);
    _quietMode = await _settings.isNotificationEnabled('quiet_mode', defaultValue: true);

    final start = await _settings.getQuietModeTime('start', defaultHour: 22);
    _quietStart = TimeOfDay(hour: start['hour']!, minute: start['minute']!);

    final end = await _settings.getQuietModeTime('end', defaultHour: 7);
    _quietEnd = TimeOfDay(hour: end['hour']!, minute: end['minute']!);

    _days = await _settings.getQuietDays();
    notifyListeners();
  }

  void setTimerEnd(bool value) {
    _timerEnd = value;
    _settings.setNotificationEnabled('timer_end', value);
    notifyListeners();
  }

  void setBreakStart(bool value) {
    _breakStart = value;
    _settings.setNotificationEnabled('break_start', value);
    notifyListeners();
  }

  void setDailyReminders(bool value) {
    _dailyReminders = value;
    _settings.setNotificationEnabled('daily_reminders', value);
    _notifications.updateDailyReminders(enabled: value);
    notifyListeners();
  }

  void toggleQuietMode() {
    _quietMode = !_quietMode;
    _settings.setNotificationEnabled('quiet_mode', _quietMode);
    notifyListeners();
  }

  void setQuietStart(TimeOfDay time) {
    _quietStart = time;
    _settings.setQuietModeTime('start', time.hour, time.minute);
    notifyListeners();
  }

  void setQuietEnd(TimeOfDay time) {
    _quietEnd = time;
    _settings.setQuietModeTime('end', time.hour, time.minute);
    notifyListeners();
  }

  void toggleDay(int index) {
    _days[index] = !_days[index];
    _settings.setQuietDays(_days);
    notifyListeners();
  }
}
