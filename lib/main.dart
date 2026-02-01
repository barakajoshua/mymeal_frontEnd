import 'package:flutter/material.dart';
import 'package:mymeal/pages/welcome.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mymeal/services/fcm_service.dart';
import 'package:mymeal/firebase_options.dart';

/// Background message handler - MUST be a top-level function
/// This handles notifications when the app is in the background or terminated
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  print('FCM Background: Message received');
  print('FCM Background: Title: ${message.notification?.title}');
  print('FCM Background: Body: ${message.notification?.body}');
  print('FCM Background: Data: ${message.data}');
  
  // Handle the background message here
  // You can process data, update local storage, etc.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase with options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
    
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Initialize FCM Service
    await FCMService().initialize();
    
  } catch (e) {
    print("Firebase initialization failed: $e");
    print("The app will proceed without Firebase. Please ensure google-services.json is correctly placed.");
  }
  
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WelcomeScreen(),
    );
  }
}
