import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_client.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  User? _currentUser;
  bool _isLoading = false;
  String _errorMessage = '';

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  // Auto Login Check
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('jwt_token')) {
      return false;
    }
    
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.get('/auth/me');
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        _currentUser = User.fromJson(userData);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        await logout();
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register
  Future<bool> register(String username, String email, String password, {String avatarUrl = ''}) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _apiClient.post('/auth/register', {
        'username': username,
        'email': email,
        'password': password,
        'avatarUrl': avatarUrl,
      });

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        _currentUser = User.fromJson(responseData);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', responseData['token']);
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = responseData['message'] ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login
  Future<bool> login(String emailOrUsername, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _apiClient.post('/auth/login', {
        'emailOrUsername': emailOrUsername,
        'password': password,
      });

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _currentUser = User.fromJson(responseData);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', responseData['token']);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = responseData['message'] ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    notifyListeners();
  }
}
