import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // 👈 QR scanner import

class EditQuotationScreen extends StatefulWidget {
  final String quotationId;
  final Map<String, dynamic> quotationData;

  const EditQuotationScreen({
    super.key,
    required this.quotationId,
    required this.quotationData,
  });

  @override
  State<EditQuotationScreen> createState() => _EditQuotationScreenState();
}

class _EditQuotationScreenState extends State<EditQuotationScreen> {
  final Dio _dio = Dio();

  // Client Details Controllers
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientGstController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _altNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _siteAddressController = TextEditingController();

  // Header and Bottom Sections
  final TextEditingController _headerController = TextEditingController();
  final TextEditingController _bottomController = TextEditingController();

  // Additional Discount & Charges
  final TextEditingController _additionalDiscountController =
      TextEditingController(text: '0');
  final TextEditingController _transportationController = TextEditingController(
    text: '0',
  );
  final TextEditingController _unloadingController = TextEditingController(
    text: '0',
  );

  // Architect Data
  List<dynamic> _architects = [];
  String? _selectedArchitectId;
  String? _selectedArchitectName;

  // Attended By Data
  List<dynamic> _employees = [];
  String? _selectedEmployeeId;
  String? _selectedEmployeeName;

  // All products (full list, fetched once) – used for size/quality dropdowns and product details
  List<dynamic> _allProducts = [];

  // Filtered products from search API – used for the search dropdown
  List<dynamic> _filteredProducts = [];

  // Debouncer for product search
  Timer? _productSearchDebounce;

  // Product rows
  List<ProductRow> _productRows = [];

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isLoadingArchitects = false;
  bool _isLoadingEmployees = false;

  // Scroll controller for keyboard handling
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await _fetchArchitects();
      await _fetchEmployees('');
      await _fetchAllProducts();
      _populateFormData();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error initializing data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateFormData() {
    final quotationData = widget.quotationData;
    debugPrint("Quotation Data Keys: ${quotationData.keys}");
    debugPrint("GST Value: ${quotationData['GstNumber']}");
    debugPrint('Received quotation data: $quotationData');

    /// ================= CLIENT DETAILS =================
    _clientNameController.text = quotationData['clientName']?.toString() ?? '';
    _contactNumberController.text =
        quotationData['contactNo']?.toString() ?? '';
    _altNumberController.text = quotationData['altContactNo']?.toString() ?? '';
    _emailController.text = quotationData['email']?.toString() ?? '';
    _clientGstController.text = quotationData['GstNumber']?.toString() ?? '';
    _siteAddressController.text = quotationData['address']?.toString() ?? '';

    /// ================= ADDITIONAL CHARGES =================
    _additionalDiscountController.text =
        quotationData['additionalDiscount']?.toString() ?? '0';
    _transportationController.text =
        quotationData['transportation']?.toString() ?? '0';
    _unloadingController.text = quotationData['unloading']?.toString() ?? '0';

    _headerController.text = quotationData['headerSection']?.toString() ?? '';
    _bottomController.text = quotationData['bottomSection']?.toString() ?? '';

    _selectedArchitectId = quotationData['architect']?.toString();
    _selectedEmployeeId = quotationData['attendedBy']?.toString();

    /// ================= PRODUCT ROWS =================
    final items = quotationData['items'] ?? [];

    debugPrint("Items length: ${items.length}");

    _productRows =
        items.map<ProductRow>((item) {
          final row = ProductRow(
            onChanged: () {
              setState(() {}); // refresh totals
            },
          );

          // Set all fields from item
          row.productId = item['productId'];
          row.productName = (item['productName'] ?? '').toString().trim();
          row.size = (item['size'] ?? '').toString().trim();
          row.quality = (item['quality'] ?? '').toString().trim();
          row.godown = 'KKW';

          row.rateController.text = item['rate']?.toString() ?? '0';
          row.covController.text = item['cov']?.toString() ?? '0';
          row.areaController.text = item['area']?.toString() ?? '';
          row.weightController.text = item['weight']?.toString() ?? '0';
          row.quantityController.text = item['box']?.toString() ?? '0';
          row.discountController.text = item['discount']?.toString() ?? '0';
          row.totalAmountController.text = item['total']?.toString() ?? '0';
          row.productSearchController.text = row.productName;

          // If API provides disRate, set it, otherwise calculate later
          if (item['disRate'] != null) {
            row.discountedRateController.text = item['disRate'].toString();
          }

          // Validate and correct product using _allProducts (if available)
          if (_allProducts.isNotEmpty) {
            final matchedProduct = _getProductDetails(
              row.productName,
              row.size,
              row.quality,
            );
            if (matchedProduct != null) {
              row.productId = matchedProduct['id'];
              row.productName =
                  (matchedProduct['name'] ?? '').toString().trim();
              row.size = (matchedProduct['size'] ?? '').toString().trim();
              row.quality = (matchedProduct['quality'] ?? '').toString().trim();
              row.rateController.text =
                  matchedProduct['rate']?.toString() ?? row.rateController.text;
              row.covController.text =
                  matchedProduct['cov']?.toString() ?? row.covController.text;
              row.productSearchController.text = row.productName;
            } else {
              debugPrint(
                'No match found for product: ${row.productName} ${row.size} ${row.quality}',
              );
            }
          }

          row.updateTWGT();
          row.updateTotal();

          return row;
        }).toList();

    if (_productRows.isEmpty) {
      _productRows.add(ProductRow(onChanged: () => setState(() {})));
    }

    setState(() {});
  }

  Future<void> _fetchArchitects() async {
    setState(() => _isLoadingArchitects = true);
    try {
      final response = await _dio.get(
        'https://dashboard.theceramicstudio.in/api/architects/list',
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() => _architects = response.data['architects']);
      }
    } catch (e) {
      debugPrint('Architect fetch error: $e');
    } finally {
      setState(() => _isLoadingArchitects = false);
    }
  }

  Future<void> _fetchEmployees(String search) async {
    setState(() => _isLoadingEmployees = true);
    try {
      final response = await _dio.get(
        'https://dashboard.theceramicstudio.in/api/employees/list',
        queryParameters: {'search': search},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() => _employees = response.data['employees']);
      }
    } catch (e) {
      debugPrint('Employees fetch error: $e');
    } finally {
      setState(() => _isLoadingEmployees = false);
    }
  }

  Future<void> _fetchAllProducts() async {
    try {
      final response = await _dio.get(
        'https://dashboard.theceramicstudio.in/api/product/list',
        queryParameters: {'search': ''},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _allProducts = response.data['products'];
          debugPrint('Fetched ${_allProducts.length} products');
        });
      }
    } catch (e) {
      debugPrint('Fetch all products error: $e');
    }
  }

  Future<void> _searchProducts(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _filteredProducts = []);
      return;
    }
    try {
      final response = await _dio.get(
        'https://dashboard.theceramicstudio.in/api/product/list',
        queryParameters: {'search': query.trim()},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() => _filteredProducts = response.data['products']);
      }
    } catch (e) {
      debugPrint('Product search error: $e');
    }
  }

  /// Fetch a single product by its ID (for QR scan)
  Future<Map<String, dynamic>?> _fetchProductById(int productId) async {
    try {
      final response = await _dio.get(
        'https://dashboard.theceramicstudio.in/api/product/list/$productId',
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['product'];
      }
    } catch (e) {
      debugPrint('Error fetching product by ID: $e');
    }
    return null;
  }

  List<String> _getSizesForProduct(String productName) {
    if (productName.isEmpty) return [];
    final normalizedName = productName.trim().toLowerCase();
    final productsWithSameName =
        _allProducts.where((p) {
          final name = (p['name']?.toString() ?? '').trim().toLowerCase();
          return name == normalizedName;
        }).toList();
    if (productsWithSameName.isEmpty) return [];
    return productsWithSameName
        .map((p) => p['size']?.toString().trim() ?? '')
        .where((size) => size.isNotEmpty)
        .toSet()
        .toList();
  }

  List<String> _getQualitiesForProduct(String productName, String size) {
    if (productName.isEmpty || size.isEmpty) return [];
    final normalizedName = productName.trim().toLowerCase();
    final normalizedSize = size.trim();
    final productsWithSameNameAndSize =
        _allProducts.where((p) {
          final name = (p['name']?.toString() ?? '').trim().toLowerCase();
          final pSize = (p['size']?.toString() ?? '').trim();
          return name == normalizedName && pSize == normalizedSize;
        }).toList();
    if (productsWithSameNameAndSize.isEmpty) return [];
    return productsWithSameNameAndSize
        .map((p) => p['quality']?.toString().trim() ?? '')
        .where((quality) => quality.isNotEmpty)
        .toSet()
        .toList();
  }

  Map<String, dynamic>? _getProductDetails(
    String productName,
    String size,
    String quality,
  ) {
    try {
      final normalizedName = productName.trim().toLowerCase();
      final normalizedSize = size.trim();
      final normalizedQuality = quality.trim();
      return _allProducts.firstWhere((p) {
        final name = (p['name']?.toString() ?? '').trim().toLowerCase();
        final pSize = (p['size']?.toString() ?? '').trim();
        final pQuality = (p['quality']?.toString() ?? '').trim();
        return name == normalizedName &&
            pSize == normalizedSize &&
            pQuality == normalizedQuality;
      });
    } catch (e) {
      return null;
    }
  }

  void _addProductRow() {
    setState(() {
      _productRows.add(ProductRow(onChanged: () => setState(() {})));
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  /// Add a new product row and pre-fill it with product details (for QR scan)
  void _addProductRowWithData(Map<String, dynamic> product) {
    // Add to _allProducts for dropdowns if not already present
    bool exists = _allProducts.any((p) => p['id'] == product['id']);
    if (!exists) {
      _allProducts.add(product);
      // Also add to _filteredProducts for search dropdown consistency
      _filteredProducts.add(product);
    }

    final row = ProductRow(onChanged: () => setState(() {}));
    row.productId = product['id'];
    row.productName = product['name'] ?? '';
    row.size = product['size']?.toString() ?? '';
    row.quality = product['quality']?.toString() ?? '';
    row.rateController.text = product['rate']?.toString() ?? '0';
    row.covController.text = product['cov']?.toString() ?? '0';
    row.productSearchController.text = product['name'] ?? '';

    if (product['godown'] != null &&
        product['godown'] is List &&
        product['godown'].isNotEmpty) {
      row.godown = product['godown'][0];
    }

    row.updateTWGT();
    row.updateTotal();

    setState(() {
      _productRows.add(row);
    });

    // Scroll to new row
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _removeProductRow(int index) {
    setState(() => _productRows.removeAt(index));
  }

  // ---------- QR CODE SCANNING ----------
  void _scanQrCode() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Scan Product QR'),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: 300,
              child: MobileScanner(
                onDetect: (BarcodeCapture capture) async {
                  final barcodes = capture.barcodes;
                  if (barcodes.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No QR code found')),
                    );
                    return;
                  }

                  final code = barcodes.first.rawValue;
                  if (code == null || code.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid QR code')),
                    );
                    return;
                  }

                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context); // close scanner

                  final productId = int.tryParse(code);
                  if (productId == null) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Invalid product ID in QR code'),
                      ),
                    );
                    return;
                  }

                  messenger.showSnackBar(
                    const SnackBar(content: Text('Fetching product...')),
                  );

                  final product = await _fetchProductById(productId);
                  if (product == null) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Product not found')),
                    );
                    return;
                  }

                  _addProductRowWithData(product);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Product "${product['name']}" added'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  double _calculateTotalAmount() {
    double total = 0;
    for (var row in _productRows) {
      total += row.getTotalAmount();
    }
    return total;
  }

  double _calculateGrandTotal() {
    double subtotal = _calculateTotalAmount();
    double additionalDiscount =
        double.tryParse(_additionalDiscountController.text) ?? 0;
    double transportation =
        double.tryParse(_transportationController.text) ?? 0;
    double unloading = double.tryParse(_unloadingController.text) ?? 0;

    double discountAmount = subtotal * (additionalDiscount / 100);
    double afterDiscount = subtotal - discountAmount;
    return afterDiscount + transportation + unloading;
  }

  bool _validateForm() {
    if (_clientNameController.text.trim().isEmpty) {
      _showSnackBar('Please enter client name');
      return false;
    }
    if (_contactNumberController.text.trim().isEmpty) {
      _showSnackBar('Please enter contact number');
      return false;
    }
    if (_siteAddressController.text.trim().isEmpty) {
      _showSnackBar('Please enter site address');
      return false;
    }
    // Architect and Attended By are now optional
    // if (_selectedArchitectId == null) {
    //   _showSnackBar('Please select an architect');
    //   return false;
    // }
    // if (_selectedEmployeeId == null) {
    //   _showSnackBar('Please select attended by');
    //   return false;
    // }
    for (int i = 0; i < _productRows.length; i++) {
      final row = _productRows[i];
      if (row.productName.isEmpty) {
        _showSnackBar('Please select product for row ${i + 1}');
        return false;
      }
      if (row.size.isEmpty) {
        _showSnackBar('Please select size for row ${i + 1}');
        return false;
      }
      if (row.quality.isEmpty) {
        _showSnackBar('Please select quality for row ${i + 1}');
        return false;
      }
      if (row.quantityController.text.trim().isEmpty ||
          double.tryParse(row.quantityController.text) == 0) {
        _showSnackBar('Please enter valid quantity for row ${i + 1}');
        return false;
      }
      if (row.productId == null) {
        _showSnackBar(
          'Product ID not found for row ${i + 1}. Please reselect the product.',
        );
        return false;
      }
    }
    return true;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _updateQuotation() async {
    if (!_validateForm()) return;
    setState(() => _isSubmitting = true);

    try {
      List<Map<String, dynamic>> rowsData = [];
      for (var row in _productRows) {
        final productDetails = _getProductDetails(
          row.productName,
          row.size,
          row.quality,
        );
        if (productDetails == null && row.productId == null) {
          throw Exception('Product details not found for ${row.productName}');
        }

        final rate = double.tryParse(row.rateController.text) ?? 0;
        final discount = double.tryParse(row.discountController.text) ?? 0;
        final discountedRate = rate * (1 - discount / 100);
        final discountPerUnit = rate * discount / 100; // DisAmount

        rowsData.add({
          "productId": row.productId ?? productDetails?['id'],
          "productName": row.productName,
          "size": row.size,
          "quality": row.quality,
          "rate": rate,
          "box": int.tryParse(row.quantityController.text) ?? 0,
          "area": row.areaController.text.trim(),
          "Coverage": double.parse(
            row.covController.text.isEmpty ? "0" : row.covController.text,
          ).toStringAsFixed(2),
          "TWgt": double.parse(
            row.twgtController.text.isEmpty ? "0" : row.twgtController.text,
          ).toStringAsFixed(2),
          "total": double.parse(
            row.totalAmountController.text.isEmpty
                ? "0"
                : row.totalAmountController.text,
          ).toStringAsFixed(2),
          "Weight": double.tryParse(row.weightController.text) ?? 0,
          "cov": double.tryParse(row.covController.text) ?? 0,
          "discount": discount,
          "disRate": discountedRate,
          "DisAmount": discountPerUnit,
        });
      }

      final clientDetails = {
        "name": _clientNameController.text.trim(),
        "contactNo": _contactNumberController.text.trim(),
        "altContactNo": _altNumberController.text.trim(),
        "email": _emailController.text.trim(),
        "GstNumber": _clientGstController.text.trim(),
        "address": _siteAddressController.text.trim(),
        "architect": _selectedArchitectId ?? "",
        "attendedBy": _selectedEmployeeId ?? "",
        "transportation": _transportationController.text,
        "unloading": _unloadingController.text,
        // Extra fields from sample
        "clientid": null,
        "Attended": "",
      };

      final headerSection = _headerController.text.trim();
      final bottomSection = _bottomController.text.trim();

      final requestBody = {
        "additionalDiscount":
            double.tryParse(_additionalDiscountController.text) ?? 0,
        "headerSection": headerSection,
        "bottomSection": bottomSection,
        "clientDetails": clientDetails,
        "rows": rowsData,
        "grandTotal": double.parse(_calculateGrandTotal().toStringAsFixed(2)),
      };

      debugPrint('Update Request Body: ${requestBody.toString()}');

      final response = await _dio.put(
        'https://dashboard.theceramicstudio.in/api/Quotation/updateQuotation/${widget.quotationId}',
        data: requestBody,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                responseData['message'] ?? 'Quotation updated successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pop(context, true);
          });
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to update quotation',
          );
        }
      } else {
        throw Exception('Failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Update quotation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // Helper methods for dropdowns
  String? _getValidArchitectId() {
    if (_selectedArchitectId == null) return null;
    final exists = _architects.any(
      (a) => a['id'].toString() == _selectedArchitectId,
    );
    if (!exists) {
      debugPrint(
        'Architect ID $_selectedArchitectId not found in list, setting to null',
      );
      return null;
    }
    return _selectedArchitectId;
  }

  String? _getValidEmployeeId() {
    if (_selectedEmployeeId == null) return null;
    final exists = _employees.any(
      (e) => e['id'].toString() == _selectedEmployeeId,
    );
    if (!exists) {
      debugPrint(
        'Employee ID $_selectedEmployeeId not found in list, setting to null',
      );
      return null;
    }
    return _selectedEmployeeId;
  }

  String? _getValidSize(ProductRow row, List<String> sizes) {
    if (row.size.isEmpty) return null;
    // Keep quotation size even if not in master list
    return row.size;
  }

  String? _getValidQuality(ProductRow row, List<String> qualities) {
    if (row.quality.isEmpty) return null;
    return row.quality;
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _calculateTotalAmount();
    final additionalDiscount =
        double.tryParse(_additionalDiscountController.text) ?? 0;
    final discountAmount = totalAmount * (additionalDiscount / 100);
    final transportation = double.tryParse(_transportationController.text) ?? 0;
    final unloading = double.tryParse(_unloadingController.text) ?? 0;
    final grandTotal = _calculateGrandTotal();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffFFA54A),
        title: const Text(
          'Edit Quotation',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // QR Scan Button
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            onPressed: _scanQrCode,
            tooltip: 'Scan product QR',
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xffFFA54A)),
              )
              : GestureDetector(
                onTap: () {
                  setState(() {
                    for (var row in _productRows) {
                      row.showProductDropdown = false;
                    }
                  });
                  FocusScope.of(context).unfocus();
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      // CLIENT DETAILS SECTION
                      const Text(
                        'CLIENT DETAILS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xffFFA54A),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Client Full Name
                      _buildClientLabel('CLIENT FULL NAME'),
                      const SizedBox(height: 4),
                      _buildClientTextField(
                        _clientNameController,
                        'Type here...',
                      ),
                      const SizedBox(height: 12),

                      // Client GST Number
                      _buildClientLabel('CLIENT GST NUMBER'),
                      const SizedBox(height: 4),
                      _buildClientTextField(_clientGstController, '27XXXXX...'),
                      const SizedBox(height: 12),

                      // Contact Number and Alt Number (Phone keyboard)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildClientLabel('CONTACT NUMBER'),
                                const SizedBox(height: 4),
                                _buildClientTextField(
                                  _contactNumberController,
                                  '+91',
                                  keyboardType: TextInputType.phone,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildClientLabel('ALT NUMBER'),
                                const SizedBox(height: 4),
                                _buildClientTextField(
                                  _altNumberController,
                                  '+91',
                                  keyboardType: TextInputType.phone,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Client Email
                      _buildClientLabel('CLIENT EMAIL'),
                      const SizedBox(height: 4),
                      _buildClientTextField(
                        _emailController,
                        'client@example.com',
                      ),
                      const SizedBox(height: 12),

                      // Site Address
                      _buildClientLabel('SITE ADDRESS'),
                      const SizedBox(height: 4),
                      _buildClientTextField(
                        _siteAddressController,
                        'Full location...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),

                      // Architect and Attended By
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildClientLabel('SELECT ARCHITECT'),
                                const SizedBox(height: 4),
                                Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: _getValidArchitectId(),
                                      hint:
                                          _isLoadingArchitects
                                              ? const Text('Loading...')
                                              : const Text(
                                                'Choose Architect...',
                                              ),
                                      items:
                                          _architects.map((architect) {
                                            final fullName =
                                                '${architect['firstname']} ${architect['lastname']}';
                                            return DropdownMenuItem<String>(
                                              value: architect['id'].toString(),
                                              child: Text(fullName),
                                            );
                                          }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedArchitectId = value;
                                          final selectedArchitect = _architects
                                              .firstWhere(
                                                (a) =>
                                                    a['id'].toString() == value,
                                                orElse: () => null,
                                              );
                                          if (selectedArchitect != null) {
                                            _selectedArchitectName =
                                                '${selectedArchitect['firstname']} ${selectedArchitect['lastname']}';
                                          }
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
                                _buildClientLabel('ATTENDED BY'),
                                const SizedBox(height: 4),
                                Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: _getValidEmployeeId(),
                                      hint:
                                          _isLoadingEmployees
                                              ? const Text('Loading...')
                                              : const Text('Choose Person...'),
                                      items:
                                          _employees.map((employee) {
                                            return DropdownMenuItem<String>(
                                              value: employee['id'].toString(),
                                              child: Text(
                                                employee['name'] ?? '',
                                              ),
                                            );
                                          }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedEmployeeId = value;
                                          final selectedEmployee = _employees
                                              .firstWhere(
                                                (e) =>
                                                    e['id'].toString() == value,
                                                orElse: () => null,
                                              );
                                          if (selectedEmployee != null) {
                                            _selectedEmployeeName =
                                                selectedEmployee['name'];
                                          }
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

                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),

                      // HEADER SECTION (Introduction Note)
                      const Text(
                        'INTRODUCTION NOTE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xffFFA54A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _headerController,
                          maxLines: 4,
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            hintText:
                                'This is with reference to our discussion with you regarding your requirement...',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),

                      // PRODUCT DETAILS SECTION
                      const Text(
                        'PRODUCT DETAILS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xffFFA54A),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Product Rows
                      ..._productRows.asMap().entries.map((entry) {
                        final index = entry.key;
                        final row = entry.value;
                        return _buildProductRow(index, row);
                      }),

                      // Add Product Button
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _addProductRow,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xffFFA54A),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add,
                                    color: Color(0xffFFA54A),
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "+ ADD PRODUCT ROW",
                                    style: TextStyle(
                                      color: Color(0xffFFA54A),
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

                      // Additional Discount Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildClientLabel('ADDITIONAL DISCOUNT'),
                            const SizedBox(height: 8),
                            _buildClientTextField(
                              _additionalDiscountController,
                              'Enter discount percentage...',
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This discount will be applied on the total amount',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Transportation & Unloading Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ADDITIONAL CHARGES',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildClientLabel('TRANSPORTATION (₹)'),
                                      const SizedBox(height: 4),
                                      _buildClientTextField(
                                        _transportationController,
                                        '0',
                                        onChanged: (_) => setState(() {}),
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildClientLabel('UNLOADING (₹)'),
                                      const SizedBox(height: 4),
                                      _buildClientTextField(
                                        _unloadingController,
                                        '0',
                                        onChanged: (_) => setState(() {}),
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'These charges will be added to the final total.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // FINAL QUOTATION VALUE SECTION
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xffFFA54A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xffFFA54A).withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Subtotal
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Subtotal',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  '₹${totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Additional Discount
                            if (additionalDiscount > 0)
                              Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                  const SizedBox(height: 8),
                                ],
                              ),

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

                            Divider(color: Colors.grey.shade400, thickness: 1),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Final Quotation Value',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xffFFA54A),
                                  ),
                                ),
                                Text(
                                  '₹${grandTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xffFFA54A),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffFFA54A),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isSubmitting ? null : _updateQuotation,
                          child:
                              _isSubmitting
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Text(
                                    'Update Quotation',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildClientLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildClientTextField(
    TextEditingController controller,
    String hintText, {
    int maxLines = 1,
    void Function(String)? onChanged,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
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

  // ========== PRODUCT ROW UI ==========
  Widget _buildProductRow(int index, ProductRow row) {
    final sizes =
        row.size.isNotEmpty
            ? [
              row.size,
              ..._getSizesForProduct(row.productName),
            ].toSet().toList()
            : _getSizesForProduct(row.productName);
    final qualities =
        row.quality.isNotEmpty
            ? [
              row.quality,
              ..._getQualitiesForProduct(row.productName, row.size),
            ].toSet().toList()
            : _getQualitiesForProduct(row.productName, row.size);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('PRODUCT'),
          const SizedBox(height: 4),
          _buildProductSearchField(row),

          const SizedBox(height: 12),

          // Row 1: Size | Quality | Rate
          Row(
            children: [
              Expanded(child: _buildSizeDropdown(row, sizes)),
              const SizedBox(width: 8),
              Expanded(child: _buildQualityDropdown(row, qualities)),
              const SizedBox(width: 8),
              Expanded(child: _buildRateField(row)),
            ],
          ),

          const SizedBox(height: 12),

          // Row 2: Coverage | Area | Box
          Row(
            children: [
              Expanded(child: _buildCoverageField(row)),
              const SizedBox(width: 8),
              Expanded(child: _buildAreaField(row)),
              const SizedBox(width: 8),
              Expanded(child: _buildBoxField(row)),
            ],
          ),

          const SizedBox(height: 12),

          // Row 3: Discount % | Weight | TWGT
          Row(
            children: [
              Expanded(child: _buildDiscountField(row)),
              const SizedBox(width: 8),
              Expanded(child: _buildWeightField(row)),
              const SizedBox(width: 8),
              Expanded(child: _buildTwgtField(row)), // read-only
            ],
          ),

          const SizedBox(height: 12),

          // Row 4: Discounted Rate | Total Amount | Godown
          Row(
            children: [
              Expanded(child: _buildDiscountedRateField(row)), // read-only
              const SizedBox(width: 8),
              Expanded(child: _buildTotalAmountField(row)), // read-only
              // const SizedBox(width: 8),
              // Expanded(child: _buildGodownDropdown(row)),
            ],
          ),

          if (_productRows.length > 1) _buildDeleteButton(index),
        ],
      ),
    );
  }

  Widget _buildProductSearchField(ProductRow row) {
    return Container(
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
                      setState(() {
                        row.productName = value;
                        row.showProductDropdown = value.isNotEmpty;
                        row.size = '';
                        row.quality = '';
                        row.weightController.clear();
                        row.twgtController.clear();
                        row.covController.clear();
                        row.rateController.clear();
                        row.totalAmountController.clear();
                        row.discountedRateController.clear();
                      });

                      if (_productSearchDebounce?.isActive ?? false) {
                        _productSearchDebounce!.cancel();
                      }
                      _productSearchDebounce = Timer(
                        const Duration(milliseconds: 400),
                        () => _searchProducts(value),
                      );
                    },
                    onTap: () {
                      setState(() {
                        row.showProductDropdown = true;
                      });
                      if (row.productName.isNotEmpty) {
                        _searchProducts(row.productName);
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search product...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (row.showProductDropdown && row.productName.isNotEmpty)
            _buildProductDropdown(row),
        ],
      ),
    );
  }

  Widget _buildProductDropdown(ProductRow row) {
    final filtered =
        _filteredProducts
            .where(
              (p) => p['name'].toString().toLowerCase().contains(
                row.productName.toLowerCase(),
              ),
            )
            .toList();
    return Container(
      height: 150,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: ListView.builder(
        itemCount: filtered.length,
        itemBuilder: (context, idx) {
          final product = filtered[idx];
          return ListTile(
            dense: true,
            title: Text(product['name'] ?? ''),
            subtitle: Text(
              'Size: ${product['size']} | Quality: ${product['quality']}',
            ),
            onTap: () {
              setState(() {
                row.productId = product['id'];
                row.productName = (product['name'] ?? '').toString().trim();
                row.size = (product['size'] ?? '').toString().trim();
                row.quality = (product['quality'] ?? '').toString().trim();
                row.productSearchController.text = row.productName;
                row.rateController.text = product['rate']?.toString() ?? '0';
                row.covController.text = product['cov']?.toString() ?? '0';
                row.showProductDropdown = false;
                row.updateTotal();
                FocusScope.of(context).unfocus();
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildSizeDropdown(ProductRow row, List<String> sizes) {
    return Column(
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
              value: _getValidSize(row, sizes),
              hint: const Text('Select'),
              items:
                  sizes.map((s) {
                    return DropdownMenuItem<String>(value: s, child: Text(s));
                  }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  row.size = value;
                  row.quality = '';
                  row.rateController.clear();
                  row.covController.clear();
                  row.discountedRateController.clear();
                  row.totalAmountController.clear();
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQualityDropdown(ProductRow row, List<String> qualities) {
    return Column(
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
              value: _getValidQuality(row, qualities),
              hint: const Text('Select'),
              items:
                  qualities.map((q) {
                    return DropdownMenuItem<String>(value: q, child: Text(q));
                  }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  row.quality = value;
                  final productDetails = _getProductDetails(
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
                  }
                  row.updateTotal();
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRateField(ProductRow row) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('RATE (₹)'),
        const SizedBox(height: 4),
        _buildTextField(
          row.rateController,
          '0',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => row.updateTotal(),
        ),
      ],
    );
  }

  Widget _buildCoverageField(ProductRow row) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('COVERAGE'),
        const SizedBox(height: 4),
        _buildTextField(
          row.covController,
          '0',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => row.updateTotal(),
        ),
      ],
    );
  }

  Widget _buildAreaField(ProductRow row) {
    return Column(
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
    );
  }

  Widget _buildBoxField(ProductRow row) {
    return Column(
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
    );
  }

  Widget _buildDiscountField(ProductRow row) {
    return Column(
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
    );
  }

  Widget _buildDiscountedRateField(ProductRow row) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('DISC. RATE (₹)'),
        const SizedBox(height: 4),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade100,
          ),
          child: TextField(
            controller: row.discountedRateController,
            enabled: false,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightField(ProductRow row) {
    return Column(
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
    );
  }

  Widget _buildTwgtField(ProductRow row) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('TWGT'),
        const SizedBox(height: 4),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade100,
          ),
          child: TextField(
            controller: row.twgtController,
            enabled: false,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalAmountField(ProductRow row) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('AMOUNT (₹)'),
        const SizedBox(height: 4),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade100,
          ),
          child: TextField(
            controller: row.totalAmountController,
            enabled: false,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  // Widget _buildGodownDropdown(ProductRow row) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       _buildLabel('GODOWN'),
  //       const SizedBox(height: 4),
  //       Container(
  //         height: 40,
  //         padding: const EdgeInsets.symmetric(horizontal: 12),
  //         decoration: BoxDecoration(
  //           border: Border.all(color: Colors.grey.shade300),
  //           borderRadius: BorderRadius.circular(8),
  //         ),
  //         child: DropdownButtonHideUnderline(
  //           child: DropdownButton<String>(
  //             isExpanded: true,
  //             value: row.godown,
  //             items: const [
  //               DropdownMenuItem(value: 'KKW', child: Text('KKW')),
  //               DropdownMenuItem(value: 'TCS', child: Text('TCS')),
  //             ],
  //             onChanged: (value) {
  //               setState(() {
  //                 row.godown = value!;
  //               });
  //             },
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildDeleteButton(int index) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _removeProductRow(index),
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    );
  }

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

  @override
  void dispose() {
    _productSearchDebounce?.cancel();
    _clientNameController.dispose();
    _clientGstController.dispose();
    _contactNumberController.dispose();
    _altNumberController.dispose();
    _emailController.dispose();
    _siteAddressController.dispose();
    _headerController.dispose();
    _bottomController.dispose();
    _additionalDiscountController.dispose();
    _transportationController.dispose();
    _unloadingController.dispose();
    _scrollController.dispose();
    for (var row in _productRows) {
      row.dispose();
    }
    super.dispose();
  }
}

class ProductRow {
  final VoidCallback? onChanged;

  ProductRow({this.onChanged});

  String productName = '';
  String size = '';
  String quality = '';
  String godown = 'KKW';
  bool showProductDropdown = false;
  int? productId;

  final TextEditingController productSearchController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController covController = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController twgtController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  final TextEditingController discountedRateController =
      TextEditingController();
  final TextEditingController totalAmountController = TextEditingController();

  void updateTWGT() {
    try {
      final weight = double.tryParse(weightController.text) ?? 0;
      final quantity = double.tryParse(quantityController.text) ?? 0;
      final twgt = weight * quantity;
      twgtController.text = twgt.toStringAsFixed(2);
      updateTotal();
    } catch (e) {
      twgtController.text = '0';
      totalAmountController.text = '0';
      onChanged?.call();
    }
  }

  void updateTotal() {
    try {
      final quantity = double.tryParse(quantityController.text) ?? 0;
      final rate = double.tryParse(rateController.text) ?? 0;
      final cov = double.tryParse(covController.text) ?? 0;
      final discount = double.tryParse(discountController.text) ?? 0;

      final discountedRate = rate * (1 - discount / 100);
      discountedRateController.text = discountedRate.toStringAsFixed(2);

      final total = discountedRate * quantity * cov;
      totalAmountController.text = total.toStringAsFixed(2);

      onChanged?.call();
    } catch (e) {
      discountedRateController.text = '0';
      totalAmountController.text = '0';
      onChanged?.call();
    }
  }

  double getTotalAmount() {
    return double.tryParse(totalAmountController.text) ?? 0;
  }

  void dispose() {
    productSearchController.dispose();
    rateController.dispose();
    covController.dispose();
    areaController.dispose();
    weightController.dispose();
    twgtController.dispose();
    quantityController.dispose();
    discountController.dispose();
    discountedRateController.dispose();
    totalAmountController.dispose();
  }
}
