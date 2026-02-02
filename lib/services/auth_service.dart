import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:mymeal/services/api_client.dart'; // To get baseUrl
import 'package:mymeal/models/user.dart';
import 'package:mymeal/services/secure_storage_service.dart';

class AuthService {
  final Dio _dio = Dio();
  
  AuthService() {
    // We use a fresh Dio instance here to avoid interceptor loops when refreshing tokens
    _dio.options.baseUrl = ApiClient.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  Future<Map<String, dynamic>> login(String phoneNumber, String password, String? deviceToken) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        "phoneNumber": phoneNumber,
        "password": password,
        if (deviceToken != null) "deviceToken": deviceToken,
        "platform": "android" 
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': response.data['data']};
      } else {
        return {'success': false, 'message': response.data['message'] ?? 'Login failed'};
      }
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      // Assuming refresh logic - backend typically receives refresh token in body or header
      // Based on prompt: POST /auth/refresh
      final response = await _dio.post('/auth/refresh', data: {
        "refreshToken": refreshToken
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': response.data};
      } else {
        return {'success': false, 'message': 'Refresh failed'};
      }
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<void> logout(String? accessToken) async {
    if (accessToken == null) return;
    try {
      await _dio.post(
        '/auth/logout', 
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'}
        )
      );
    } catch (e) {
      print("Logout error: $e");
    }
  }

  Map<String, dynamic> _handleDioError(DioException e) {
    String message = 'Connection failed';
    if (e.response != null) {
      if (e.response?.data is Map && e.response?.data['message'] != null) {
        message = e.response?.data['message'];
      } else {
        message = 'Server Error: ${e.response?.statusCode}';
      }
    }
    return {'success': false, 'message': message};
  }
}
