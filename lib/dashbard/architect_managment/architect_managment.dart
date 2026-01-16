import 'package:flutter/material.dart';
import 'package:tcs_invantory_managment_system/dashbard/architect_managment/add_architect.dart';
import 'package:tcs_invantory_managment_system/dashbard/architect_managment/edit_architect.dart';

class ArchitectManagementScreen extends StatelessWidget {
  const ArchitectManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      /// ================= TOP ORANGE AREA =================
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            decoration: const BoxDecoration(
              color: Color(0xFFFFA54A),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  /// HEADER
                  const SizedBox(height: 14),

                  /// SEARCH + ADD
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Row(
                            children: const [
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
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddArchitectScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// ================= LIST =================
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: const [
                ArchitectCard(showOptions: true),
                ArchitectCard(),
                ArchitectCard(),
                ArchitectCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ===================================================================
/// ARCHITECT CARD (SAME TO SAME)
// ===================================================================

class ArchitectCard extends StatelessWidget {
  final bool showOptions;

  const ArchitectCard({super.key, this.showOptions = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// NAME + MENU
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Name : Sagar",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditArchitectScreen(isEdit: true),
                      ),
                    );
                  }
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text("Edit Architect Info"),
                      ),
                      if (showOptions)
                        const PopupMenuItem(
                          value: 'option1',
                          child: Text("Option 1"),
                        ),
                      if (showOptions)
                        const PopupMenuItem(
                          value: 'option2',
                          child: Text("Option 2"),
                        ),
                    ],
                icon: const Icon(Icons.more_vert, size: 18),
              ),
            ],
          ),

          const SizedBox(height: 6),

          /// WHATSAPP + COMMISSION
          Row(
            children: const [
              Expanded(
                child: Text(
                  "Whatsapp No. : +91 9876543210",
                  style: TextStyle(fontSize: 12.5),
                ),
              ),
              Text("Commission : 9%", style: TextStyle(fontSize: 12.5)),
            ],
          ),

          const SizedBox(height: 4),

          /// DOB + LOYALTY
          Row(
            children: const [
              Expanded(
                child: Text(
                  "Date Of Birth : 17/12/2000",
                  style: TextStyle(fontSize: 12.5),
                ),
              ),
              Text("Loyalty Points : 5", style: TextStyle(fontSize: 12.5)),
            ],
          ),
        ],
      ),
    );
  }
}
