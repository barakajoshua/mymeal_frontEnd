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
    
    if (refreshToken != null) {
      // Try to refresh
       print("DEBUG: Refresh token found, attempting to refresh session...");
      final result = await _authService.refreshToken(refreshToken);
      if (result['success']) {
        _accessToken = result['data']['accessToken'];
        // Backend could return user here, or we load from sharedPrefs if not returned
        // For robustness, let's load user from prefs if available because refresh endpoint often just returns tokens
        final prefs = await SharedPreferences.getInstance();
        final userStr = prefs.getString('user_data');
        if (userStr != null) {
          try {
            _user = User.fromJson(jsonDecode(userStr));
             _status = AuthStatus.authenticated;
          } catch(e) {
            print("Error parsing user data: $e");
            _status = AuthStatus.unauthenticated;
          }
        } else {
           // If we have token, but no user data, we should fetch Profile (if api exists) or login again.
           // For now, assume login again is safer 
           _status = AuthStatus.unauthenticated;
        }

        if (_status == AuthStatus.authenticated) {
            // Update refreshed tokens if present
            // Note: backend response might have new refresh token too
            if (result['data']['refreshToken'] != null) {
                await _storageService.saveRefreshToken(result['data']['refreshToken']);
            }
        }

      } else {
        print("DEBUG: Refresh token expired or invalid.");
        await _storageService.deleteRefreshToken();
        _status = AuthStatus.unauthenticated;
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
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
    await _authService.logout(_accessToken);
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
