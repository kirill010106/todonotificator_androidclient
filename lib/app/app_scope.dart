import 'package:flutter/material.dart';

import '../data/repositories.dart';
import '../services/gamification_service.dart';
import '../services/notification_service.dart';
import 'navigation_state.dart';
import 'timer_controller.dart';

class AppServices {
  const AppServices({
    required this.auth,
    required this.tasks,
    required this.settings,
    required this.timer,
    required this.navigation,
    required this.notifications,
    required this.gamification,
    required this.gamificationRepository,
  });

  final AuthRepository auth;
  final TaskRepository tasks;
  final SettingsRepository settings;
  final TimerController timer;
  final AppNavigationState navigation;
  final NotificationService notifications;
  final GamificationService gamification;
  final GamificationRepository gamificationRepository;
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
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}
