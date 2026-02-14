import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:tcs_invantory_managment_system/dashbard/orderbook/add_order_screen.dart';
import 'package:tcs_invantory_managment_system/dashbard/orderbook/edit_order.dart';

/// ================= SEARCH BAR WIDGET =================
class OrderBookSearchBarWidget extends StatefulWidget {
  final ValueChanged<String> onSearchChanged;
  final String initialValue;

  const OrderBookSearchBarWidget({
    super.key,
    required this.onSearchChanged,
    this.initialValue = '',
  });

  @override
  State<OrderBookSearchBarWidget> createState() =>
      _OrderBookSearchBarWidgetState();
}

class _OrderBookSearchBarWidgetState extends State<OrderBookSearchBarWidget> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialValue);
    _searchFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(OrderBookSearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controller with parent state
    if (widget.initialValue != _searchController.text) {
      _searchController.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    widget.onSearchChanged('');
    _searchFocusNode.requestFocus();
  }

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();

    // Debounce search (500ms delay)
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      widget.onSearchChanged(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: "Search by product name, size, quality...",
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
              onPressed: _clearSearch,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

class OrderBookManagementScreen extends StatefulWidget {
  const OrderBookManagementScreen({super.key});

  @override
  State<OrderBookManagementScreen> createState() =>
      _OrderBookManagementScreenState();
}

class _OrderBookManagementScreenState extends State<OrderBookManagementScreen> {
  bool isLoading = true;
  bool loadingMore = false;
  List orders = []; // Store orders
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // ✅ PAGINATION VARIABLES
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// ================= FETCH ORDER LIST WITH PAGINATION =================
  Future<void> _fetchOrders({bool isLoadMore = false}) async {
    if (!isLoadMore) {
      setState(() {
        isLoading = true;
        _currentPage = 1;
        orders = [];
        _hasMoreData = true;
      });
    } else {
      setState(() {
        loadingMore = true;
      });
    }

    try {
      final Map<String, dynamic> queryParams = {
        'page': _currentPage,
        'limit': 10,
        if (searchQuery.isNotEmpty) 'search': searchQuery,
      };

      debugPrint('Fetching orders with params: $queryParams');

      final response = await _dio.get(
        "https://dashboard.theceramicstudio.in/api/orderBook/list",
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data["success"] == true) {
        final data = response.data;

        setState(() {
          if (isLoadMore) {
            orders.addAll(data["orders"] ?? []);
          } else {
            orders = data["orders"] ?? [];
          }

          _currentPage = data["page"] ?? _currentPage;
          _totalPages = data["totalPages"] ?? _totalPages;
          _totalItems = data["total"] ?? _totalItems;
          _hasMoreData = (_currentPage) < (_totalPages);

          isLoading = false;
          loadingMore = false;
        });

        debugPrint('Pagination Info:');
        debugPrint('Current Page: $_currentPage');
        debugPrint('Total Pages: $_totalPages');
        debugPrint('Total Items: $_totalItems');
        debugPrint('Has More Data: $_hasMoreData');
        debugPrint('Orders Count: ${orders.length}');
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      debugPrint("ORDER LIST ERROR: $e");
      setState(() {
        isLoading = false;
        loadingMore = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to load orders"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// ================= SCROLL LISTENER FOR PAGINATION =================
  void _scrollListener() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    debugPrint('Scroll Position: $currentScroll / $maxScroll');
    debugPrint('Loading More: $loadingMore, Has More: $_hasMoreData');

    // Agar 50 pixels pehle ho bottom se aur data load karne ke liye available hai
    if (currentScroll >= (maxScroll - 50) &&
        !loadingMore &&
        _hasMoreData &&
        orders.isNotEmpty) {
      debugPrint('Loading more data...');
      _loadMoreData();
    }
  }

  /// ================= LOAD MORE DATA =================
  Future<void> _loadMoreData() async {
    if (!_hasMoreData || loadingMore) {
      debugPrint(
        'Cannot load more: HasMore=$_hasMoreData, LoadingMore=$loadingMore',
      );
      return;
    }

    debugPrint('Starting to load more data. Current page: $_currentPage');
    setState(() {
      loadingMore = true;
    });

    _currentPage++;
    await _fetchOrders(isLoadMore: true);
  }

  /// ================= API-BASED SEARCH =================
  void _searchOrders(String query) {
    // Cancel any previous search timer
    setState(() {
      searchQuery = query;
    });
    _fetchOrders();
  }

  void _clearSearch() {
    setState(() {
      searchQuery = '';
      _searchController.clear();
    });
    _fetchOrders();
  }

  /// ================= DELETE ORDER =================
  Future<void> _deleteOrder(int id) async {
    try {
      await _dio.delete(
        "https://dashboard.theceramicstudio.in/api/orderBook/delete/$id",
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Order deleted successfully"),
          backgroundColor: Colors.green,
        ),
      );

      _fetchOrders(); // refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Delete failed"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// ================= DELETE CONFIRM =================
  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Delete Order"),
            content: const Text("Are you sure you want to delete this order?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteOrder(id);
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  /// ================= REFRESH FUNCTION =================
  Future<void> _refreshOrders() async {
    setState(() {
      isLoading = true;
      searchQuery = '';
      _searchController.clear();
    });
    await _fetchOrders();
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F6F6),
      body: SafeArea(
        child: Column(
          children: [
            /// ================= TOP BAR WITH SEARCH =================
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: const BoxDecoration(
                color: Color(0xFFFFA54A),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(26),
                  bottomRight: Radius.circular(26),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OrderBookSearchBarWidget(
                      onSearchChanged: _searchOrders,
                      initialValue: searchQuery,
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddOrderScreen(),
                        ),
                      ).then((_) {
                        _refreshOrders();
                      });
                    },
                    child: Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            /// ================= ORDER LIST =================
            Expanded(
              child:
                  isLoading && orders.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                        onRefresh: _refreshOrders,
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            /// ORDER COUNT HEADER
                            if (orders.isNotEmpty)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    "Orders (${orders.length} of $_totalItems)",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),

                            /// ORDERS LIST
                            SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final order = orders[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: OrderCard(
                                    order: order,
                                    onEdit: () async {
                                      final refresh = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) =>
                                                  EditOrderScreen(order: order),
                                        ),
                                      );

                                      if (refresh == true) {
                                        _fetchOrders();
                                      }
                                    },
                                    onDelete: () => _confirmDelete(order["id"]),
                                  ),
                                );
                              }, childCount: orders.length),
                            ),

                            /// EMPTY STATE
                            if (orders.isEmpty && !isLoading)
                              SliverFillRemaining(child: _buildEmptyState()),

                            /// LOAD MORE INDICATOR
                            if (loadingMore)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              ),

                            /// NO MORE ORDERS MESSAGE
                            if (!_hasMoreData && orders.isNotEmpty)
                              SliverToBoxAdapter(
                                child: const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: Text(
                                      "No more orders",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ),

                            /// EXTRA SPACE AT BOTTOM FOR BETTER SCROLLING
                            SliverToBoxAdapter(child: Container(height: 50)),
                          ],
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= EMPTY STATE =================
  Widget _buildEmptyState() {
    if (searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "No results found for '$searchQuery'",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              "Try searching with different keywords",
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA54A),
              ),
              child: const Text("Clear Search"),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_outlined, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            "No Orders Found",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            "Add your first order to get started",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddOrderScreen()),
              ).then((_) {
                _refreshOrders();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFA54A),
            ),
            child: const Text("Add Order"),
          ),
        ],
      ),
    );
  }
}

/// ===================================================================
/// ORDER CARD
/// ===================================================================

class OrderCard extends StatelessWidget {
  final Map order;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const OrderCard({
    super.key,
    required this.order,
    required this.onEdit,
    required this.onDelete,
  });

  /// ================= FORMAT DATE =================
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (e) {
      return dateString.split("T").first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ORDER ID
          Text(
            "Order #${order["id"]}",
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),

          _row("Product Name", order["name"]),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: Text("Size : ${order["size"]}")),
              Text("Quality : ${order["quality"]}"),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text("Date : ${_formatDate(order["date"].toString())}"),
              ),
              Text("Quantity : ${order["quantity"]}"),
            ],
          ),
          const SizedBox(height: 6),
          Text("Brand : ${order["brand"]}"),
          const SizedBox(height: 14),

          /// BUTTONS
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                  label: const Text(
                    "Edit",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                  label: const Text(
                    "Delete",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return RichText(
      text: TextSpan(
        text: "$label : ",
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}
