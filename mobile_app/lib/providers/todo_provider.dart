import 'package:flutter/foundation.dart';
import '../models/todo_model.dart';
import '../models/location_model.dart';
import '../services/todo_service.dart';
import '../services/location_service.dart';

class TodoProvider extends ChangeNotifier {
  final TodoService _todoService;
  final LocationService _locationService;

  List<TodoModel> _todos = [];
  List<TodoModel> _todayTodos = [];
  List<TodoModel> _upcomingTodos = [];
  bool _isLoading = false;

  TodoProvider({TodoService? todoService, LocationService? locationService})
      : _todoService = todoService ?? TodoService(),
        _locationService = locationService ?? LocationService();

  List<TodoModel> get todos => _todos;
  List<TodoModel> get todayTodos => _todayTodos;
  List<TodoModel> get upcomingTodos => _upcomingTodos;
  bool get isLoading => _isLoading;

  Future<void> fetchTodos() async {
    _isLoading = true;
    notifyListeners();

    try {
      _todos = await _todoService.getUserTodos();
      // Also compute today/upcoming locally as fallback
      _computeLocalFilters();
    } catch (e) {
      debugPrint('fetchTodos error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTodayTodos() async {
    try {
      _todayTodos = await _todoService.getTodayTodos();
      notifyListeners();
    } catch (e) {
      debugPrint('fetchTodayTodos error: $e');
      // Fallback: filter from all todos locally
      _todayTodos = _filterTodayLocally();
      notifyListeners();
    }
  }

  Future<void> fetchUpcomingTodos() async {
    try {
      _upcomingTodos = await _todoService.getUpcomingTodos();
      notifyListeners();
    } catch (e) {
      debugPrint('fetchUpcomingTodos error: $e');
      // Fallback: filter from all todos locally
      _upcomingTodos = _filterUpcomingLocally();
      notifyListeners();
    }
  }

  /// Compute today and upcoming from the already-fetched all-todos list
  void _computeLocalFilters() {
    if (_todayTodos.isEmpty) {
      _todayTodos = _filterTodayLocally();
    }
    if (_upcomingTodos.isEmpty) {
      _upcomingTodos = _filterUpcomingLocally();
    }
  }

  List<TodoModel> _filterTodayLocally() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return _todos.where((t) {
      if (t.location == null) return false;
      final vd = t.location!.visitDate;
      return !vd.isBefore(todayStart) && vd.isBefore(todayEnd);
    }).toList();
  }

  List<TodoModel> _filterUpcomingLocally() {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));

    return _todos.where((t) {
      if (t.location == null) return false;
      return t.location!.visitDate.isAfter(todayEnd) && t.status != 'completed';
    }).toList();
  }

  Future<TodoModel> addTodo({
    required String city,
    required double latitude,
    required double longitude,
    required String address,
    required DateTime visitDate,
    required String taskTitle,
    required String taskDescription,
    int reminderRadius = 700,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final location = await _locationService.createLocation(
        city, latitude, longitude, address, visitDate,
      );

      final todo = await _todoService.createTodo(
        location.id, taskTitle, taskDescription, reminderRadius,
      );

      _todos.insert(0, todo);
      _computeLocalFilters();
      notifyListeners();
      return todo;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TodoModel> updateTodo(int id, Map<String, dynamic> fields) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updatedTodo = await _todoService.updateTodo(id, fields);

      final index = _todos.indexWhere((t) => t.id == id);
      if (index != -1) _todos[index] = updatedTodo;

      final todayIndex = _todayTodos.indexWhere((t) => t.id == id);
      if (todayIndex != -1) _todayTodos[todayIndex] = updatedTodo;

      final upcomingIndex = _upcomingTodos.indexWhere((t) => t.id == id);
      if (upcomingIndex != -1) _upcomingTodos[upcomingIndex] = updatedTodo;

      notifyListeners();
      return updatedTodo;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTodo(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _todoService.deleteTodo(id);
      _todos.removeWhere((t) => t.id == id);
      _todayTodos.removeWhere((t) => t.id == id);
      _upcomingTodos.removeWhere((t) => t.id == id);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TodoModel> markComplete(int id) async {
    return updateTodo(id, {'status': 'completed'});
  }

  Future<TodoModel> updateTodoStatus(int id, String status) async {
    return updateTodo(id, {'status': status});
  }

  Future<LocationModel> createLocation({
    required String city,
    required double latitude,
    required double longitude,
    required String address,
    required DateTime visitDate,
  }) async {
    final location = await _locationService.createLocation(
      city, latitude, longitude, address, visitDate,
    );
    return location;
  }

  Future<TodoModel> createTodo({
    required int locationId,
    required String taskTitle,
    required String taskDescription,
    int reminderRadius = 700,
  }) async {
    final todo = await _todoService.createTodo(
      locationId, taskTitle, taskDescription, reminderRadius,
    );
    _todos.insert(0, todo);
    _computeLocalFilters();
    notifyListeners();
    return todo;
  }
}
