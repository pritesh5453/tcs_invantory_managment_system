import 'package:flutter/material.dart';
import 'package:tcs_invantory_managment_system/dashbard/product%20Managment/add%20product.dart';
import 'package:tcs_invantory_managment_system/dashbard/product%20Managment/edit_product.dart';
import 'package:tcs_invantory_managment_system/dashbard/product%20Managment/view_preducts_screen.dart';

/// ================= SCREEN =================
class ProductRegistrationScreen extends StatelessWidget {
  const ProductRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F6F6),
      body: SafeArea(
        child: Column(
          children: [
            /// TOP BAR
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
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
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, size: 20, color: Colors.grey),
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
                      openAddProductSheet(context);
                    },
                    child: Container(
                      height: 42,
                      width: 42,
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

            /// LIST
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: const [ProductCard(), ProductCard()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ================= PRODUCT CARD =================
class ProductCard extends StatelessWidget {
  const ProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TOP ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "In Stock",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'view') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProductViewScreen(),
                      ),
                    );
                  } else if (value == 'edit') {
                    openEditProductSheet(context);
                  } else if (value == 'delete') {
                    showDeleteDialog(context);
                  }
                },
                itemBuilder:
                    (_) => const [
                      PopupMenuItem(
                        value: 'view',
                        child: ListTile(
                          leading: Icon(Icons.visibility),
                          title: Text("View"),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit, color: Colors.blue),
                          title: Text("Edit"),
                        ),
                      ),

                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text(
                            "Delete",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// IMAGE + DETAILS
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: const DecorationImage(
                    image: AssetImage("assets/images/marble.png"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Sagar Marbel",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text("Category: Marbel"),
                    Text("Brand: Somany"),
                    Text("Rate: ₹150"),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text("Quality: Premium"), Text("Godown: KKW")],
          ),

          const SizedBox(height: 6),

          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text("Batches: 2"), Text("Total Qty: 120")],
          ),
        ],
      ),
    );
  }
}

/// ================= Add Product =================
void openAddProductSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const AddProductSheet(),
  );
}

/// ================= Edit Product =================

void openEditProductSheet(BuildContext context) {
  debugPrint("EDIT SHEET OPEN");
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const EditProductSheet(),
  );
}

/// ================= DIALOGS =================

void showDeleteDialog(BuildContext context) {
  showDialog(
    context: context,
    builder:
        (_) => AlertDialog(
          title: const Text("Delete Product"),
          content: const Text("Are you sure you want to delete this product?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
  );
}
