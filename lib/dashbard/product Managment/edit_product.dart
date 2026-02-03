import 'package:flutter/material.dart';

/// ================= EDIT PRODUCT SHEET =================
class EditProductSheet extends StatefulWidget {
  const EditProductSheet({super.key});

  @override
  State<EditProductSheet> createState() => _EditProductSheetState();
}

class _EditProductSheetState extends State<EditProductSheet> {
  /// Controllers (normally API se prefill karoge)
  final TextEditingController productNameCtrl = TextEditingController(
    text: "Sagar Marble",
  );
  final TextEditingController sizeCtrl = TextEditingController(
    text: "600x1200",
  );
  final TextEditingController brandCtrl = TextEditingController(text: "Somany");
  final TextEditingController rateCtrl = TextEditingController(text: "150");
  final TextEditingController coverageCtrl = TextEditingController(
    text: "15.5",
  );

  String selectedQuality = "Premium";
  String selectedCategory = "Marble";
  String selectedStatus = "In Stock";

  bool godownKKW = true;
  bool godownMN = false;
  bool godownTCS = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Edit Product",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            _label("Product Name *"),
            _textField(controller: productNameCtrl),

            _label("Product Size *"),
            _textField(controller: sizeCtrl),

            _label("Brand Name *"),
            _textField(controller: brandCtrl),

            _label("Quality *"),
            _dropdown(
              value: selectedQuality,
              items: const ["Premium", "Standard", "Economy"],
              onChanged: (v) => setState(() => selectedQuality = v!),
            ),

            _label("Category *"),
            _dropdown(
              value: selectedCategory,
              items: const ["Marble", "Tiles", "Granite"],
              onChanged: (v) => setState(() => selectedCategory = v!),
            ),

            _label("Rate *"),
            _textField(controller: rateCtrl, type: TextInputType.number),

            _label("Status *"),
            _dropdown(
              value: selectedStatus,
              items: const ["In Stock", "Out of Stock"],
              onChanged: (v) => setState(() => selectedStatus = v!),
            ),

            _label("Godown"),
            Row(
              children: [
                _checkBox(
                  "KKW",
                  godownKKW,
                  (v) => setState(() => godownKKW = v),
                ),
                _checkBox("MN", godownMN, (v) => setState(() => godownMN = v)),
                _checkBox(
                  "TCS",
                  godownTCS,
                  (v) => setState(() => godownTCS = v),
                ),
              ],
            ),

            _label("Coverage Product"),
            _textField(controller: coverageCtrl),

            const SizedBox(height: 16),

            /// UPDATE BUTTON
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffFFA54A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  /// 👉 Yaha UPDATE PRODUCT API lagegi
                  Navigator.pop(context);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  child: Text("Update"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ================= REUSABLE WIDGETS =================

Widget _label(String text) => Padding(
  padding: const EdgeInsets.only(top: 10, bottom: 4),
  child: Text(
    text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
  ),
);

Widget _textField({
  required TextEditingController controller,
  TextInputType type = TextInputType.text,
}) => TextField(
  controller: controller,
  keyboardType: type,
  decoration: InputDecoration(
    isDense: true,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  ),
);

Widget _dropdown({
  required String value,
  required List<String> items,
  required ValueChanged<String?> onChanged,
}) => DropdownButtonFormField<String>(
  value: value,
  items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
  onChanged: onChanged,
  decoration: InputDecoration(
    isDense: true,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  ),
);

Widget _checkBox(String label, bool value, ValueChanged<bool> onChanged) => Row(
  children: [
    Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
    Text(label),
  ],
);
