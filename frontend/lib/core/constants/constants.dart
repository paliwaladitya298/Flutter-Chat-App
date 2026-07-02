import 'package:flutter/material.dart';

class AppConstants {
  // Backend URL configuration
  // Use 'http://10.0.2.2:5000' for Android Emulator to connect to localhost
  // Use 'http://localhost:5000' for iOS Simulator, Web or Desktop
  static const String baseUrl = 'http://10.0.2.2:5000'; 
  
  static const String apiBaseUrl = '$baseUrl/api';
  static const String socketUrl = baseUrl;

  // Modern WhatsApp-inspired color palette
  static const Color primaryColorLight = Color(0xFF00A884); // WhatsApp Green
  static const Color primaryColorDark = Color(0xFF00A884);
  
  static const Color backgroundColorLight = Color(0xFFF7F7F7);
  static const Color backgroundColorDark = Color(0xFF111B21); // WhatsApp Dark Background
  
  static const Color appBarColorLight = Color(0xFFFFFFFF);
  static const Color appBarColorDark = Color(0xFF202C33); // WhatsApp AppBar Dark

  static const Color bubbleSentLight = Color(0xFFE7FFDB);
  static const Color bubbleSentDark = Color(0xFF005C4B);
  
  static const Color bubbleReceivedLight = Color(0xFFFFFFFF);
  static const Color bubbleReceivedDark = Color(0xFF202C33);
}
