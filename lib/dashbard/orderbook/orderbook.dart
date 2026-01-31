import 'package:flutter/material.dart';
import 'package:tcs_invantory_managment_system/dashbard/orderbook/add_order_screen.dart';

class OrderBookManagementScreen extends StatelessWidget {
  const OrderBookManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F6F6),
      body: SafeArea(
        child: Column(
          children: [
            /// ================= TOP ORANGE BAR =================
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: const BoxDecoration(
                color: Color(0xFFFFA54A),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(26),
                  bottomRight: Radius.circular(26),
                ),
              ),
              child: Column(
                children: [
                  /// SEARCH + ADD
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.search, color: Colors.grey),
                              SizedBox(width: 8),
                              Text(
                                "Search..",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            /// ================= ORDER LIST =================
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: const [OrderCard(), OrderCard()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===================================================================
/// ORDER CARD
/// ===================================================================

class OrderCard extends StatelessWidget {
  const OrderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// PRODUCT NAME
          _row("Product Name", "Saga White Posh"),

          const SizedBox(height: 6),

          /// SIZE + QUALITY
          Row(
            children: const [
              Expanded(
                child: Text("Size : 800x3000", style: TextStyle(fontSize: 13)),
              ),
              Text("Quality : 30", style: TextStyle(fontSize: 13)),
            ],
          ),

          const SizedBox(height: 6),

          /// DATE + QUANTITY
          Row(
            children: const [
              Expanded(
                child: Text(
                  "Date : 24/01/2026",
                  style: TextStyle(fontSize: 13),
                ),
              ),
              Text("Quantity : 30", style: TextStyle(fontSize: 13)),
            ],
          ),

          const SizedBox(height: 6),

          /// BRAND
          const Text("Brand : Simpolo", style: TextStyle(fontSize: 13)),

          const SizedBox(height: 14),

          /// BUTTONS
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddOrderScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                  label: const Text(
                    "Edit",
                    style: TextStyle(color: Colors.blue),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  label: const Text(
                    "Delete",
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return RichText(
      text: TextSpan(
        text: "$label : ",
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}
