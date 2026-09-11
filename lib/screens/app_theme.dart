import 'package:flutter/material.dart';

class AppTheme {
  static const Color brand = Color(0xFFCCFD04);

  /// 🌞 LIGHT THEME
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: brand,
    scaffoldBackgroundColor: const Color(0xfff5f7fb),
    appBarTheme: const AppBarTheme(
      backgroundColor: brand,
      foregroundColor: Colors.black,
    ),
    cardColor: Colors.white,
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.black),
    ),
  );

  /// 🌙 DARK THEME (REAL NIGHT MODE)
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.black,
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),
    cardColor: const Color(0xFF1E1E1E),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white),
    ),
  );
}
