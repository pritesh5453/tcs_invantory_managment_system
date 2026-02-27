import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class AddOrderScreen extends StatefulWidget {
  const AddOrderScreen({super.key});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  /// ================= CONTROLLERS =================
  final TextEditingController productController = TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController sizeController = TextEditingController();
  final TextEditingController qualityController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  DateTime? selectedDate;
  bool isLoading = false;

  /// ================= PRODUCT SEARCH =================
  final Dio _dio = Dio();
  List<dynamic> _products = [];
  List<dynamic> _filteredProducts = [];
  bool _showProductDropdown = false;
  Timer? _productSearchDebounce;

  /// ================= DATE PICKER =================
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      selectedDate = picked;
      dateController.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {});
    }
  }

  /// ================= FETCH PRODUCTS =================
  Future<void> _fetchProducts(String search) async {
    if (search.trim().isEmpty) {
      setState(() {
        _filteredProducts = [];
        _showProductDropdown = false;
      });
      return;
    }

    try {
      final response = await _dio.get(
        'https://dashboard.theceramicstudio.in/api/product/list',
        queryParameters: {'search': search},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _products = response.data['products'];
          // Filter locally by name (API already searches, but we keep it)
          _filteredProducts =
              _products
                  .where(
                    (p) => p['name'].toString().toLowerCase().contains(
                      search.toLowerCase(),
                    ),
                  )
                  .toList();
          _showProductDropdown = _filteredProducts.isNotEmpty;
        });
      } else {
        _filteredProducts = [];
        _showProductDropdown = false;
      }
    } catch (e) {
      debugPrint('Product search error: $e');
      _filteredProducts = [];
      _showProductDropdown = false;
    }
  }

  /// ================= CREATE ORDER API =================
  Future<void> _createOrder() async {
    if (productController.text.isEmpty ||
        brandController.text.isEmpty ||
        sizeController.text.isEmpty ||
        qualityController.text.isEmpty ||
        quantityController.text.isEmpty ||
        selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => isLoading = true);

    try {
      await Dio().post(
        "https://dashboard.theceramicstudio.in/api/orderBook/create",
        data: {
          "name": productController.text.trim(),
          "size": sizeController.text.trim(),
          "quality": qualityController.text.trim(),
          "date": dateController.text.trim(),
          "quantity": quantityController.text.trim(),
          "brand": brandController.text.trim(), // brand name
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Order created successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true); // refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to create order"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F6F6),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 150),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// HEADER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Add Order",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.close, color: Colors.red),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      /// PRODUCT SEARCH FIELD (with dropdown)
                      _label("Product Name"),
                      const SizedBox(height: 4),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.search,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: productController,
                                      onChanged: (value) {
                                        // Clear dependent fields when search changes
                                        brandController.clear();
                                        sizeController.clear();
                                        qualityController.clear();

                                        if (_productSearchDebounce?.isActive ??
                                            false) {
                                          _productSearchDebounce!.cancel();
                                        }

                                        _productSearchDebounce = Timer(
                                          const Duration(milliseconds: 400),
                                          () => _fetchProducts(value),
                                        );
                                      },
                                      onTap: () {
                                        if (productController.text.isNotEmpty) {
                                          _fetchProducts(
                                            productController.text,
                                          );
                                        }
                                      },
                                      decoration: const InputDecoration(
                                        hintText: "Search product...",
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_showProductDropdown &&
                                _filteredProducts.isNotEmpty)
                              Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                ),
                                child: ListView.builder(
                                  itemCount: _filteredProducts.length,
                                  itemBuilder: (context, index) {
                                    final product = _filteredProducts[index];
                                    return ListTile(
                                      title: Text(product['name'] ?? ''),
                                      subtitle: Text(
                                        'Size: ${product['size']} | Quality: ${product['quality']} | Brand: ${product['brand']}',
                                      ),
                                      onTap: () {
                                        setState(() {
                                          productController.text =
                                              product['name'] ?? '';
                                          brandController.text =
                                              product['brand'] ?? '';
                                          sizeController.text =
                                              product['size']?.toString() ?? '';
                                          qualityController.text =
                                              product['quality']?.toString() ??
                                              '';
                                          _showProductDropdown = false;
                                          FocusScope.of(context).unfocus();
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// BRAND NAME
                      _label("Brand Name"),
                      const SizedBox(height: 4),
                      TextField(
                        controller: brandController,
                        readOnly: true,
                        decoration: _decoration("Brand"),
                      ),

                      const SizedBox(height: 12),

                      /// SIZE + QUALITY (read-only)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label("Size"),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: sizeController,
                                  readOnly: true,
                                  decoration: _decoration("Eg. 1200x1800"),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label("Quality"),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: qualityController,
                                  readOnly: true,
                                  decoration: _decoration("PREMIUM"),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      /// DATE + QUANTITY
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label("Order Date"),
                                TextField(
                                  controller: dateController,
                                  readOnly: true,
                                  onTap: _pickDate,
                                  decoration: _decoration(
                                    "YYYY-MM-DD",
                                    icon: Icons.calendar_month,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label("Quantity"),
                                TextField(
                                  controller: quantityController,
                                  keyboardType: TextInputType.number,
                                  decoration: _decoration("Eg. 1"),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// BUTTONS
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Discard"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _createOrder,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFA54A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child:
                                  isLoading
                                      ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                      : const Text(
                                        "Add Order",
                                        style: TextStyle(color: Colors.white),
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= HELPERS =================
  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    ),
  );

  InputDecoration _decoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: icon != null ? Icon(icon) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  void dispose() {
    _productSearchDebounce?.cancel();
    productController.dispose();
    brandController.dispose();
    sizeController.dispose();
    qualityController.dispose();
    quantityController.dispose();
    dateController.dispose();
    super.dispose();
  }
}
