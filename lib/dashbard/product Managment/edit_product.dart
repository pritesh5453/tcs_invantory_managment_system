import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart'; // ADDED
import 'dart:io'; // ADDED
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
  late TextEditingController descriptionCtrl; // ADDED - for description

  /// DROPDOWN DATA
  List<Map<String, dynamic>> brands = [];
  List<Map<String, dynamic>> qualities = [];
  List<Map<String, dynamic>> categories = [];

  // Store product's original values
  String? originalBrand;
  String? originalQuality;
  String? originalCategory;

  String? selectedBrand;
  String? selectedQuality;
  String? selectedCategory;

  bool godownKKW = false;
  bool godownTCS = false;

  bool loading = true;
  bool saving = false;

  List<BatchForm> batchForms = [];

  /// IMAGE PICKER - ADDED
  File? _imageFile;
  String? _existingImageUrl; // To store the current product image URL
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    productNameCtrl.dispose();
    sizeCtrl.dispose();
    rateCtrl.dispose();
    coverageCtrl.dispose();
    descriptionCtrl.dispose(); // ADDED
    for (var batch in batchForms) {
      batch.batchNo.dispose();
      batch.qty.dispose();
      batch.location.dispose();
    }
    super.dispose();
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
    descriptionCtrl =
        TextEditingController(); // ADDED - handle if description exists

    // Store existing image URL if available - ADDED
    _existingImageUrl = widget.product.imageUrl;

    // Store original values
    originalBrand = widget.product.brand;
    originalQuality = widget.product.quality;
    originalCategory = widget.product.category;

    // Check if values exist in dropdown lists
    // BRAND: Only select if value exists in brands list
    if (originalBrand != null && originalBrand!.isNotEmpty) {
      final brandExists = brands.any((brand) => brand['name'] == originalBrand);
      if (brandExists) {
        selectedBrand = originalBrand;
      } else {
        selectedBrand = null; // Don't select if not in list
      }
    }

    // QUALITY: Only select if value exists in qualities list
    if (originalQuality != null && originalQuality!.isNotEmpty) {
      final qualityExists = qualities.any(
        (quality) => quality['name'] == originalQuality,
      );
      if (qualityExists) {
        selectedQuality = originalQuality;
      } else {
        selectedQuality = null; // Don't select if not in list
      }
    }

    // CATEGORY: Only select if value exists in categories list
    if (originalCategory != null && originalCategory!.isNotEmpty) {
      final categoryExists = categories.any(
        (category) => category['name'] == originalCategory,
      );
      if (categoryExists) {
        selectedCategory = originalCategory;
      } else {
        selectedCategory = null; // Don't select if not in list
      }
    }

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

  /// ================= IMAGE PICKER METHODS - ADDED =================
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // optional compression
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _existingImageUrl = null; // Clear existing URL when new image is picked
      });
    }
  }

  /// ================= UPDATE API =================
  Future<void> updateProduct() async {
    setState(() => saving = true);

    final godownList = <String>[];
    if (godownKKW) godownList.add("KKW");
    if (godownTCS) godownList.add("TCS");

    // Decide which value to send:
    // 1. If user selected something from dropdown, use that
    // 2. Else, use original value from product
    final brandToSend = selectedBrand ?? originalBrand;
    final qualityToSend = selectedQuality ?? originalQuality;
    final categoryToSend = selectedCategory ?? originalCategory;

    // Prepare batches
    final List<Map<String, dynamic>> batches = [];
    for (var batch in batchForms) {
      final batchNo = batch.batchNo.text.trim();
      final qty = batch.qty.text.trim();
      final location = batch.location.text.trim();

      if (batchNo.isNotEmpty) {
        batches.add({
          "batchNo": batchNo,
          "qty": int.tryParse(qty) ?? 0,
          "location": location,
        });
      }
    }

    // Build FormData for multipart request - MODIFIED
    final formData = FormData.fromMap({
      "name": productNameCtrl.text.trim(),
      "size": sizeCtrl.text.trim(),
      "brand": brandToSend,
      "category": categoryToSend,
      "quality": qualityToSend,
      "rate": rateCtrl.text.trim(),
      "status": "",
      "link": "",
      "cov": coverageCtrl.text.trim(),
      "godown": godownList,
      "description": descriptionCtrl.text.trim(),
      "batches": batches,
    });

    // Attach image if selected - ADDED
    if (_imageFile != null) {
      formData.files.add(
        MapEntry(
          "image", // Field name for the image
          await MultipartFile.fromFile(
            _imageFile!.path,
            filename: _imageFile!.path.split('/').last,
          ),
        ),
      );
    }
    // If no new image but we want to keep existing image, we don't send image field
    // The API should preserve the existing image if no new image is sent

    try {
      final res = await dio.put(
        "/product/products/${widget.productId}",
        data: formData,
        options: Options(
          headers: {
            "Accept": "application/json",
            // Content-Type will be set automatically for multipart
          },
        ),
      );

      if (res.data['success'] == true) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res.data['message'] ?? "Product updated successfully",
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.data['message'] ?? "Failed to update product"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("UPDATE ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Update failed: ${e.toString()}"),
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

            /// PRODUCT IMAGE SECTION - ADDED
            _label("Product Image"),
            Row(
              children: [
                // Image display
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _buildImagePreview(),
                ),
                const SizedBox(width: 12),
                // Image picker buttons
                Expanded(
                  child: Column(
                    children: [
                      TextButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_library),
                        label: const Text("Change Image"),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

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
                  hint: Text(
                    originalBrand != null && originalBrand!.isNotEmpty
                        ? "Original: $originalBrand"
                        : "Select Brand",
                  ),
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
                  hint: Text(
                    originalQuality != null && originalQuality!.isNotEmpty
                        ? "Original: $originalQuality"
                        : "Select Quality",
                  ),
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
                  hint: Text(
                    originalCategory != null && originalCategory!.isNotEmpty
                        ? "Original: $originalCategory"
                        : "Select Category",
                  ),
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

            _label("Coverage"),
            _textField(controller: coverageCtrl),

            _label("Description"), // ADDED
            _textField(
              controller: descriptionCtrl,
              hint: "Enter product description",
              maxLines: 3,
            ),

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

            // Show original values info
            if ((originalBrand != null &&
                    originalBrand!.isNotEmpty &&
                    selectedBrand == null) ||
                (originalQuality != null &&
                    originalQuality!.isNotEmpty &&
                    selectedQuality == null) ||
                (originalCategory != null &&
                    originalCategory!.isNotEmpty &&
                    selectedCategory == null))
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Note: Some values are not in the dropdown list but will be preserved as-is.",
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),

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

  /// Helper method to build image preview - ADDED
  Widget _buildImagePreview() {
    if (_imageFile != null) {
      // Show newly picked image
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          _imageFile!,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        ),
      );
    } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      // Show existing image from URL
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          _existingImageUrl!,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey.shade200,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
        ),
      );
    } else {
      // No image
      return const Icon(Icons.image, color: Colors.grey, size: 40);
    }
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
  int maxLines = 1, // ADDED maxLines parameter
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

Widget _checkBox(String label, bool value, ValueChanged<bool> onChanged) => Row(
  children: [
    Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
    Text(label),
  ],
);
