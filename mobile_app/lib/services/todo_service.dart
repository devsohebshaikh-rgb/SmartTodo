import '../models/todo_model.dart';
import 'api_service.dart';

class TodoService {
  final ApiService _apiService;

  TodoService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  Future<TodoModel> createTodo(
    int locationId,
    String taskTitle,
    String taskDescription,
    int reminderRadius,
  ) async {
    final response = await _apiService.post('/todo', {
      'locationId': locationId,
      'taskTitle': taskTitle,
      'taskDescription': taskDescription,
      'reminderRadius': reminderRadius,
    });

    final data = response['data'] ?? response;
    return TodoModel.fromJson(data);
  }

  Future<List<TodoModel>> getUserTodos() async {
    final response = await _apiService.get('/todos/user/0');
    final data = response['data'] ?? response;
    final List<dynamic> todos = data is List ? data : [];
    return todos.map((json) => TodoModel.fromJson(json)).toList();
  }

  Future<List<TodoModel>> getTodayTodos() async {
    final response = await _apiService.get('/todos/today');
    final data = response['data'] ?? response;
    final List<dynamic> todos = data is List ? data : [];
    return todos.map((json) => TodoModel.fromJson(json)).toList();
  }

  Future<List<TodoModel>> getUpcomingTodos() async {
    final response = await _apiService.get('/todos/upcoming');
    final data = response['data'] ?? response;
    final List<dynamic> todos = data is List ? data : [];
    return todos.map((json) => TodoModel.fromJson(json)).toList();
  }

  Future<TodoModel> getTodo(int id) async {
    final response = await _apiService.get('/todo/$id');
    final data = response['data'] ?? response;
    return TodoModel.fromJson(data);
  }

  Future<TodoModel> updateTodo(int id, Map<String, dynamic> fields) async {
    final response = await _apiService.put('/todo/$id', fields);
    final data = response['data'] ?? response;
    return TodoModel.fromJson(data);
  }

  Future<void> deleteTodo(int id) async {
    await _apiService.delete('/todo/$id');
  }
}
