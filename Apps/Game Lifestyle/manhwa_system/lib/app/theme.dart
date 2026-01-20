import 'package:flutter/material.dart';

/// App Theme Configuration
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B0F17),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF3EF2D4),
      ),
    );
  }
}
