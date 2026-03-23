import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/todo_model.dart';
import '../services/geofence_service.dart';
import '../services/notification_service.dart';
import '../screens/alarm/alarm_screen.dart';
import '../main.dart';

class LocationProvider extends ChangeNotifier {
  final GeofenceService _geofenceService;
  final NotificationService _notificationService;

  bool _isTracking = false;
  Position? _currentPosition;
  StreamSubscription<List<GeofenceEvent>>? _geofenceSubscription;

  // Track snooze times — key: todoId, value: when snooze expires
  final Map<int, DateTime> _snoozedUntil = {};

  // Track which todos are completed (dismissed permanently)
  final Set<int> _completedTodoIds = {};

  // Prevent multiple alarm screens at once
  bool _alarmScreenActive = false;

  // Queue of pending alarms
  final List<GeofenceEvent> _alarmQueue = [];

  LocationProvider({
    GeofenceService? geofenceService,
    NotificationService? notificationService,
  })  : _geofenceService = geofenceService ?? GeofenceService(),
        _notificationService = notificationService ?? NotificationService();

  bool get isTracking => _isTracking;
  Position? get currentPosition => _currentPosition;

  void updateActiveTodos(List<TodoModel> todos) {
    _geofenceService.updateTodos(todos);
    debugPrint('LocationProvider: updated active todos (${todos.length} total)');
  }

  Future<void> startTracking() async {
    if (_isTracking) return;

    try {
      await _notificationService.initialize();
      await _geofenceService.startLocationMonitoring();

      _geofenceSubscription?.cancel();
      _geofenceSubscription =
          _geofenceService.geofenceEvents.listen((events) async {
        for (final event in events) {
          _handleGeofenceEvent(event);
        }
      });

      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        debugPrint('Could not get initial position: $e');
      }

      _isTracking = true;
      notifyListeners();
      debugPrint('LocationProvider: tracking STARTED');
    } catch (e) {
      _isTracking = false;
      notifyListeners();
      debugPrint('LocationProvider: tracking FAILED - $e');
      rethrow;
    }
  }

  void _handleGeofenceEvent(GeofenceEvent event) {
    final todoId = event.todo.id;

    // Skip if task is already marked complete
    if (_completedTodoIds.contains(todoId)) return;
    if (event.todo.status == 'completed') return;

    // Skip if currently snoozed (within 15-minute window)
    if (_snoozedUntil.containsKey(todoId)) {
      final snoozeExpiry = _snoozedUntil[todoId]!;
      if (DateTime.now().isBefore(snoozeExpiry)) {
        return; // Still snoozed
      } else {
        _snoozedUntil.remove(todoId); // Snooze expired, re-alert
        debugPrint('Snooze expired for: ${event.todo.taskTitle}, re-alerting!');
      }
    }

    debugPrint(
        'ALARM TRIGGER: ${event.todo.taskTitle} at ${event.distance.toStringAsFixed(0)}m');

    // Queue the alarm
    _alarmQueue.add(event);
    _processAlarmQueue();
  }

  void _processAlarmQueue() {
    if (_alarmScreenActive || _alarmQueue.isEmpty) return;

    final event = _alarmQueue.removeAt(0);
    _showAlarmScreen(event);
  }

  Future<void> _showAlarmScreen(GeofenceEvent event) async {
    _alarmScreenActive = true;

    // Also fire a notification (in case screen is off)
    await _notificationService.showReminderNotification(event.todo);

    // Open full-screen alarm
    final context = navigatorKey.currentContext;
    if (context == null) {
      _alarmScreenActive = false;
      // Fallback: just set snooze so it retries in 15 mins
      _snoozedUntil[event.todo.id] =
          DateTime.now().add(const Duration(minutes: 15));
      return;
    }

    try {
      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => AlarmScreen(
            todo: event.todo,
            distance: event.distance,
          ),
        ),
      );

      if (result == 'completed') {
        // User marked task complete — stop alerting for this todo
        _completedTodoIds.add(event.todo.id);
        _snoozedUntil.remove(event.todo.id);
        await _notificationService.cancelNotification(event.todo.id);
        debugPrint('Task completed: ${event.todo.taskTitle}');
      } else {
        // User pressed "Got It" — snooze for 15 minutes, then re-alert
        _snoozedUntil[event.todo.id] =
            DateTime.now().add(const Duration(minutes: 15));
        await _notificationService.cancelNotification(event.todo.id);
        debugPrint(
            'Snoozed: ${event.todo.taskTitle} — will re-alert in 15 minutes');
      }
    } catch (e) {
      debugPrint('Alarm screen error: $e');
      _snoozedUntil[event.todo.id] =
          DateTime.now().add(const Duration(minutes: 15));
    }

    _alarmScreenActive = false;
    // Process next alarm in queue
    _processAlarmQueue();
  }

  void stopTracking() {
    _geofenceSubscription?.cancel();
    _geofenceSubscription = null;
    _geofenceService.stopLocationMonitoring();
    _isTracking = false;
    _snoozedUntil.clear();
    _completedTodoIds.clear();
    _alarmQueue.clear();
    _alarmScreenActive = false;
    notifyListeners();
    debugPrint('LocationProvider: tracking STOPPED');
  }

  void resetNotifications() {
    _snoozedUntil.clear();
    _completedTodoIds.clear();
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
