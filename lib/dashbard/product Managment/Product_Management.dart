import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ImagePickerTest extends StatefulWidget {
  const ImagePickerTest({super.key});

  @override
  State<ImagePickerTest> createState() => _ImagePickerTestState();
}

class _ImagePickerTestState extends State<ImagePickerTest> {
  File? image;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final XFile? img = await picker.pickImage(source: ImageSource.gallery);

    if (img != null) {
      setState(() {
        image = File(img.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Image Picker Test")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: pickImage,
            child: Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child:
                  image == null
                      ? const Center(child: Text("Tap to Pick Image"))
                      : Image.file(image!, fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }
}

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
              child: Column(
                children: [
                  // Row(
                  //   children: const [
                  //     Icon(Icons.menu),
                  //     SizedBox(width: 12),
                  // Text(
                  //   "Product Registration",
                  //   style: TextStyle(
                  //     fontSize: 18,
                  //     fontWeight: FontWeight.w600,
                  //   ),
                  // ),
                  //   ],
                  //   ),
                  const SizedBox(height: 14),
                  Row(
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
                        onTap: () => openAddProductSheet(context),
                        child: Container(
                          height: 46,
                          width: 46,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 1.5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// LIST
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [ProductCard(), ProductCard()],
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
                // icon: const Icon(Icons.more_vert),
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
                  } else if (value == 'barcode') {
                    showBarcodeDialog(context);
                  } else if (value == 'qr') {
                    showQrDialog(context);
                  } else if (value == 'delete') {
                    showDeleteDialog(context);
                  }
                },
                itemBuilder:
                    (context) => const [
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
                        value: 'barcode',
                        child: ListTile(
                          leading: Icon(Icons.barcode_reader),
                          title: Text("Barcode"),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'qr',
                        child: ListTile(
                          leading: Icon(Icons.qr_code),
                          title: Text("QR Code"),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [Text("Quality: Premium"), Text("Godown: KKW")],
          ),

          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [Text("Batches: 2"), Text("Total Qty: 120")],
          ),

          const Align(
            alignment: Alignment.centerRight,
            child: Icon(Icons.keyboard_arrow_down),
          ),
        ],
      ),
    );
  }
}

/// ================= ADD PRODUCT SHEET =================
void openAddProductSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return Container(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Add Product",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              _label("Product Image *"),
              _uploadBox(),

              _label("Product Name *"),
              _textField(),

              _label("Product Size *"),
              _textField(),

              _label("Brand Name *"),
              _textField(),

              _label("Quality *"),
              _dropdown(),

              _label("Category *"),
              _dropdown(),

              _label("Rate *"),
              _textField(type: TextInputType.number),

              _label("Status *"),
              _dropdown(),

              _label("Godown"),
              Row(
                children: [_CheckBox("KKW"), _CheckBox("MN"), _CheckBox("TCS")],
              ),

              _label("Coverage Product*"),
              _textField(),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: const [
                        Expanded(child: Text("Batch Number")),
                        SizedBox(width: 10),
                        Expanded(child: Text("Quantity")),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: _textField(type: TextInputType.number)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: _textField(type: TextInputType.number),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.add_circle_outline),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Expanded(child: Text("Location")),
                        SizedBox(width: 10),
                        Expanded(child: Text("Action")),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: _textField()),
                        const SizedBox(width: 10),
                        const Icon(Icons.add_circle_outline),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffFFA54A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Text("Save"),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// ================= HELPERS =================
Widget _label(String text) => Padding(
  padding: const EdgeInsets.only(top: 10, bottom: 4),
  child: Text(
    text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
  ),
);

Widget _textField({TextInputType type = TextInputType.text}) => TextField(
  keyboardType: type,
  decoration: InputDecoration(
    hintText: "Text..",
    isDense: true,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  ),
);

Widget _dropdown() => DropdownButtonFormField(
  items: const [],
  onChanged: (v) {},
  decoration: InputDecoration(
    hintText: "Select",
    isDense: true,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  ),
);

Widget _uploadBox() => Container(
  height: 42,
  padding: const EdgeInsets.symmetric(horizontal: 12),
  decoration: BoxDecoration(
    border: Border.all(color: Colors.grey),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: const [Text("Upload..."), Icon(Icons.upload)],
  ),
);

class _CheckBox extends StatelessWidget {
  final String label;
  const _CheckBox(this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [Checkbox(value: false, onChanged: (v) {}), Text(label)],
    );
  }
}

///
/////
void showBarcodeDialog(BuildContext context) {
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Barcode",
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
                const SizedBox(height: 12),
                const Icon(Icons.barcode_reader, size: 80),
                const SizedBox(height: 8),
                const Text("test3"),
              ],
            ),
          ),
        ),
  );
}

//
void showQrDialog(BuildContext context) {
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "QR Code",
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
                const SizedBox(height: 12),
                const Icon(Icons.qr_code, size: 120),
                const SizedBox(height: 8),
                const Text("gajre.ramesh@gmail.com"),
              ],
            ),
          ),
        ),
  );
}

///
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
              onPressed: () {
                Navigator.pop(context);
                // later: setState करून delete logic टाकशील
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
  );
}
//

void openEditProductSheet(BuildContext context) {
  openAddProductSheet(context);
}

//////////////////-----------

class ProductViewScreen extends StatelessWidget {
  const ProductViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xffFFA54A),
        title: const Text("Product Details"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// IMAGE
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  "assets/images/marble.png",
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 14),

              _info("Name", "Sagar Marbel"),
              _info("Category", "Marbel"),
              _info("Brand", "Somany"),
              _info("Rate", "₹150"),

              const SizedBox(height: 8),
              const Text(
                "Batch Details:",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const Text("Batch1: Qty=0, Loc=NSK"),
              const Text("Batch2: Qty=0, Loc=NSK"),

              const SizedBox(height: 8),
              _info("Quality", "Premium"),
              _info("Godown", "KKW"),

              const SizedBox(height: 16),

              /// BARCODE + QR
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  Column(
                    children: [
                      Icon(Icons.barcode_reader, size: 80),
                      SizedBox(height: 4),
                      Text("test3"),
                    ],
                  ),
                  Column(
                    children: [
                      Icon(Icons.qr_code, size: 80),
                      SizedBox(height: 4),
                      Text("gajre.ramesh@gmail.com"),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

////
