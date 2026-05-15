import 'package:flutter/material.dart';

import 'app/app_scope.dart';
import 'app/app_start.dart';
import 'app/navigation_state.dart';
import 'app/timer_controller.dart';
import 'data/local_database.dart';
import 'data/local_repositories.dart';
import 'services/gamification_service.dart';
import 'services/notification_service.dart';
import 'ui/theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = LocalDatabase.instance;
  final settings = LocalSettingsRepository(database);
  final tasks = LocalTaskRepository(database, settings);
  final gamificationRepo = LocalGamificationRepository(database);
  final gamification = GamificationService(gamificationRepo);
  tasks.gamification = gamification;
  final navigation = AppNavigationState();
  final notifications = NotificationService();
  await notifications.init();

  // Load current user so XP is attributed correctly from the first session.
  final userId = await settings.getCurrentUserId();
  if (userId != null) {
    await gamification.load(userId);
  }

  final timer = TimerController(
    tasks: tasks,
    gamification: gamification,
    notifications: notifications,
    userId: userId,
  );
  final auth = LocalAuthRepository(database, settings);
  final services = AppServices(
    auth: auth,
    tasks: tasks,
    settings: settings,
    timer: timer,
    navigation: navigation,
    notifications: notifications,
    gamification: gamification,
    gamificationRepository: gamificationRepo,
  );

  runApp(AppScope(services: services, child: const PomodoroTodoApp()));
}

class PomodoroTodoApp extends StatelessWidget {
  const PomodoroTodoApp({super.key});

  // Ключ для доступа к главному навигатору из любой точки приложения
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
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
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const AppStart(),
      // builder не нужен — мини-плеер теперь встроен в HomeScreen
      builder: (context, child) => child ?? const SizedBox.shrink(),
    );
  }
}

