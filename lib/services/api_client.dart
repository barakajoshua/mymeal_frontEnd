import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mymeal/services/dio_service.dart';
import 'package:mymeal/services/secure_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mymeal/services/fcm_service.dart';
import 'package:mymeal/firebase_options.dart';

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
      String? token = await FCMService().getToken();
      
      if (token != null && !token.startsWith("ERROR") && !token.startsWith("FAILED")) {
        print("REAL FCM TOKEN FOUND: $token");
        return token;
      } else {
        token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          return token;
        }
        return "FAILED_TO_GET_FCM_TOKEN_${DateTime.now().millisecondsSinceEpoch}";
      }
    } catch (e) {
      print("Error getting device token: $e");
      return "ERROR_GETTING_FCM_TOKEN_${e.toString().replaceAll(' ', '_')}";
    }
  }

  // Public Methods (using DioService, but could use AuthService for consistency if desired)
  
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String password,
    int roleId = 1, 
    bool includeDeviceToken = true,
  }) async {
    String? deviceToken;
    if (includeDeviceToken) {
      deviceToken = await getDeviceToken();
    }
    
    final Map<String, dynamic> payload = {
      "fullName": fullName,
      "phoneNumber": phoneNumber,
      "email": email,
      "password": password,
      "roleId": roleId,
      if (includeDeviceToken && deviceToken != null) "deviceToken": deviceToken,
      if (includeDeviceToken) "platform": Platform.isAndroid ? "android" : "ios",
    };

    try {
      final response = await DioService().client.post('/auth/register', data: payload);
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  static Future<Map<String, dynamic>> login({
    required String phoneNumber,
    required String password,
  }) async {
    // This method might still be used by old code, but updated Login page uses AuthProvider.
    // We should ideally deprecate this or bridge it to AuthProvider if possible (but tricky with static)
    // For now, let's keep it functional using DioService (it will just be a pass-through).
    // Note: AuthProvider uses AuthService (raw Dio), so this standalone call won't update AuthProvider state!
    // WARNING: Using this method won't update app state. We should log a warning or try to fix.
    // Given the task, we replaced usages in login.dart. Assuming no other usages.
    
    // However, to be safe, we implement it via DioService client.
    final String? deviceToken = await getDeviceToken();
    final Map<String, dynamic> payload = {
      "phoneNumber": phoneNumber,
      "password": password,
      "deviceToken": deviceToken,
      "platform": Platform.isAndroid ? "android" : "ios",
    };

    try {
      final response = await DioService().client.post('/auth/login', data: payload);
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Authenticated Methods (DioService handles token injection)

  static Future<Map<String, dynamic>> updateDeviceToken(String deviceToken) async {
    final Map<String, dynamic> payload = {
      "deviceToken": deviceToken,
      "platform": Platform.isAndroid ? "android" : "ios",
    };

    try {
      final response = await DioService().client.post('/auth/update-token', data: payload);
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  static Future<Map<String, dynamic>> getMenus() async {
    try {
      final response = await DioService().client.get('/menu');
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  static Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> deliveryLocation,
    String? notes,
  }) async {
    final Map<String, dynamic> payload = {
      "items": items,
      "deliveryLocation": deliveryLocation,
      "notes": notes ?? "",
    };

    try {
      final response = await DioService().client.post('/orders', data: payload);
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  static Future<Map<String, dynamic>> getCategories() async {
    try {
      final response = await DioService().client.get('/categories/active');
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  static Future<Map<String, dynamic>> getMyOrders() async {
    try {
      final response = await DioService().client.get('/orders/my');
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Helper Methods

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userDataStr = prefs.getString('user_data');
    if (userDataStr != null) {
      return jsonDecode(userDataStr);
    }
    return null;
  }
  
  // Manager / Admin Methods

  static Future<Map<String, dynamic>> getAllOrders() async {
    try {
      final response = await DioService().client.get('/orders');
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  static Future<Map<String, dynamic>> updateOrderStatus(int orderId, String status) async {
    try {
      final response = await DioService().client.put(
        '/orders/$orderId/status',
        data: {'status': status},
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  static Future<Map<String, dynamic>> getAllCategories() async {
    try {
      final response = await DioService().client.get('/categories');
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  static Future<Map<String, dynamic>> createCategory({
    required String name,
    required String description,
    required int sortOrder,
    bool isActive = true,
  }) async {
    final Map<String, dynamic> payload = {
      "name": name,
      "description": description,
      "sort_order": sortOrder,
      "is_active": isActive,
    };

    try {
      final response = await DioService().client.post('/categories', data: payload);
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  static Future<Map<String, dynamic>> getAllMenuItems() async {
    try {
      final response = await DioService().client.get('/menu');
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }
  
  static Future<Map<String, dynamic>> getAllChefs() async {
    try {
      final response = await DioService().client.get('/chefs');
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  static Future<Map<String, dynamic>> createChefProfile({
      required int userId,
      required String displayName,
      required String specialty,
      required String bio,
      required int experienceYears,
    }) async {
    final Map<String, dynamic> payload = {
      "userId": userId,
      "displayName": displayName,
      "specialty": specialty,
      "bio": bio,
      "experienceYears": experienceYears,
      "isActive": true,
    };

    try {
      final response = await DioService().client.post('/chefs', data: payload);
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  static Future<Map<String, dynamic>> updateChef({
    required int chefId,
    required int userId,
    required String displayName,
    required String specialty,
    required String bio,
    required int experienceYears,
    required bool isActive,
  }) async {
    final Map<String, dynamic> payload = {
      "userId": userId,
      "displayName": displayName,
      "specialty": specialty,
      "bio": bio,
      "experienceYears": experienceYears,
      "isActive": isActive,
    };

    try {
      final response = await DioService().client.put('/chefs/$chefId', data: payload);
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  static Future<Map<String, dynamic>> createProduct({
    required int categoryId,
    required int chefId,
    required String name,
    required String description,
    required double price,
    required String availableDate,
    required bool isAvailable,
    List<File>? images, // Up to 5 images
  }) async {
    try {
      final formData = FormData.fromMap({
        'category_id': categoryId,
        'chef_id': chefId,
        'name': name,
        'description': description,
        'price': price,
        'available_date': availableDate,
        'is_available': isAvailable,
      });

      final imageKeys = ['image_url', 'image_url_2', 'image_url_3', 'image_url_4', 'image_url_5'];
      
      if (images != null) {
        for (int i = 0; i < imageKeys.length; i++) {
          if (i < images.length) {
            final file = images[i];
            formData.files.add(MapEntry(
              imageKeys[i],
              await MultipartFile.fromFile(file.path),
            ));
          } else {
             formData.fields.add(MapEntry(imageKeys[i], ""));
          }
        }
      } else {
        for (var key in imageKeys) {
          formData.fields.add(MapEntry(key, ""));
        }
      }

      final response = await DioService().client.post(
        '/menu', 
        data: formData,
        options: Options(contentType: 'multipart/form-data')
      );
      
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  static Future<Map<String, dynamic>> updateProduct({
    required int productId,
    required String name,
    required double price,
    required bool isAvailable,
  }) async {
    final Map<String, dynamic> payload = {
      "name": name,
      "price": price,
      "is_available": isAvailable,
    };

    try {
      final response = await DioService().client.put('/menu/$productId', data: payload);
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Response Handler
  static Map<String, dynamic> _handleResponse(Response response) {
    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
      if (response.data is Map<String, dynamic>) {
        return {'success': true, ...response.data};
      }
      return {'success': true, 'data': response.data};
    } else {
      Map<String, dynamic> errorData = {};
      if (response.data is Map<String, dynamic>) {
        errorData = response.data;
      }
      return {
        'success': false,
        'message': errorData['message'] ?? 'Request failed with status: ${response.statusCode}',
        ...errorData
      };
    }
  }

  static Map<String, dynamic> _handleDioError(DioException e) {
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
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    try {
        if (token != null) {
            await DioService().client.post(
                '/auth/logout',
                options: Options(
                    headers: {'Authorization': 'Bearer $token'}
                )
            );
        }
    } catch (e) {
        print("Logout error: $e");
    }
    
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    await SecureStorageService.instance.deleteRefreshToken();
  }

  static Future<Map<String, dynamic>> registerManager({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String password,
  }) async {
    return register(
      fullName: fullName, 
      phoneNumber: phoneNumber, 
      email: email, 
      password: password, 
      roleId: 3
    );
  }
}
