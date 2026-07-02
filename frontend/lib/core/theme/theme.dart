import 'package:flutter/material.dart';
import '../constants/constants.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppConstants.primaryColorLight,
      colorScheme: const ColorScheme.light(
        primary: AppConstants.primaryColorLight,
        secondary: Color(0xFF00A884),
        surface: AppConstants.appBarColorLight,
        background: AppConstants.backgroundColorLight,
      ),
      scaffoldBackgroundColor: AppConstants.backgroundColorLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppConstants.appBarColorLight,
        foregroundColor: Color(0xFF1F2C34),
        elevation: 0.5,
        centerTitle: false,
      ),
      cardTheme: const CardTheme(
        color: Colors.white,
        elevation: 1,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Color(0xFF1F2C34)),
        bodyMedium: TextStyle(fontSize: 15.0, color: Color(0xFF54656F)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppConstants.primaryColorDark,
      colorScheme: const ColorScheme.dark(
        primary: AppConstants.primaryColorDark,
        secondary: Color(0xFF00A884),
        surface: AppConstants.appBarColorDark,
        background: AppConstants.backgroundColorDark,
      ),
      scaffoldBackgroundColor: AppConstants.backgroundColorDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppConstants.appBarColorDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: const CardTheme(
        color: AppConstants.appBarColorDark,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white),
        bodyMedium: TextStyle(fontSize: 15.0, color: Color(0xFF8696A0)),
      ),
    );
  }
}
