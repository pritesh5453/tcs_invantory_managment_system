import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:tcs_invantory_managment_system/dashbard/orderbook/add_order_screen.dart';
import 'package:tcs_invantory_managment_system/dashbard/orderbook/edit_order.dart';

class OrderBookManagementScreen extends StatefulWidget {
  const OrderBookManagementScreen({super.key});

  @override
  State<OrderBookManagementScreen> createState() =>
      _OrderBookManagementScreenState();
}

class _OrderBookManagementScreenState extends State<OrderBookManagementScreen> {
  bool isLoading = true;
  List orders = [];

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
        orders = response.data["orders"] ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("ORDER LIST ERROR: $e");
    }
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

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F6F6),
      body: SafeArea(
        child: Column(
          children: [
            /// ================= TOP BAR =================
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
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey),
                          SizedBox(width: 8),
                          Text(
                            "Search..",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
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
                      );
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
                      : orders.isEmpty
                      ? RefreshIndicator(
                        onRefresh: _fetchOrders,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 200),
                            Center(child: Text("No Orders Found")),
                          ],
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh: _fetchOrders,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            final order = orders[index];
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                child: Text(
                  "Date : ${order["date"].toString().split("T").first}",
                ),
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
          fontSize: 13,
          color: Colors.black,
          fontWeight: FontWeight.w500,
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
