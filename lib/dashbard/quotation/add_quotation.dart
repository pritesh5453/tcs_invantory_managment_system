import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class AddQuotationSheet extends StatefulWidget {
  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddQuotationSheet(),
    );
  }

  @override
  State<AddQuotationSheet> createState() => _AddQuotationSheetState();
}

class _AddQuotationSheetState extends State<AddQuotationSheet> {
  Timer? _productSearchDebounce;
  final Dio _dio = Dio();

  // Client Details Controllers
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientGstController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _altNumberController = TextEditingController();
  final TextEditingController _siteAddressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Additional Discount
  final TextEditingController _additionalDiscountController =
      TextEditingController(text: '0');

  // Architect Data
  List<dynamic> _architects = [];
  String? _selectedArchitectId;
  String? _selectedArchitectName;

  List<dynamic> _customers = [];
  List<dynamic> _filteredCustomers = [];
  bool _showCustomerDropdown = false;
  Timer? _customerSearchDebounce;
  int? _selectedClientId; // 👈 new variable to store selected client ID

  // Attended By Data
  List<dynamic> _employees = [];
  String? _selectedEmployeeId;
  String? _selectedEmployeeName;

  // Products data (global search results, used for dropdowns and finding details)
  List<dynamic> _products = [];
  List<dynamic> _filteredProducts = [];

  // Form controllers
  final TextEditingController _dateController = TextEditingController(
    text: DateFormat('dd-MM-yyyy').format(DateTime.now()),
  );
  final TextEditingController _billNoController = TextEditingController();

  // Product rows
  List<ProductRow> _productRows = [ProductRow()];

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

  Future<void> _fetchArchitects() async {
    setState(() {
      _isLoadingArchitects = true;
    });

    try {
      final response = await _dio.get(
        'https://dashboard.theceramicstudio.in/api/architects/list',
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

  Future<void> _fetchCustomers(String search) async {
    if (search.trim().isEmpty) {
      setState(() {
        _filteredCustomers = [];
        _showCustomerDropdown = false;
      });
      return;
    }

    try {
      final response = await _dio.get(
        'https://dashboard.theceramicstudio.in/api/users/list',
        queryParameters: {'search': search},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _customers = response.data['customers'];
          _filteredCustomers = _customers;
          _showCustomerDropdown = true;
        });
      }
    } catch (e) {
      debugPrint("Customer fetch error: $e");
    }
  }

  Future<void> _fetchEmployees(String search) async {
    setState(() {
      _isLoadingEmployees = true;
    });

    try {
      final response = await _dio.get(
        'https://dashboard.theceramicstudio.in/api/employees/list',
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
    if (search.trim().isEmpty) {
      setState(() {
        _filteredProducts = [];
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
          _filteredProducts = response.data['products'];
          // Also update main products list for dropdowns
          _products = response.data['products'];
        });
      }
    } catch (e) {
      debugPrint('Product search error: $e');
    }
  }

  // Helper to find product details from the global _products list (used when quality changes)
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

  // Get unique sizes for a product name (used for dropdown)
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

  // Get unique qualities for a product name and size (used for dropdown)
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

  void _addProductRow() {
    setState(() {
      _productRows.add(ProductRow());
      // Scroll to bottom after adding new row
      Future.delayed(const Duration(milliseconds: 100), () {});
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

      if (row.productId == null && row.selectedProductDetails == null) {
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

  // Save quotation API call
  Future<void> _saveQuotation() async {
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
        // Use the stored product details instead of searching global list
        final productDetails = row.selectedProductDetails;
        if (productDetails == null) {
          throw Exception('Product details not found for ${row.productName}');
        }

        final rowData = {
          "productId": productDetails['id'] ?? row.productId,
          "productName": row.productName,
          "size": row.size,
          "quality": row.quality,
          "rate": double.tryParse(row.rateController.text) ?? 0,
          "box": int.tryParse(row.quantityController.text) ?? 0,
          "area": row.areaController.text.trim().toString(),
          "Weight": row.weightController.text,
          "TWgt": row.twgtController.text,
          "Coverage": row.covController.text,
          "cov": double.tryParse(row.covController.text) ?? 0,
          "discount": double.tryParse(row.discountController.text) ?? 0,
          "total": row.getTotalAmount().toStringAsFixed(2),
          "godown": row.godown,
        };
        rowsData.add(rowData);
      }

      // Prepare client details – include clientid if selected, otherwise null
      final clientDetails = {
        "clientid": _selectedClientId, // 👈 new field
        "name": _clientNameController.text.trim(),
        "contactNo": _contactNumberController.text.trim(),
        "altContactNo": _altNumberController.text.trim(),
        "email": _emailController.text.trim(),
        "gstNo": _clientGstController.text.trim(),
        "address": _siteAddressController.text.trim(),
        "architect": _selectedArchitectId ?? "",
        "attendedBy": _selectedEmployeeId ?? "",
        "attended": "",
      };

      // Prepare request body
      final requestBody = {
        "additionalDiscount":
            double.tryParse(_additionalDiscountController.text) ?? 0,
        "clientDetails": clientDetails,
        "rows": rowsData,
        "grandTotal": double.parse(_calculateGrandTotal().toStringAsFixed(2)),
      };

      debugPrint('Request Body: ${requestBody.toString()}');

      // Make API call
      final response = await _dio.post(
        'https://dashboard.theceramicstudio.in/api/Quotation/saveQuotation',
        data: requestBody,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      debugPrint('Response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                responseData['message'] ?? 'Quotation saved successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Close the bottom sheet after delay
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pop(context, true);
          });
        } else {
          // API returned success: false with an error message
          _showErrorSnackBar(
            responseData['message'] ?? 'Failed to save quotation',
          );
        }
      } else {
        // Handle non-200 status codes
        _showErrorSnackBar(
          'Server error: ${response.statusCode}\n${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      // Handle Dio errors specifically
      debugPrint('DioException: $e');
      debugPrint('Response data: ${e.response?.data}');
      debugPrint('Status code: ${e.response?.statusCode}');

      String errorMessage = 'Failed to save quotation';

      if (e.response != null) {
        // The request was made and the server responded with a status code
        // that falls out of the range of 2xx
        final responseData = e.response?.data;

        if (responseData != null) {
          // Try to extract error message from response
          if (responseData is Map) {
            if (responseData['message'] != null) {
              errorMessage = responseData['message'];
            } else if (responseData['error'] != null) {
              errorMessage = responseData['error'];
            } else if (responseData['errors'] != null) {
              // Handle validation errors
              final errors = responseData['errors'];
              if (errors is Map) {
                // Format validation errors
                final errorStrings = errors.entries
                    .map((entry) {
                      final field = entry.key;
                      final messages = entry.value;
                      if (messages is List) {
                        return '$field: ${messages.join(', ')}';
                      }
                      return '$field: $messages';
                    })
                    .join('\n');
                errorMessage = 'Validation errors:\n$errorStrings';
              } else if (errors is List) {
                errorMessage = errors.join('\n');
              }
            }
          }

          // Add status code for debugging
          errorMessage += '\n(Status: ${e.response?.statusCode})';
        } else {
          errorMessage = 'Server error (${e.response?.statusCode})';
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout. Please check your internet.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Receive timeout. Server is not responding.';
      } else if (e.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Send timeout. Please try again.';
      } else if (e.type == DioExceptionType.cancel) {
        errorMessage = 'Request cancelled.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network.';
      }

      _showErrorSnackBar(errorMessage);
    } catch (e) {
      debugPrint('Unexpected error: $e');
      _showErrorSnackBar('Unexpected error: ${e.toString()}');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // Helper method to show error snackbar with better formatting
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 14)),
        backgroundColor: Colors.red,
        duration: const Duration(
          seconds: 5,
        ), // Longer duration for error messages
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.viewInsets.bottom;
    final safeAreaBottom = mediaQuery.padding.bottom;

    final totalAmount = _calculateTotalAmount();
    final additionalDiscount =
        double.tryParse(_additionalDiscountController.text) ?? 0;
    final discountAmount = totalAmount * (additionalDiscount / 100);
    final grandTotal = _calculateGrandTotal();

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: Material(
        child: Container(
          margin: const EdgeInsets.only(top: 50),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Header (Fixed)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xffFFA54A),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Create Quotation",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Scrollable Content Area
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Close all dropdowns when tapping outside
                    setState(() {
                      for (var row in _productRows) {
                        row.showProductDropdown = false;
                      }
                    });
                    FocusScope.of(context).unfocus();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child:
                        _isLoading
                            ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xffFFA54A),
                              ),
                            )
                            : SingleChildScrollView(
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
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: TextField(
                                            controller: _clientNameController,
                                            onChanged: (value) {
                                              // Clear selected client ID when user types manually
                                              _selectedClientId = null;

                                              if (_customerSearchDebounce
                                                      ?.isActive ??
                                                  false) {
                                                _customerSearchDebounce!
                                                    .cancel();
                                              }

                                              _customerSearchDebounce = Timer(
                                                const Duration(
                                                  milliseconds: 400,
                                                ),
                                                () {
                                                  _fetchCustomers(value);
                                                },
                                              );

                                              setState(() {});
                                            },
                                            onTap: () {
                                              if (_clientNameController
                                                  .text
                                                  .isNotEmpty) {
                                                _showCustomerDropdown = true;
                                              }
                                            },
                                            decoration: const InputDecoration(
                                              hintText: "Search customer...",
                                              border: InputBorder.none,
                                              isDense: true,
                                            ),
                                          ),
                                        ),

                                        /// DROPDOWN
                                        if (_showCustomerDropdown &&
                                            _filteredCustomers.isNotEmpty)
                                          Container(
                                            height: 150,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey.shade200,
                                              ),
                                              borderRadius:
                                                  const BorderRadius.only(
                                                    bottomLeft: Radius.circular(
                                                      8,
                                                    ),
                                                    bottomRight:
                                                        Radius.circular(8),
                                                  ),
                                            ),
                                            child: ListView.builder(
                                              itemCount:
                                                  _filteredCustomers.length,
                                              itemBuilder: (context, index) {
                                                final customer =
                                                    _filteredCustomers[index];
                                                final fullName =
                                                    "${customer['name']} ${customer['Last_Name'] ?? ''}";

                                                return ListTile(
                                                  title: Text(fullName),
                                                  subtitle: Text(
                                                    customer['phone'] ?? '',
                                                  ),
                                                  onTap: () {
                                                    setState(() {
                                                      _clientNameController
                                                          .text = fullName;
                                                      _contactNumberController
                                                              .text =
                                                          customer['phone'] ??
                                                          '';
                                                      _altNumberController
                                                              .text =
                                                          customer['altphone'] ??
                                                          '';
                                                      _emailController.text =
                                                          customer['email'] ??
                                                          '';
                                                      _siteAddressController
                                                              .text =
                                                          customer['siteName'] ??
                                                          '';

                                                      // 👈 Store selected client ID
                                                      _selectedClientId =
                                                          customer['id'];

                                                      _showCustomerDropdown =
                                                          false;

                                                      /// Optional: Architect & Employee Auto Assign
                                                      // Architect Auto Select
                                                      final architectName =
                                                          customer['assignedArchitect'];
                                                      if (architectName !=
                                                          null) {
                                                        final architect =
                                                            _architects.firstWhere(
                                                              (a) =>
                                                                  "${a['firstname']} ${a['lastname']}"
                                                                      .toLowerCase()
                                                                      .trim() ==
                                                                  architectName
                                                                      .toLowerCase()
                                                                      .trim(),
                                                              orElse:
                                                                  () => null,
                                                            );

                                                        if (architect != null) {
                                                          _selectedArchitectId =
                                                              architect['id']
                                                                  .toString();
                                                        }
                                                      }

                                                      // Employee Auto Select
                                                      final employeeName =
                                                          customer['assignedEmployee'];
                                                      if (employeeName !=
                                                          null) {
                                                        final employee =
                                                            _employees.firstWhere(
                                                              (e) =>
                                                                  (e['name'] ??
                                                                          '')
                                                                      .toLowerCase()
                                                                      .trim() ==
                                                                  employeeName
                                                                      .toLowerCase()
                                                                      .trim(),
                                                              orElse:
                                                                  () => null,
                                                            );

                                                        if (employee != null) {
                                                          _selectedEmployeeId =
                                                              employee['id']
                                                                  .toString();
                                                        }
                                                      }
                                                    });

                                                    FocusScope.of(
                                                      context,
                                                    ).unfocus();
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Client GST Number
                                  _buildClientLabel('CLIENT GST NUMBER'),
                                  const SizedBox(height: 4),
                                  _buildClientTextField(
                                    _clientGstController,
                                    '27XXXXX...',
                                  ),
                                  const SizedBox(height: 12),

                                  // Contact Number and Alt Number
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                  _buildClientLabel('CLIENT EMAIL (OPTIONAL)'),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildClientLabel(
                                              'SELECT ARCHITECT',
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              height: 40,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                  ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.grey.shade300,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: DropdownButtonHideUnderline(
                                                child: DropdownButton<String>(
                                                  isExpanded: true,
                                                  value: _selectedArchitectId,
                                                  hint:
                                                      _isLoadingArchitects
                                                          ? const Text(
                                                            'Loading...',
                                                          )
                                                          : const Text(
                                                            'Choose Architect...',
                                                          ),
                                                  items:
                                                      _architects.map((
                                                        architect,
                                                      ) {
                                                        final fullName =
                                                            '${architect['firstname']} ${architect['lastname']}';
                                                        return DropdownMenuItem<
                                                          String
                                                        >(
                                                          value:
                                                              architect['id']
                                                                  .toString(),
                                                          child: Text(fullName),
                                                        );
                                                      }).toList(),
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _selectedArchitectId =
                                                          value;
                                                      final selectedArchitect =
                                                          _architects.firstWhere(
                                                            (a) =>
                                                                a['id']
                                                                    .toString() ==
                                                                value,
                                                            orElse: () => null,
                                                          );
                                                      if (selectedArchitect !=
                                                          null) {
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildClientLabel('ATTENDED BY'),
                                            const SizedBox(height: 4),
                                            Container(
                                              height: 40,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                  ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.grey.shade300,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: DropdownButtonHideUnderline(
                                                child: DropdownButton<String>(
                                                  isExpanded: true,
                                                  value: _selectedEmployeeId,
                                                  hint:
                                                      _isLoadingEmployees
                                                          ? const Text(
                                                            'Loading...',
                                                          )
                                                          : const Text(
                                                            'Choose Person...',
                                                          ),
                                                  items:
                                                      _employees.map((
                                                        employee,
                                                      ) {
                                                        return DropdownMenuItem<
                                                          String
                                                        >(
                                                          value:
                                                              employee['id']
                                                                  .toString(),
                                                          child: Text(
                                                            employee['name'] ??
                                                                '',
                                                          ),
                                                        );
                                                      }).toList(),
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _selectedEmployeeId =
                                                          value;
                                                      final selectedEmployee =
                                                          _employees.firstWhere(
                                                            (e) =>
                                                                e['id']
                                                                    .toString() ==
                                                                value,
                                                            orElse: () => null,
                                                          );
                                                      if (selectedEmployee !=
                                                          null) {
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _addProductRow,
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: const Color(0xffFFA54A),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
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

                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildClientLabel(
                                          'ADDITIONAL DISCOUNT',
                                        ),
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

                                  // Additional Discount Section
                                  const SizedBox(height: 20),

                                  // FINAL QUOTATION VALUE SECTION
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xffFFA54A,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(
                                          0xffFFA54A,
                                        ).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        // Subtotal

                                        // Additional Discount
                                        if (additionalDiscount > 0)
                                          Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
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
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                            ],
                                          ),

                                        // Grand Total
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xffFFA54A,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: const Color(
                                                0xffFFA54A,
                                              ).withOpacity(0.3),
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              // Subtotal
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
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
                                                      fontWeight:
                                                          FontWeight.w500,
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
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          'Additional Discount ($additionalDiscount%)',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 14,
                                                                color:
                                                                    Colors
                                                                        .green,
                                                              ),
                                                        ),
                                                        Text(
                                                          '-₹${discountAmount.toStringAsFixed(2)}',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color:
                                                                    Colors
                                                                        .green,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                  ],
                                                ),

                                              // Grand Total
                                              Divider(
                                                color: Colors.grey.shade400,
                                                thickness: 1,
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  const Text(
                                                    'Final Quotation Value',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Color(0xffFFA54A),
                                                    ),
                                                  ),
                                                  Text(
                                                    '₹${grandTotal.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      fontSize: 22,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xffFFA54A),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Buttons (Always visible at bottom)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            side: const BorderSide(
                                              color: Colors.red,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed:
                                              _isSubmitting
                                                  ? null
                                                  : () =>
                                                      Navigator.pop(context),
                                          child: const Text(
                                            'CANCEL',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xffFFA54A,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed:
                                              _isSubmitting
                                                  ? null
                                                  : _saveQuotation,
                                          child:
                                              _isSubmitting
                                                  ? const SizedBox(
                                                    height: 20,
                                                    width: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                  : const Text(
                                                    'Proceed to Save',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 20),
                                ],
                              ),
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
                            // Clear stored details
                            row.selectedProductDetails = null;

                            // Debounce API call
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
                              // Store full product details
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
                              // Clear stored details since size changed
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
                              // Find product details for this combination
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
                                // Store the full details
                                row.selectedProductDetails = productDetails;
                              } else {
                                // Clear if not found
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

          // Rate, COV, and AREA
          Row(
            children: [
              // Rate
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
              // COV
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
              // AREA
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
              // BOX
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
              // DISCOUNT
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
              // WEIGHT
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
              // TWGT
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
              // AMOUNT
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
              // GODOWN
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
    _dateController.dispose();
    _billNoController.dispose();
    _clientNameController.dispose();
    _clientGstController.dispose();
    _contactNumberController.dispose();
    _altNumberController.dispose();
    _siteAddressController.dispose();
    _emailController.dispose();
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

      // Apply discount to rate first
      final discountedRate = rate * (1 - discount / 100);
      // Then calculate base amount with quantity
      final baseAmount = discountedRate * quantity;
      // Finally apply COV factor
      final finalAmount = baseAmount * cov;

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
