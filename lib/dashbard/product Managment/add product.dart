import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

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

/// ================= ADD PRODUCT SHEET =================
class AddProductSheet extends StatefulWidget {
  const AddProductSheet({super.key});

  @override
  State<AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<AddProductSheet> {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://dashboarduat.theceramicstudio.in/api",
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
    ),
  );

  /// TEXT CONTROLLERS
  final productNameCtrl = TextEditingController();
  final sizeCtrl = TextEditingController();
  final rateCtrl = TextEditingController();
  final coverageCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();

  /// DROPDOWN DATA
  List<Map<String, dynamic>> brands = [];
  List<Map<String, dynamic>> qualities = [];
  List<Map<String, dynamic>> categories = [];

  int? selectedBrandId;
  String? selectedQuality;
  String? selectedCategory;

  bool dropdownLoading = true;
  bool loading = false;

  /// GODOWN - Fixed: Should be a String, not separate booleans
  List<String> selectedGodowns = [];

  /// BATCHES
  List<BatchForm> batchForms = [BatchForm()];

  @override
  void initState() {
    super.initState();
    fetchDropdowns();
  }

  @override
  void dispose() {
    // Dispose all controllers
    productNameCtrl.dispose();
    sizeCtrl.dispose();
    rateCtrl.dispose();
    coverageCtrl.dispose();
    descriptionCtrl.dispose();

    // Dispose batch controllers
    for (var batch in batchForms) {
      batch.batchNo.dispose();
      batch.qty.dispose();
      batch.location.dispose();
    }
    super.dispose();
  }

  /// ================= FETCH DROPDOWNS =================
  Future<void> fetchDropdowns() async {
    try {
      final res = await Future.wait([
        dio.get("/brands/list"),
        dio.get("/qualities/list"),
        dio.get("/categories/list"),
      ]);

      setState(() {
        brands =
            (res[0].data['brands'] as List?)
                ?.where((e) => e['status'] == "Available")
                .cast<Map<String, dynamic>>()
                .toList() ??
            [];

        qualities =
            (res[1].data['qualities'] as List?)
                ?.where((e) => e['status'] == "Available")
                .cast<Map<String, dynamic>>()
                .toList() ??
            [];

        categories =
            (res[2].data['categories'] as List?)
                ?.where((e) => e['status'] == "Available")
                .cast<Map<String, dynamic>>()
                .toList() ??
            [];
      });
    } catch (e) {
      debugPrint("Dropdown error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load dropdowns: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => dropdownLoading = false);
  }

  /// ================= VALIDATE FORM =================
  bool _validateForm() {
    if (productNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Product name is required")));
      return false;
    }
    if (sizeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Size is required")));
      return false;
    }
    if (selectedBrandId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Brand is required")));
      return false;
    }
    if (selectedQuality == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Quality is required")));
      return false;
    }
    if (selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Category is required")));
      return false;
    }
    if (rateCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Rate is required")));
      return false;
    }

    // Validate batches
    for (int i = 0; i < batchForms.length; i++) {
      final batch = batchForms[i];
      if (batch.batchNo.text.trim().isEmpty &&
          batch.qty.text.trim().isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Batch ${i + 1}: Batch number is required if quantity is provided",
            ),
          ),
        );
        return false;
      }
    }

    return true;
  }

  /// ================= ADD PRODUCT API =================
  Future<void> addProduct() async {
    if (!_validateForm()) return;

    setState(() => loading = true);

    // Prepare batches - only include if batchNo is provided
    final List<Map<String, dynamic>> batches = [];
    for (var batch in batchForms) {
      final batchNo = batch.batchNo.text.trim();
      final qty = batch.qty.text.trim();
      final location = batch.location.text.trim();

      if (batchNo.isNotEmpty) {
        batches.add({
          "batch_no": batchNo,
          "qty": int.tryParse(qty) ?? 0,
          "location": location,
        });
      }
    }

    final body = {
      "name": productNameCtrl.text.trim(),
      "size": sizeCtrl.text.trim(),
      "brand": selectedBrandId,
      "category": selectedCategory,
      "quality": selectedQuality,
      "rate": rateCtrl.text.trim(),
      "cov": coverageCtrl.text.trim(),
      "godown": selectedGodowns,
      "description": descriptionCtrl.text.trim(),
      "batches": batches,
    };

    debugPrint("Sending data: $body");

    try {
      final res = await dio.post(
        "/product/add",
        data: body,
        options: Options(headers: {"Content-Type": "application/json"}),
      );

      debugPrint("Response: ${res.data}");

      if (res.data['success'] == true) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.data['message'] ?? "Product added successfully"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.data['message'] ?? "Failed to add product"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("ADD ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to add product: ${e.toString()}"),
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
      child:
          dropdownLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Add Product",
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

                    const SizedBox(height: 10),

                    _label("Product Name *"),
                    _textField(productNameCtrl, hint: "Enter product name"),

                    _label("Size *"),
                    _textField(sizeCtrl, hint: "e.g., 600x1200"),

                    /// BRAND
                    _label("Brand Name *"),
                    DropdownButtonFormField<int>(
                      value: selectedBrandId,
                      items:
                          brands
                              .map<DropdownMenuItem<int>>(
                                (b) => DropdownMenuItem<int>(
                                  value: b['id'] as int,
                                  child: Text(b['name'] as String),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => selectedBrandId = v),
                      decoration: _decoration(),
                    ),

                    /// QUALITY
                    _label("Quality Grade *"),
                    DropdownButtonFormField<String>(
                      value: selectedQuality,
                      items:
                          qualities
                              .map<DropdownMenuItem<String>>(
                                (q) => DropdownMenuItem<String>(
                                  value: q['name'] as String,
                                  child: Text(q['name'] as String),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => selectedQuality = v),
                      decoration: _decoration(),
                    ),

                    /// CATEGORY
                    _label("Category *"),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items:
                          categories
                              .map<DropdownMenuItem<String>>(
                                (c) => DropdownMenuItem<String>(
                                  value: c['name'] as String,
                                  child: Text(c['name'] as String),
                                ),
                              )
                              .toList(),
                      onChanged: (v) {
                        setState(() {
                          selectedCategory = v;
                        });
                      },
                      decoration: _decoration(),
                    ),

                    _label("Rate *"),
                    _textField(
                      rateCtrl,
                      hint: "Enter rate",
                      type: TextInputType.number,
                    ),

                    _label("Godown"),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text("KKW"),
                          selected: selectedGodowns.contains("KKW"),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                selectedGodowns.add("KKW");
                              } else {
                                selectedGodowns.remove("KKW");
                              }
                            });
                          },
                        ),

                        FilterChip(
                          label: const Text("TCS"),
                          selected: selectedGodowns.contains("TCS"),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                selectedGodowns.add("TCS");
                              } else {
                                selectedGodowns.remove("TCS");
                              }
                            });
                          },
                        ),
                      ],
                    ),

                    _label("Coverage"),
                    _textField(coverageCtrl, hint: "Enter coverage area"),

                    _label("Description"),
                    _textField(
                      descriptionCtrl,
                      hint: "Enter product description",
                      maxLines: 3,
                    ),

                    const SizedBox(height: 14),
                    const Text(
                      "Stock Batches",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text("Add Batch"),
                        onPressed: () {
                          setState(() => batchForms.add(BatchForm()));
                        },
                      ),
                    ),

                    /// BATCH LIST
                    ...batchForms.asMap().entries.map((e) {
                      final i = e.key;
                      final b = e.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Batch ${i + 1}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _textField(
                                    b.batchNo,
                                    hint: "Batch No",
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _textField(
                                    b.qty,
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
                                    b.location,
                                    hint: "Location",
                                  ),
                                ),
                                if (batchForms.length > 1)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        b.batchNo.dispose();
                                        b.qty.dispose();
                                        b.location.dispose();
                                        batchForms.removeAt(i);
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffFFA54A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: loading ? null : addProduct,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 10,
                            ),
                            child:
                                loading
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : const Text("Save"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
    );
  }
}

/// ================= REUSABLE =================
InputDecoration _decoration({String? hint}) => InputDecoration(
  isDense: true,
  hintText: hint,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
);

Widget _label(String text) => Padding(
  padding: const EdgeInsets.only(top: 10, bottom: 4),
  child: Text(
    text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
  ),
);

Widget _textField(
  TextEditingController controller, {
  TextInputType type = TextInputType.text,
  String? hint,
  int maxLines = 1,
}) => TextField(
  controller: controller,
  keyboardType: type,
  maxLines: maxLines,
  decoration: InputDecoration(
    hintText: hint,
    isDense: true,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  ),
);
