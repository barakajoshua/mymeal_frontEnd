import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:mymeal/services/api_client.dart';

/// FCM Service to handle push notifications
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _currentToken;

  /// Initialize FCM and set up listeners
  Future<void> initialize() async {
    try {
      // Request notification permissions
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('FCM: User granted permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('FCM: User granted permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('FCM: User granted provisional permission');
      } else {
        print('FCM: User declined or has not accepted permission');
      }

      // Get initial token
      _currentToken = await _messaging.getToken();
      if (_currentToken != null) {
        print('FCM: Initial token retrieved: $_currentToken');
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        print('FCM: Token refreshed: $newToken');
        _currentToken = newToken;
        _updateTokenOnBackend(newToken);
      });

      // Set up foreground notification handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Set up notification tap handler (when app is in background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a terminated state via notification
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        print('FCM: App opened from terminated state via notification');
        _handleNotificationTap(initialMessage);
      }

      print('FCM: Service initialized successfully');
    } catch (e) {
      print('FCM: Error initializing service: $e');
    }
  }

  /// Handle foreground messages (when app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    print('FCM: Foreground message received');
    print('FCM: Title: ${message.notification?.title}');
    print('FCM: Body: ${message.notification?.body}');
    print('FCM: Data: ${message.data}');

    // You can show a local notification here or update UI
    // For now, we'll just log it
  }

  /// Handle notification tap (when user taps notification)
  void _handleNotificationTap(RemoteMessage message) {
    print('FCM: Notification tapped');
    print('FCM: Title: ${message.notification?.title}');
    print('FCM: Body: ${message.notification?.body}');
    print('FCM: Data: ${message.data}');

    // Navigate to specific screen based on notification data
    // You can implement navigation logic here based on message.data
  }

  /// Update token on backend
  Future<void> _updateTokenOnBackend(String token) async {
    try {
      print('FCM: Updating token on backend: $token');
      final result = await ApiClient.updateDeviceToken(token);
      
      if (result['success'] == true) {
        print('FCM: Token successfully updated on backend');
      } else {
        print('FCM: Failed to update token on backend: ${result['message']}');
      }
    } catch (e) {
      print('FCM: Error updating token on backend: $e');
    }
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    if (_currentToken != null) {
      return _currentToken;
    }
    
    try {
      _currentToken = await _messaging.getToken();
      return _currentToken;
    } catch (e) {
      print('FCM: Error getting token: $e');
      return null;
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('FCM: Subscribed to topic: $topic');
    } catch (e) {
      print('FCM: Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('FCM: Unsubscribed from topic: $topic');
    } catch (e) {
      print('FCM: Error unsubscribing from topic: $e');
    }
  }
}
