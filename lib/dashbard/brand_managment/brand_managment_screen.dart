import 'package:flutter/material.dart';

class Brand {
  String name;
  bool isAvailable;

  Brand({required this.name, required this.isAvailable});
}

class BrandManagementScreen extends StatefulWidget {
  const BrandManagementScreen({super.key});

  @override
  State<BrandManagementScreen> createState() => _BrandManagementScreenState();
}

class _BrandManagementScreenState extends State<BrandManagementScreen> {
  List<Brand> brands = [
    Brand(name: "New Product 01", isAvailable: true),
    Brand(name: "New Product 02", isAvailable: false),
  ];

  /// 🔹 OPEN ADD / EDIT SHEET
  void openBrandSheet({Brand? brand, int? index}) {
    final nameController = TextEditingController(
      text: brand != null ? brand.name : "",
    );
    bool isAvailable = brand?.isAvailable ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// TITLE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        brand == null ? "Add New Brand" : "Edit Brand",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  /// BRAND NAME
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Brand Name",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// STATUS DROPDOWN
                  DropdownButtonFormField<bool>(
                    value: isAvailable,
                    items: const [
                      DropdownMenuItem(value: true, child: Text("Available")),
                      DropdownMenuItem(
                        value: false,
                        child: Text("Not Available"),
                      ),
                    ],
                    onChanged: (value) {
                      setModalState(() => isAvailable = value!);
                    },
                    decoration: const InputDecoration(
                      labelText: "Availability Status",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// SAVE BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffFFA54A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        if (brand == null) {
                          // ADD
                          setState(() {
                            brands.add(
                              Brand(
                                name: nameController.text,
                                isAvailable: isAvailable,
                              ),
                            );
                          });
                        } else {
                          // EDIT
                          setState(() {
                            brands[index!] = Brand(
                              name: nameController.text,
                              isAvailable: isAvailable,
                            );
                          });
                        }
                        Navigator.pop(context);
                      },
                      child: const Text("Save"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 🔹 DELETE BRAND
  void deleteBrand(int index) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Delete Brand"),
            content: const Text("Are you sure you want to delete this brand?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  setState(() => brands.removeAt(index));
                  Navigator.pop(context);
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F6F6),

      body: SafeArea(
        child: Column(
          children: [
            /// 🔶 TOP BAR
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xffFFA54A),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(26),
                  bottomRight: Radius.circular(26),
                ),
              ),
              child: Row(
                children: [
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
                  InkWell(
                    onTap: () {
                      openBrandSheet(); // 👈 add brand sheet उघडायला
                    },
                    child: Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            /// 🔶 LIST
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: brands.length,
                itemBuilder: (context, index) {
                  final brand = brands[index];
                  return BrandCard(
                    brand: brand,
                    onEdit: () => openBrandSheet(brand: brand, index: index),
                    onDelete: () => deleteBrand(index),
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

class BrandCard extends StatelessWidget {
  final Brand brand;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BrandCard({
    super.key,
    required this.brand,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// STATUS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color:
                  brand.isAvailable
                      ? Colors.green.shade100
                      : Colors.red.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              brand.isAvailable ? "Available" : "Not Available",
              style: TextStyle(
                fontSize: 12,
                color: brand.isAvailable ? Colors.green : Colors.red,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            "Brand Identity: ${brand.name}",
            style: const TextStyle(fontWeight: FontWeight.w600),
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
