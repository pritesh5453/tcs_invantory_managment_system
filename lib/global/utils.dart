import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class Utils {
  void showToastMessage(String message) {
    Get.rawSnackbar(
      message: message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      // : Colors.white,
      borderRadius: 8,
      margin: EdgeInsets.all(12),
      duration: Duration(seconds: 2),
    );
  }

  Future<void> launchDialer(String number) async {
    final Uri telUrl = Uri.parse('tel:$number');
    var status = await Permission.phone.request();
    if (status.isGranted) {
      if (await canLaunchUrl(telUrl)) {
        await launchUrl(telUrl);
      } else {
        throw 'Could not launch $telUrl';
      }
    } else {
      print('Phone permission denied');
    }
  }

  final String email = "seller.care@gmail.com";
  final String subject = "";
  final String body = "";
  Future<void> launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': subject, 'body': body},
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      print("Could not launch email");
    }
  }

  final String websiteUrl = "https://myyvo.com/";
  Future<void> launchWebsite() async {
    final Uri uri = Uri.parse(websiteUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print("Could not launch $websiteUrl");
    }
  }

  void showTopSnackBar(BuildContext context, String message, Color color) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: 50.0, // Adjust position from the top
            left: MediaQuery.of(context).size.width * 0.1,
            width: MediaQuery.of(context).size.width * 0.8,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      color, // Dynamic color (red for error, green for success)
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  message,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }
}
