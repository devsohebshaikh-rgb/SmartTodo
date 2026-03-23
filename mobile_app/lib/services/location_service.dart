import '../models/location_model.dart';
import 'api_service.dart';

class LocationService {
  final ApiService _apiService;

  LocationService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  Future<LocationModel> createLocation(
    String city,
    double latitude,
    double longitude,
    String address,
    DateTime visitDate,
  ) async {
    final response = await _apiService.post('/location', {
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'visitDate': visitDate.toIso8601String().split('T')[0],
    });

    final data = response['data'] ?? response;
    return LocationModel.fromJson(data);
  }

  Future<List<LocationModel>> getUserLocations() async {
    final response = await _apiService.get('/location/user/0');
    final data = response['data'] ?? response;
    final List<dynamic> locations = data is List ? data : [];
    return locations.map((json) => LocationModel.fromJson(json)).toList();
  }

  Future<LocationModel> getLocation(int id) async {
    final response = await _apiService.get('/location/$id');
    final data = response['data'] ?? response;
    return LocationModel.fromJson(data);
  }
}
