import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/services.dart';

const _foregroundChannel = MethodChannel('pomodoro/foreground');

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );

    // Request Android 13+ notification permission if available
    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.requestNotificationsPermission();
  }

  Future<void> showOngoingNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Start or update native foreground service to provide a more reliable ongoing notification.
    try {
      await _foregroundChannel.invokeMethod('startForeground', {
        'title': title,
        'body': body,
      });
    } catch (_) {
      // Fallback to flutter_local_notifications if platform channel fails
      final androidDetails = AndroidNotificationDetails(
        'pomodoro_ongoing',
        'Pomodoro Ongoing',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        onlyAlertOnce: true,
        showWhen: false,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(),
      );

      await _notifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _foregroundChannel.invokeMethod('stopForeground');
    } catch (_) {
      await _notifications.cancel(id: id);
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'pomodoro_channel',
          'Pomodoro Notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'pomodoro_scheduled',
          'Scheduled Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> updateDailyReminders({bool enabled = true}) async {
    if (!enabled) {
      await cancel(1001); // 1001 is the ID for daily reminder
      return;
    }
    // Default 9:00 AM for daily reminder
    await scheduleDailyNotification(
      id: 1001,
      title: 'Пора за дело!',
      body: 'Ваши задачи ждут вас. Начните первый помидор!',
      hour: 9,
      minute: 0,
    );
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  Future<void> cancel(int id) async {
    await _notifications.cancel(id: id);
  }
}
