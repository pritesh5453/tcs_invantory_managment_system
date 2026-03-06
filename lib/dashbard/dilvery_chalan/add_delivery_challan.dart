import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:math';

/// ================= MODEL CLASSES =================
class Quotation {
  final int id;
  final String clientName;
  final String contactNo;
  final String address;
  final String clientId;
  final double transportation;
  final double unloading;
  final double additionalDiscount;
  final List<QuotationItem> items;

  Quotation({
    required this.id,
    required this.clientName,
    required this.contactNo,
    required this.address,
    required this.clientId,
    required this.transportation,
    required this.unloading,
    required this.additionalDiscount,
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
      clientId: json['clientId']?.toString() ?? '',
      transportation:
          double.tryParse(json['transportation']?.toString() ?? '0') ?? 0,
      unloading: double.tryParse(json['unloading']?.toString() ?? '0') ?? 0,
      additionalDiscount:
          double.tryParse(json['additionalDiscount']?.toString() ?? '0') ?? 0,
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
  final double rate;
  final double disRate;
  final double cov;
  final String size;
  final String quality;

  QuotationItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.remainingBoxes,
    required this.batches,
    required this.currentStock,
    required this.rate,
    required this.disRate,
    required this.cov,
    required this.size,
    required this.quality,
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
      rate: double.tryParse(json['rate']?.toString() ?? '0') ?? 0,
      disRate: double.tryParse(json['disRate']?.toString() ?? '0') ?? 0,
      cov: double.tryParse(json['cov']?.toString() ?? '0') ?? 0,
      size: json['size']?.toString() ?? '',
      quality: json['quality']?.toString() ?? '',
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

      final discountedRate = rate * (1 - discount / 100);
      final total = discountedRate * quantity * cov;

      amountController.text = total.toStringAsFixed(2);
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
  final int? quotationId; // 👈 optional parameter

  const AddDeliveryChallanScreen({super.key, this.quotationId});

  @override
  State<AddDeliveryChallanScreen> createState() =>
      _AddDeliveryChallanScreenState();
}

class _AddDeliveryChallanScreenState extends State<AddDeliveryChallanScreen> {
  final Dio dio = Dio();

  // Search
  final TextEditingController _searchController = TextEditingController();

  // Selected quotation and its items (displayed list)
  Quotation? _selectedQuotation;
  List<QuotationItem> _displayedQuotationItems = [];

  // Payment summary data
  double? _quotationAmount;
  double? _quotationPaidAmount;
  double? _customerWalletAmount;
  double? _additionalDiscount;
  bool _isLoadingSummary = false;

  // Black/White challan toggle
  bool? _isBlackChallan;

  // Dispatch logistics (now optional)
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _driverContactController =
      TextEditingController();
  final TextEditingController _vehicleNoController = TextEditingController();
  final TextEditingController _transportationController = TextEditingController(
    text: '',
  );
  final TextEditingController _unloadingController = TextEditingController(
    text: '',
  );
  // Note fields (optional)
  final TextEditingController _note1Controller = TextEditingController();
  final TextEditingController _note2Controller = TextEditingController();

  // Dispatch boxes controllers for each quotation item
  final Map<int, TextEditingController> _dispatchBoxesControllers = {};

  // Additional product rows
  List<AdditionalProductRow> _additionalRows = [];

  // Additional discount
  final TextEditingController _additionalDiscountController =
      TextEditingController(text: '');

  // Loading states
  bool _isSearching = false;
  bool _isSubmitting = false;
  bool _isLoadingQuotation = false; // 👈 new loading state for initial fetch

  // Quotations list for search
  List<Quotation> _quotations = [];

  // Debounce timers
  Timer? _searchDebounce;
  Timer? _productSearchDebounce;

  // Product search data (for manual rows)
  List<dynamic> _products = [];
  List<dynamic> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    if (widget.quotationId != null) {
      _loadQuotationById(widget.quotationId!);
    }
  }

  /// Fetch a single quotation by ID and pre‑fill the form
  Future<void> _loadQuotationById(int id) async {
    setState(() => _isLoadingQuotation = true);
    try {
      final response = await dio.get(
        "https://dashboard.theceramicstudio.in/api/Quotation/list/$id",
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final quotationData = response.data['quotation'];
        final quotation = Quotation.fromJson(quotationData);
        _selectQuotation(quotation);
      } else {
        _showError("Failed to load quotation");
      }
    } catch (e) {
      debugPrint("Load quotation by ID error: $e");
      _showError("Error loading quotation");
    } finally {
      setState(() => _isLoadingQuotation = false);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _productSearchDebounce?.cancel();
    _searchController.dispose();
    _driverNameController.dispose();
    _driverContactController.dispose();
    _vehicleNoController.dispose();
    _transportationController.dispose();
    _unloadingController.dispose();
    _note1Controller.dispose();
    _note2Controller.dispose();
    _additionalDiscountController.dispose();
    _dispatchBoxesControllers.forEach((key, controller) {
      controller.dispose();
    });
    for (var row in _additionalRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _initializeControllers() {
    for (var item in _displayedQuotationItems) {
      if (!_dispatchBoxesControllers.containsKey(item.id)) {
        // If remainingBoxes > 0, prefill; otherwise leave empty.
        final initialText =
            item.remainingBoxes > 0 ? item.remainingBoxes.toString() : '';
        final controller = TextEditingController(text: initialText);
        _dispatchBoxesControllers[item.id] = controller;
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

    _searchDebounce?.cancel();
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

  void _selectQuotation(Quotation quotation) async {
    setState(() {
      _selectedQuotation = quotation;
      _displayedQuotationItems = List.from(quotation.items); // copy
      _quotations = [];
      _searchController.text = '';
      _driverNameController.clear();
      _driverContactController.clear();
      _vehicleNoController.clear();
      _transportationController.text = quotation.transportation.toString();
      _unloadingController.text = quotation.unloading.toString();
      _additionalDiscountController.text =
          quotation.additionalDiscount.toString();
      _additionalDiscount = quotation.additionalDiscount; // set from quotation
      _note1Controller.clear();
      _note2Controller.clear();
      _isBlackChallan = null;
    });

    _initializeControllers();
    await _fetchPaymentSummary(quotation.id);
  }

  Future<void> _fetchPaymentSummary(int quotationId) async {
    setState(() => _isLoadingSummary = true);
    try {
      final response = await dio.get(
        "https://dashboard.theceramicstudio.in/api/Quotation/payment-summary/$quotationId",
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        setState(() {
          _quotationAmount = (data['quotationAmount'] ?? 0).toDouble();
          _quotationPaidAmount = (data['quotationPaidAmount'] ?? 0).toDouble();
          _customerWalletAmount =
              (data['customerWalletAmount'] ?? 0).toDouble();
          // If payment summary includes additionalDiscount, use it; otherwise keep existing
          if (data.containsKey('additionalDiscount')) {
            _additionalDiscount =
                double.tryParse(
                  data['additionalDiscount']?.toString() ?? '0',
                ) ??
                0;
            _additionalDiscountController.text = _additionalDiscount.toString();
          }
        });
      }
    } catch (e) {
      debugPrint("Payment summary error: $e");
    } finally {
      setState(() => _isLoadingSummary = false);
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedQuotation = null;
      _displayedQuotationItems = [];
      _dispatchBoxesControllers.clear();
      _quotationAmount = null;
      _quotationPaidAmount = null;
      _customerWalletAmount = null;
      _additionalDiscount = null;
      _additionalDiscountController.text = '';
      _transportationController.text = '';
      _unloadingController.text = '';
    });
  }

  // ---------- Product search for manual rows ----------
  Future<void> _fetchProducts({required String search}) async {
    if (search.trim().isEmpty) {
      setState(() => _filteredProducts = []);
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
  }

  void _removeAdditionalRow(int index) {
    setState(() {
      _additionalRows[index].dispose();
      _additionalRows.removeAt(index);
    });
  }

  // ---------- Delete quotation item ----------
  void _deleteQuotationItem(int itemId) {
    setState(() {
      _displayedQuotationItems.removeWhere((item) => item.id == itemId);
      _dispatchBoxesControllers.remove(itemId);
    });
  }

  // ---------- Calculations ----------
  double _calculateQuotationItemsTotal() {
    double total = 0;
    for (var item in _displayedQuotationItems) {
      final controller = _dispatchBoxesControllers[item.id];
      final dispatchBoxes = double.tryParse(controller?.text ?? '0') ?? 0;
      total += dispatchBoxes * item.disRate * item.cov;
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
    double transportation =
        double.tryParse(_transportationController.text) ?? 0;
    double unloading = double.tryParse(_unloadingController.text) ?? 0;

    // Discount only on subtotal (products)
    double discountAmount = subtotal * (additionalDiscount / 100);
    double discountedSubtotal = subtotal - discountAmount;

    return discountedSubtotal + transportation + unloading;
  }

  // ---------- Refresh grand total (called after any change in additional rows) ----------
  void _refreshGrandTotal() {
    setState(() {});
  }

  // ---------- Validation ----------
  bool _validateForm() {
    if (_selectedQuotation == null && _additionalRows.isEmpty) {
      _showError("Please select a quotation or add at least one product");
      return false;
    }

    // Driver fields are optional – validation removed.

    if (_transportationController.text.isEmpty ||
        double.tryParse(_transportationController.text) == null) {
      _showError("Please enter a valid transportation amount");
      return false;
    }

    if (_unloadingController.text.isEmpty ||
        double.tryParse(_unloadingController.text) == null) {
      _showError("Please enter a valid unloading amount");
      return false;
    }

    if (_isBlackChallan == null) {
      _showError("Please select Challan Type (Blue or Red)");
      return false;
    }

    bool hasQuotationDispatch = false;
    for (var item in _displayedQuotationItems) {
      final controller = _dispatchBoxesControllers[item.id];
      final value = int.tryParse(controller?.text ?? '0') ?? 0;
      if (value > 0) {
        hasQuotationDispatch = true;
        break;
      }
    }
    if (!hasQuotationDispatch && _additionalRows.isEmpty) {
      _showError("Please enter dispatch boxes for at least one product");
      return false;
    }

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
  // ---------- API Submission ----------
  Future<void> _generateDeliveryChallan() async {
    if (!_validateForm()) return;

    setState(() => _isSubmitting = true);

    try {
      final List<Map<String, dynamic>> items = [];

      // Quotation items (isExtra: 0)
      int rowId = 1;
      for (var item in _displayedQuotationItems) {
        final controller = _dispatchBoxesControllers[item.id];
        final dispatchBoxes = int.tryParse(controller?.text ?? '0') ?? 0;
        if (dispatchBoxes > 0) {
          items.add({
            "rowId": rowId++,
            "productId": item.productId,
            "productName": item.productName,
            "dispatchBoxes": dispatchBoxes,
            "rate": item.disRate,
            "cov": item.cov,
            "currentStock": item.currentStock,
            "isExtra": 0,
            "size": item.size,
            "quality": item.quality,
            "batches":
                item.batches
                    .map(
                      (b) => {
                        "batch_no": b.batchNo,
                        "qty": b.qty,
                        "location": b.location,
                      },
                    )
                    .toList(),
          });
        }
      }

      // Additional items (isExtra: 1)
      for (var row in _additionalRows) {
        final productDetails = row.selectedProductDetails;
        if (productDetails == null) continue;
        items.add({
          "rowId": rowId++,
          "productId": productDetails['id'] ?? row.productId,
          "productName": row.productName,
          "dispatchBoxes": int.tryParse(row.quantityController.text) ?? 0,
          "rate": double.tryParse(row.rateController.text) ?? 0,
          "cov": double.tryParse(row.covController.text) ?? 0,
          "wight": double.tryParse(row.weightController.text.trim()) ?? 0.0,
          "currentStock": 0,
          "isExtra": 1,
          "size": row.size,
          "quality": row.quality,
          "batches": [],
        });
      }

      final double grandTotal = _calculateGrandTotal();

      final Map<String, dynamic> payload = {
        "quotationId": _selectedQuotation?.id,
        "client": _selectedQuotation?.clientName ?? "",
        "ClientId": _selectedQuotation?.clientId ?? "",
        "contact": _selectedQuotation?.contactNo ?? "",
        "address": _selectedQuotation?.address ?? "",
        "walletDifference": grandTotal,
        "grandTotalAmount": grandTotal,
        "additionalDis":
            double.tryParse(_additionalDiscountController.text) ?? 0,
        "isBlackChallan": _isBlackChallan,
        "transportation": double.tryParse(_transportationController.text) ?? 0,
        "unloading": double.tryParse(_unloadingController.text) ?? 0,
        "driverDetails": {
          "deliveryBoy": _driverNameController.text.trim(),
          "contact": _driverContactController.text.trim(),
          "tempo": _vehicleNoController.text.trim(),
        },
        "items": items,
      };

      debugPrint("Payload: ${jsonEncode(payload)}");

      final response = await dio.post(
        "https://dashboard.theceramicstudio.in/api/Quotation/generate-dc",
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

  // ---------- Updated Product Card with conditional prefilled dispatch boxes ----------
  // ---------- Updated Product Card with conditional prefilled dispatch boxes ----------
  Widget _buildProductItem(QuotationItem item) {
    final controller =
        _dispatchBoxesControllers[item.id] ??
        TextEditingController(
          text: item.remainingBoxes > 0 ? item.remainingBoxes.toString() : '',
        );
    final remaining = max(0, item.remainingBoxes);

    // 🔥 Calculate amount for this product
    final dispatchBoxes = double.tryParse(controller.text) ?? 0;
    final productAmount = dispatchBoxes * item.disRate * item.cov;

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
          // Product name and IN STOCK badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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

          const SizedBox(height: 8),

          // Size and Quality
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "Size: ${item.size}",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "Quality: ${item.quality}",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // COV, RATE, REMAINING, DISPATCH BOXES, DELETE
          Row(
            children: [
              // COV
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "COV",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.cov.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // RATE (Discounted Rate)
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "DISC. RATE",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "₹${item.disRate.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // REMAINING
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "REMAINING",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$remaining qty",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // DISPATCH BOXES
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "DISPATCH BOXES",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 40,
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        onChanged: (_) {
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 8,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // DELETE button
              Container(
                margin: const EdgeInsets.only(left: 8),
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _deleteQuotationItem(item.id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 🔥 NEW: Product Amount Row
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFA9C42).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFFA9C42).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Amount:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '₹${productAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFA9C42),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Batches section
          if (item.batches.isNotEmpty) ...[
            const Text(
              "Batches:",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  item.batches.map((batch) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
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
                            "Qty: ${batch.qty} (${batch.location.toUpperCase()})",
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
          ] else ...[
            Text(
              "No batches available",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------- Additional Product Row with auto-update callback ----------
  Widget _buildAdditionalProductRow(
    int index,
    AdditionalProductRow row,
    VoidCallback onUpdate,
  ) {
    final sizes = _getSizesForProduct(row.productName);
    final qualities = _getQualitiesForProduct(row.productName, row.size);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        children: [
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
                            row.size = '';
                            row.quality = '';
                            row.weightController.clear();
                            row.twgtController.clear();
                            row.covController.clear();
                            row.rateController.clear();
                            row.amountController.clear();
                            row.selectedProductDetails = null;

                            _productSearchDebounce?.cancel();
                            _productSearchDebounce = Timer(
                              const Duration(milliseconds: 400),
                              () {
                                if (value.trim().isNotEmpty) {
                                  _fetchProducts(search: value.trim());
                                } else {
                                  setState(() => _filteredProducts = []);
                                }
                              },
                            );
                            setState(() {});
                          },
                          onTap: () {
                            setState(() => row.showProductDropdown = true);
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
                              row.rateController.text =
                                  product['rate']?.toString() ?? '0';
                              row.covController.text =
                                  product['cov']?.toString() ?? '0';
                              row.selectedProductDetails = product;
                              row.showProductDropdown = false;
                              row.updateTotal();
                              onUpdate();
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
                              onUpdate();
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
                              onUpdate();
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) {
                        row.updateTotal();
                        onUpdate();
                      },
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) {
                        row.updateTotal();
                        onUpdate();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

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
                      onChanged: (_) {
                        row.updateTWGT();
                        onUpdate();
                      },
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
                      onChanged: (_) {
                        row.updateTWGT();
                        onUpdate();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

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
            ],
          ),

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

  // ---------- Payment Summary Section ----------
  Widget _buildPaymentSummarySection() {
    if (_selectedQuotation == null) return const SizedBox();

    return Container(
      width: double.infinity,
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
          const Text(
            "PAYMENT SUMMARY",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          if (_isLoadingSummary)
            const Center(child: CircularProgressIndicator())
          else if (_quotationAmount != null) ...[
            _buildSummaryRow(
              "Quotation Amount",
              "₹${_quotationAmount!.toStringAsFixed(2)}",
            ),
            _buildSummaryRow(
              "Paid Amount",
              "₹${_quotationPaidAmount!.toStringAsFixed(2)}",
            ),
            _buildSummaryRow(
              "Wallet Balance",
              "₹${_customerWalletAmount!.toStringAsFixed(2)}",
            ),
            if (_additionalDiscount != null)
              _buildSummaryRow(
                "Additional Discount",
                "${_additionalDiscount!.toStringAsFixed(0)}%",
              ),
          ],

          const Divider(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Delivery Challan Amount",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                "₹${_calculateGrandTotal().toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFA9C42),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ---------- Challan Type Toggle ----------
  Widget _buildChallanTypeToggle() {
    return Container(
      width: double.infinity,
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
          const Text(
            "CHALLAN TYPE",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isBlackChallan = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          _isBlackChallan == true
                              ? Colors.blue
                              : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '',
                        style: TextStyle(
                          color:
                              _isBlackChallan == true
                                  ? Colors.white
                                  : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isBlackChallan = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          _isBlackChallan == false
                              ? Colors.red
                              : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '',
                        style: TextStyle(
                          color:
                              _isBlackChallan == false
                                  ? Colors.white
                                  : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Search Bar ----------
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

  // ---------- Selected Quotation Card ----------
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

  // ---------- Dispatch Logistics ----------
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
            "DISPATCH LOGISTICS (Optional)",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),

          _buildInputField(
            label: "Driver Name (Optional)",
            hintText: "Enter driver name",
            controller: _driverNameController,
            icon: Icons.person_outline,
          ),

          const SizedBox(height: 12),

          _buildInputField(
            label: "Contact (Optional)",
            hintText: "Enter contact number",
            controller: _driverContactController,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 12),

          _buildInputField(
            label: "Vehicle No (Optional)",
            hintText: "Enter vehicle number",
            controller: _vehicleNoController,
            icon: Icons.local_shipping_outlined,
          ),
          const SizedBox(height: 10),

          // Transportation
          _buildInputField(
            label: "Transportation (₹)",
            hintText: "Enter transportation amount",
            controller: _transportationController,
            icon: Icons.local_shipping_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),

          const SizedBox(height: 12),

          // Unloading
          _buildInputField(
            label: "Unloading (₹)",
            hintText: "Enter unloading amount",
            controller: _unloadingController,
            icon: Icons.unarchive_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                  onChanged: (_) {
                    setState(() {});
                  },
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

  // ---------- Main Build ----------
  @override
  Widget build(BuildContext context) {
    final subtotal = _calculateTotalAmount();
    final additionalDiscount =
        double.tryParse(_additionalDiscountController.text) ?? 0;
    final transportation = double.tryParse(_transportationController.text) ?? 0;
    final unloading = double.tryParse(_unloadingController.text) ?? 0;

    final discountAmount = subtotal * (additionalDiscount / 100);
    final discountedSubtotal = subtotal - discountAmount;
    final grandTotal = discountedSubtotal + transportation + unloading;

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
      body:
          _isLoadingQuotation // 👈 show loading while fetching initial quotation
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFA9C42)),
              )
              : GestureDetector(
                onTap: () {
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
                      _buildSearchBar(),
                      const SizedBox(height: 20),

                      // 👇 Everything below is shown only if a quotation is selected
                      if (_selectedQuotation != null) ...[
                        _buildSelectedQuotation(),
                        const SizedBox(height: 20),
                        _buildPaymentSummarySection(),
                        const SizedBox(height: 20),
                        _buildChallanTypeToggle(),
                        const SizedBox(height: 20),
                        _buildDispatchLogistics(),
                        const SizedBox(height: 24),

                        if (_displayedQuotationItems.isNotEmpty) ...[
                          const Text(
                            "PRODUCTS FROM QUOTATION",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._displayedQuotationItems
                              .map(_buildProductItem)
                              .toList(),
                          const SizedBox(height: 24),
                        ],

                        const Text(
                          "ADDITIONAL PRODUCTS",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFA9C42),
                          ),
                        ),
                        const SizedBox(height: 16),

                        ..._additionalRows.asMap().entries.map(
                          (entry) => _buildAdditionalProductRow(
                            entry.key,
                            entry.value,
                            _refreshGrandTotal,
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _addAdditionalRow,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFFA9C42),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add,
                                      color: Color(0xFFFA9C42),
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "+ ADD PRODUCT",
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

                        const SizedBox(height: 20),

                        // Grand Total Section
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
                              // Subtotal
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Subtotal',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
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
                              const SizedBox(height: 8),
                              // Transportation
                              if (transportation != 0)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Transportation',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      '+₹${transportation.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              // Unloading
                              if (unloading != 0)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Unloading',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      '+₹${unloading.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              if (transportation != 0 || unloading != 0)
                                const SizedBox(height: 8),

                              // Additional Discount
                              // if (additionalDiscount > 0) ...[
                              //   Row(
                              //     mainAxisAlignment:
                              //         MainAxisAlignment.spaceBetween,
                              //     children: [
                              //       Text(
                              //         'Additional Discount ($additionalDiscount%)',
                              //         style: const TextStyle(
                              //           fontSize: 14,
                              //           color: Colors.green,
                              //         ),
                              //       ),
                              //       Text(
                              //         '-₹${discountAmount.toStringAsFixed(2)}',
                              //         style: const TextStyle(
                              //           fontSize: 14,
                              //           fontWeight: FontWeight.w500,
                              //           color: Colors.green,
                              //         ),
                              //       ),
                              //     ],
                              //   ),
                              //   const SizedBox(height: 8),
                              // ],
                              const Divider(height: 24, thickness: 1),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                _isSubmitting ? null : _generateDeliveryChallan,
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
                    ],
                  ),
                ),
              ),
    );
  }
}
