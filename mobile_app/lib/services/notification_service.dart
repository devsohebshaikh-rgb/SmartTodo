import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/todo_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FlutterLocalNotificationsPlugin? _notificationsPlugin;
  bool _isInitialized = false;

  static const String _alarmChannelId = 'smart_todo_alarm';
  static const String _alarmChannelName = 'Todo Alarm';
  static const String _alarmChannelDescription =
      'High priority alarm for geofence triggers';

  Future<void> initialize() async {
    if (_isInitialized) return;
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin!.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    final androidPlugin =
        _notificationsPlugin!.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    _isInitialized = true;
    debugPrint('NotificationService initialized');
  }

  /// Shows persistent notification with custom sound
  Future<void> showReminderNotification(TodoModel todo) async {
    if (kIsWeb || _notificationsPlugin == null) {
      debugPrint('Reminder (web): ${todo.taskTitle}');
      return;
    }

    final locationName = todo.location?.city ?? 'your destination';
    final title = 'Task Reminder!';
    final body =
        'You are near $locationName!\n${todo.taskTitle}: ${todo.taskDescription}';

    final androidDetails = AndroidNotificationDetails(
      _alarmChannelId,
      _alarmChannelName,
      channelDescription: _alarmChannelDescription,
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('notifyme'),
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      autoCancel: false,
      ongoing: true,
      ticker: 'Task Reminder',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin!.show(
      todo.id,
      title,
      body,
      details,
      payload: todo.id.toString(),
    );

    debugPrint('NOTIFICATION FIRED for: ${todo.taskTitle}');
  }

  Future<void> cancelNotification(int id) async {
    if (kIsWeb || _notificationsPlugin == null) return;
    await _notificationsPlugin!.cancel(id);
  }

  Future<void> cancelAll() async {
    if (kIsWeb || _notificationsPlugin == null) return;
    await _notificationsPlugin!.cancelAll();
  }
}
