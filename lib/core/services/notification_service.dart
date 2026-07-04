import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
  }

  Future<void> showBudgetWarning(String category, double percentUsed) async {
    await _plugin.show(
      category.hashCode,
      'Budget Alert: $category',
      percentUsed >= 100
          ? 'You have exceeded your $category budget for this month.'
          : 'You have used ${percentUsed.toStringAsFixed(0)}% of your $category budget.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'budget_channel',
          'Budget Alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> scheduleDailyReminder({int hour = 21, int minute = 0}) async {
    await _plugin.zonedSchedule(
      1001,
      'Log today\'s expenses',
      'Don\'t forget to add your transactions for today in FinWise AI.',
      _nextInstanceOf(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          'Daily Reminders',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> showMonthlySummary(String summary) async {
    await _plugin.show(
      2001,
      'Your Monthly Finance Summary',
      summary,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'summary_channel',
          'Monthly Summary',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> showSavingsMilestone(double amount) async {
    await _plugin.show(
      3001,
      'Savings Milestone Reached! 🎉',
      'You\'ve saved ₹${amount.toStringAsFixed(0)} this month. Keep it up!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'milestone_channel',
          'Savings Milestones',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
