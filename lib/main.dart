// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Correct imports - notice all file names match exactly
import 'package:kkr_ml_classes/screens/splash_screen.dart';
import 'package:kkr_ml_classes/screens/login_screen.dart';
import 'package:kkr_ml_classes/screens/home_screen.dart';
import 'package:kkr_ml_classes/screens/batch_detail_screen.dart';
import 'package:kkr_ml_classes/screens/video_player_screen.dart';
import 'package:kkr_ml_classes/providers/auth_provider.dart';
import 'package:kkr_ml_classes/providers/batch_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // Changed to StatelessWidget
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BatchProvider()),
      ],
      child: MaterialApp(
        title: 'KKR ML APP',
        theme: ThemeData(
          primaryColor: Color(0xFF6B46C1),
          scaffoldBackgroundColor: Colors.white,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => SplashScreen(),
          '/login': (context) => LoginScreen(),
          '/home': (context) => HomeScreen(),
          '/batch-detail': (context) => BatchDetailScreen(
            batchId: ModalRoute.of(context)!.settings.arguments as String,
          ),
          '/video-player': (context) => VideoPlayerScreen(
            lectureData:
                ModalRoute.of(context)!.settings.arguments
                    as Map<String, dynamic>,
          ),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
