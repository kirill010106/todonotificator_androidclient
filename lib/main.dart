import 'package:flutter/material.dart';

import 'app/app_scope.dart';
import 'app/app_start.dart';
import 'app/navigation_state.dart';
import 'app/timer_controller.dart';
import 'data/local_database.dart';
import 'data/local_repositories.dart';
import 'services/notification_service.dart';
import 'ui/theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = LocalDatabase.instance;
  final settings = LocalSettingsRepository(database);
  final tasks = LocalTaskRepository(database, settings);
  final navigation = AppNavigationState();
  final notifications = NotificationService();
  await notifications.init();
  final timer = TimerController(tasks: tasks, notifications: notifications);
  final services = AppServices(
    auth: LocalAuthRepository(database, settings),
    tasks: tasks,
    settings: settings,
    timer: timer,
    navigation: navigation,
    notifications: notifications,
  );

  runApp(AppScope(services: services, child: const PomodoroTodoApp()));
}

class PomodoroTodoApp extends StatelessWidget {
  const PomodoroTodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PomodoroToDo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
          bodyMedium: TextStyle(fontSize: 14, color: AppColors.mutedText),
          bodySmall: TextStyle(fontSize: 12, color: AppColors.mutedText),
        ),
      ),
      home: const AppStart(),
    );
  }
}
