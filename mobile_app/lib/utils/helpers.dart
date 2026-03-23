import 'package:flutter/material.dart';
import 'constants.dart';

/// Formats a DateTime into a readable string (e.g., "Mar 16, 2026").
String formatDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

/// Formats a distance in meters into a human-readable string.
String formatDistance(double meters) {
  if (meters < 1000) {
    return '${meters.round()} m';
  } else {
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}

/// Returns a Color corresponding to the todo status.
Color getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return AppColors.pending;
    case 'in_progress':
      return AppColors.inProgress;
    case 'completed':
      return AppColors.completed;
    case 'missed':
      return AppColors.missed;
    default:
      return AppColors.textLight;
  }
}

/// Returns an IconData corresponding to the todo status.
IconData getStatusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return Icons.schedule;
    case 'in_progress':
      return Icons.play_circle_outline;
    case 'completed':
      return Icons.check_circle_outline;
    case 'missed':
      return Icons.cancel_outlined;
    default:
      return Icons.help_outline;
  }
}

/// Shows a SnackBar with the given message.
void showAppSnackBar(BuildContext context, String message,
    {bool isError = false}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppColors.error : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ),
  );
}
