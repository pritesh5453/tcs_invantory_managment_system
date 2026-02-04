import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'Product_Management.dart';

/// ================= EDIT PRODUCT SHEET =================
class EditProductSheet extends StatefulWidget {
  final int productId;
  final Product product;

  const EditProductSheet({
    super.key,
    required this.productId,
    required this.product,
  });

  @override
  State<EditProductSheet> createState() => _EditProductSheetState();
}

class _EditProductSheetState extends State<EditProductSheet> {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://dashboarduat.theceramicstudio.in/api",
      headers: {"Accept": "application/json"},
    ),
  );

  late TextEditingController productNameCtrl;
  late TextEditingController sizeCtrl;
  late TextEditingController brandCtrl;
  late TextEditingController rateCtrl;
  late TextEditingController coverageCtrl;

  String selectedQuality = "";
  String selectedCategory = "";
  String selectedStatus = "";

  bool godownKKW = false;
  bool godownMN = false;
  bool godownTCS = false;

  bool loading = false;

  @override
  void initState() {
    super.initState();

    /// PREFILL DATA
    productNameCtrl = TextEditingController(text: widget.product.name);
    sizeCtrl = TextEditingController(text: widget.product.size ?? "");
    brandCtrl = TextEditingController(text: widget.product.brand ?? "");
    rateCtrl = TextEditingController(text: widget.product.rate);
    coverageCtrl = TextEditingController(text: widget.product.cov ?? "");

    selectedQuality = widget.product.quality;
    selectedCategory = widget.product.category;
    selectedStatus = widget.product.availQty > 0 ? "In Stock" : "Out of Stock";

    final godowns = widget.product.godown.split(",");
    godownKKW = godowns.contains("KKW");
    godownMN = godowns.contains("MN");
    godownTCS = godowns.contains("TCS");
  }

  /// ================= UPDATE API =================
  Future<void> updateProduct() async {
    setState(() => loading = true);

    final godownList = <String>[];
    if (godownKKW) godownList.add("KKW");
    if (godownMN) godownList.add("MN");
    if (godownTCS) godownList.add("TCS");

    final body = {
      "name": productNameCtrl.text.trim(),
      "size": sizeCtrl.text.trim(),
      "brand": brandCtrl.text.trim(),
      "category": selectedCategory,
      "quality": selectedQuality,
      "rate": rateCtrl.text.trim(),
      "status": "",
      "link": "",
      "godown": godownList.join(","),
      "description": "",
      "cov": coverageCtrl.text.trim(),
      "image": widget.product.image,
      "availQty": widget.product.availQty,
      "batches": widget.product.batches,
    };

    try {
      final res = await dio.put(
        "/product/products/${widget.productId}",
        data: body,
      );

      if (res.data['success'] == true) {
        Navigator.pop(context, true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.data['message']),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("UPDATE ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Update failed"),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => loading = false);
  }

  /// ================= UI =================
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
              items: const ["PREMIUM", "COMMERCIAL", "PROJECT"],
              onChanged: (v) => setState(() => selectedQuality = v!),
            ),

            _label("Category *"),
            _dropdown(
              value: selectedCategory,
              items: const ["TILES", "ADHESIVE", "MARBLE"],
              onChanged: (v) => setState(() => selectedCategory = v!),
            ),

            _label("Rate *"),
            _textField(controller: rateCtrl, type: TextInputType.number),

            _label("Status"),
            Text(selectedStatus),

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

            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffFFA54A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: loading ? null : updateProduct,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 10,
                  ),
                  child:
                      loading
                          ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text("Update"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ================= REUSABLE =================
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
