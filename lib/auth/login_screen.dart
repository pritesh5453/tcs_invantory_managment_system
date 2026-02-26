import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tcs_invantory_managment_system/auth/prefs/permission_manager.dart';
import 'dart:convert'; // JSON encode/decode ke liye
import 'package:tcs_invantory_managment_system/dashbard/main_dashbard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool obscure = true;
  bool rememberMe = true;
  bool isLoading = false;

  /// ✅ Success animation
  bool showSuccessOverlay = false;
  double logoScale = 1.0;

  final TextEditingController mobileController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://dashboard.theceramicstudio.in",
      headers: {"Content-Type": "application/json"},
    ),
  );

  /// 🔐 LOGIN FUNCTION
  // Login Screen me ye changes karo login function me:
  Future<void> login() async {
    if (mobileController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      showMessage("Email or Mobile & password required");
      return;
    }

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      // 🔥 1. Pehle FCM token generate karo (agar nahi hai to)
      String? fcmToken = prefs.getString('fcm_token');
      if (fcmToken == null || fcmToken.isEmpty) {
        fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await prefs.setString('fcm_token', fcmToken);
        } else {
          // Agar token nahi mila to empty string bhejo, but try to proceed
          fcmToken = "";
        }
      }

      // 2. Ab login API call karo with fcm_token
      final response = await dio.post(
        "/api/employees/login",
        data: {
          "email": mobileController.text.trim(),
          "password": passwordController.text.trim(),
          "fcmToken": fcmToken,
        },
      );

      final data = response.data;

      if (response.statusCode == 200 && data["success"] == true) {
        // User data save karo
        if (rememberMe) {
          await prefs.setBool("isLoggedIn", true);
          await prefs.setString("token", data["token"]);
          await prefs.setString("role", data["role"] ?? "employee");

          final user = data["user"];
          if (user != null) {
            await prefs.setInt("userId", user["id"] ?? 0);
            await prefs.setString("userName", user["name"] ?? "");
            await prefs.setString("userEmail", user["email"] ?? "");
            await prefs.setString("userPhone", user["phone"] ?? "");
            await prefs.setString("profilePhoto", user["profile_photo"] ?? "");
          }

          // Permissions
          final permissions = data["permissions"];
          if (permissions != null) {
            await prefs.setString("permissions", json.encode(permissions));
            PermissionManager.updatePermissions(permissions);
          } else {
            await prefs.setString("permissions", "{}");
            PermissionManager.updatePermissions({});
          }
        } else {
          await prefs.clear();
        }

        // Success animation & navigate
        setState(() {
          showSuccessOverlay = true;
          logoScale = 1.8;
        });

        await Future.delayed(const Duration(milliseconds: 1200));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeWithAnimatedDrawer()),
        );
      } else {
        showMessage("Invalid credentials");
      }
    } on DioException catch (e) {
      showMessage(e.response?.data["message"] ?? "Login failed");
    } catch (e) {
      showMessage("Something went wrong");
    }

    setState(() => isLoading = false);
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          /// 🔹 LOGIN UI
          if (!showSuccessOverlay)
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 60),

                      /// LOGO
                      Center(
                        child: Image.asset(
                          "assets/images/Logo_2.png",
                          height: 120,
                        ),
                      ),

                      const SizedBox(height: 40),

                      /// TEXTS
                      const Text(
                        "WELCOME BACK",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Log In to your Account",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),

                      const SizedBox(height: 35),

                      /// EMAIL / MOBILE
                      const Text(
                        "Email or Phone Number",
                        style: TextStyle(color: Colors.grey),
                      ),
                      TextField(
                        controller: mobileController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                          enabledBorder: UnderlineInputBorder(),
                          focusedBorder: UnderlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      /// PASSWORD
                      const Text(
                        "Password",
                        style: TextStyle(color: Colors.grey),
                      ),
                      TextField(
                        controller: passwordController,
                        obscureText: obscure,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                          enabledBorder: const UnderlineInputBorder(),
                          focusedBorder: const UnderlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscure ? Icons.visibility_off : Icons.visibility,
                              size: 18,
                            ),
                            onPressed: () {
                              setState(() => obscure = !obscure);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      /// REMEMBER + FORGOT
                      Row(
                        children: [
                          Checkbox(
                            value: rememberMe,
                            activeColor: Colors.orange,
                            onChanged: (val) {
                              setState(() => rememberMe = val!);
                            },
                          ),
                          const Text("Remember me"),
                          const Spacer(),
                        ],
                      ),

                      const SizedBox(height: 30),

                      /// LOGIN BUTTON
                      GestureDetector(
                        onTap: isLoading ? null : login,
                        child: Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Center(
                            child:
                                isLoading
                                    ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                    : const Text(
                                      "Login",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),

          /// ✅ SUCCESS OVERLAY
          if (showSuccessOverlay)
            Container(
              color: Colors.white,
              child: Center(
                child: AnimatedScale(
                  scale: logoScale,
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutBack,
                  child: Image.asset("assets/images/Logo_2.png", height: 120),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
