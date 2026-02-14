import 'dart:async';
import 'dart:convert';
import 'dart:io';
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

/// ================= ADD DELIVERY CHALLAN SCREEN =================
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

  // Dispatch boxes controllers for each item
  final Map<int, TextEditingController> _dispatchBoxesControllers = {};

  // Loading states
  bool _isSearching = false;
  bool _isSubmitting = false;

  // Quotations list for search
  List<Quotation> _quotations = [];

  // Search with debounce
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    // Initialize controllers for existing items
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedQuotation != null) {
        _initializeControllers();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _driverNameController.dispose();
    _driverContactController.dispose();
    _vehicleNoController.dispose();

    // Dispose all dispatch boxes controllers
    _dispatchBoxesControllers.forEach((key, controller) {
      controller.dispose();
    });

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
    });

    // Initialize controllers for items
    _initializeControllers();
  }

  void _clearSelection() {
    setState(() {
      _selectedQuotation = null;
      _dispatchBoxesControllers.clear();
    });
  }

  Future<void> _generateDeliveryChallan() async {
    // Validate inputs
    if (_selectedQuotation == null) {
      _showError("Please select a quotation");
      return;
    }

    if (_driverNameController.text.isEmpty) {
      _showError("Please enter driver name");
      return;
    }

    if (_driverContactController.text.isEmpty) {
      _showError("Please enter driver contact");
      return;
    }

    if (_vehicleNoController.text.isEmpty) {
      _showError("Please enter vehicle number");
      return;
    }

    // Check if at least one dispatch box is entered
    bool hasDispatchBoxes = false;
    for (var controller in _dispatchBoxesControllers.values) {
      final value = int.tryParse(controller.text) ?? 0;
      if (value > 0) {
        hasDispatchBoxes = true;
        break;
      }
    }

    if (!hasDispatchBoxes) {
      _showError("Please enter dispatch boxes for at least one product");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Prepare items for API
      final List<Map<String, dynamic>> items = [];

      for (var item in _selectedQuotation!.items) {
        final controller = _dispatchBoxesControllers[item.id];
        final dispatchBoxes = int.tryParse(controller?.text ?? '0') ?? 0;

        if (dispatchBoxes > 0) {
          // Find rate from original item data (you might need to store rate in your model)
          // For now, using a placeholder rate
          final rate = "120.00"; // You should get this from your item data

          items.add({
            "productId": item.productId,
            "productName": item.productName,
            "dispatchBoxes": dispatchBoxes,
            "rate": rate,
          });
        }
      }

      final Map<String, dynamic> payload = {
        "quotationId": _selectedQuotation!.id,
        "client": _selectedQuotation!.clientName,
        "contact": _selectedQuotation!.contactNo,
        "address": _selectedQuotation!.address,
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

          // Clear form and go back
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// SEARCH BAR
            _buildSearchBar(),

            const SizedBox(height: 20),

            /// SELECTED QUOTATION
            if (_selectedQuotation != null) ...[
              _buildSelectedQuotation(),
              const SizedBox(height: 24),

              /// DISPATCH LOGISTICS
              _buildDispatchLogistics(),
              const SizedBox(height: 24),

              /// PRODUCTS LIST
              _buildProductsList(),
              const SizedBox(height: 32),

              /// GENERATE BUTTON
              _buildGenerateButton(),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

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

          // Search results
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

          // Driver Name
          _buildInputField(
            label: "Driver Name",
            hintText: "Enter driver name",
            controller: _driverNameController,
            icon: Icons.person_outline,
          ),

          const SizedBox(height: 12),

          // Driver Contact
          _buildInputField(
            label: "Contact",
            hintText: "Enter contact number",
            controller: _driverContactController,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 12),

          // Vehicle Number
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

  Widget _buildProductsList() {
    if (_selectedQuotation == null || _selectedQuotation!.items.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "PRODUCTS",
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
          // Product name header
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

          // Batches
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

          // Stock info and dispatch boxes
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

  Widget _buildGenerateButton() {
    return SizedBox(
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
          elevation: 0,
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
                  "Generate Delivery Challan",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
      ),
    );
  }
}
