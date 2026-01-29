import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class ApiClient {
  static const String _baseUrlLocal = 'https://penetratingly-nonstructural-alton.ngrok-free.dev/api';
  static const String _baseUrlEmulator = 'https://penetratingly-nonstructural-alton.ngrok-free.dev/api';

  static String get baseUrl {
    if (Platform.isAndroid) {
      return _baseUrlEmulator;
    }
    return _baseUrlLocal;
  }

  static Future<String?> getDeviceToken() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      String? token = await messaging.getToken();
      
      if (token != null) {
        print("REAL FCM TOKEN FOUND: $token");
        return token;
      } else {
        print("FCM Token retrieval returned null. Ensure Firebase is configured.");
        return "FAILED_TO_GET_FCM_TOKEN_${DateTime.now().millisecondsSinceEpoch}";
      }
    } catch (e) {
      print("Error getting device token: $e");
      return "ERROR_GETTING_FCM_TOKEN_${e.toString().replaceAll(' ', '_')}";
    }
  }

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String password,
  }) async {
    final String? deviceToken = await getDeviceToken();
    
    final Map<String, dynamic> payload = {
      "fullName": fullName,
      "phoneNumber": phoneNumber,
      "email": email,
      "password": password,
      "roleId": 1,
      "deviceToken": deviceToken,
      "platform": Platform.isAndroid ? "android" : "ios",
    };

    final String url = '$baseUrl/auth/register';
    print("DEBUG: Registering to $url");
    print("DEBUG: Payload: ${jsonEncode(payload)}");

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      print("DEBUG: Status Code: ${response.statusCode}");
      print("DEBUG: Response Body: ${response.body}");

      return _handleResponse(response);
    } catch (e) {
      print("DEBUG: Registration failed with error: $e");
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String phoneNumber,
    required String password,
  }) async {
    final String? deviceToken = await getDeviceToken();
    final Map<String, dynamic> payload = {
      "phoneNumber": phoneNumber,
      "password": password,
      "deviceToken": deviceToken,
      "platform": Platform.isAndroid ? "android" : "ios",
    };

    final String url = '$baseUrl/auth/login';
    print("DEBUG: Logging in to $url");
    print("DEBUG: Payload: ${jsonEncode(payload)}");

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      print("DEBUG: Status Code: ${response.statusCode}");
      print("DEBUG: Response Body: ${response.body}");

      final result = _handleResponse(response);
      
      if (result['success'] == true && result.containsKey('data')) {
        final data = result['data'];
        final prefs = await SharedPreferences.getInstance();
        
        if (data.containsKey('token')) {
          await prefs.setString('auth_token', data['token']);
        }
        
        if (data.containsKey('user')) {
          await prefs.setString('user_data', jsonEncode(data['user']));
        }
      }
      
      return result;
    } catch (e) {
      print("DEBUG: Login failed with error: $e");
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userDataStr = prefs.getString('user_data');
    if (userDataStr != null) {
      return jsonDecode(userDataStr);
    }
    return null;
  }

  static Future<Map<String, dynamic>> getMenus() async {
    final String url = '$baseUrl/menu';
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');

    print("DEBUG: Fetching menus from $url");
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print("DEBUG: Menus Status Code: ${response.statusCode}");
      return _handleResponse(response);
    } catch (e) {
      print("DEBUG: Fetching menus failed: $e");
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> getCategories() async {
    final String url = '$baseUrl/categories/active';
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');

    print("DEBUG: Fetching categories from $url");
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print("DEBUG: Categories Status Code: ${response.statusCode}");
      return _handleResponse(response);
    } catch (e) {
      print("DEBUG: Fetching categories failed: $e");
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    print("DEBUG: Raw Response Body: ${response.body}");
    try {
      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, ...decoded};
      } else {
        return {
          'success': false,
          'message': decoded['message'] ?? 'Request failed with status: ${response.statusCode}',
          ...decoded
        };
      }
    } catch (e) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true};
      }
      return {'success': false, 'message': 'Error parsing response: $e'};
    }
  }
}
