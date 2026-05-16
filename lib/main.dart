import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pomorodo_todo/l10n/app_localizations.dart';

import 'app/app_scope.dart';
import 'app/app_start.dart';
import 'app/navigation_state.dart';
import 'app/timer_controller.dart';
import 'data/local_database.dart';
import 'data/local_repositories.dart';
import 'services/gamification_service.dart';
import 'services/notification_service.dart';
import 'services/audio_service.dart';
import 'ui/theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = LocalDatabase.instance;
  final settings = LocalSettingsRepository(database);
  final tasks = LocalTaskRepository(database, settings);
  final gamificationRepo = LocalGamificationRepository(database);
  final audio = AudioService();
  final gamification = GamificationService(gamificationRepo, audio);
  tasks.gamification = gamification;
  final navigation = AppNavigationState();
  final notifications = NotificationService();
  await notifications.init();

  final userId = await settings.getCurrentUserId();
  if (userId != null) {
    await gamification.load(userId);
  }

  final timer = TimerController(
    tasks: tasks,
    gamification: gamification,
    audio: audio,
    notifications: notifications,
    userId: userId,
  );
  
  final auth = LocalAuthRepository(database, settings);
  final locale = LocaleController(settings);
  await locale.load();

  final services = AppServices(
    auth: auth,
    tasks: tasks,
    settings: settings,
    timer: timer,
    navigation: navigation,
    notifications: notifications,
    gamification: gamification,
    gamificationRepository: gamificationRepo,
    audio: audio,
    locale: locale,
  );

  runApp(AppScope(services: services, child: const PomodoroTodoApp()));
}

class PomodoroTodoApp extends StatelessWidget {
  const PomodoroTodoApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);

    return ListenableBuilder(
      listenable: services.locale,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: services.locale.locale,
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
          builder: (context, child) => child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
