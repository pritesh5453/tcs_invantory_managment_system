import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:excel/excel.dart' as excel; // 👈 prefixed to avoid conflict
import 'package:flutter/material.dart';
import 'dart:typed_data'; // ✅ For Uint8List
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tcs_invantory_managment_system/dashbard/orderbook/add_order_screen.dart';
import 'package:tcs_invantory_managment_system/dashbard/orderbook/edit_order.dart';
import 'package:tcs_invantory_managment_system/dashbard/orderbook/order_model.dart'
    as order_model;
import 'package:tcs_invantory_managment_system/dashbard/orderbook/order_services.dart';
import 'package:tcs_invantory_managment_system/dashbard/product%20Managment/Product_Management.dart'
    hide Product;

// Create type aliases for clarity
typedef OrderBrand = order_model.Brand;
typedef OrderType = order_model.Order;
typedef ProductType = order_model.Product;

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  // ---------- Data ----------
  List<OrderType> _orders = [];
  List<OrderBrand> _brands = [];
  OrderBrand? _selectedBrand;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  final int _limit = 10;

  // ---------- UI State ----------
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isLoadingBrands = false;
  String _searchQuery = '';
  DateTime? _selectedDate;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  // ---------- Fetch methods ----------
  Future<void> _loadOrders({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _orders = [];
      });
    }
    setState(() => _isLoading = refresh ? true : _isLoading);

    try {
      final response = await OrderApiService.fetchOrders(
        page: _currentPage,
        limit: _limit,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        date:
            _selectedDate != null
                ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                : null,
        brandName: _selectedBrand?.name,
      );
      setState(() {
        if (refresh) {
          _orders = response.orders;
        } else {
          _orders.addAll(response.orders);
        }
        _totalPages = response.totalPages;
        _totalItems = response.total;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load orders: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadBrands() async {
    setState(() {
      _isLoadingBrands = true;
    });

    try {
      debugPrint('🔄 Fetching brands from API...');
      final brands = await OrderApiService.fetchBrands();

      debugPrint('✅ Brands fetched: ${brands.length}');

      for (var brand in brands) {
        debugPrint('   - Brand: ${brand.name} (ID: ${brand.id})');
      }

      setState(() {
        _brands = brands.cast<OrderBrand>();
        if (_selectedBrand != null && !_brands.contains(_selectedBrand)) {
          _selectedBrand = null;
        }
        _isLoadingBrands = false;
      });

      debugPrint('✅ Brands loaded in state: ${_brands.length}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_brands.length} brands loaded successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Brands error: $e');
      setState(() {
        _isLoadingBrands = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load brands: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // ---------- Refresh All (Brands + Orders) ----------
  Future<void> _refreshAll() async {
    await _loadBrands();
    await _loadOrders(refresh: true);
  }

  // ---------- Debug API (using Dio) ----------
  Future<void> _debugCheckApi() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://dashboard.theceramicstudio.in/api/brands/GetAlllist',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final brands = data['brands'] as List?;
        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text('API Debug'),
                content: Text(
                  'Status: ${response.statusCode}\n'
                  'Success: ${data['success']}\n'
                  'Brands count: ${brands?.length ?? 0}\n\n'
                  'First brand: ${brands?.isNotEmpty == true ? brands![0]['name'] : 'N/A'}',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ---------- Pagination ----------
  void _loadNextPage() {
    if (_currentPage < _totalPages && !_isLoadingMore && !_isLoading) {
      setState(() {
        _currentPage++;
        _isLoadingMore = true;
      });
      _loadOrders();
    }
  }

  void _loadPreviousPage() {
    if (_currentPage > 1 && !_isLoadingMore && !_isLoading) {
      setState(() {
        _currentPage--;
        _isLoadingMore = true;
      });
      _loadOrders(refresh: true);
    }
  }

  // ---------- Search debounce ----------
  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadOrders(refresh: true);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
    _loadOrders(refresh: true);
  }

  // ---------- Date picker ----------
  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
      _loadOrders(refresh: true);
    }
  }

  void _clearDate() {
    setState(() => _selectedDate = null);
    _loadOrders(refresh: true);
  }

  // ---------- Delete order ----------
  Future<void> _deleteOrder(OrderType order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Delete Order'),
            content: Text(
              'Are you sure you want to delete order ${order.orderId}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirm == true) {
      final success = await OrderApiService.deleteOrder(order.id.toString());
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order deleted'),
            backgroundColor: Colors.green,
          ),
        );
        _loadOrders(refresh: true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delete failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ---------- View products dialog ----------
  void _showProductsDialog(List<ProductType> products) {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(maxHeight: 1000),
              width: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Products",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.download,
                              color: Colors.green,
                            ),
                            onPressed: () => _exportToExcel(products),
                            tooltip: 'Export to Excel',
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: products.length,
                      itemBuilder: (ctx, i) {
                        final p = products[i];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.productName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _productTag("Size", p.size, Colors.blue),
                                  _productTag(
                                    "Qty",
                                    p.quantity.toString(),
                                    Colors.green,
                                  ),
                                  _productTag(
                                    "Quality",
                                    p.quality,
                                    Colors.purple,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // ✅ Export to Excel
  Future<void> _exportToExcel(List<ProductType> products) async {
    try {
      var excelFile = excel.Excel.createExcel();
      String sheetName = excelFile.getDefaultSheet()!;
      excelFile.rename(sheetName, "Order Details");
      sheetName = "Order Details";

      excel.Sheet sheetObject = excelFile[sheetName];

      // Header Row
      sheetObject.appendRow([
        excel.TextCellValue('Product Name'),
        excel.TextCellValue('Size'),
        excel.TextCellValue('Quantity'),
        excel.TextCellValue('Quality'),
      ]);

      // Product Rows
      for (var p in products) {
        sheetObject.appendRow([
          excel.TextCellValue(p.productName),
          excel.TextCellValue(p.size),
          excel.TextCellValue(p.quantity.toString()),
          excel.TextCellValue(p.quality),
        ]);
      }

      var fileBytes = excelFile.save();
      if (fileBytes == null) return;

      Uint8List uint8list = Uint8List.fromList(fileBytes);

      // Save file in temporary directory (no permissions needed)
      final directory = await getTemporaryDirectory();
      final fileName = 'products_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(uint8list);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Excel exported successfully"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Show open/share options
        _showExcelOptions(filePath, fileName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Export failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showExcelOptions(String filePath, String fileName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Excel Exported',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('What would you like to do?'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOptionButton(
                    icon: Icons.visibility,
                    label: 'Open',
                    onTap: () async {
                      Navigator.pop(ctx);
                      final result = await OpenFilex.open(filePath);
                      if (result.type != ResultType.done) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Could not open file: ${result.message}",
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                  ),
                  _buildOptionButton(
                    icon: Icons.share,
                    label: 'Share',
                    onTap: () async {
                      Navigator.pop(ctx);
                      await Share.shareXFiles([
                        XFile(filePath),
                      ], text: 'Order Products');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.orange),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _productTag(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: RichText(
        text: TextSpan(
          // 👈 this is Flutter's TextSpan, no conflict now
          style: const TextStyle(fontSize: 12),
          children: [
            TextSpan(
              text: "$title: ",
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value, style: const TextStyle(color: Colors.black)),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 OrderManagementScreen initialized');
    _loadBrands();
    _loadOrders(refresh: true);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilters(),
            Expanded(child: _buildOrderList()),
            _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFFA54A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Management',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Manage multi-product brand orders',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _refreshAll,
                    tooltip: 'Refresh All',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _buildBrandDropdown()),
              const SizedBox(width: 8),
              Expanded(child: _buildDateFilter()),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildSearchField()),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateOrderScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA54A),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(70, 40),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBrandDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<OrderBrand>(
          value: _selectedBrand,
          hint:
              _isLoadingBrands
                  ? const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Loading brands...'),
                    ],
                  )
                  : const Text('All Brands'),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          items: [
            const DropdownMenuItem<OrderBrand>(
              value: null,
              child: Text('All Brands'),
            ),
            ..._brands.map(
              (brand) => DropdownMenuItem<OrderBrand>(
                value: brand,
                child: Text(brand.name),
              ),
            ),
          ],
          onChanged: (brand) {
            setState(() {
              _selectedBrand = brand;
            });
            _loadOrders(refresh: true);
          },
        ),
      ),
    );
  }

  Widget _buildDateFilter() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedDate == null
                    ? 'dd-mm-yyyy'
                    : DateFormat('dd-MM-yyyy').format(_selectedDate!),
                style: TextStyle(
                  color:
                      _selectedDate == null
                          ? Colors.grey.shade600
                          : Colors.black,
                ),
              ),
            ),
            if (_selectedDate != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 16),
                onPressed: _clearDate,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          const Icon(Icons.search, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search ID or Brand...',
                border: InputBorder.none,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: _clearSearch,
            ),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    if (_isLoading && _orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No orders found',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    final scrollController = ScrollController();

    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,
      child: ListView.builder(
        controller: scrollController,
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.orderId,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.shopping_cart,
                              color: Colors.orange,
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Cart for ${order.orderId} - Coming Soon',
                                  ),
                                ),
                              );
                            },
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              if (value == 'edit') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => EditOrderScreen(order: order),
                                  ),
                                ).then((_) => _loadOrders(refresh: true));
                              } else if (value == 'delete') {
                                _deleteOrder(order);
                              }
                            },
                            itemBuilder:
                                (_) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yyyy').format(order.orderDate),
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.business,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        order.brandName,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _showProductsDialog(order.products),
                      icon: const Icon(Icons.view_list, size: 18),
                      label: Text('View ${order.products.length} Products'),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.orange.shade50,
                        foregroundColor: Colors.orange.shade800,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPagination() {
    if (_orders.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${_orders.length} of $_totalItems records',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1 ? _loadPreviousPage : null,
                color: _currentPage > 1 ? Colors.orange : Colors.grey,
              ),
              Text(
                '$_currentPage',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < _totalPages ? _loadNextPage : null,
                color: _currentPage < _totalPages ? Colors.orange : Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
