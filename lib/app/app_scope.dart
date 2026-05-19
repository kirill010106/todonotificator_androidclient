import 'package:flutter/material.dart';

import '../data/repositories.dart';
import '../services/gamification_service.dart';
import '../services/notification_service.dart';
import '../services/audio_service.dart';
import 'navigation_state.dart';
import 'timer_controller.dart';

class LocaleController extends ChangeNotifier {
  LocaleController(this._repository);

  final SettingsRepository _repository;
  Locale _locale = const Locale('ru');

  Locale get locale => _locale;

  Future<void> load() async {
    final languageCode = await _repository.getLocale();
    if (languageCode != null) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    await _repository.setLocale(locale.languageCode);
    notifyListeners();
  }
}

class AppServices {
  const AppServices({
    required this.auth,
    required this.tasks,
    required this.settings,
    required this.stats,
    required this.timer,
    required this.navigation,
    required this.notifications,
    required this.gamification,
    required this.gamificationRepository,
    required this.audio,
    required this.locale,
  });

  final AuthRepository auth;
  final TaskRepository tasks;
  final SettingsRepository settings;
  final StatsRepository stats;
  final TimerController timer;
  final AppNavigationState navigation;
  final NotificationService notifications;
  final GamificationService gamification;
  final GamificationRepository gamificationRepository;
  final AudioService audio;
  final LocaleController locale;
}

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.services,
    required super.child,
  });

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    if (scope == null) {
      throw FlutterError('AppScope not found in widget tree');
    }
    return scope.services;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}
