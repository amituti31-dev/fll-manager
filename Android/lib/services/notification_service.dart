import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import '../models/models.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId = 'task_reminders';
  static const _channelName = 'תזכורות משימות';

  static Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));

    // Request POST_NOTIFICATIONS permission on Android 13+
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();

    _initialized = true;
  }

  static Future<void> scheduleTaskReminder(MemberTask task) async {
    if (task.due == null) return;

    final parts = task.due!.split('/');
    if (parts.length != 3) return;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return;

    final dueDate = DateTime(y, m, d);
    final reminderDay = dueDate.subtract(const Duration(days: 1));
    final reminderAt = DateTime(
        reminderDay.year, reminderDay.month, reminderDay.day, 9, 0);

    if (reminderAt.isBefore(DateTime.now())) return;

    final scheduled = tz.TZDateTime.from(reminderAt, tz.local);
    final desc = task.desc.length > 50
        ? '${task.desc.substring(0, 50)}...'
        : task.desc;

    await _plugin.zonedSchedule(
      task.id,
      '⏰ תזכורת: משימה מחר',
      task.memberId == 'all'
          ? 'כל הקבוצה: $desc'
          : '${task.memberName}: $desc',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'תזכורות למשימות שמגיעות מחר',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelTaskReminder(int taskId) async {
    await _plugin.cancel(taskId);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
