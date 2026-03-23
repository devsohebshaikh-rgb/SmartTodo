import 'package:flutter/material.dart';

class AppConstants {
  static const String apiBaseUrl = 'https://smartlocation.bhagvanjikipooja.com/api';
  static const String appName = 'Smart Todo';
  static const int defaultGeofenceRadius = 700;
  static const double defaultMapLatitude = 20.5937;
  static const double defaultMapLongitude = 78.9629;
  static const double defaultMapZoom = 5.0;
}

class AppColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF5A52D5);
  static const Color primaryLight = Color(0xFF9D97FF);
  static const Color secondary = Color(0xFF00BFA6);
  static const Color accent = Color(0xFFFF6584);
  static const Color background = Color(0xFFF8F9FE);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF2D3142);
  static const Color textLight = Color(0xFF9C9EB9);
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFA726);

  // Status colors
  static const Color pending = Color(0xFFFFA726);
  static const Color inProgress = Color(0xFF42A5F5);
  static const Color completed = Color(0xFF66BB6A);
  static const Color missed = Color(0xFFEF5350);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
