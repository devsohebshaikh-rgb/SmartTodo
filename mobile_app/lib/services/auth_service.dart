import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService;

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  AuthService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final response = await _apiService.post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });

    // Backend wraps in {success, data: {token, user}}
    final data = response['data'] ?? response;
    final token = data['token'] as String;
    final user = UserModel.fromJson(data['user']);

    await _storeToken(token);
    await _storeUser(user);

    return {'user': user, 'token': token};
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _apiService.post('/auth/login', {
      'email': email,
      'password': password,
    });

    // Backend wraps in {success, data: {token, user}}
    final data = response['data'] ?? response;
    final token = data['token'] as String;
    final user = UserModel.fromJson(data['user']);

    await _storeToken(token);
    await _storeUser(user);

    return {'user': user, 'token': token};
  }

  Future<void> _storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> _storeUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr == null || userStr.isEmpty) return null;
    return UserModel.fromJson(jsonDecode(userStr));
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
