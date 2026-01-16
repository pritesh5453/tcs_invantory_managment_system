import 'package:flutter/material.dart';
import 'package:tcs_invantory_managment_system/dashbard/dilvery_chalan/update_timeline.dart';

class DeliveryChalanScreen extends StatelessWidget {
  const DeliveryChalanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: Column(
        children: [
          /// ================= TOP SEARCH BAR SECTION =================
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            decoration: const BoxDecoration(
              color: Color(0xFFFA9C42),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  /// 🔍 SEARCH FIELD
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: "Search..",
                          hintStyle: TextStyle(color: Colors.grey),
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),

          /// ================= LIST =================
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 2,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _chalanCard(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// ================= CHALAN CARD =================
  Widget _chalanCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TOP ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 14, color: Colors.black),
                  children: [
                    TextSpan(text: "Chalan no. :   "),
                    TextSpan(
                      text: "CH 01",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 14, color: Colors.black),
                  children: [
                    TextSpan(text: "Date :   "),
                    TextSpan(
                      text: "01/01/2026",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// RECIPIENT
          RichText(
            text: const TextSpan(
              style: TextStyle(color: Colors.black, fontSize: 14),
              children: [
                TextSpan(text: "Recipient Details :   "),
                TextSpan(
                  text: "Pritesh Pawar",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          /// MOBILE
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 14, color: Colors.black),
              children: [
                TextSpan(text: "Mobile Number :   "),
                TextSpan(
                  text: "+91 7875272898",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          /// BUTTONS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UpdateTimelineScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.location_on_outlined,
                  color: Colors.blue,
                ),
                label: const Text(
                  "Update Timeline",
                  style: TextStyle(color: Colors.blue),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
