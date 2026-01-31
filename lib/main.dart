import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth/prefs/app_preference.dart';
import 'auth/splash_screen.dart';

Future<void> main() async {
  /// 🔥 STEP 1: ALWAYS FIRST
  WidgetsFlutterBinding.ensureInitialized();

  /// 🔥 STEP 2: Firebase init
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  /// STEP 3: Shared Preferences
  await AppPreference().initialAppPreference();

  /// STEP 4: Status bar config
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  /// STEP 5: run app
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inventory Management System',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),

      /// 🔥 ALWAYS START FROM SPLASH
      home: const SplashAnimationScreen(),
    );
  }
}
