import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/todo_model.dart';

class GeofenceEvent {
  final TodoModel todo;
  final double distance;

  GeofenceEvent({required this.todo, required this.distance});
}

class GeofenceService {
  static final GeofenceService _instance = GeofenceService._internal();
  factory GeofenceService() => _instance;
  GeofenceService._internal();

  StreamSubscription<Position>? _positionSubscription;
  Timer? _periodicCheckTimer;
  final StreamController<List<GeofenceEvent>> _geofenceController =
      StreamController<List<GeofenceEvent>>.broadcast();

  Stream<List<GeofenceEvent>> get geofenceEvents => _geofenceController.stream;

  List<TodoModel> _activeTodos = [];
  Position? lastKnownPosition;

  void updateTodos(List<TodoModel> todos) {
    final now = DateTime.now();

    _activeTodos = todos.where((t) {
      if (t.location == null) return false;
      if (t.status == 'completed' || t.status == 'missed') return false;
      final visitDate = t.location!.visitDate;
      // Include today's tasks (visitDate could be UTC midnight — compare date parts)
      final vdLocal = visitDate.toLocal();
      final isSameDay = vdLocal.year == now.year &&
          vdLocal.month == now.month &&
          vdLocal.day == now.day;
      return isSameDay;
    }).toList();

    debugPrint(
        'GeofenceService: monitoring ${_activeTodos.length} active todos for today');

    // If we already have a position, immediately check geofences with new todos
    if (lastKnownPosition != null && _activeTodos.isNotEmpty) {
      _doGeofenceCheck(lastKnownPosition!);
    }
  }

  double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000;
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  List<GeofenceEvent> checkGeofences(
      double currentLat, double currentLng, List<TodoModel> todos) {
    final List<GeofenceEvent> triggered = [];

    for (final todo in todos) {
      if (todo.location == null) continue;
      if (todo.status == 'completed' || todo.status == 'missed') continue;

      final distance = calculateDistance(
        currentLat,
        currentLng,
        todo.location!.latitude,
        todo.location!.longitude,
      );

      debugPrint(
          'GeofenceCheck: "${todo.taskTitle}" distance=${distance.toStringAsFixed(0)}m radius=${todo.reminderRadius}m');

      if (distance <= todo.reminderRadius) {
        triggered.add(GeofenceEvent(todo: todo, distance: distance));
      }
    }

    return triggered;
  }

  void _doGeofenceCheck(Position position) {
    lastKnownPosition = position;
    final events = checkGeofences(
      position.latitude,
      position.longitude,
      _activeTodos,
    );
    if (events.isNotEmpty) {
      debugPrint('GEOFENCE TRIGGERED: ${events.length} events!');
      _geofenceController.add(events);
    }
  }

  Future<void> startLocationMonitoring() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    // ===== 1. IMMEDIATE CHECK with current position =====
    try {
      final currentPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      debugPrint(
          'Initial position: ${currentPos.latitude}, ${currentPos.longitude}');
      _doGeofenceCheck(currentPos);
    } catch (e) {
      debugPrint('Could not get initial position: $e');
    }

    // ===== 2. CONTINUOUS STREAM for movement-based checks =====
    late LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
        intervalDuration: const Duration(seconds: 5),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText:
              'Smart Todo is monitoring your location for task reminders',
          notificationTitle: 'Smart Todo - Location Active',
          enableWakeLock: true,
          notificationIcon:
              AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
          setOngoing: true,
        ),
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
      );
    }

    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        debugPrint(
            'LocationStream: ${position.latitude}, ${position.longitude}');
        _doGeofenceCheck(position);
      },
      onError: (error) {
        debugPrint('Location stream error: $error');
      },
    );

    // ===== 3. PERIODIC TIMER as backup (every 15 seconds) =====
    // In case the position stream doesn't fire (user is stationary)
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) async {
        try {
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          _doGeofenceCheck(pos);
        } catch (e) {
          // If we have a last known position, re-check with that
          if (lastKnownPosition != null) {
            _doGeofenceCheck(lastKnownPosition!);
          }
        }
      },
    );

    debugPrint('GeofenceService: location monitoring STARTED (stream + timer)');
  }

  void stopLocationMonitoring() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = null;
    debugPrint('GeofenceService: location monitoring STOPPED');
  }

  void dispose() {
    stopLocationMonitoring();
    _geofenceController.close();
  }
}
