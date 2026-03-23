class LocationModel {
  final int id;
  final int userId;
  final String city;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime visitDate;
  final DateTime createdAt;

  LocationModel({
    required this.id,
    required this.userId,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.visitDate,
    required this.createdAt,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      userId: json['user_id'] is int
          ? json['user_id']
          : int.parse(json['user_id'].toString()),
      city: json['city'] ?? '',
      latitude: json['latitude'] is double
          ? json['latitude']
          : double.parse(json['latitude'].toString()),
      longitude: json['longitude'] is double
          ? json['longitude']
          : double.parse(json['longitude'].toString()),
      address: json['address'] ?? '',
      visitDate: json['visit_date'] != null
          ? DateTime.parse(json['visit_date'])
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'visit_date': visitDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'LocationModel(id: $id, city: $city, lat: $latitude, lng: $longitude)';
  }
}
