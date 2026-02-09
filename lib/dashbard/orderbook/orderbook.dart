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
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    widget.onSearchChanged('');
    _searchFocusNode.requestFocus();
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
              onChanged: widget.onSearchChanged,
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
  List allOrders = []; // Store all orders
  List filteredOrders = []; // Store filtered orders
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  /// ================= FETCH ORDER LIST =================
  Future<void> _fetchOrders() async {
    try {
      setState(() => isLoading = true);

      final response = await Dio().get(
        "https://dashboarduat.theceramicstudio.in/api/orderBook/list",
      );

      setState(() {
        allOrders = response.data["orders"] ?? [];
        _filterOrders(); // Apply search filter
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("ORDER LIST ERROR: $e");
    }
  }

  /// ================= LOCAL SEARCH FILTER =================
  void _filterOrders() {
    if (searchQuery.isEmpty) {
      setState(() {
        filteredOrders = List.from(allOrders);
      });
    } else {
      final filtered =
          allOrders.where((order) {
            final name = order["name"]?.toString().toLowerCase() ?? '';
            final size = order["size"]?.toString().toLowerCase() ?? '';
            final quality = order["quality"]?.toString().toLowerCase() ?? '';
            final brand = order["brand"]?.toString().toLowerCase() ?? '';
            final quantity = order["quantity"]?.toString().toLowerCase() ?? '';
            final date = order["date"]?.toString().toLowerCase() ?? '';
            final id = order["id"]?.toString().toLowerCase() ?? '';

            final query = searchQuery.toLowerCase();

            return name.contains(query) ||
                size.contains(query) ||
                quality.contains(query) ||
                brand.contains(query) ||
                quantity.contains(query) ||
                date.contains(query) ||
                id.contains(query);
          }).toList();

      setState(() {
        filteredOrders = filtered;
      });
    }
  }

  /// ================= SEARCH FUNCTIONALITY =================
  void _searchOrders(String query) {
    setState(() {
      searchQuery = query;
    });
    _filterOrders();
  }

  void _clearSearch() {
    setState(() {
      searchQuery = '';
    });
    _filterOrders();
  }

  /// ================= DELETE ORDER =================
  Future<void> _deleteOrder(int id) async {
    try {
      await Dio().delete(
        "https://dashboarduat.theceramicstudio.in/api/orderBook/delete/$id",
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
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredOrders.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                        onRefresh: _refreshOrders,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = filteredOrders[index];
                            return OrderCard(
                              order: order,
                              onEdit: () async {
                                final refresh = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => EditOrderScreen(order: order),
                                  ),
                                );

                                if (refresh == true) {
                                  _fetchOrders();
                                }
                              },
                              onDelete: () => _confirmDelete(order["id"]),
                            );
                          },
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

    return RefreshIndicator(
      onRefresh: _refreshOrders,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          const Center(
            child: Column(
              children: [
                Icon(Icons.inventory_outlined, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  "No Orders Found",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  "Add your first order to get started",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
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
      margin: const EdgeInsets.only(bottom: 14),
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
