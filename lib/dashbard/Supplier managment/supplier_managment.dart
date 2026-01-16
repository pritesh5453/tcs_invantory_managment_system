import 'package:flutter/material.dart';
import 'add_new_supplier.dart';

class SupplierManagementScreen extends StatefulWidget {
  const SupplierManagementScreen({super.key});

  @override
  State<SupplierManagementScreen> createState() =>
      _SupplierManagementScreenState();
}

class _SupplierManagementScreenState extends State<SupplierManagementScreen> {
  List<Map<String, String>> suppliers = [
    {"name": "Pritesh Pawar", "mobile": "+91 8552011102"},
    {"name": "Pritesh Pawar", "mobile": "+91 8552011102"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            /// 🔶 HEADER
            Container(
              height: 120, // ⭐ IMPORTANT FIX
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: const BoxDecoration(
                color: Color(0xffFFA54A),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(26),
                  bottomRight: Radius.circular(26),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      /// 🔍 SEARCH BAR
                      Expanded(
                        child: Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
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

                      /// ➕ ADD BUTTON
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddNewSupplierScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          height: 46,
                          width: 46,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 1.5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            /// 📋 SUPPLIER LIST
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: suppliers.length,
                itemBuilder: (context, index) {
                  final supplier = suppliers[index];
                  return SupplierCard(
                    index: index + 1,
                    name: supplier["name"]!,
                    mobile: supplier["mobile"]!,
                    onEdit: () async {
                      final updatedSupplier =
                          await Navigator.push<Map<String, String>>(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => EditSupplierScreen(
                                    index: index + 1,
                                    name: supplier["name"]!,
                                    mobile: supplier["mobile"]!,
                                  ),
                            ),
                          );

                      if (updatedSupplier != null) {
                        setState(() {
                          suppliers[index] = updatedSupplier;
                        });
                      }
                    },
                    onDelete: () {
                      setState(() {
                        suppliers.removeAt(index);
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🧾 SUPPLIER CARD
class SupplierCard extends StatelessWidget {
  final int index;
  final String name;
  final String mobile;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SupplierCard({
    super.key,
    required this.index,
    required this.name,
    required this.mobile,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Index: ${index.toString().padLeft(2, '0')}",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              text: "Supplier Name : ",
              style: const TextStyle(fontSize: 14, color: Colors.black),
              children: [
                TextSpan(
                  text: name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              text: "Mobile number : ",
              style: const TextStyle(fontSize: 14, color: Colors.black),
              children: [
                TextSpan(
                  text: mobile,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 18),
                label: const Text("Edit"),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: onDelete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text("Delete"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ✏️ EDIT SUPPLIER SCREEN
class EditSupplierScreen extends StatelessWidget {
  final int index;
  final String name;
  final String mobile;

  const EditSupplierScreen({
    super.key,
    required this.index,
    required this.name,
    required this.mobile,
  });

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController(text: name);
    final mobileController = TextEditingController(text: mobile);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit),
                  const SizedBox(width: 8),
                  const Text(
                    "Edit Supplier Info",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Text(
                "Supplier Name",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                "Mobile Number",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: mobileController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      "name": nameController.text,
                      "mobile": mobileController.text,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFA9C42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text("Save"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
