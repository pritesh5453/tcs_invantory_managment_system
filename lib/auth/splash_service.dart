import 'package:flutter/material.dart';
import 'package:tcs_invantory_managment_system/auth/login_screen.dart';
import 'package:tcs_invantory_managment_system/auth/prefs/PreferencesKey.dart';
import 'package:tcs_invantory_managment_system/auth/prefs/app_preference.dart';

class SplashServices {
  void checkAuthentication(BuildContext context) async {
    Future.delayed(const Duration(seconds: 1), () {
      if (AppPreference().getString(PreferencesKey.token).isEmpty ||
          AppPreference().getString(PreferencesKey.token) == "") {
        // Get.to(LangvangeSelection());
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else {
        // Navigator.pushReplacement(
        //   context,MaterialPageRoute(builder: (context) => HomePage()),
        // );
      }
      // Navigator.popAndPushNamed(context, RoutesName.loginscreen);
    });
  }
}
