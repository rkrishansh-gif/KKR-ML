// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:kkr_ml_classes/screens/splash_screen.dart';
import 'package:kkr_ml_classes/screens/login_screen.dart';
import 'package:kkr_ml_classes/screens/setup_name_screen.dart';
import 'package:kkr_ml_classes/screens/home_screen.dart';
import 'package:kkr_ml_classes/screens/profile_screen.dart';
import 'package:kkr_ml_classes/screens/admin_panel_screen.dart';

import 'package:kkr_ml_classes/providers/auth_provider.dart';
import 'package:kkr_ml_classes/providers/batch_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Portrait only + transparent status bar
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF1A1A2E),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BatchProvider()),
      ],
      child: MaterialApp(
        title: 'KKR ML Classes',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: false, // Material 2 — consistent look across devices
          primaryColor: const Color(0xFF6C63FF),
          scaffoldBackgroundColor: const Color(0xFF0F0F1A),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF6C63FF),
            secondary: Color(0xFF3B82F6),
            surface: Color(0xFF1E1E30),
            background: Color(0xFF0F0F1A),
          ),

          // AppBar global theme
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1A1A2E),
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
            ),
          ),

          // SnackBar global theme
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF1E1E30),
            contentTextStyle: const TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Fast smooth page transitions
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: _SmoothPageTransition(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
        ),
        initialRoute: '/',
        routes: {
          '/':           (context) => const SplashScreen(),
          '/login':      (context) => const LoginScreen(),
          '/setup-name': (context) => const SetupNameScreen(),
          '/home':       (context) => const HomeScreen(),
          '/profile':    (context) => const ProfileScreen(),
          '/admin':      (context) => const AdminPanelScreen(),
        },

        // Fallback for unknown routes
        onUnknownRoute: (settings) => MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        ),
      ),
    );
  }
}

// ── Custom smooth page transition (faster than default 300ms) ─────────────────

class _SmoothPageTransition extends PageTransitionsBuilder {
  const _SmoothPageTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final slideTween = Tween(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic));

    final fadeTween = Tween<double>(
      begin: 0.0, end: 1.0,
    ).chain(CurveTween(curve: Curves.easeOutCubic));

    return SlideTransition(
      position: animation.drive(slideTween),
      child: FadeTransition(
        opacity: animation.drive(fadeTween),
        child: child,
      ),
    );
  }
}