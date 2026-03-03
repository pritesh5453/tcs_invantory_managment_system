import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class AddOrderScreen extends StatefulWidget {
  const AddOrderScreen({super.key});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final Dio dio = Dio();

  /// Controllers
  final productCtrl = TextEditingController();
  final quantityCtrl = TextEditingController();
  final dateCtrl = TextEditingController();

  /// Product Data
  List products = [];
  List filteredProducts = [];

  bool showDropdown = false;
  Timer? debounce;

  /// Selected Values
  String productName = "";
  String selectedSize = "";
  String selectedQuality = "";
  String selectedBrand = "";

  DateTime? selectedDate;

  bool loading = false;

  /// ================= FETCH PRODUCTS =================
  Future<void> fetchProducts(String search) async {
    if (search.trim().isEmpty) {
      setState(() {
        showDropdown = false;
      });
      return;
    }

    try {
      final res = await dio.get(
        "https://dashboard.theceramicstudio.in/api/product/list",
        queryParameters: {"search": search},
      );

      if (res.data["success"] == true) {
        products = res.data["products"];

        setState(() {
          filteredProducts = products;
          showDropdown = true;
        });
      }
    } catch (e) {
      debugPrint("Product fetch error $e");
    }
  }

  /// ================= DROPDOWN DATA =================

  List<String> getSizes() {
    return products
        .where((p) => p["name"] == productName)
        .map((e) => e["size"].toString())
        .toSet()
        .toList();
  }

  List<String> getQualities() {
    return products
        .where(
          (p) =>
              p["name"] == productName && p["size"].toString() == selectedSize,
        )
        .map((e) => e["quality"].toString())
        .toSet()
        .toList();
  }

  List<String> getBrands() {
    return products
        .where(
          (p) =>
              p["name"] == productName &&
              p["size"].toString() == selectedSize &&
              p["quality"].toString() == selectedQuality,
        )
        .map((e) => e["brand"].toString())
        .toSet()
        .toList();
  }

  /// ================= DATE =================

  Future pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      selectedDate = picked;

      dateCtrl.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";

      setState(() {});
    }
  }

  /// ================= CREATE ORDER =================

  Future createOrder() async {
    if (productName.isEmpty ||
        selectedSize.isEmpty ||
        selectedQuality.isEmpty ||
        selectedBrand.isEmpty ||
        quantityCtrl.text.isEmpty ||
        dateCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }

    setState(() => loading = true);

    try {
      await dio.post(
        "https://dashboard.theceramicstudio.in/api/orderBook/create",
        data: {
          "name": productName,
          "size": selectedSize,
          "quality": selectedQuality,
          "brand": selectedBrand,
          "date": dateCtrl.text,
          "quantity": quantityCtrl.text,
        },
      );

      if (!mounted) return;

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Order Created Successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Order Failed"),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => loading = false);
  }

  /// ================= UI =================

  @override
  Widget build(BuildContext context) {
    final sizes = getSizes();
    final qualities = getQualities();
    final brands = getBrands();

    return Scaffold(
      backgroundColor: const Color(0xffF6F6F6),

      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 120),

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

                      /// PRODUCT SEARCH
                      _label("Product"),

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
                                      controller: productCtrl,

                                      onChanged: (v) {
                                        debounce?.cancel();

                                        debounce = Timer(
                                          const Duration(milliseconds: 400),
                                          () => fetchProducts(v),
                                        );
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

                            if (showDropdown)
                              Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                ),

                                child: ListView.builder(
                                  itemCount: filteredProducts.length,
                                  itemBuilder: (c, i) {
                                    final p = filteredProducts[i];

                                    return ListTile(
                                      title: Text(p["name"]),

                                      subtitle: Text(
                                        "${p["size"]} | ${p["quality"]} | ${p["brand"]}",
                                      ),

                                      onTap: () {
                                        setState(() {
                                          productName = p["name"];

                                          selectedSize = p["size"].toString();

                                          selectedQuality =
                                              p["quality"].toString();

                                          selectedBrand = p["brand"].toString();

                                          productCtrl.text = productName;

                                          showDropdown = false;

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

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: _dropdownBox(
                              "Size",
                              sizes,
                              sizes.contains(selectedSize)
                                  ? selectedSize
                                  : null,
                              (v) {
                                selectedSize = v!;
                                selectedQuality = "";
                                selectedBrand = "";
                                setState(() {});
                              },
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: _dropdownBox(
                              "Quality",
                              qualities,
                              qualities.contains(selectedQuality)
                                  ? selectedQuality
                                  : null,
                              (v) {
                                selectedQuality = v!;
                                selectedBrand = "";
                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      _dropdownBox(
                        "Brand",
                        brands,
                        brands.contains(selectedBrand) ? selectedBrand : null,
                        (v) {
                          selectedBrand = v!;
                          setState(() {});
                        },
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label("Order Date"),

                                TextField(
                                  controller: dateCtrl,
                                  readOnly: true,
                                  onTap: pickDate,
                                  decoration: _decoration(
                                    "YYYY-MM-DD",
                                    Icons.calendar_month,
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
                                  controller: quantityCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: _decoration("Eg.100"),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 48,

                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffFFA54A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),

                          onPressed: loading ? null : createOrder,

                          child:
                              loading
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
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

  InputDecoration _decoration(String hint, [IconData? icon]) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: icon != null ? Icon(icon) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _dropdownBox(
    String label,
    List<String> items,
    String? value,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),

          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),

          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              hint: Text("Select $label"),
              items:
                  items
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    productCtrl.dispose();
    quantityCtrl.dispose();
    dateCtrl.dispose();
    debounce?.cancel();
    super.dispose();
  }
}
