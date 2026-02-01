import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
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
      // Use the singleton FCMService to get the token
      // This ensures we use the initialized instance
      String? token = await FCMService().getToken();
      
      if (token != null && !token.startsWith("ERROR") && !token.startsWith("FAILED")) {
        print("REAL FCM TOKEN FOUND: $token");
        return token;
      } else {
        print("FCM Token retrieval returned null or error: $token. Retrying once...");
        // Fallback retry
        token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          print("REAL FCM TOKEN FOUND ON RETRY: $token");
          return token;
        }
        return "FAILED_TO_GET_FCM_TOKEN_${DateTime.now().millisecondsSinceEpoch}";
      }
    } catch (e) {
      print("Error getting device token: $e");
      // If we get the 'no-app' error, it means Firebase wasn't initialized yet
      if (e.toString().contains('no-app')) {
        try {
          // One last attempt to initialize if not done
          await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
          String? token = await FirebaseMessaging.instance.getToken();
          if (token != null) return token;
        } catch (_) {}
      }
      return "ERROR_GETTING_FCM_TOKEN_${e.toString().replaceAll(' ', '_')}";
    }
  }

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String password,
    int roleId = 1, // Default to Customer
    bool includeDeviceToken = true, // Set to false when registering chefs from manager
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

  static Future<Map<String, dynamic>> updateDeviceToken(String deviceToken) async {
    final String url = '$baseUrl/auth/update-token';
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');

    final Map<String, dynamic> payload = {
      "deviceToken": deviceToken,
      "platform": Platform.isAndroid ? "android" : "ios",
    };

    print("DEBUG: Updating device token at $url");

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      print("DEBUG: Update token Status Code: ${response.statusCode}");
      return _handleResponse(response);
    } catch (e) {
      print("DEBUG: Update token failed: $e");
      return {'success': false, 'message': 'Connection failed: $e'};
    }
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

  static Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> deliveryLocation,
    String? notes,
  }) async {
    final String url = '$baseUrl/orders';
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');

    final Map<String, dynamic> payload = {
      "items": items,
      "deliveryLocation": deliveryLocation,
      "notes": notes ?? "",
    };

    print("DEBUG: Creating order at $url");
    print("DEBUG: Payload: ${jsonEncode(payload)}");

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      print("DEBUG: Order Status Code: ${response.statusCode}");
      return _handleResponse(response);
    } catch (e) {
      print("DEBUG: Order creation failed: $e");
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

  static Future<Map<String, dynamic>> getMyOrders() async {
    final String url = '$baseUrl/orders/my';
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');

    print("DEBUG: Fetching my orders from $url");
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print("DEBUG: My Orders Status Code: ${response.statusCode}");
      return _handleResponse(response);
    } catch (e) {
      print("DEBUG: Fetching my orders failed: $e");
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  // --- Manager/Admin API Methods ---

  // Orders
  static Future<Map<String, dynamic>> getAllOrders() async {
    final String url = '$baseUrl/orders'; // Shared route for Admin/Manager
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateOrderStatus(int orderId, String status) async {
    final String url = '$baseUrl/orders/$orderId/status';
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      ).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  // Categories
  static Future<Map<String, dynamic>> getAllCategories() async {
    final String url = '$baseUrl/categories'; // Manager route
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> createCategory({
    required String name,
    required String description,
    required int sortOrder,
    bool isActive = true,
  }) async {
    final String url = '$baseUrl/categories';
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');

    final Map<String, dynamic> payload = {
      "name": name,
      "description": description,
      "sort_order": sortOrder,
      "is_active": isActive,
    };

    print("DEBUG: Creating category at $url");
    print("DEBUG: Payload: ${jsonEncode(payload)}");

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  // Menu Items
  static Future<Map<String, dynamic>> getAllMenuItems() async {
    final String url = '$baseUrl/menu'; // Manager route
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  // Chefs
  static Future<Map<String, dynamic>> getAllChefs() async {
    final String url = '$baseUrl/chefs';
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> createChefProfile({
    required int userId,
    required String displayName,
    required String specialty,
    required String bio,
    required int experienceYears,
  }) async {
    final String url = '$baseUrl/chefs'; // Assuming POST /chefs creates the profile
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');

    final Map<String, dynamic> payload = {
      "userId": userId,
      "displayName": displayName,
      "specialty": specialty,
      "bio": bio,
      "experienceYears": experienceYears,
      "isActive": true,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
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
    final String url = '$baseUrl/chefs/$chefId';
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');

    final Map<String, dynamic> payload = {
      "userId": userId,
      "displayName": displayName,
      "specialty": specialty,
      "bio": bio,
      "experienceYears": experienceYears,
      "isActive": isActive,
    };

    print("DEBUG: Updating chef at $url");
    print("DEBUG: Payload: ${jsonEncode(payload)}");

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  // Create Product (Single Endpoint for Data + Images)
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
    final String url = '$baseUrl/menu';
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');

    print("DEBUG: Creating product (Multipart) at $url");

    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));
      
      // Add headers
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add fields
      request.fields['category_id'] = categoryId.toString();
      request.fields['chef_id'] = chefId.toString();
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['price'] = price.toString();
      request.fields['available_date'] = availableDate;
      request.fields['is_available'] = isAvailable.toString();

      // Handle Images mapping to image_url, image_url_2, etc.
      // Define the keys
      final imageKeys = ['image_url', 'image_url_2', 'image_url_3', 'image_url_4', 'image_url_5'];
      
      // Add files for available images
      if (images != null) {
        for (int i = 0; i < imageKeys.length; i++) {
          if (i < images.length) {
            // Add file
            final file = images[i];
            final multipartFile = await http.MultipartFile.fromPath(
              imageKeys[i], // Field name: image_url, image_url_2...
              file.path,
            );
            request.files.add(multipartFile);
          } else {
            // Send empty string for missing images? 
            // Some backends might expect the key to exist as a text field if empty.
            request.fields[imageKeys[i]] = "";
          }
        }
      } else {
        // No images, send all as empty strings
        for (var key in imageKeys) {
          request.fields[key] = "";
        }
      }

      print("DEBUG: Sending Multipart Request with fields: ${request.fields}");
      print("DEBUG: Sending ${request.files.length} files. Field names: ${request.files.map((f) => f.field).toList()}");

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response);
    } catch (e) {
      print('DEBUG: Create product error: $e');
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateProduct({
    required int productId,
    required String name,
    required double price,
    required bool isAvailable,
  }) async {
    final String url = '$baseUrl/menu/$productId';
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');

    final Map<String, dynamic> payload = {
      "name": name,
      "price": price,
      "is_available": isAvailable,
    };

    print("DEBUG: Updating product at $url");
    print("DEBUG: Payload: ${jsonEncode(payload)}");

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  // Managers (Admin Only)
  static Future<Map<String, dynamic>> registerManager({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String password,
  }) async {
    // Role 3 = Manager
    return register(
      fullName: fullName, 
      phoneNumber: phoneNumber, 
      email: email, 
      password: password, 
      roleId: 3
    );
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
