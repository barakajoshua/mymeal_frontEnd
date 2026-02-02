import 'package:flutter/material.dart';
import 'package:mymeal/pages/welcome.dart';
import 'package:mymeal/pages/main_screen.dart'; 
import 'package:mymeal/providers/auth_provider.dart';
import 'package:mymeal/services/dio_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mymeal/services/fcm_service.dart';
import 'package:mymeal/firebase_options.dart';
import 'package:mymeal/services/local_notification_service.dart';

/// Background message handler - MUST be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('FCM Background: Message received');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await LocalNotificationService.init();
    await FCMService().initialize();
  } catch (e) {
    print("Firebase initialization failed: $e");
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  
  @override
  void initState() {
    super.initState();
    // Link DioService to AuthProvider once context is available or via callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
        DioService().updateAuthProvider(Provider.of<AuthProvider>(context, listen: false));
        Provider.of<AuthProvider>(context, listen: false).checkAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mymeal',
      theme: ThemeData(
        fontFamily: 'comfortaa',
        primarySwatch: Colors.green,
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          switch (auth.status) {
            case AuthStatus.checking:
              return const _SplashScreen();
            case AuthStatus.authenticated:
              return const MainScreen();
            case AuthStatus.unauthenticated:
              return const WelcomeScreen();
            default:
              return const WelcomeScreen();
          }
        },
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF357D5D)),
      ),
    );
  }
}
