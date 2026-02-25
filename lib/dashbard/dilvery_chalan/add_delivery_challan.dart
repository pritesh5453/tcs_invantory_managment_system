import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

/// ================= MODEL CLASSES =================
class Quotation {
  final int id;
  final String clientName;
  final String contactNo;
  final String address;
  final List<QuotationItem> items;

  Quotation({
    required this.id,
    required this.clientName,
    required this.contactNo,
    required this.address,
    required this.items,
  });

  factory Quotation.fromJson(Map<String, dynamic> json) {
    final List<dynamic> itemsJson = json['items'] ?? [];
    final List<QuotationItem> items =
        itemsJson.map((item) => QuotationItem.fromJson(item)).toList();

    return Quotation(
      id: json['id'] ?? 0,
      clientName: json['clientName'] ?? '',
      contactNo: json['contactNo'] ?? '',
      address: json['address'] ?? '',
      items: items,
    );
  }
}

class QuotationItem {
  final int id;
  final int productId;
  final String productName;
  final int remainingBoxes;
  final List<Batch> batches;
  final int currentStock;

  QuotationItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.remainingBoxes,
    required this.batches,
    required this.currentStock,
  });

  factory QuotationItem.fromJson(Map<String, dynamic> json) {
    final List<dynamic> batchesJson = json['batches'] ?? [];
    final List<Batch> batches =
        batchesJson.map((batch) => Batch.fromJson(batch)).toList();

    return QuotationItem(
      id: json['id'] ?? 0,
      productId: json['productId'] ?? 0,
      productName: json['productName'] ?? '',
      remainingBoxes: json['remainingBoxes'] ?? 0,
      batches: batches,
      currentStock: json['currentStock'] ?? 0,
    );
  }
}

class Batch {
  final String batchNo;
  final int qty;
  final String location;

  Batch({required this.batchNo, required this.qty, required this.location});

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      batchNo: json['batch_no'] ?? '',
      qty: json['qty'] ?? 0,
      location: json['location'] ?? '',
    );
  }
}

/// ================= MODEL FOR MANUALLY ADDED PRODUCT ROWS =================
class AdditionalProductRow {
  String productName = '';
  String size = '';
  String quality = '';
  String godown = 'KKW';
  bool showProductDropdown = false;
  int? productId;

  // Store the full product details when selected
  Map<String, dynamic>? selectedProductDetails;

  final TextEditingController productSearchController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController covController = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController twgtController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController discountController = TextEditingController();

  void updateTWGT() {
    try {
      final weight = double.tryParse(weightController.text) ?? 0;
      final quantity = double.tryParse(quantityController.text) ?? 0;
      final twgt = weight * quantity;
      twgtController.text = twgt.toStringAsFixed(2);
      updateTotal();
    } catch (e) {
      twgtController.text = '0';
      amountController.text = '0';
    }
  }

  void updateTotal() {
    try {
      final quantity = double.tryParse(quantityController.text) ?? 0;
      final rate = double.tryParse(rateController.text) ?? 0;
      final cov = double.tryParse(covController.text) ?? 0;
      final discount = double.tryParse(discountController.text) ?? 0;

      // Calculate base amount: Rate * QUANTITY
      final baseAmount = rate * quantity;
      final covAmount = baseAmount * cov;
      final discountAmount = covAmount * (discount / 100);
      final finalAmount = covAmount - discountAmount;

      amountController.text = finalAmount.toStringAsFixed(2);
    } catch (e) {
      amountController.text = '0';
    }
  }

  double getTotalAmount() {
    return double.tryParse(amountController.text) ?? 0;
  }

  void dispose() {
    productSearchController.dispose();
    rateController.dispose();
    covController.dispose();
    areaController.dispose();
    weightController.dispose();
    twgtController.dispose();
    quantityController.dispose();
    amountController.dispose();
    discountController.dispose();
  }
}

/// ================= MAIN SCREEN =================
class AddDeliveryChallanScreen extends StatefulWidget {
  const AddDeliveryChallanScreen({super.key});

  @override
  State<AddDeliveryChallanScreen> createState() =>
      _AddDeliveryChallanScreenState();
}

class _AddDeliveryChallanScreenState extends State<AddDeliveryChallanScreen> {
  final Dio dio = Dio();

  // Search
  final TextEditingController _searchController = TextEditingController();

  // Selected quotation
  Quotation? _selectedQuotation;

  // Dispatch logistics
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _driverContactController =
      TextEditingController();
  final TextEditingController _vehicleNoController = TextEditingController();

  // Dispatch boxes controllers for each quotation item
  final Map<int, TextEditingController> _dispatchBoxesControllers = {};

  // Additional product rows (manually added)
  List<AdditionalProductRow> _additionalRows = [];

  // Additional discount
  final TextEditingController _additionalDiscountController =
      TextEditingController(text: '0');

  // Loading states
  bool _isSearching = false;
  bool _isSubmitting = false;

  // Quotations list for search
  List<Quotation> _quotations = [];

  // Search with debounce
  Timer? _searchDebounce;

  // Product search data (for manual rows)
  List<dynamic> _products = [];
  List<dynamic> _filteredProducts = [];
  Timer? _productSearchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedQuotation != null) {
        _initializeControllers();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _productSearchDebounce?.cancel();
    _searchController.dispose();
    _driverNameController.dispose();
    _driverContactController.dispose();
    _vehicleNoController.dispose();
    _additionalDiscountController.dispose();

    // Dispose all dispatch boxes controllers
    _dispatchBoxesControllers.forEach((key, controller) {
      controller.dispose();
    });

    // Dispose all additional rows
    for (var row in _additionalRows) {
      row.dispose();
    }

    super.dispose();
  }

  void _initializeControllers() {
    if (_selectedQuotation == null) return;

    for (var item in _selectedQuotation!.items) {
      if (!_dispatchBoxesControllers.containsKey(item.id)) {
        _dispatchBoxesControllers[item.id] = TextEditingController(text: '0');
      }
    }
  }

  Future<void> _searchQuotations(String query) async {
    if (query.length < 3) {
      setState(() {
        _quotations = [];
      });
      return;
    }

    if (_searchDebounce?.isActive ?? false) {
      _searchDebounce!.cancel();
    }

    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isSearching = true);

      try {
        final response = await dio.get(
          "https://dashboard.theceramicstudio.in/api/Quotation/search/$query",
        );

        if (response.statusCode == 200 && response.data['success'] == true) {
          final List data = response.data['quotations'] ?? [];
          setState(() {
            _quotations = data.map((e) => Quotation.fromJson(e)).toList();
          });
        }
      } catch (e) {
        debugPrint("Search error: $e");
        _showError("Search failed");
      } finally {
        setState(() => _isSearching = false);
      }
    });
  }

  void _selectQuotation(Quotation quotation) {
    setState(() {
      _selectedQuotation = quotation;
      _quotations = []; // Clear search results
      _searchController.text = '';
      _driverNameController.clear();
      _driverContactController.clear();
      _vehicleNoController.clear();
      // Do not clear additional rows or discount – they stay
    });

    _initializeControllers();
  }

  void _clearSelection() {
    setState(() {
      _selectedQuotation = null;
      _dispatchBoxesControllers.clear();
    });
  }

  // ---------- Product search for manual rows ----------
  Future<void> _fetchProducts({required String search}) async {
    if (search.trim().isEmpty) {
      setState(() {
        _filteredProducts = [];
      });
      return;
    }

    try {
      final response = await dio.get(
        'https://dashboard.theceramicstudio.in/api/product/list',
        queryParameters: {'search': search},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _filteredProducts = response.data['products'];
          _products = response.data['products'];
        });
      }
    } catch (e) {
      debugPrint('Product search error: $e');
    }
  }

  Map<String, dynamic>? _findProductDetails(
    String productName,
    String size,
    String quality,
  ) {
    try {
      return _products.firstWhere(
        (p) =>
            p['name'] == productName &&
            (p['size']?.toString() ?? '') == size &&
            (p['quality']?.toString() ?? '') == quality,
        orElse: () => null,
      );
    } catch (e) {
      return null;
    }
  }

  List<String> _getSizesForProduct(String productName) {
    if (productName.isEmpty) return [];
    final productsWithSameName =
        _products.where((p) => p['name'] == productName).toList();
    if (productsWithSameName.isEmpty) return [];
    final sizes =
        productsWithSameName
            .map((p) => p['size']?.toString() ?? '')
            .where((size) => size.isNotEmpty)
            .toSet()
            .toList();
    return sizes;
  }

  List<String> _getQualitiesForProduct(String productName, String size) {
    if (productName.isEmpty || size.isEmpty) return [];
    final productsWithSameNameAndSize =
        _products
            .where(
              (p) =>
                  p['name'] == productName &&
                  (p['size']?.toString() ?? '') == size,
            )
            .toList();
    if (productsWithSameNameAndSize.isEmpty) return [];
    final qualities =
        productsWithSameNameAndSize
            .map((p) => p['quality']?.toString() ?? '')
            .where((quality) => quality.isNotEmpty)
            .toSet()
            .toList();
    return qualities;
  }

  // ---------- Manual row management ----------
  void _addAdditionalRow() {
    setState(() {
      _additionalRows.add(AdditionalProductRow());
    });
    // Scroll to bottom after adding
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // You can add scroll controller logic if needed
    });
  }

  void _removeAdditionalRow(int index) {
    setState(() {
      _additionalRows[index].dispose();
      _additionalRows.removeAt(index);
    });
  }

  // ---------- Calculations ----------
  double _calculateQuotationItemsTotal() {
    double total = 0;
    if (_selectedQuotation != null) {
      for (var item in _selectedQuotation!.items) {
        final controller = _dispatchBoxesControllers[item.id];
        final dispatchBoxes = double.tryParse(controller?.text ?? '0') ?? 0;
        // You need to know the rate for quotation items – assuming you have it in the item or you fetch it.
        // For now, use a placeholder rate of 0. You should adjust based on your data.
        // Possibly you need to extend QuotationItem to include rate.
        // We'll assume there is a field 'rate' in QuotationItem. If not, you'll need to fetch product details.
        final rate = 0.0; // Replace with actual rate
        total += dispatchBoxes * rate;
      }
    }
    return total;
  }

  double _calculateAdditionalRowsTotal() {
    double total = 0;
    for (var row in _additionalRows) {
      total += row.getTotalAmount();
    }
    return total;
  }

  double _calculateTotalAmount() {
    return _calculateQuotationItemsTotal() + _calculateAdditionalRowsTotal();
  }

  double _calculateGrandTotal() {
    double subtotal = _calculateTotalAmount();
    double additionalDiscount =
        double.tryParse(_additionalDiscountController.text) ?? 0;
    if (additionalDiscount > 0) {
      double discountAmount = subtotal * (additionalDiscount / 100);
      return subtotal - discountAmount;
    }
    return subtotal;
  }

  // ---------- Validation ----------
  bool _validateForm() {
    if (_selectedQuotation == null && _additionalRows.isEmpty) {
      _showError("Please select a quotation or add at least one product");
      return false;
    }

    if (_driverNameController.text.isEmpty) {
      _showError("Please enter driver name");
      return false;
    }

    if (_driverContactController.text.isEmpty) {
      _showError("Please enter driver contact");
      return false;
    }

    if (_vehicleNoController.text.isEmpty) {
      _showError("Please enter vehicle number");
      return false;
    }

    // Validate quotation items have at least one dispatch box > 0 if quotation exists
    if (_selectedQuotation != null) {
      bool hasQuotationDispatch = false;
      for (var item in _selectedQuotation!.items) {
        final controller = _dispatchBoxesControllers[item.id];
        final value = int.tryParse(controller?.text ?? '0') ?? 0;
        if (value > 0) {
          hasQuotationDispatch = true;
          break;
        }
      }
      // If there are no additional rows, we need at least one quotation dispatch
      if (!hasQuotationDispatch && _additionalRows.isEmpty) {
        _showError("Please enter dispatch boxes for at least one product");
        return false;
      }
    }

    // Validate additional rows
    for (int i = 0; i < _additionalRows.length; i++) {
      final row = _additionalRows[i];
      if (row.productName.isEmpty) {
        _showError("Please select product for additional row ${i + 1}");
        return false;
      }
      if (row.size.isEmpty) {
        _showError("Please select size for additional row ${i + 1}");
        return false;
      }
      if (row.quality.isEmpty) {
        _showError("Please select quality for additional row ${i + 1}");
        return false;
      }
      if (row.quantityController.text.trim().isEmpty ||
          double.tryParse(row.quantityController.text) == 0) {
        _showError("Please enter valid quantity for additional row ${i + 1}");
        return false;
      }
      if (row.productId == null && row.selectedProductDetails == null) {
        _showError("Product details not found for additional row ${i + 1}");
        return false;
      }
    }

    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  // ---------- API Submission ----------
  Future<void> _generateDeliveryChallan() async {
    if (!_validateForm()) return;

    setState(() => _isSubmitting = true);

    try {
      // Prepare quotation items (if any)
      final List<Map<String, dynamic>> quotationItems = [];
      if (_selectedQuotation != null) {
        for (var item in _selectedQuotation!.items) {
          final controller = _dispatchBoxesControllers[item.id];
          final dispatchBoxes = int.tryParse(controller?.text ?? '0') ?? 0;
          if (dispatchBoxes > 0) {
            // You need to get the actual rate for the product – you might have it in item or need to fetch
            final rate = 0.0; // TODO: replace with actual rate from your data
            quotationItems.add({
              "quotationItemId": item.id,
              "productId": item.productId,
              "productName": item.productName,
              "dispatchBoxes": dispatchBoxes,
              "rate": rate,
            });
          }
        }
      }

      // Prepare additional items
      final List<Map<String, dynamic>> additionalItems = [];
      for (var row in _additionalRows) {
        final productDetails = row.selectedProductDetails;
        if (productDetails == null) continue;

        additionalItems.add({
          "productId": productDetails['id'] ?? row.productId,
          "productName": row.productName,
          "size": row.size,
          "quality": row.quality,
          "rate": double.tryParse(row.rateController.text) ?? 0,
          "box": int.tryParse(row.quantityController.text) ?? 0,
          "area": row.areaController.text.trim(),
          "weight": double.tryParse(row.weightController.text) ?? 0,
          "twgt": double.tryParse(row.twgtController.text) ?? 0,
          "coverage": double.tryParse(row.covController.text) ?? 0,
          "discount": double.tryParse(row.discountController.text) ?? 0,
          "total": row.getTotalAmount(),
          "godown": row.godown,
        });
      }

      final Map<String, dynamic> payload = {
        "quotationId": _selectedQuotation?.id,
        "driverDetails": {
          "deliveryBoy": _driverNameController.text.trim(),
          "contact": _driverContactController.text.trim(),
          "tempo": _vehicleNoController.text.trim(),
        },
        "additionalDiscount":
            double.tryParse(_additionalDiscountController.text) ?? 0,
        "quotationItems": quotationItems,
        "additionalItems": additionalItems,
        "grandTotal": _calculateGrandTotal(),
      };

      debugPrint("Payload: ${jsonEncode(payload)}");

      // TODO: Replace with your actual delivery challan endpoint
      final response = await dio.post(
        "https://dashboard.theceramicstudio.in/api/DeliveryChallan/create",
        data: payload,
        options: Options(headers: {"Content-Type": "application/json"}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data['success'] == true) {
          _showSuccess("Delivery Challan Generated Successfully!");
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.pop(context, true);
          });
        } else {
          _showError(data['message'] ?? "Failed to generate challan");
        }
      } else {
        _showError("Server error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Generate challan error: $e");
      _showError("Failed to generate delivery challan");
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // ---------- UI Helpers ----------
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hintText, {
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          border: InputBorder.none,
          isDense: true,
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildAdditionalProductRow(int index, AdditionalProductRow row) {
    final sizes = _getSizesForProduct(row.productName);
    final qualities = _getQualitiesForProduct(row.productName, row.size);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.blue.shade50, // light blue background to distinguish
      ),
      child: Column(
        children: [
          // Product Name Search
          _buildLabel('PRODUCT'),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: row.productSearchController,
                          onChanged: (value) {
                            row.productName = value;
                            row.showProductDropdown = value.isNotEmpty;

                            // Reset dependent fields
                            row.size = '';
                            row.quality = '';
                            row.weightController.clear();
                            row.twgtController.clear();
                            row.covController.clear();
                            row.rateController.clear();
                            row.amountController.clear();
                            row.selectedProductDetails = null;

                            if (_productSearchDebounce?.isActive ?? false) {
                              _productSearchDebounce!.cancel();
                            }

                            _productSearchDebounce = Timer(
                              const Duration(milliseconds: 400),
                              () {
                                if (value.trim().isNotEmpty) {
                                  _fetchProducts(search: value.trim());
                                } else {
                                  setState(() {
                                    _filteredProducts = [];
                                  });
                                }
                              },
                            );

                            setState(() {});
                          },
                          onTap: () {
                            setState(() {
                              row.showProductDropdown = true;
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: 'Search product...',
                            hintStyle: TextStyle(fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (row.showProductDropdown && row.productName.isNotEmpty)
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: ListView.builder(
                      itemCount:
                          _filteredProducts
                              .where(
                                (p) => p['name']
                                    .toString()
                                    .toLowerCase()
                                    .contains(row.productName.toLowerCase()),
                              )
                              .length,
                      itemBuilder: (context, idx) {
                        final product =
                            _filteredProducts
                                .where(
                                  (p) => p['name']
                                      .toString()
                                      .toLowerCase()
                                      .contains(row.productName.toLowerCase()),
                                )
                                .toList()[idx];
                        return ListTile(
                          title: Text(product['name'] ?? ''),
                          subtitle: Text(
                            'Size: ${product['size']} | Quality: ${product['quality']}',
                          ),
                          onTap: () {
                            setState(() {
                              row.productId = product['id'];
                              row.productName = product['name'];
                              row.size = product['size'].toString();
                              row.quality = product['quality'].toString();
                              row.productSearchController.text =
                                  product['name'];
                              row.rateController.text = product['rate'] ?? '0';
                              row.covController.text = product['cov'] ?? '0';
                              row.selectedProductDetails = product;
                              row.showProductDropdown = false;
                              row.updateTotal();
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

          // Size and Quality Dropdowns
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('SIZE'),
                    const SizedBox(height: 4),
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value:
                              row.size.isNotEmpty && sizes.contains(row.size)
                                  ? row.size
                                  : null,
                          hint: const Text('Select Size'),
                          items:
                              sizes.map((size) {
                                return DropdownMenuItem<String>(
                                  value: size,
                                  child: Text(size),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              row.size = value;
                              row.quality = '';
                              row.weightController.clear();
                              row.twgtController.clear();
                              row.covController.clear();
                              row.rateController.clear();
                              row.amountController.clear();
                              row.selectedProductDetails = null;
                              row.updateTotal();
                            });
                          },
                        ),
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
                    _buildLabel('QUALITY'),
                    const SizedBox(height: 4),
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value:
                              row.quality.isNotEmpty &&
                                      qualities.contains(row.quality)
                                  ? row.quality
                                  : null,
                          hint: const Text('Select Quality'),
                          items:
                              qualities.map((quality) {
                                return DropdownMenuItem<String>(
                                  value: quality,
                                  child: Text(quality),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              row.quality = value;
                              final productDetails = _findProductDetails(
                                row.productName,
                                row.size,
                                value,
                              );
                              if (productDetails != null) {
                                row.productId = productDetails['id'];
                                row.rateController.text =
                                    productDetails['rate']?.toString() ?? '0';
                                row.covController.text =
                                    productDetails['cov']?.toString() ?? '0';
                                row.selectedProductDetails = productDetails;
                              } else {
                                row.selectedProductDetails = null;
                                row.rateController.clear();
                                row.covController.clear();
                              }
                              row.updateTotal();
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Rate, COV, AREA
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('RATE (₹)'),
                    const SizedBox(height: 4),
                    _buildTextField(
                      row.rateController,
                      '0',
                      onChanged: (_) => row.updateTotal(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('COVERAGE'),
                    const SizedBox(height: 4),
                    _buildTextField(
                      row.covController,
                      '0',
                      onChanged: (_) => row.updateTotal(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('AREA'),
                    const SizedBox(height: 4),
                    _buildTextField(
                      row.areaController,
                      '0',
                      keyboardType: TextInputType.text,
                      onChanged: (_) => row.updateTotal(),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // BOX, DISCOUNT, WEIGHT
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('BOX'),
                    const SizedBox(height: 4),
                    _buildTextField(
                      row.quantityController,
                      '0',
                      keyboardType: TextInputType.number,
                      onChanged: (_) => row.updateTWGT(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('DISCOUNT (%)'),
                    const SizedBox(height: 4),
                    _buildTextField(
                      row.discountController,
                      '0',
                      keyboardType: TextInputType.number,
                      onChanged: (_) => row.updateTotal(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('WEIGHT'),
                    const SizedBox(height: 4),
                    _buildTextField(
                      row.weightController,
                      '0',
                      keyboardType: TextInputType.number,
                      onChanged: (_) => row.updateTWGT(),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // TWGT, AMOUNT, GODOWN
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('TWGT'),
                    const SizedBox(height: 4),
                    _buildTextField(row.twgtController, '0', enabled: false),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('AMOUNT (₹)'),
                    const SizedBox(height: 4),
                    _buildTextField(row.amountController, '0', enabled: false),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('GODOWN'),
                    const SizedBox(height: 4),
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: row.godown,
                          items: const [
                            DropdownMenuItem(value: 'KKW', child: Text('KKW')),
                            DropdownMenuItem(value: 'TCS', child: Text('TCS')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              row.godown = value!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Delete button
          Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _removeAdditionalRow(index),
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 4),
                      Text(
                        'Delete Row',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Main Build ----------
  @override
  Widget build(BuildContext context) {
    final subtotal = _calculateTotalAmount();
    final additionalDiscount =
        double.tryParse(_additionalDiscountController.text) ?? 0;
    final discountAmount = subtotal * (additionalDiscount / 100);
    final grandTotal = _calculateGrandTotal();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Create Delivery Challan",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFFA9C42),
      ),
      body: GestureDetector(
        onTap: () {
          // Close dropdowns when tapping outside
          for (var row in _additionalRows) {
            row.showProductDropdown = false;
          }
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              _buildSearchBar(),

              const SizedBox(height: 20),

              // Selected Quotation (if any)
              if (_selectedQuotation != null) ...[
                _buildSelectedQuotation(),
                const SizedBox(height: 24),
              ],

              // Dispatch Logistics
              _buildDispatchLogistics(),
              const SizedBox(height: 24),

              // Quotation Products (if any)
              if (_selectedQuotation != null &&
                  _selectedQuotation!.items.isNotEmpty) ...[
                Text(
                  "PRODUCTS FROM QUOTATION",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                ..._selectedQuotation!.items.map((item) {
                  return _buildProductItem(item);
                }).toList(),
                const SizedBox(height: 24),
              ],

              // Additional Products Section
              const Text(
                "ADDITIONAL PRODUCTS",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFA9C42),
                ),
              ),
              const SizedBox(height: 16),

              // Additional product rows
              ..._additionalRows.asMap().entries.map((entry) {
                return _buildAdditionalProductRow(entry.key, entry.value);
              }),

              // Add Product Row Button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _addAdditionalRow,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFFA9C42)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Color(0xFFFA9C42), size: 18),
                          SizedBox(width: 8),
                          Text(
                            "+ ADD PRODUCT ROW",
                            style: TextStyle(
                              color: Color(0xFFFA9C42),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Additional Discount
              // Container(
              //   padding: const EdgeInsets.all(16),
              //   decoration: BoxDecoration(
              //     border: Border.all(color: Colors.grey.shade300),
              //     borderRadius: BorderRadius.circular(8),
              //   ),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       _buildLabel('ADDITIONAL DISCOUNT (%)'),
              //       const SizedBox(height: 8),
              //       _buildTextField(
              //         _additionalDiscountController,
              //         'Enter discount percentage...',
              //       ),
              //       const SizedBox(height: 8),
              //       Text(
              //         'This discount will be applied on the total amount',
              //         style: TextStyle(
              //           fontSize: 12,
              //           color: Colors.grey.shade600,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              const SizedBox(height: 24),

              // Totals
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFA9C42).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFA9C42).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subtotal',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        Text(
                          '₹${subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    if (additionalDiscount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Additional Discount ($additionalDiscount%)',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            '-₹${discountAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Divider(height: 24, thickness: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Grand Total',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFA9C42),
                          ),
                        ),
                        Text(
                          '₹${grandTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFA9C42),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Generate Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _generateDeliveryChallan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFA9C42),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isSubmitting
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text(
                            'Generate Delivery Challan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Existing UI methods (unchanged)
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 249, 249, 249),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.black),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _searchQuotations,
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      hintText: "Search quotation by client name or number",
                      hintStyle: TextStyle(color: Colors.black),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_selectedQuotation != null)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: _clearSelection,
                  ),
              ],
            ),
          ),

          if (_quotations.isNotEmpty || _isSearching)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: Material(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child:
                    _isSearching
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _quotations.length,
                          itemBuilder: (context, index) {
                            final quotation = _quotations[index];
                            return ListTile(
                              title: Text(
                                "Quotation #${quotation.id}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(quotation.clientName),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              ),
                              onTap: () => _selectQuotation(quotation),
                              dense: true,
                            );
                          },
                        ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedQuotation() {
    if (_selectedQuotation == null) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "SELECTED QUOTATION #${_selectedQuotation!.id}",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFA9C42).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFFFA9C42),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedQuotation!.clientName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedQuotation!.contactNo,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedQuotation!.address,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchLogistics() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "DISPATCH LOGISTICS",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),

          _buildInputField(
            label: "Driver Name",
            hintText: "Enter driver name",
            controller: _driverNameController,
            icon: Icons.person_outline,
          ),

          const SizedBox(height: 12),

          _buildInputField(
            label: "Contact",
            hintText: "Enter contact number",
            controller: _driverContactController,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 12),

          _buildInputField(
            label: "Vehicle No (e.g. MH-15-AB-1234)",
            hintText: "Enter vehicle number",
            controller: _vehicleNoController,
            icon: Icons.local_shipping_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Icon(icon, color: Colors.grey.shade500, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductItem(QuotationItem item) {
    final controller =
        _dispatchBoxesControllers[item.id] ?? TextEditingController(text: '0');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.productName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFA9C42).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "IN STOCK: ${item.currentStock} qty",
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFFFA9C42),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (item.batches.isNotEmpty) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  item.batches.map((batch) {
                    final location = batch.location.toUpperCase();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "B#${batch.batchNo}",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Qty: ${batch.qty} ($location)",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${item.currentStock} qty",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "REMAINING",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),

                Container(
                  width: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: "0",
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "DISPATCH BOXES",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
