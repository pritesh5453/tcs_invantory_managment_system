import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class AddInventorySheet extends StatefulWidget {
  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddInventorySheet(),
    );
  }

  @override
  State<AddInventorySheet> createState() => _AddInventorySheetState();
}

class _AddInventorySheetState extends State<AddInventorySheet> {
  Timer? _productSearchDebounce;
  final Dio _dio = Dio();

  // Suppliers data
  List<dynamic> _suppliers = [];
  List<dynamic> _filteredSuppliers = [];
  String? _selectedSupplierId;
  String? _selectedSupplierName;
  String? _selectedSupplierContact;
  bool _showSupplierDropdown = false;

  // Focus nodes for closing dropdowns
  final FocusNode _supplierFocusNode = FocusNode();

  // Products data
  List<dynamic> _products = [];
  List<dynamic> _filteredProducts = [];

  // Form controllers
  final TextEditingController _dateController = TextEditingController(
    text: DateFormat('dd-MM-yyyy').format(DateTime.now()),
  );
  final TextEditingController _billNoController = TextEditingController();
  final TextEditingController _supplierSearchController =
      TextEditingController();

  // Product rows
  List<ProductRow> _productRows = [ProductRow()];

  bool _isLoading = true;
  bool _isSubmitting = false;

  // Scroll controller for keyboard handling
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupFocusNodes();
  }

  void _setupFocusNodes() {
    _supplierFocusNode.addListener(() {
      if (!_supplierFocusNode.hasFocus) {
        setState(() {
          _showSupplierDropdown = false;
        });
      }
    });

    // 🔥 REMOVED: Automatic scroll on keyboard open
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   FocusScope.of(context).addListener(() {
    //     if (FocusScope.of(context).hasFocus) {
    //       Future.delayed(const Duration(milliseconds: 300), () {
    //         if (_scrollController.hasClients) {
    //           _scrollController.animateTo(
    //             _scrollController.position.maxScrollExtent,
    //             duration: const Duration(milliseconds: 300),
    //             curve: Curves.easeOut,
    //           );
    //         }
    //       });
    //     }
    //   });
    // });
  }

  Future<void> _initializeData() async {
    await _fetchSuppliers();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchSuppliers() async {
    try {
      final response = await _dio.get(
        'https://dashboard.theceramicstudio.in/api/suppliers/list',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _suppliers = response.data['suppliers'];
          _filteredSuppliers = _suppliers;
        });
      }
    } catch (e) {
      print('Error fetching suppliers: $e');
    }
  }

  Future<void> _fetchProducts({required String search}) async {
    print('\n🔎 Fetching products for search: "$search"');

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

      print('📥 Products API Response Status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> newProducts = response.data['products'];
        print('✅ Found ${newProducts.length} products');

        setState(() {
          // Filtered products for dropdown - current search ke
          _filteredProducts = newProducts;

          // 🔥 CRITICAL FIX: Accumulate, don't replace
          for (var newProduct in newProducts) {
            bool exists = _products.any(
              (existing) => existing['id'] == newProduct['id'],
            );
            if (!exists) {
              _products.add(newProduct);
              print(
                '➕ ADDED to memory: ID:${newProduct['id']} - ${newProduct['name']}',
              );
            } else {
              print('⏩ Already in memory: ID:${newProduct['id']}');
            }
          }
        });

        // Debug - show all products in memory
        print('📦 TOTAL products in memory: ${_products.length}');
        for (var p in _products) {
          print('   📌 ID:${p['id']} | ${p['name']}');
        }
      }
    } catch (e) {
      debugPrint('❌ Product search error: $e');
    }
  }

  void _filterSuppliers(String query) {
    setState(() {
      _showSupplierDropdown = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredSuppliers = _suppliers;
      } else {
        _filteredSuppliers =
            _suppliers.where((supplier) {
              final name = supplier['name']?.toString().toLowerCase() ?? '';
              final mobile = supplier['mobile']?.toString().toLowerCase() ?? '';
              final searchLower = query.toLowerCase();

              return name.contains(searchLower) || mobile.contains(searchLower);
            }).toList();
      }
    });
  }

  void _onSupplierSelected(Map<String, dynamic> supplier) {
    setState(() {
      _selectedSupplierId = supplier['id'].toString();
      _selectedSupplierName = supplier['name'];
      _selectedSupplierContact = supplier['mobile'];
      _supplierSearchController.text = supplier['name'];
      _showSupplierDropdown = false;
      _supplierFocusNode.unfocus();
    });
  }

  // Get unique sizes for a product name
  List<String> _getSizesForProduct(String productName) {
    final productsWithSameName =
        _products.where((p) => p['name'] == productName).toList();
    final sizes =
        productsWithSameName.map((p) => p['size'].toString()).toSet().toList();
    return sizes;
  }

  // Get unique qualities for a product name and size
  List<String> _getQualitiesForProduct(String productName, String size) {
    final productsWithSameNameAndSize =
        _products
            .where((p) => p['name'] == productName && p['size'] == size)
            .toList();

    final qualities =
        productsWithSameNameAndSize
            .map((p) => p['quality'].toString())
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
    print('\n🔍 Searching for: "$productName" | "$size" | "$quality"');
    print('📦 Products in memory at search time: ${_products.length}');

    // List all products in memory
    for (var p in _products) {
      print('   Memory: ID:${p['id']} | "${p['name']}"');
    }

    // Try exact match first
    try {
      final product = _products.firstWhere(
        (p) =>
            p['name'] == productName &&
            p['size'] == size &&
            p['quality'] == quality,
      );
      print('✅ Exact match found! ID: ${product['id']}');
      return product;
    } catch (e) {
      print('⚠️ No exact match, trying case-insensitive...');
    }

    // Try case-insensitive match
    try {
      final product = _products.firstWhere(
        (p) =>
            p['name'].toString().toLowerCase() == productName.toLowerCase() &&
            p['size'].toString().toLowerCase() == size.toLowerCase() &&
            p['quality'].toString().toLowerCase() == quality.toLowerCase(),
      );
      print('✅ Case-insensitive match found! ID: ${product['id']}');
      return product;
    } catch (e) {
      print('❌ Product NOT found in memory!');
      return null;
    }
  }

  Future<void> _submitPurchase() async {
    if (_selectedSupplierId == null || _productRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select supplier and add at least one product'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate all product rows
    for (var row in _productRows) {
      if (row.productName.isEmpty || row.size.isEmpty || row.quality.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all product details'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (row.batches.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No batches available for ${row.productName}'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (row.selectedBatch == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select batch for ${row.productName}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (row.quantityController.text.isEmpty ||
          double.tryParse(row.quantityController.text) == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter valid quantity for all products'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (_billNoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter bill number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Format date to YYYY-MM-DD
      final dateParts = _dateController.text.split('-');
      final formattedDate = '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}';

      // Prepare items array
      final List<Map<String, dynamic>> items = [];
      double subTotal = 0;

      print('========== SUBMIT PURCHASE ==========');
      print('Total rows: ${_productRows.length}');

      for (var row in _productRows) {
        final productDetails = _getProductDetails(
          row.productName,
          row.size,
          row.quality,
        );

        if (productDetails == null) {
          print('❌ Product details not found for: ${row.productName}');
          continue;
        }

        final rate = double.tryParse(row.rateController.text) ?? 0;
        final quantity = double.tryParse(row.quantityController.text) ?? 0;
        final discount = double.tryParse(row.discountController.text) ?? 0;
        final total = row.getTotalAmount();

        print('✅ Adding product: ${productDetails['id']} - ${row.productName}');
        print('   Batch: ${row.selectedBatch}, Qty: $quantity');

        // 🔥 FIX 1: Send ALL batches, not just selected one
        final List<Map<String, dynamic>> allBatches = [];
        for (var batch in row.batches) {
          allBatches.add({
            "batch_no": batch['batch_no'].toString(),
            "qty": int.tryParse(batch['qty'].toString()) ?? 0,
            "location": batch['location']?.toString() ?? row.godown,
          });
        }

        // 🔥 FIX 2: Find selected batch details
        final selectedBatchData = row.batches.firstWhere(
          (b) => b['batch_no'] == row.selectedBatch,
          orElse:
              () => {
                'batch_no': row.selectedBatch ?? '',
                'qty': 0,
                'location': row.godown,
              },
        );

        // 🔥 FIX 3: Create filteredProducts array (same as web)
        final filteredProduct = {
          "id": productDetails['id'],
          "name": productDetails['name'],
          "size": productDetails['size'],
          "brand": productDetails['brand']?.toString() ?? "",
          "category": productDetails['category']?.toString() ?? "",
          "quality": productDetails['quality'],
          "rate": productDetails['rate']?.toString() ?? "0",
          "status": productDetails['status'] ?? "",
          "link": productDetails['link'] ?? "",
          "godown": productDetails['godown']?.toString() ?? "",
          "description": productDetails['description']?.toString() ?? "",
          "cov": productDetails['cov']?.toString() ?? "0",
          "image": productDetails['image']?.toString() ?? "",
          "created_at": productDetails['created_at']?.toString() ?? "",
          "availQty": productDetails['availQty'] ?? 0,
          "batches":
              allBatches
                  .map(
                    (b) => {
                      "batch_no": b['batch_no'],
                      "qty": b['qty'],
                      "location": b['location'],
                    },
                  )
                  .toList(),
          "image_url": productDetails['image_url']?.toString() ?? "",
        };

        items.add({
          "productId": productDetails['id'],
          "productName": row.productName,
          "size": row.size,
          "quality": row.quality,
          "rate": rate,
          "cov": row.covController.text,
          "batches": allBatches, // 🔥 Send ALL batches
          "batchNo": row.selectedBatch,
          "availQty": int.tryParse(selectedBatchData['qty'].toString()) ?? 0,
          "qty": row.quantityController.text,
          "total": total,
          "discount":
              row.discountController.text.isEmpty
                  ? ""
                  : row
                      .discountController
                      .text, // 🔥 Empty string if no discount
          "godown": row.godown,
          "filteredProducts": [filteredProduct], // 🔥 ADD THIS - web jaisa
          "stockDiff": quantity,
        });

        subTotal += total;
      }

      if (items.isEmpty) {
        throw Exception('No valid products to add');
      }

      final requestData = {
        "purchaseDate": formattedDate,
        "clientName": _selectedSupplierName,
        "clientContact": _selectedSupplierContact,
        "billNo": _billNoController.text,
        "purchaseId": null,
        "items": items,
        "subTotal": subTotal,
      };

      print('📤 Sending request with ${items.length} items');
      print('Data: ${requestData.toString()}');

      final response = await _dio.post(
        'https://dashboard.theceramicstudio.in/api/purchase/add',
        data: requestData,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      print('📥 Response: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.data['message'] ?? 'Purchase added successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(response.data['message'] ?? 'Failed to add purchase');
      }
    } catch (e) {
      print('❌ Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  void _addProductRow() {
    setState(() {
      _productRows.add(ProductRow());
      // 🔥 KEPT: Manual scroll on add product row
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

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.viewInsets.bottom;
    final safeAreaBottom = mediaQuery.padding.bottom;

    return Container(
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
                  "Add New Purchase",
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
                setState(() {
                  _showSupplierDropdown = false;
                  for (var row in _productRows) {
                    row.showProductDropdown = false;
                  }
                });
                FocusScope.of(context).unfocus();
              },
              child: Padding(
                padding: EdgeInsets.only(
                  bottom:
                      bottomPadding > 0
                          ? bottomPadding + safeAreaBottom
                          : safeAreaBottom,
                ),
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
                              // Date Field
                              _buildLabel('DATE'),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => _selectDate(context),
                                child: Container(
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
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _dateController,
                                          enabled: false,
                                          style: const TextStyle(fontSize: 14),
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Bill Number
                              _buildLabel('BILL NUMBER'),
                              const SizedBox(height: 4),
                              _buildTextField(
                                _billNoController,
                                'Ex: BILL-101',
                              ),

                              const SizedBox(height: 12),

                              // Supplier Dropdown with Search
                              _buildLabel('SUPPLIER'),
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
                                              focusNode: _supplierFocusNode,
                                              controller:
                                                  _supplierSearchController,
                                              onChanged: _filterSuppliers,
                                              onTap:
                                                  () => setState(() {
                                                    _showSupplierDropdown =
                                                        true;
                                                  }),
                                              decoration: const InputDecoration(
                                                hintText: 'Search supplier...',
                                                hintStyle: TextStyle(
                                                  fontSize: 14,
                                                ),
                                                border: InputBorder.none,
                                                isDense: true,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_showSupplierDropdown &&
                                        _filteredSuppliers.isNotEmpty)
                                      Container(
                                        height: 200,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade200,
                                          ),
                                          borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(8),
                                            bottomRight: Radius.circular(8),
                                          ),
                                        ),
                                        child: ListView.builder(
                                          itemCount: _filteredSuppliers.length,
                                          itemBuilder: (context, index) {
                                            final supplier =
                                                _filteredSuppliers[index];
                                            return ListTile(
                                              title: Text(
                                                supplier['name'] ?? '',
                                              ),
                                              subtitle: Text(
                                                supplier['mobile'] ?? '',
                                              ),
                                              onTap:
                                                  () => _onSupplierSelected(
                                                    supplier,
                                                  ),
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Supplier Contact (Auto-filled)
                              _buildLabel('SUPPLIER CONTACT'),
                              const SizedBox(height: 4),
                              _buildTextField(
                                TextEditingController(
                                  text: _selectedSupplierContact ?? '',
                                ),
                                'Auto-filled from supplier',
                                enabled: false,
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
                                      borderRadius: BorderRadius.circular(8),
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

                              const SizedBox(height: 32),

                              // Grand Total
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  border: Border.all(
                                    color: const Color(0xffFFA54A),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "GRAND TOTAL",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "₹ ${_calculateGrandTotal().toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xffFFA54A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Buttons
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      onPressed:
                                          _isSubmitting
                                              ? null
                                              : () => Navigator.pop(context),
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      onPressed:
                                          _isSubmitting
                                              ? null
                                              : _submitPurchase,
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
                                                'SAVE PURCHASE',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildProductRow(int index, ProductRow row) {
    final sizes =
        row.productName.isNotEmpty ? _getSizesForProduct(row.productName) : [];
    final qualities =
        row.productName.isNotEmpty && row.size.isNotEmpty
            ? _getQualitiesForProduct(row.productName, row.size)
            : [];

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
                            row.selectedBatch = null;
                            row.covController.clear();
                            row.rateController.clear();
                            row.stockController.clear();
                            row.amountController.clear();
                            row.batches = [];

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
                              row.productName = product['name'];
                              row.size = product['size'].toString();
                              row.quality = product['quality'].toString();
                              row.productSearchController.text =
                                  product['name'];
                              row.rateController.text =
                                  product['rate']?.toString() ?? '0';
                              row.covController.text =
                                  product['cov']?.toString() ?? '0';

                              // 🔥 FIX: Properly handle batches
                              if (product['batches'] != null &&
                                  product['batches'].isNotEmpty) {
                                row.batches = List.from(product['batches']);
                                row.selectedBatch =
                                    row.batches.first['batch_no'];
                                row.stockController.text =
                                    row.batches.first['qty'].toString();
                                print(
                                  '✅ Batches loaded: ${row.batches.length} for ${product['name']}',
                                );
                              } else {
                                row.batches = [];
                                row.selectedBatch = null;
                                row.stockController.text = '0';
                                print('⚠️ No batches for ${product['name']}');
                              }

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
                          value: sizes.contains(row.size) ? row.size : null,
                          hint: const Text('Select Size'),
                          items:
                              sizes.map<DropdownMenuItem<String>>((size) {
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
                              row.selectedBatch = null;
                              row.covController.clear();
                              row.rateController.clear();
                              row.stockController.clear();
                              row.amountController.clear();
                              row.batches = [];
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
                              qualities.contains(row.quality)
                                  ? row.quality
                                  : null,
                          hint: const Text('Select Quality'),
                          items:
                              qualities.map<DropdownMenuItem<String>>((
                                quality,
                              ) {
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
                                row.rateController.text =
                                    productDetails['rate']?.toString() ?? '0';
                                row.covController.text =
                                    productDetails['cov']?.toString() ?? '0';

                                // 🔥 FIX: Load batches properly
                                if (productDetails['batches'] != null &&
                                    productDetails['batches'].isNotEmpty) {
                                  row.batches = List.from(
                                    productDetails['batches'],
                                  );
                                  row.selectedBatch =
                                      row.batches.first['batch_no'];
                                  row.stockController.text =
                                      row.batches.first['qty'].toString();
                                  print(
                                    '✅ Batches loaded: ${row.batches.length}',
                                  );
                                } else {
                                  row.batches = [];
                                  row.selectedBatch = null;
                                  row.stockController.text = '0';
                                  print('⚠️ No batches available');
                                }
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
                    _buildLabel('COV (%)'),
                    const SizedBox(height: 4),
                    _buildTextField(row.covController, '0', enabled: false),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Batch Selection and Stock
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('BATCH SELECTION'),
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
                          value: row.selectedBatch,
                          hint:
                              row.batches.isEmpty
                                  ? const Text('No batches available')
                                  : const Text('Select Batch'),
                          items:
                              row.batches.map((batch) {
                                return DropdownMenuItem<String>(
                                  value: batch['batch_no'],
                                  child: Text('Batch ${batch['batch_no']}'),
                                );
                              }).toList(),
                          onChanged:
                              row.batches.isEmpty
                                  ? null
                                  : (value) {
                                    setState(() {
                                      row.selectedBatch = value;
                                      final selectedBatch = row.batches
                                          .firstWhere(
                                            (b) => b['batch_no'] == value,
                                            orElse: () => {'qty': 0},
                                          );
                                      row.stockController.text =
                                          selectedBatch['qty'].toString();
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
                    _buildLabel('STOCK'),
                    const SizedBox(height: 4),
                    _buildTextField(row.stockController, '0', enabled: false),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Quantity and Discount
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('QUANTITY'),
                    const SizedBox(height: 4),
                    _buildTextField(
                      row.quantityController,
                      '0',
                      keyboardType: TextInputType.number,
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

  double _calculateGrandTotal() {
    double total = 0;
    for (var row in _productRows) {
      total += row.getTotalAmount();
    }
    return total;
  }

  @override
  void dispose() {
    _dateController.dispose();
    _billNoController.dispose();
    _supplierSearchController.dispose();
    _supplierFocusNode.dispose();
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
  List<dynamic> batches = [];
  String? selectedBatch;
  String godown = 'KKW';
  bool showProductDropdown = false;

  final TextEditingController productSearchController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController covController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController discountController = TextEditingController();

  void updateTotal() {
    try {
      final rate = double.tryParse(rateController.text) ?? 0;
      final quantity = double.tryParse(quantityController.text) ?? 0;
      final cov = double.tryParse(covController.text) ?? 0;
      final discount = double.tryParse(discountController.text) ?? 0;

      // ✅ CORRECT FORMULA: rate * cov * quantity
      final baseAmount = rate * cov * quantity;

      // Apply discount (percentage)
      final discountAmount = baseAmount * (discount / 100);
      final finalAmount = baseAmount - discountAmount;

      amountController.text = finalAmount.toStringAsFixed(2);

      print(
        '💰 Total: ₹$rate × $cov × $quantity qty - $discount% = ₹$finalAmount',
      );
    } catch (e) {
      print('Error in updateTotal: $e');
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
    stockController.dispose();
    quantityController.dispose();
    amountController.dispose();
    discountController.dispose();
  }
}
