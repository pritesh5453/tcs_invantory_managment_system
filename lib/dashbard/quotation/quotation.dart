import 'package:flutter/material.dart';
import 'package:tcs_invantory_managment_system/dashbard/quotation/add_quotation.dart';
import 'package:tcs_invantory_managment_system/dashbard/quotation/dispatch_challan.dart';
import 'package:tcs_invantory_managment_system/dashbard/quotation/edit_quotation.dart';
import 'package:tcs_invantory_managment_system/dashbard/quotation/settlement.dart';

class Quontation_home_screen extends StatefulWidget {
  const Quontation_home_screen({super.key});

  @override
  State<Quontation_home_screen> createState() => _Quontation_home_screenState();
}

class _Quontation_home_screenState extends State<Quontation_home_screen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Header_ui(),
            SizedBox(height: 20),
            InvoiceCard(),
            InvoiceCard(),
          ],
        ),
      ),
    );
  }
}

class Header_ui extends StatelessWidget {
  const Header_ui({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: const Color(0xFFFFA54A),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search..",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Addquotationscreen(),
                      ),
                    );
                  },
                  child: Container(
                    height: 45,
                    width: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFA9C42),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class InvoiceCard extends StatelessWidget {
  const InvoiceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE7F7E9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Active",
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Pritesh Pawar",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Text("06/01/2026", style: TextStyle(color: Colors.grey)),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              amountColumn("Grand Total", "₹90,000"),
              divider(),
              amountColumn("Paid Amount", "₹00.00"),
              divider(),
              amountColumn("Due Amount", "₹90,000", valueColor: Colors.orange),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              /// Edit Button
              OutlinedButton.icon(
                icon: Icon(Icons.edit, color: Colors.blue),
                label: Text("Edit", style: TextStyle(color: Colors.blue)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.blue), // Outline color
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              EditQuotationScreen(), // Replace with your screen
                    ),
                  );
                },
              ),

              // const SizedBox(width: 10),
              Spacer(flex: 1),

              /// Pay Button
              outlinedButton(
                icon: Icons.credit_card,
                label: "Pay",
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettlementScreen(),
                    ),
                  );
                },
              ),

              Spacer(flex: 1),

              PopupMenuButton<String>(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == "delivery_chalan") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DispatchChallanScreen(),
                      ),
                    );
                  }
                },
                itemBuilder:
                    (context) => const [
                      PopupMenuItem(
                        value: "delivery_chalan",
                        child: Text("Delivery Chalan"),
                      ),
                      PopupMenuItem(value: "code", child: Text("Code")),
                      PopupMenuItem(value: "name", child: Text("Name")),
                    ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Text("More"),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget amountColumn(
    String title,
    String value, {
    Color valueColor = Colors.black,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  static Widget divider() {
    return Container(height: 36, width: 1, color: Colors.grey.shade300);
  }

  static Widget outlinedButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }
}
