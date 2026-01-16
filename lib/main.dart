import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tcs_invantory_managment_system/auth/prefs/app_preference.dart';
import 'package:tcs_invantory_managment_system/auth/login_screen.dart';
import 'package:tcs_invantory_managment_system/auth/splash_screen.dart';
import 'package:tcs_invantory_managment_system/dashbard/main_dashbard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// 🔹 Init app preferences
  await AppPreference().initialAppPreference();

  /// 🔹 GLOBAL STATUS BAR CONFIGURATION
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  /// 🔹 CHECK REMEMBER ME / LOGIN STATUS
  final Widget startScreen = await _getStartScreen();

  runApp(ProviderScope(child: MyApp(startScreen: startScreen)));
}

/// 🔐 Decide start screen
Future<Widget> _getStartScreen() async {
  final prefs = await SharedPreferences.getInstance();

  final bool isLoggedIn = prefs.getBool("isLoggedIn") ?? false;
  final String? token = prefs.getString("token");

  if (isLoggedIn && token != null && token.isNotEmpty) {
    /// ✅ User already logged in
    return const HomeWithAnimatedDrawer();
  } else {
    /// ❌ Not logged in → Splash → Login
    return const SplashAnimationScreen();
  }
}

class MyApp extends StatelessWidget {
  final Widget startScreen;

  const MyApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inventory Management System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: startScreen,
    );
  }
}
