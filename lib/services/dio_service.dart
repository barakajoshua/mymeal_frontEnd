import 'package:dio/dio.dart';
import 'package:mymeal/providers/auth_provider.dart';
import 'package:mymeal/services/api_client.dart';
import 'package:mymeal/services/auth_service.dart';
import 'package:mymeal/services/secure_storage_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class DioService {
  static final DioService _instance = DioService._internal();
  factory DioService() => _instance;
  
  late Dio _dio;
  late AuthProvider _authProvider; // We need a way to reference provider without context in simple singleton, or inject it.
  
  // To solve circular dependency or context issues, we can set provider later or use a callback
  // Ideally, authentication logic for refresh should be self-contained or use a repository.
  // For simplicity given the constraints:
  
  bool _isRefreshing = false;
  
  DioService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiClient.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
      }
    ));
    
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
           // Add token from AuthProvider if available
           // Since DioService is a singleton, we need updated access to the token.
           // A common pattern is to let AuthProvider configure Dio, or expose a static getter if simple.
           // Or simpler: pass token from UI? No, requirement is "Adds access token to every request".
           
           // Strategy: We will inject the token getter or AuthProvider instance.
           if (_authProvider.accessToken != null) {
             options.headers['Authorization'] = 'Bearer ${_authProvider.accessToken}';
           }
           print("DEBUG: DIO Request [${options.method}] ${options.path}");
           return handler.next(options);
        },
        onError: (DioException e, handler) async {
           print("DEBUG: DIO Error ${e.response?.statusCode}: ${e.message}");
           
           if (e.response?.statusCode == 401) {
             // Token expired
             if (!_isRefreshing) {
               _isRefreshing = true;
               
               try {
                 final refreshToken = await SecureStorageService.instance.getRefreshToken();
                 if (refreshToken != null) {
                    print("DEBUG: 401 received. Attempting auto-refresh...");
                    final authService = AuthService(); // Use raw service to avoid loop
                    final result = await authService.refreshToken(refreshToken);
                    
                    if (result['success']) {
                      final newAccessToken = result['data']['accessToken'];
                      final newRefreshToken = result['data']['refreshToken']; // Optional rotation
                      
                      _authProvider.setAccessToken(newAccessToken);
                      
                      if (newRefreshToken != null) {
                         await SecureStorageService.instance.saveRefreshToken(newRefreshToken);
                      }
                      
                      _isRefreshing = false;
                      
                      // Retry original request
                      // Update header with new token
                      e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                      
                      final clonedRequest = await _dio.request(
                        e.requestOptions.path,
                        options: Options(
                          method: e.requestOptions.method,
                          headers: e.requestOptions.headers,
                        ),
                        data: e.requestOptions.data,
                        queryParameters: e.requestOptions.queryParameters,
                      );
                      
                      return handler.resolve(clonedRequest);
                    }
                 }
               } catch (refreshError) {
                 print("DEBUG: Auto-refresh failed: $refreshError");
               } finally {
                 _isRefreshing = false;
               }
               
               // If we reach here, refresh failed or no refresh token
               print("DEBUG: Refresh failed or unavailable. Logging out.");
               _authProvider.logout(); // Navigate to login
             }
           }
           
           return handler.next(e);
        }
      )
    );
  }

  Dio get client => _dio;

  // Initializer to link provider
  void updateAuthProvider(AuthProvider provider) {
    _authProvider = provider;
  }
}
