import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class EditInventorySheet extends StatefulWidget {
  final Map<String, dynamic> purchase;

  const EditInventorySheet({super.key, required this.purchase});

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> purchase,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditInventorySheet(purchase: purchase),
    );
  }

  @override
  State<EditInventorySheet> createState() => _EditInventorySheetState();
}

class _EditInventorySheetState extends State<EditInventorySheet> {
  final Dio _dio = Dio();

  // Suppliers data
  List<dynamic> _suppliers = [];
  List<dynamic> _filteredSuppliers = [];
  String? _selectedSupplierId;
  String? _selectedSupplierName;
  String? _selectedSupplierContact;
  bool _showSupplierDropdown = false;

  // Focus nodes
  final FocusNode _supplierFocusNode = FocusNode();

  // Products data
  List<dynamic> _products = [];
  List<dynamic> _filteredProducts = [];
  Map<int, dynamic> _productMap = {}; // lookup by product ID

  // Form controllers
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _billNoController = TextEditingController();
  final TextEditingController _supplierSearchController =
      TextEditingController();

  // Product rows
  List<ProductRow> _productRows = [];

  bool _isLoading = true;
  bool _isSubmitting = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _setupFocusNodes();
    _initializeData();
  }

  void _setupFocusNodes() {
    _supplierFocusNode.addListener(() {
      if (!_supplierFocusNode.hasFocus) {
        setState(() => _showSupplierDropdown = false);
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
    setState(() => _isLoading = true);

    await _fetchSuppliers();
    await _fetchAllProducts();

    _productRows.clear();
    _prefillData();
    _prefillProductsFromApi();

    setState(() => _isLoading = false);
  }

  void _prefillData() {
    print('\n📝 Prefilling purchase data...');

    final purchaseDate = widget.purchase['purchase_date'];
    if (purchaseDate != null) {
      try {
        final date = DateTime.parse(purchaseDate);
        _dateController.text = DateFormat('dd-MM-yyyy').format(date);
      } catch (e) {
        print('Date parse error: $e');
      }
    }

    _billNoController.text = widget.purchase['bill_no'] ?? '';

    _selectedSupplierName = widget.purchase['client_name'];
    _selectedSupplierContact = widget.purchase['client_contact'];
    _supplierSearchController.text = widget.purchase['client_name'] ?? '';

    final items = widget.purchase['items'] as List? ?? [];
    print('📦 Found ${items.length} items in purchase');

    for (var item in items) {
      final row = ProductRow();
      row.productId = item['product_id'];
      row.selectedBatch = item['batch_no']?.toString();
      row.rateController.text = (item['rate'] ?? 0).toString();
      row.covController.text = (item['cov'] ?? 0).toString();
      row.quantityController.text = (item['qty'] ?? 0).toString();
      row.discountController.text = (item['discount'] ?? 0).toString();
      row.godown = item['godown'] ?? 'KKW';
      row.productSearchController.text = item['product_name'] ?? '';
      _productRows.add(row);

      print(
        '  ➕ Added row for product ID: ${row.productId} - ${item['product_name']}',
      );
    }

    if (_productRows.isEmpty) {
      _productRows.add(ProductRow());
    }
  }

  void _prefillProductsFromApi() {
    print('\n🔍 Prefilling products from API...');

    for (var i = 0; i < _productRows.length; i++) {
      final row = _productRows[i];

      if (row.productId == null) {
        print('⚠️ Row $i has no productId, skipping');
        continue;
      }

      final product = _productMap[row.productId!];
      if (product == null) {
        print('❌ Product ID ${row.productId} not found in _productMap');
        continue;
      }

      print('✅ Found product: ID:${product['id']} - ${product['name']}');
      print('   Size from API: "${product['size']}"');
      print('   Quality from API: "${product['quality']}"');

      row.productName = product['name'] ?? '';
      row.size = product['size']?.toString() ?? '';
      row.quality = product['quality']?.toString() ?? '';
      row.productSearchController.text = row.productName;

      if (row.rateController.text.isEmpty || row.rateController.text == '0') {
        row.rateController.text = product['rate']?.toString() ?? '0';
      }
      if (row.covController.text.isEmpty || row.covController.text == '0') {
        row.covController.text = product['cov']?.toString() ?? '0';
      }

      row.batches = List.from(product['batches'] ?? []);
      print('   Batches loaded: ${row.batches.length}');

      if (row.batches.isNotEmpty) {
        final savedBatchNo = row.selectedBatch;

        if (savedBatchNo != null && savedBatchNo.isNotEmpty) {
          final matchingBatch = row.batches.firstWhere(
            (b) => b['batch_no'].toString() == savedBatchNo.toString(),
            orElse: () => row.batches.first,
          );
          row.selectedBatch = matchingBatch['batch_no'].toString();
          row.stockController.text = matchingBatch['qty'].toString();
          print('   ✅ Batch set to saved: ${row.selectedBatch}');
        } else {
          row.selectedBatch = row.batches.first['batch_no'].toString();
          row.stockController.text = row.batches.first['qty'].toString();
          print('   ✅ Batch set to first: ${row.selectedBatch}');
        }
      }

      row.updateTotal();

      print(
        '📊 Row $i updated: ${row.productName} | ${row.size} | ${row.quality}',
      );
    }

    setState(() {});
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

          final clientName = widget.purchase['client_name'];
          if (clientName != null) {
            final found = _suppliers.firstWhere(
              (s) => s['name'] == clientName,
              orElse: () => null,
            );
            if (found != null) {
              _selectedSupplierId = found['id'].toString();
              _selectedSupplierContact =
                  found['mobile'] ?? _selectedSupplierContact;
            }
          }
        });
      }
    } catch (e) {
      print('Supplier fetch error: $e');
    }
  }

  Future<void> _fetchAllProducts() async {
    try {
      final response = await _dio.get(
        'https://dashboard.theceramicstudio.in/api/product/list?limit=1000',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final products = response.data['products'] ?? [];
        print('📦 Fetched ${products.length} products from API');

        setState(() {
          _products = List<Map<String, dynamic>>.from(products);
          _filteredProducts = _products;
          _productMap = {for (var p in _products) p['id'] as int: p};
        });

        final optimus = _productMap[1363];
        if (optimus != null) {
          print('✅ Optimus product found in map: ${optimus['name']}');
          print('   Size: "${optimus['size']}"');
          print('   Quality: "${optimus['quality']}"');
        } else {
          print('❌ Optimus product (ID:1363) NOT found in map');
          await _fetchOptimusProduct();
        }
      }
    } catch (e) {
      debugPrint('Product fetch error: $e');
    }
  }

  Future<void> _fetchOptimusProduct() async {
    try {
      print('🔍 Trying to fetch Optimus product specifically...');

      final response = await _dio.get(
        'https://dashboard.theceramicstudio.in/api/product/list?search=optimus&limit=10',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final products = response.data['products'] ?? [];

        if (products.isNotEmpty) {
          print('✅ Found ${products.length} Optimus products');

          setState(() {
            for (var product in products) {
              bool exists = _products.any((p) => p['id'] == product['id']);
              if (!exists) {
                _products.add(product);
                _productMap[product['id']] = product;
                print('➕ Added Optimus product ID: ${product['id']}');
              }
            }
            _filteredProducts = List.from(_products);
          });
        }
      }
    } catch (e) {
      print('❌ Error fetching Optimus product: $e');
    }
  }

  void _filterSuppliers(String query) {
    setState(() {
      _showSupplierDropdown = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredSuppliers = _suppliers;
      } else {
        final lower = query.toLowerCase();
        _filteredSuppliers =
            _suppliers.where((s) {
              final name = s['name']?.toString().toLowerCase() ?? '';
              final mobile = s['mobile']?.toString().toLowerCase() ?? '';
              return name.contains(lower) || mobile.contains(lower);
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

  List<String> _getSizesForProduct(String productName) {
    if (productName.isEmpty) return [];

    print('\n🔍 Getting sizes for: "$productName"');

    final matches =
        _products.where((p) {
          final pName = (p['name'] as String?)?.trim().toLowerCase() ?? '';
          final searchName = productName.trim().toLowerCase();
          return pName == searchName;
        }).toList();

    print('📊 Found ${matches.length} matches');

    final sizes =
        matches
            .map((p) {
              final size = p['size'].toString();
              print('   - Size: "$size"');
              return size;
            })
            .toSet()
            .toList();

    return sizes;
  }

  List<String> _getQualitiesForProduct(String productName, String size) {
    if (productName.isEmpty || size.isEmpty) return [];

    print('\n🔍 Getting qualities for: "$productName" | Size: "$size"');

    final matches =
        _products.where((p) {
          final pName = (p['name'] as String?)?.trim().toLowerCase() ?? '';
          final pSize = (p['size'] as String?)?.trim() ?? '';
          final searchName = productName.trim().toLowerCase();
          final searchSize = size.trim();

          return pName == searchName && pSize == searchSize;
        }).toList();

    print('📊 Found ${matches.length} matches');

    final qualities =
        matches
            .map((p) {
              final quality = p['quality'].toString();
              print('   - Quality: "$quality"');
              return quality;
            })
            .toSet()
            .toList();

    return qualities;
  }

  Map<String, dynamic>? _getProductDetails(
    String productName,
    String size,
    String quality,
  ) {
    if (productName.isEmpty || size.isEmpty || quality.isEmpty) return null;

    print(
      '\n🔍 Getting product details for: "$productName" | "$size" | "$quality"',
    );

    return _products.firstWhere(
      (p) {
        final pName = (p['name'] as String?)?.trim().toLowerCase() ?? '';
        final pSize = (p['size'] as String?)?.trim() ?? '';
        final pQuality = (p['quality'] as String?)?.trim() ?? '';
        final searchName = productName.trim().toLowerCase();
        final searchSize = size.trim();
        final searchQuality = quality.trim();

        final match =
            pName == searchName &&
            pSize == searchSize &&
            pQuality == searchQuality;

        if (match) {
          print('✅ Product found! ID: ${p['id']}');
        }

        return match;
      },
      orElse: () {
        print('❌ Product not found');
        return null;
      },
    );
  }

  // 🔥 NEW: Calculate grand total
  double _calculateGrandTotal() {
    double total = 0;
    for (var row in _productRows) {
      total += row.getTotalAmount();
    }
    return total;
  }

  Future<void> _submitPurchase() async {
    if (_selectedSupplierId == null) {
      _showSnackBar('Please select a supplier');
      return;
    }
    if (_billNoController.text.isEmpty) {
      _showSnackBar('Please enter bill number');
      return;
    }
    if (_productRows.isEmpty) {
      _showSnackBar('Add at least one product');
      return;
    }

    for (var row in _productRows) {
      if (row.productId == null) {
        _showSnackBar('Please select a valid product for all rows');
        return;
      }
      if (row.quantityController.text.isEmpty ||
          double.tryParse(row.quantityController.text) == 0) {
        _showSnackBar('Quantity must be greater than 0');
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final dateParts = _dateController.text.split('-');
      final formattedDate = '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}';

      List<Map<String, dynamic>> items = [];
      double subTotal = 0;

      for (var row in _productRows) {
        final product = _productMap[row.productId!];
        if (product == null) continue;

        final rate = double.tryParse(row.rateController.text) ?? 0;
        final quantity = double.tryParse(row.quantityController.text) ?? 0;
        final discount = double.tryParse(row.discountController.text) ?? 0;
        final total = row.getTotalAmount();

        items.add({
          "productId": product['id'],
          "productName": row.productName,
          "size": row.size,
          "quality": row.quality,
          "rate": rate,
          "cov": row.covController.text,
          "batches": product['batches'] ?? [],
          "batchNo": row.selectedBatch,
          "availQty": double.tryParse(row.stockController.text) ?? 0,
          "qty": row.quantityController.text,
          "total": total,
          "discount":
              row.discountController.text.isEmpty
                  ? "0"
                  : row.discountController.text,
          "godown": row.godown,
          "stockDiff": quantity,
        });

        subTotal += total;
      }

      print('📤 Updating purchase with ${items.length} items');

      final response = await _dio.put(
        'https://dashboard.theceramicstudio.in/api/purchase/update/${widget.purchase['id']}',
        data: {
          "purchaseDate": formattedDate,
          "clientName": _selectedSupplierName,
          "clientContact": _selectedSupplierContact,
          "billNo": _billNoController.text,
          "purchaseId": widget.purchase['id'],
          "items": items,
          "subTotal": subTotal,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      print('📥 Response: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        Navigator.pop(context);
        _showSnackBar(
          response.data['message'] ?? 'Purchase updated successfully',
          isError: false,
        );
      } else {
        throw Exception(response.data['message'] ?? 'Update failed');
      }
    } catch (e) {
      print('❌ Error: $e');
      _showSnackBar('Error: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(
        () => _dateController.text = DateFormat('dd-MM-yyyy').format(picked),
      );
    }
  }

  void _addProductRow() {
    setState(() {
      _productRows.add(ProductRow());
      // 🔥 KEPT: Manual scroll on add product row (optional)
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
    setState(() => _productRows.removeAt(index));
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
          // Header
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
                  "Edit Purchase",
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

          // Scrollable content
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showSupplierDropdown = false;
                  for (var row in _productRows) row.showProductDropdown = false;
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
                              // Date
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

                              // Supplier Search
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
                                                  () => setState(
                                                    () =>
                                                        _showSupplierDropdown =
                                                            true,
                                                  ),
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
                                          itemBuilder: (context, idx) {
                                            final supplier =
                                                _filteredSuppliers[idx];
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

                              // Supplier Contact
                              _buildLabel('SUPPLIER CONTACT'),
                              const SizedBox(height: 4),
                              _buildTextField(
                                TextEditingController(
                                  text: _selectedSupplierContact ?? '',
                                ),
                                'Auto-filled',
                                enabled: false,
                              ),

                              const SizedBox(height: 20),
                              const Divider(),
                              const SizedBox(height: 16),

                              // Product Section
                              const Text(
                                'PRODUCT DETAILS',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xffFFA54A),
                                ),
                              ),
                              const SizedBox(height: 16),

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

                              // 🔥 NEW: Grand Total
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
                                                'UPDATE PURCHASE',
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
          // Product Search
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
                            setState(() {
                              row.productName = value;
                              row.showProductDropdown = value.isNotEmpty;
                              row.size = '';
                              row.quality = '';
                              row.selectedBatch = null;
                              row.covController.clear();
                              row.rateController.clear();
                              row.productId = null;
                            });
                          },
                          onTap:
                              () => setState(
                                () => row.showProductDropdown = true,
                              ),
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
                                (p) =>
                                    (p['name'] as String?)
                                        ?.toLowerCase()
                                        .contains(
                                          row.productName.toLowerCase(),
                                        ) ??
                                    false,
                              )
                              .length,
                      itemBuilder: (context, idx) {
                        final filtered =
                            _filteredProducts
                                .where(
                                  (p) =>
                                      (p['name'] as String?)
                                          ?.toLowerCase()
                                          .contains(
                                            row.productName.toLowerCase(),
                                          ) ??
                                      false,
                                )
                                .toList();
                        final product = filtered[idx];
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
                              row.batches = product['batches'] ?? [];
                              if (row.batches.isNotEmpty) {
                                row.selectedBatch =
                                    row.batches.first['batch_no'];
                                row.stockController.text =
                                    row.batches.first['qty'].toString();
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
                          value:
                              row.size.isNotEmpty && sizes.contains(row.size)
                                  ? row.size
                                  : null,
                          hint: const Text('Select Size'),
                          items:
                              sizes
                                  .map<DropdownMenuItem<String>>(
                                    (s) => DropdownMenuItem<String>(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value == null) return;

                            setState(() {
                              row.size = value;
                              row.quality = '';
                              row.selectedBatch = null;
                              row.covController.clear();
                              row.rateController.clear();
                              row.productId = null;
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
                              qualities
                                  .map<DropdownMenuItem<String>>(
                                    (q) => DropdownMenuItem<String>(
                                      value: q,
                                      child: Text(q),
                                    ),
                                  )
                                  .toList(),
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
                                row.batches = productDetails['batches'] ?? [];

                                if (row.batches.isNotEmpty) {
                                  row.selectedBatch =
                                      row.batches.first['batch_no'];
                                  row.stockController.text =
                                      row.batches.first['qty'].toString();
                                }
                              } else {
                                row.productId = null;
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

          // Batch and Stock
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
                                  value: batch['batch_no'].toString(),
                                  child: Text('Batch ${batch['batch_no']}'),
                                );
                              }).toList(),
                          onChanged:
                              row.batches.isEmpty
                                  ? null
                                  : (value) {
                                    setState(() {
                                      row.selectedBatch = value;
                                      final batch = row.batches.firstWhere(
                                        (b) =>
                                            b['batch_no'].toString() == value,
                                        orElse: () => {'qty': 0},
                                      );
                                      row.stockController.text =
                                          batch['qty'].toString();
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
                          onChanged:
                              (value) => setState(() => row.godown = value!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Delete button
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
  int? productId;
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

      final baseAmount = rate * cov * quantity;
      final discountAmount = baseAmount * (discount / 100);
      final finalAmount = baseAmount - discountAmount;

      amountController.text = finalAmount.toStringAsFixed(2);
    } catch (e) {
      print('Error in updateTotal: $e');
      amountController.text = '0';
    }
  }

  double getTotalAmount() => double.tryParse(amountController.text) ?? 0;

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
