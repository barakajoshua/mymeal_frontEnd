import 'package:flutter/material.dart';
import 'package:mymeal/models/user.dart';
import 'package:mymeal/services/auth_service.dart';
import 'package:mymeal/services/secure_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:mymeal/services/api_client.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.checking;
  User? _user;
  String? _accessToken;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get accessToken => _accessToken;

  final AuthService _authService = AuthService();
  final SecureStorageService _storageService = SecureStorageService.instance;

  Future<void> checkAuth() async {
    _status = AuthStatus.checking;
    notifyListeners();

    // Check refresh token in secure storage
    final refreshToken = await _storageService.getRefreshToken();
    
    // Check for cached user data
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user_data');
    User? cachedUser;
    
    if (userStr != null) {
      try {
        cachedUser = User.fromJson(jsonDecode(userStr));
      } catch (e) {
        print("Error parsing cached user data: $e");
      }
    }

    if (refreshToken != null) {
      print("DEBUG: Refresh token found, attempting to refresh session...");
      
      // Try to refresh token
      final result = await _authService.refreshToken(refreshToken);
      
      if (result['success']) {
        _accessToken = result['data']['accessToken'];
        
        // Success! We have a valid session.
        // Update refresh token if a new one was sent (optional/future proofing)
        if (result['data']['refreshToken'] != null) {
            await _storageService.saveRefreshToken(result['data']['refreshToken']);
        }

        // Now ensure we have User data
        if (cachedUser != null) {
          // We have cached user, use it immediately for speed
          _user = cachedUser;
          _status = AuthStatus.authenticated;
          
          // Background: Try to update profile with fresh data (silent update)
          _fetchAndSaveProfile(); 
        } else {
          // No cached user? We NEED to fetch it from backend.
           print("DEBUG: No cached user found. Fetching profile from backend...");
           bool profileSuccess = await _fetchAndSaveProfile();
           
           if (profileSuccess) {
             _status = AuthStatus.authenticated;
           } else {
             // If we can't get profile even with valid token, something is wrong (or network failed after token refresh?)
             // If it was network error during profile fetch, we are in a tough spot: Valid token, but no user info.
             // We'll set unauthenticated to force re-login as fallback, or handle specifically.
             // For now:
             _status = AuthStatus.unauthenticated; 
           }
        }
        
      } else {
        // Refresh Failed. Why?
        final bool isNetworkError = result['isNetworkError'] == true;
        final int? statusCode = result['statusCode'];

        print("DEBUG: Refresh failed. NetworkError: $isNetworkError, Status: $statusCode");

        if (isNetworkError) {
          // INTERNET DOWN.
          // If we have cached user, allow "Offline Mode".
          if (cachedUser != null) {
             print("DEBUG: Network error but cached user found. Entering Offline Mode.");
             _user = cachedUser;
             _status = AuthStatus.authenticated;
             // Note: _accessToken is null here, so API calls will likely fail or get queued until net is back.
             // But valid use case for viewing cached content.
          } else {
             // No internet and no cache. Cannot log in.
             _status = AuthStatus.unauthenticated;
          }
        } else {
          // SERVER REJECTED (401/403/400). Token is invalid/expired.
          print("DEBUG: Refresh token invalid. Logging out.");
          await _storageService.deleteRefreshToken();
          _status = AuthStatus.unauthenticated;
        }
      }
    } else {
      // No refresh token found.
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // Helper to fetch and save profile
  Future<bool> _fetchAndSaveProfile() async {
    if (_accessToken == null) return false;
    
    final result = await _authService.getUserProfile(_accessToken!);
    if (result['success']) {
      final userData = result['data'];
      _user = User.fromJson(userData);
      
      // Update cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(userData));
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<Map<String, dynamic>> login(String phoneNumber, String password) async {
    final deviceToken = await ApiClient.getDeviceToken(); // Still using ApiClient for helper
    final result = await _authService.login(phoneNumber, password, deviceToken);

    if (result['success']) {
      final data = result['data'];
      _accessToken = data['accessToken'];
      final refreshToken = data['refreshToken'];
      final userJson = data['user'];

      if (userJson != null) {
        _user = User.fromJson(userJson);
        // Persist User for offline/restart checks (optional but good for UX)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(userJson));
      }
      
      if (refreshToken != null) {
        await _storageService.saveRefreshToken(refreshToken);
      }

      _status = AuthStatus.authenticated;
      notifyListeners();
    }
    return result;
  }

  Future<void> logout() async {
    // Get refresh token before deleting it
    final refreshToken = await _storageService.getRefreshToken();
    
    // Call backend to invalidate session
    await _authService.logout(_accessToken, refreshToken);
    
    await _storageService.deleteRefreshToken();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');

    _accessToken = null;
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // Method to update access token manually (called by interceptors)
  void setAccessToken(String token) {
    _accessToken = token;
    notifyListeners(); // Careful, this might rebuild UI unnecessarily if not handled
  }
}
