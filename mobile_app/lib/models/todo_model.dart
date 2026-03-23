import 'location_model.dart';

class TodoModel {
  final int id;
  final int userId;
  final int locationId;
  final String taskTitle;
  final String taskDescription;
  final int reminderRadius;
  final String status;
  final bool isReminded;
  final LocationModel? location;
  final DateTime createdAt;
  final DateTime updatedAt;

  TodoModel({
    required this.id,
    required this.userId,
    required this.locationId,
    required this.taskTitle,
    required this.taskDescription,
    this.reminderRadius = 700,
    this.status = 'pending',
    this.isReminded = false,
    this.location,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TodoModel.fromJson(Map<String, dynamic> json) {
    LocationModel? locationModel;

    // Handle nested 'location' object from API
    if (json['location'] != null && json['location'] is Map<String, dynamic>) {
      locationModel = LocationModel.fromJson(json['location']);
    }
    // Handle flat fields from API join response (city, latitude, longitude)
    else if (json['city'] != null ||
        json['latitude'] != null ||
        json['longitude'] != null) {
      locationModel = LocationModel(
        id: json['location_id'] is int
            ? json['location_id']
            : int.parse(json['location_id'].toString()),
        userId: json['user_id'] is int
            ? json['user_id']
            : int.parse(json['user_id'].toString()),
        city: json['city'] ?? '',
        latitude: json['latitude'] is double
            ? json['latitude']
            : double.parse((json['latitude'] ?? '0').toString()),
        longitude: json['longitude'] is double
            ? json['longitude']
            : double.parse((json['longitude'] ?? '0').toString()),
        address: json['address'] ?? '',
        visitDate: json['visit_date'] != null
            ? DateTime.parse(json['visit_date'])
            : DateTime.now(),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
      );
    }

    return TodoModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      userId: json['user_id'] is int
          ? json['user_id']
          : int.parse(json['user_id'].toString()),
      locationId: json['location_id'] is int
          ? json['location_id']
          : int.parse(json['location_id'].toString()),
      taskTitle: json['task_title'] ?? '',
      taskDescription: json['task_description'] ?? '',
      reminderRadius: json['reminder_radius'] is int
          ? json['reminder_radius']
          : int.parse((json['reminder_radius'] ?? '700').toString()),
      status: json['status'] ?? 'pending',
      isReminded: json['is_reminded'] == true ||
          json['is_reminded'] == 1 ||
          json['is_reminded'] == 'true',
      location: locationModel,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'location_id': locationId,
      'task_title': taskTitle,
      'task_description': taskDescription,
      'reminder_radius': reminderRadius,
      'status': status,
      'is_reminded': isReminded,
      'location': location?.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TodoModel copyWith({
    int? id,
    int? userId,
    int? locationId,
    String? taskTitle,
    String? taskDescription,
    int? reminderRadius,
    String? status,
    bool? isReminded,
    LocationModel? location,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TodoModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      locationId: locationId ?? this.locationId,
      taskTitle: taskTitle ?? this.taskTitle,
      taskDescription: taskDescription ?? this.taskDescription,
      reminderRadius: reminderRadius ?? this.reminderRadius,
      status: status ?? this.status,
      isReminded: isReminded ?? this.isReminded,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'TodoModel(id: $id, taskTitle: $taskTitle, status: $status)';
  }
}
