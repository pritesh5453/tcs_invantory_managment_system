import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:flutter_riverpod/legacy.dart';
import 'package:tcs_invantory_managment_system/api_service/api_service.dart';
import 'package:tcs_invantory_managment_system/api_service/urls.dart';
import 'package:tcs_invantory_managment_system/auth/prefs/PreferencesKey.dart';
import 'package:tcs_invantory_managment_system/auth/prefs/app_preference.dart';

final loginProvider = StateNotifierProvider<LoginNotifier, AsyncValue<void>>((
  ref,
) {
  return LoginNotifier();
});

class LoginNotifier extends StateNotifier<AsyncValue<void>> {
  LoginNotifier() : super(const AsyncValue.data(null));

  Future<void> login(String username, String password, context) async {
      String? token = await FirebaseMessaging.instance.getToken();
  debugPrint("🔥 FCM TOKEN => $token");
    // FirebaseMessaging messaging = FirebaseMessaging.instance;
    // String? token = await messaging.getToken();
    // print("token $token");
    state = const AsyncValue.loading();

    try {
      final response = await ApiService().postRequest(endpoint, {
        'username': username,
        'password': password,
        'fcm_token': token,
      });
      print(
        "response*****************************************************************",
      );
      print(response?.statusCode);
      if (response != null && response.data['success'] == true) {
        final responseData = response.data;
        if (responseData != null && response.data['success'] == true) {
          String token = responseData['token']['accessToken'];
          await AppPreference().setString(
            PreferencesKey.token,
            responseData['token']['accessToken'],
          );
          await AppPreference().setString(
            PreferencesKey.name,
            responseData['user']['username'],
          );
          await AppPreference().setString(
            PreferencesKey.email,
            responseData['user']['email'],
          );
          await AppPreference().setString(
            PreferencesKey.userID,
            responseData['user']['userId'],
          );

          print("kkmm");
          state = const AsyncValue.data(null);
          // Navigator.pushReplacement(
          //   context,
          //   MaterialPageRoute(builder: (context) => HomePage()),
          // );
        } else {
          state = AsyncValue.error(
            'Invalid username or password',
            StackTrace.current,
          );
        }
      } else {
        state = AsyncValue.error(
          'Invalid username or password',
          StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(
        'Failed to login. Please try again.',
        stackTrace,
      );
    }
  }
}
