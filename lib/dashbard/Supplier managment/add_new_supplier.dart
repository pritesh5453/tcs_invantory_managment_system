import 'package:flutter/material.dart';

class AddNewSupplierScreen extends StatelessWidget {
  const AddNewSupplierScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  // Left Icon
                  const Icon(
                    Icons.person_add_alt_1,
                    size: 26,
                    color: Colors.purple,
                  ),

                  const SizedBox(width: 10),

                  const Text(
                    "Add New Supplier",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      size: 28,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Text(
                "Supplier Name",
                style: TextStyle(fontSize: 14,fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              TextField(
                decoration: InputDecoration(
                  hintText: "enter brand name..",
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                "Mobile Number",
                style: TextStyle(fontSize: 14,fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),

              TextField(
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: "enter Mobile Number",
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFA9C42),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Save",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}