import 'package:flutter/material.dart';

class InventoryManagementScreen extends StatelessWidget {
  const InventoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F6F6),

      /// TOP BAR
      body: SafeArea(
        child: Column(
          children: [
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
                    onTap: () => openAddInventorySheet(context),
                    child: Container(
                      height: 40,
                      width: 40,
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
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 4,
                itemBuilder: (_, i) => InventoryCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InventoryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TOP
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Bill no. 14-44",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'view') {
                    openInventoryView(context);
                  } else if (value == 'edit') {
                    openEditInventorySheet(context);
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
                          leading: Icon(Icons.edit),
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

          const SizedBox(height: 6),
          const Text("Pritesh Pawar"),
          const Text("+91 9876543210"),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Purchase Date: 17/12/2000"),
              Text("Sub Total: ₹1399", style: TextStyle(color: Colors.green)),
            ],
          ),
        ],
      ),
    );
  }
}

void openInventoryView(BuildContext context) {
  showDialog(
    context: context,
    builder:
        (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Purchase Details",
                      style: TextStyle(
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
                const Divider(),
                const Text("Bill no: 14-44"),
                const Text("Client: Pritesh Pawar"),
                const Text("Product ID: 1344"),
                const Text("Batch: 13"),
                const Text("Quantity: 44"),
                const Text("Rate: ₹195"),
                const Text("Total: ₹1399"),
                const Text("Godown: KKW"),
              ],
            ),
          ),
        ),
  );
}

void openAddInventorySheet(BuildContext context) {
  openInventorySheet(context, title: "Add Inventory");
}

void openEditInventorySheet(BuildContext context) {
  openInventorySheet(context, title: "Edit Inventory Info");
}

void openInventorySheet(BuildContext context, {required String title}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder:
        (_) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
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
                const SizedBox(height: 10),
                _tf("Purchase Date"),
                _tf("Bill Number"),
                _tf("Client Name"),
                _tf("Client Contact"),
                const SizedBox(height: 10),
                const Text(
                  "Add Product",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                _tf("Product"),
                _tf("Size"),
                _tf("Quality"),
                _tf("Rate"),
                _tf("Batch"),
                _tf("Quantity"),
                _tf("Total"),
                _tf("COV"),
                _tf("Godown"),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffFFA54A),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Save"),
                  ),
                ),
              ],
            ),
          ),
        ),
  );
}

Widget _tf(String hint) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: TextField(
    decoration: InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      isDense: true,
    ),
  ),
);

void showDeleteDialog(BuildContext context) {
  showDialog(
    context: context,
    builder:
        (_) => AlertDialog(
          title: const Text("Delete"),
          content: const Text("Delete this inventory?"),
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
