import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
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

  Future<void> login(
    String username,
    String password,
    BuildContext context,
  ) async {
    state = const AsyncValue.loading();

    String? fcmToken;
    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
      debugPrint("🔥 FCM TOKEN => $fcmToken");
    } catch (e) {
      debugPrint("Failed to get FCM token: $e");
      fcmToken = null;
    }

    try {
      final response = await ApiService().postRequest(endpoint, {
        'username': username,
        'password': password,
        'fcm_token': fcmToken,
      });

      debugPrint("Login response status: ${response?.statusCode}");

      if (response != null && response.data['success'] == true) {
        final responseData = response.data;
        if (responseData != null) {
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

          state = const AsyncValue.data(null);
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
      debugPrint("Login error: $e");
      state = AsyncValue.error(
        'Failed to login. Please try again.',
        stackTrace,
      );
    }
  }
}
