import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'Product_Management.dart';

/// ================= BATCH FORM MODEL =================
class BatchForm {
  final TextEditingController batchNo;
  final TextEditingController qty;
  final TextEditingController location;

  BatchForm({String batchNo = "", String qty = "", String location = ""})
    : batchNo = TextEditingController(text: batchNo),
      qty = TextEditingController(text: qty),
      location = TextEditingController(text: location);
}

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
      baseUrl: "https://dashboard.theceramicstudio.in/api",
      headers: {"Accept": "application/json"},
    ),
  );

  late TextEditingController productNameCtrl;
  late TextEditingController sizeCtrl;
  late TextEditingController rateCtrl;
  late TextEditingController coverageCtrl;

  /// DROPDOWN DATA
  List<Map<String, dynamic>> brands = [];
  List<Map<String, dynamic>> qualities = [];
  List<Map<String, dynamic>> categories = [];

  String? selectedBrand;
  String? selectedQuality;
  String? selectedCategory;

  bool godownKKW = false;
  bool godownTCS = false;

  bool loading = true;
  bool saving = false;

  List<BatchForm> batchForms = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  /// ================= INITIALIZE DATA =================
  Future<void> _initData() async {
    try {
      // Fetch all dropdown data in parallel
      await Future.wait([
        _fetchBrands(),
        _fetchQualities(),
        _fetchCategories(),
      ]);

      // Prefill form data after dropdowns are loaded
      _prefillForm();

      setState(() => loading = false);
    } catch (e) {
      debugPrint("Initialization error: $e");
      setState(() => loading = false);
    }
  }

  /// ================= FETCH BRANDS =================
  Future<void> _fetchBrands() async {
    try {
      final response = await dio.get("/brands/list");
      if (response.data['success'] == true) {
        setState(() {
          brands =
              (response.data['brands'] as List)
                  .where((brand) => brand['status'] == "Available")
                  .cast<Map<String, dynamic>>()
                  .toList();
        });
      }
    } catch (e) {
      debugPrint("Brands fetch error: $e");
    }
  }

  /// ================= FETCH QUALITIES =================
  Future<void> _fetchQualities() async {
    try {
      final response = await dio.get("/qualities/list");
      if (response.data['success'] == true) {
        setState(() {
          qualities =
              (response.data['qualities'] as List)
                  .where((quality) => quality['status'] == "Available")
                  .cast<Map<String, dynamic>>()
                  .toList();
        });
      }
    } catch (e) {
      debugPrint("Qualities fetch error: $e");
    }
  }

  /// ================= FETCH CATEGORIES =================
  Future<void> _fetchCategories() async {
    try {
      final response = await dio.get("/categories/list");
      if (response.data['success'] == true) {
        setState(() {
          categories =
              (response.data['categories'] as List)
                  .where((category) => category['status'] == "Available")
                  .cast<Map<String, dynamic>>()
                  .toList();
        });
      }
    } catch (e) {
      debugPrint("Categories fetch error: $e");
    }
  }

  /// ================= PREFILL FORM =================
  void _prefillForm() {
    // Initialize text controllers
    productNameCtrl = TextEditingController(text: widget.product.name);
    sizeCtrl = TextEditingController(text: widget.product.size);
    rateCtrl = TextEditingController(text: widget.product.rate);
    coverageCtrl = TextEditingController(text: widget.product.cov);

    // Helper function to check if value is integer
    bool isInteger(String? value) {
      if (value == null || value.isEmpty) return false;
      return int.tryParse(value) != null;
    }

    // Set selected dropdown values with integer handling
    // Brand: if value is integer or empty, set to null
    selectedBrand =
        (widget.product.brand != null &&
                widget.product.brand!.isNotEmpty &&
                !isInteger(widget.product.brand!))
            ? widget.product.brand
            : null;

    // Quality: if value is integer or empty, set to null
    selectedQuality =
        (widget.product.quality != null &&
                widget.product.quality!.isNotEmpty &&
                !isInteger(widget.product.quality!))
            ? widget.product.quality
            : null;

    // Category: if value is integer or empty, set to null
    selectedCategory =
        (widget.product.category != null &&
                widget.product.category!.isNotEmpty &&
                !isInteger(widget.product.category!))
            ? widget.product.category
            : null;

    /// ===== GODOWN PREFILL =====
    final godowns = widget.product.godown.split(",");
    godownKKW = godowns.contains("KKW");
    godownTCS = godowns.contains("TCS");

    /// ===== BATCHES PREFILL =====
    if (widget.product.batches.isNotEmpty) {
      for (final b in widget.product.batches) {
        batchForms.add(
          BatchForm(
            batchNo: b['batch_no']?.toString() ?? "",
            qty: b['qty']?.toString() ?? "",
            location: b['location']?.toString() ?? "",
          ),
        );
      }
    } else {
      batchForms.add(BatchForm());
    }
  }

  /// ================= UPDATE API =================
  Future<void> updateProduct() async {
    setState(() => saving = true);

    final godownList = <String>[];
    if (godownKKW) godownList.add("KKW");
    if (godownTCS) godownList.add("TCS");

    final body = {
      "name": productNameCtrl.text.trim(),
      "size": sizeCtrl.text.trim(),
      "brand": selectedBrand,
      "category": selectedCategory,
      "quality": selectedQuality,
      "rate": rateCtrl.text.trim(),
      "status": "",
      "link": "",
      "cov": coverageCtrl.text.trim(),
      "godown": godownList,
      "description": "",
      "batches":
          batchForms
              .map(
                (b) => {
                  "batchNo": b.batchNo.text.trim(),
                  "qty": b.qty.text.trim(),
                  "location": b.location.text.trim(),
                },
              )
              .toList(),
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

    setState(() => saving = false);
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

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

            _label("Product Name"),
            _textField(controller: productNameCtrl),

            _label("Size"),
            _textField(controller: sizeCtrl),

            /// BRAND DROPDOWN FROM API
            _label("Brand"),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedBrand,
                  isExpanded: true,
                  hint: const Text("Select Brand"),
                  items:
                      brands.map<DropdownMenuItem<String>>((brand) {
                        return DropdownMenuItem<String>(
                          value: brand['name'],
                          child: Text(brand['name']),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedBrand = value;
                    });
                  },
                ),
              ),
            ),

            /// QUALITY DROPDOWN FROM API
            _label("Quality"),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedQuality,
                  isExpanded: true,
                  hint: const Text("Select Quality"),
                  items:
                      qualities.map<DropdownMenuItem<String>>((quality) {
                        return DropdownMenuItem<String>(
                          value: quality['name'],
                          child: Text(quality['name']),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedQuality = value;
                    });
                  },
                ),
              ),
            ),

            /// CATEGORY DROPDOWN FROM API
            _label("Category"),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedCategory,
                  isExpanded: true,
                  hint: const Text("Select Category"),
                  items:
                      categories.map<DropdownMenuItem<String>>((category) {
                        return DropdownMenuItem<String>(
                          value: category['name'],
                          child: Text(category['name']),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                    });
                  },
                ),
              ),
            ),

            _label("Rate"),
            _textField(controller: rateCtrl, type: TextInputType.number),

            _label("Godown"),
            Row(
              children: [
                _checkBox(
                  "KKW",
                  godownKKW,
                  (v) => setState(() => godownKKW = v),
                ),
                _checkBox(
                  "TCS",
                  godownTCS,
                  (v) => setState(() => godownTCS = v),
                ),
              ],
            ),

            _label("Product Cov"),
            _textField(controller: coverageCtrl),

            const SizedBox(height: 12),
            const Text(
              "Stock Batches",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    batchForms.add(BatchForm());
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text("Add Batch"),
              ),
            ),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: batchForms.length,
              itemBuilder: (_, i) {
                final b = batchForms[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _textField(
                              controller: b.batchNo,
                              hint: "Batch No",
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _textField(
                              controller: b.qty,
                              hint: "Qty",
                              type: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _textField(
                              controller: b.location,
                              hint: "Location",
                            ),
                          ),
                          if (batchForms.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  batchForms.removeAt(i);
                                });
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
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
                onPressed: saving ? null : updateProduct,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 10,
                  ),
                  child:
                      saving
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

/// ================= HELPERS =================
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
  String? hint,
}) => TextField(
  controller: controller,
  keyboardType: type,
  decoration: InputDecoration(
    hintText: hint,
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
