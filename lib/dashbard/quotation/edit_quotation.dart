import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

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
  Timer? _productSearchDebounce;
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

  // Additional Discount
  final TextEditingController _additionalDiscountController =
      TextEditingController(text: '0');

  // Architect Data
  List<dynamic> _architects = [];
  String? _selectedArchitectId;
  String? _selectedArchitectName;

  // Attended By Data
  List<dynamic> _employees = [];
  String? _selectedEmployeeId;
  String? _selectedEmployeeName;

  // Products data
  List<dynamic> _products = [];
  List<dynamic> _filteredProducts = [];

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
      // Fetch architects
      await _fetchArchitects();

      // Fetch employees
      await _fetchEmployees('');

      // Fetch all products for dropdown
      await _fetchProducts(search: '');

      // Initialize form with existing data
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

    debugPrint('Received quotation data: $quotationData');

    /// ================= CLIENT DETAILS =================
    _clientNameController.text = quotationData['clientName']?.toString() ?? '';

    _contactNumberController.text =
        quotationData['contactNo']?.toString() ?? '';

    _altNumberController.text = quotationData['altContactNo']?.toString() ?? '';

    _emailController.text = quotationData['email']?.toString() ?? '';

    _clientGstController.text = quotationData['gstNo']?.toString() ?? '';

    _siteAddressController.text = quotationData['address']?.toString() ?? '';

    _additionalDiscountController.text =
        quotationData['additionalDiscount']?.toString() ?? '0';

    _headerController.text = quotationData['headerSection']?.toString() ?? '';

    _bottomController.text = quotationData['bottomSection']?.toString() ?? '';

    _selectedArchitectId = quotationData['architect']?.toString();

    _selectedEmployeeId = quotationData['attendedBy']?.toString();

    /// ================= PRODUCT ROWS =================
    final items = quotationData['items'] ?? [];

    debugPrint("Items length: ${items.length}");

    _productRows =
        items.map<ProductRow>((item) {
          final row = ProductRow();

          row.productId = item['productId'];
          row.productName = item['productName'] ?? '';
          row.size = item['size'] ?? '';
          row.quality = item['quality'] ?? '';
          row.godown = 'KKW';

          row.rateController.text = item['rate']?.toString() ?? '0';

          row.covController.text = item['cov']?.toString() ?? '0';

          row.weightController.text = item['weight']?.toString() ?? '0';

          row.quantityController.text = item['box']?.toString() ?? '0';

          row.discountController.text = item['discount']?.toString() ?? '0';

          row.amountController.text = item['total']?.toString() ?? '0';

          row.productSearchController.text = item['productName'] ?? '';

          row.updateTWGT();
          row.updateTotal();

          return row;
        }).toList();

    if (_productRows.isEmpty) {
      _productRows.add(ProductRow());
    }

    setState(() {});
  }

  Future<void> _fetchArchitects() async {
    setState(() {
      _isLoadingArchitects = true;
    });

    try {
      final response = await _dio.get(
        'https://dashboarduat.theceramicstudio.in/api/architects/list',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _architects = response.data['architects'];
        });
      }
    } catch (e) {
      debugPrint('Architect fetch error: $e');
    } finally {
      setState(() {
        _isLoadingArchitects = false;
      });
    }
  }

  Future<void> _fetchEmployees(String search) async {
    setState(() {
      _isLoadingEmployees = true;
    });

    try {
      final response = await _dio.get(
        'https://dashboarduat.theceramicstudio.in/api/employees/list',
        queryParameters: {'search': search},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _employees = response.data['employees'];
        });
      }
    } catch (e) {
      debugPrint('Employees fetch error: $e');
    } finally {
      setState(() {
        _isLoadingEmployees = false;
      });
    }
  }

  Future<void> _fetchProducts({required String search}) async {
    try {
      final response = await _dio.get(
        'https://dashboarduat.theceramicstudio.in/api/product/list',
        queryParameters: {'search': search},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _products = response.data['products'];
        });
      }
    } catch (e) {
      debugPrint('Product search error: $e');
    }
  }

  // Get unique sizes for a product name
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

  // Get unique qualities for a product name and size
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

  // Get product details for name, size, and quality
  Map<String, dynamic>? _getProductDetails(
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

  void _addProductRow() {
    setState(() {
      _productRows.add(ProductRow());
      // Scroll to bottom after adding new row
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

  void _removeProductRow(int index) {
    setState(() {
      _productRows.removeAt(index);
    });
  }

  // Calculate total of all product rows
  double _calculateTotalAmount() {
    double total = 0;
    for (var row in _productRows) {
      total += row.getTotalAmount();
    }
    return total;
  }

  // Calculate grand total after additional discount
  double _calculateGrandTotal() {
    double subtotal = _calculateTotalAmount();
    double additionalDiscount =
        double.tryParse(_additionalDiscountController.text) ?? 0;

    // Apply additional discount as percentage
    if (additionalDiscount > 0) {
      double discountAmount = subtotal * (additionalDiscount / 100);
      return subtotal - discountAmount;
    }
    return subtotal;
  }

  // Validate form before submission
  bool _validateForm() {
    // Validate client details
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

    if (_selectedArchitectId == null) {
      _showSnackBar('Please select an architect');
      return false;
    }

    if (_selectedEmployeeId == null) {
      _showSnackBar('Please select attended by');
      return false;
    }

    // Validate product rows
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

  // Show snackbar message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Update quotation API call
  Future<void> _updateQuotation() async {
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Prepare rows data
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

        final rowData = {
          "productId": row.productId ?? productDetails?['id'],
          "productName": row.productName,
          "size": row.size,
          "quality": row.quality,
          "rate": double.tryParse(row.rateController.text) ?? 0,
          "box": int.tryParse(row.quantityController.text) ?? 0,
          "area": "", // Empty as per API example
          "Weight":
              row.weightController.text.isNotEmpty
                  ? double.tryParse(row.weightController.text) ?? 0
                  : 0,
          "TWgt":
              row.twgtController.text.isNotEmpty
                  ? double.tryParse(row.twgtController.text) ?? 0
                  : 0,
          "Coverage":
              row.covController.text.isNotEmpty
                  ? double.tryParse(row.covController.text) ?? 0
                  : 0,
          "cov": double.tryParse(row.covController.text) ?? 0,
          "discount": double.tryParse(row.discountController.text) ?? 0,
          "total": row.getTotalAmount(),
        };
        rowsData.add(rowData);
      }

      // Prepare client details
      final clientDetails = {
        "clientid": null, // From example
        "name": _clientNameController.text.trim(),
        "contactNo": _contactNumberController.text.trim(),
        "altContactNo": _altNumberController.text.trim(),
        "email": _emailController.text.trim(),
        "gstNo": _clientGstController.text.trim(),
        "address": _siteAddressController.text.trim(),
        "architect": _selectedArchitectId ?? "",
        "attendedBy": _selectedEmployeeId ?? "",
        "attended": "", // Empty as per your example
      };

      // Prepare request body
      final requestBody = {
        "quotationId": int.parse(widget.quotationId),
        "additionalDiscount":
            double.tryParse(_additionalDiscountController.text) ?? 0,
        "headerSection": _headerController.text.trim(),
        "bottomSection": _bottomController.text.trim(),
        "clientDetails": clientDetails,
        "rows": rowsData,
        "grandTotal": _calculateGrandTotal(),
      };

      debugPrint('Update Request Body: ${requestBody.toString()}');

      // Make API call
      final response = await _dio.put(
        'https://dashboarduat.theceramicstudio.in/api/Quotation/updateQuotation/${widget.quotationId}',
        data: requestBody,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      debugPrint('Update Response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                responseData['message'] ?? 'Quotation updated successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Close the screen after delay
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pop(context, true); // Return success flag
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
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _calculateTotalAmount();
    final additionalDiscount =
        double.tryParse(_additionalDiscountController.text) ?? 0;
    final discountAmount = totalAmount * (additionalDiscount / 100);
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
                  // Close all dropdowns when tapping outside
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

                      // Contact Number and Alt Number
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

                      // Select Architect and Attended By
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
                                      value:
                                          _architects.any(
                                                (a) =>
                                                    a['id'].toString() ==
                                                    _selectedArchitectId,
                                              )
                                              ? _selectedArchitectId
                                              : null,
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
                                      value: _selectedEmployeeId,
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

                      // Product Section Header
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

                      // BOTTOM SECTION (Bank Details & Terms)
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

                            // Grand Total
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
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildProductRow(int index, ProductRow row) {
    final sizes = _getSizesForProduct(row.productName);
    final qualities = _getQualitiesForProduct(row.productName, row.size);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
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

                            // Debounce API call
                            if (_productSearchDebounce?.isActive ?? false) {
                              _productSearchDebounce!.cancel();
                            }

                            _productSearchDebounce = Timer(
                              const Duration(milliseconds: 400),
                              () {
                                if (value.trim().isNotEmpty) {
                                  _fetchProducts(search: value.trim());
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
                          _products
                              .where(
                                (p) => p['name']
                                    .toString()
                                    .toLowerCase()
                                    .contains(row.productName.toLowerCase()),
                              )
                              .length,
                      itemBuilder: (context, idx) {
                        final product =
                            _products
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
              // Size Dropdown
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

              // Quality Dropdown
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
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Rate and COV
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
              const SizedBox(width: 12),
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
                      onChanged: (_) => row.updateTWGT(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
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
            ],
          ),

          const SizedBox(height: 12),
          // Weight and TWGT
          Row(
            children: [
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
              const SizedBox(width: 12),
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
            ],
          ),

          const SizedBox(height: 12),

          // Amount and Godown
          Row(
            children: [
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
              const SizedBox(width: 12),
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

          // Delete button for additional rows
          if (_productRows.length > 1)
            Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _removeProductRow(index),
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
    _clientNameController.dispose();
    _clientGstController.dispose();
    _contactNumberController.dispose();
    _altNumberController.dispose();
    _emailController.dispose();
    _siteAddressController.dispose();
    _headerController.dispose();
    _bottomController.dispose();
    _additionalDiscountController.dispose();
    _scrollController.dispose();
    for (var row in _productRows) {
      row.dispose();
    }
    super.dispose();
  }
}

class ProductRow {
  String productName = '';
  String size = '';
  String quality = '';
  String godown = 'KKW';
  bool showProductDropdown = false;
  int? productId;

  final TextEditingController productSearchController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController covController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController twgtController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController discountController = TextEditingController();

  void updateTWGT() {
    try {
      final weight = double.tryParse(weightController.text) ?? 0;
      final quantity = double.tryParse(quantityController.text) ?? 0;

      // Calculate TWGT: Weight * Quantity
      final twgt = weight * quantity;
      twgtController.text = twgt.toStringAsFixed(2);

      // Update total amount
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

      final covAmount = baseAmount * (cov);
      final amountAfterCov = covAmount;

      // Apply discount (assuming discount is a percentage)
      final discountAmount = amountAfterCov * (discount / 100);
      final finalAmount = amountAfterCov - discountAmount;

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
    weightController.dispose();
    twgtController.dispose();
    quantityController.dispose();
    amountController.dispose();
    discountController.dispose();
  }
}
