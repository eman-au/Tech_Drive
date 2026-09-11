// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // ✅ NEW
import 'firebase_options.dart';
// Screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/my_profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/contact_us_screen.dart';
import 'screens/help_support_screen.dart';
import 'screens/become_worker_promo_screen.dart';
import 'screens_for_workers/worker_home_screen.dart';
import 'screens_admin/admin_login_screen.dart';
import 'screens_admin/admin_dashboard_screen.dart';
// Theme
import 'theme_controller.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'services/notification_service.dart';

// ✅ NEW — background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Initialize local notifications & high importance channel
  await NotificationService.initializeLocalNotifications();

  // Listen to auth changes and manage global notification listener lifecycle
  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user != null) {
      NotificationService.startListening(user.uid);
    } else {
      NotificationService.stopListening();
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static const Color brand = Color(0xFFCCFD04);
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Tech Drive',
          navigatorKey: MyApp.navigatorKey,
          themeMode: mode,
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: brand,
            scaffoldBackgroundColor: const Color(0xfff5f7fb),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              centerTitle: true,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: brand,
            scaffoldBackgroundColor: const Color(0xFF121212),
          ),
          home: const SplashScreen(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
            '/profile': (context) => const MyProfileScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/contact': (context) => const ContactUsScreen(),
            '/support': (context) => const HelpSupportScreen(),
            '/worker': (context) => const BecomeWorkerPromoScreen(),
            '/worker-home': (context) => const WorkerHomeScreen(),
            '/admin-login': (context) => const AdminLoginScreen(),
            '/admin-dashboard': (context) => const AdminDashboardScreen(),
          },
        );
      },
    );
  }
}