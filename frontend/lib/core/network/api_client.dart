import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // GET Request
  Future<http.Response> get(String path) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}$path');
    final headers = await _getHeaders();
    try {
      final response = await http.get(url, headers: headers);
      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // POST Request
  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}$path');
    final headers = await _getHeaders();
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Multipart Post for File Uploads
  Future<http.Response> uploadFile(String path, File file) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}$path');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    
    try {
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll({
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      });
      
      final stream = http.ByteStream(file.openRead());
      final length = await file.length();
      
      final multipartFile = http.MultipartFile(
        'image', 
        stream, 
        length,
        filename: file.path.split('/').last,
      );
      
      request.files.add(multipartFile);
      final streamedResponse = await request.send();
      return await http.Response.fromStream(streamedResponse);
    } catch (e) {
      throw Exception('Upload error: $e');
    }
  }
}
