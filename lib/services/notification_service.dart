import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  bool _timezoneReady = false;

  bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() async {
    if (_initialized || !_isSupportedPlatform) return;

    timezone_data.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      timezone.setLocalLocation(timezone.getLocation(localTimezone.identifier));
      _timezoneReady = true;
    } catch (_) {
      _timezoneReady = false;
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    if (!_isSupportedPlatform || !_timezoneReady) return false;

    final android = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    if (android != null) return android;

    final ios = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: false, sound: true);
    return ios ?? false;
  }

  Future<bool> scheduleHabitReminder({
    required String habitId,
    required String habitName,
    required String? reminder,
    required List<int> weekdays,
  }) async {
    final time = parseTime(reminder);
    if (time == null || !await requestPermission()) return false;

    await cancelHabitReminder(habitId);
    const androidDetails = AndroidNotificationDetails(
      'habit_reminders',
      'Habit reminders',
      channelDescription: 'Scheduled reminders for your habits',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final selectedDays = weekdays.isEmpty ? [1] : weekdays;
    for (final weekday in selectedDays) {
      final scheduledDate = _nextOccurrence(
        time,
        weekdays.isEmpty ? null : weekday,
      );
      await _plugin.zonedSchedule(
        id: _notificationId(habitId, weekday),
        title: habitName,
        body: 'A small step for today is ready.',
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: weekdays.isEmpty
            ? DateTimeComponents.time
            : DateTimeComponents.dayOfWeekAndTime,
        payload: habitId,
      );
    }
    return true;
  }

  Future<void> cancelHabitReminder(String habitId) async {
    if (!_isSupportedPlatform) return;
    await initialize();
    for (var weekday = 1; weekday <= 7; weekday++) {
      await _plugin.cancel(id: _notificationId(habitId, weekday));
    }
  }

  Future<void> cancelAll() async {
    if (!_isSupportedPlatform) return;
    await initialize();
    await _plugin.cancelAll();
  }

  @visibleForTesting
  static (int, int)? parseTime(String? value) {
    if (value == null) return null;
    final twelveHour = RegExp(
      r'^\s*(\d{1,2}):(\d{2})\s*(AM|PM)\s*$',
      caseSensitive: false,
    ).firstMatch(value);
    if (twelveHour != null) {
      final hour = int.parse(twelveHour.group(1)!);
      final minute = int.parse(twelveHour.group(2)!);
      if (hour < 1 || hour > 12 || minute > 59) return null;
      final isPm = twelveHour.group(3)!.toUpperCase() == 'PM';
      return ((hour % 12) + (isPm ? 12 : 0), minute);
    }

    final twentyFourHour = RegExp(
      r'^\s*(\d{1,2}):(\d{2})\s*$',
    ).firstMatch(value);
    if (twentyFourHour == null) return null;
    final hour = int.parse(twentyFourHour.group(1)!);
    final minute = int.parse(twentyFourHour.group(2)!);
    if (hour > 23 || minute > 59) return null;
    return (hour, minute);
  }

  timezone.TZDateTime _nextOccurrence((int, int) time, int? weekday) {
    final now = timezone.TZDateTime.now(timezone.local);
    var candidate = timezone.TZDateTime(
      timezone.local,
      now.year,
      now.month,
      now.day,
      time.$1,
      time.$2,
    );

    while (candidate.isBefore(now) ||
        (weekday != null && candidate.weekday != weekday)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  int _notificationId(String habitId, int weekday) {
    var hash = 0x811c9dc5;
    for (final codeUnit in habitId.codeUnits) {
      hash = ((hash ^ codeUnit) * 0x01000193) & 0x7fffffff;
    }
    return (hash + weekday) & 0x7fffffff;
  }
}
