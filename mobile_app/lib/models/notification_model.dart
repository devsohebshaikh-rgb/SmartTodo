class NotificationModel {
  final int id;
  final int todoId;
  final int userId;
  final String message;
  final DateTime triggeredAt;
  final String status;

  NotificationModel({
    required this.id,
    required this.todoId,
    required this.userId,
    required this.message,
    required this.triggeredAt,
    required this.status,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      todoId: json['todo_id'] is int
          ? json['todo_id']
          : int.parse(json['todo_id'].toString()),
      userId: json['user_id'] is int
          ? json['user_id']
          : int.parse(json['user_id'].toString()),
      message: json['message'] ?? '',
      triggeredAt: json['triggered_at'] != null
          ? DateTime.parse(json['triggered_at'])
          : DateTime.now(),
      status: json['status'] ?? 'sent',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'todo_id': todoId,
      'user_id': userId,
      'message': message,
      'triggered_at': triggeredAt.toIso8601String(),
      'status': status,
    };
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, todoId: $todoId, message: $message)';
  }
}
