import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:tcs_invantory_managment_system/dashbard/Inventory%20Management/add_Inventory.dart';
import 'package:tcs_invantory_managment_system/dashbard/Inventory%20Management/edit_inventory.dart';
import 'package:tcs_invantory_managment_system/auth/prefs/permission_manager.dart';
import 'package:tcs_invantory_managment_system/dashbard/main_dashbard_screen.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() =>
      _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  late bool canAddInventory;
  late bool canDeleteInventory;
  final Dio _dio = Dio();

  List<dynamic> purchases = [];
  List<dynamic> filteredPurchases = [];
  bool isLoading = true;
  bool loadingMore = false;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // ✅ PAGINATION VARIABLES
  int _currentPage = 1;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();
  final int _pageLimit = 10;

  @override
  void initState() {
    super.initState();

    canAddInventory = PermissionManager.hasPermission(
      "Inventory Management_Add",
    );
    canDeleteInventory = PermissionManager.hasPermission(
      "Inventory Management_Delete",
    );

    fetchPurchases();

    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// ================= FETCH PURCHASES WITH PAGINATION =================
  Future<List<dynamic>> _fetchPurchasesAPI({
    int page = 1,
    String search = '',
  }) async {
    try {
      final response = await _dio.get(
        'https://dashboard.theceramicstudio.in/api/purchase/list',
        queryParameters: {
          'page': page,
          'limit': _pageLimit,
          if (search.isNotEmpty) 'search': search,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['purchases'] ?? [];
      } else {
        throw Exception('Failed to load purchases');
      }
    } catch (e) {
      print('API Error fetching purchases: $e');
      throw Exception('Failed to load purchases');
    }
  }

  Future<void> fetchPurchases({bool isLoadMore = false}) async {
    if (!isLoadMore) {
      setState(() {
        isLoading = true;
        _currentPage = 1;
        purchases = [];
        filteredPurchases = [];
      });
    } else {
      setState(() {
        loadingMore = true;
      });
    }

    try {
      final List<dynamic> newPurchases = await _fetchPurchasesAPI(
        page: _currentPage,
        search: searchQuery,
      );

      setState(() {
        if (isLoadMore) {
          purchases.addAll(newPurchases);
          filteredPurchases.addAll(newPurchases);
        } else {
          purchases = newPurchases;
          filteredPurchases = newPurchases;
        }

        // ✅ CHECK IF WE HAVE MORE DATA
        _hasMoreData = newPurchases.length >= _pageLimit;
        isLoading = false;
        loadingMore = false;
      });
    } catch (e) {
      print('Error fetching purchases: $e');
      setState(() {
        isLoading = false;
        loadingMore = false;
      });
    }
  }

  /// ================= SCROLL LISTENER FOR PAGINATION =================
  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !loadingMore &&
        _hasMoreData) {
      _loadMoreData();
    }
  }

  /// ================= LOAD MORE DATA =================
  Future<void> _loadMoreData() async {
    if (!_hasMoreData || loadingMore) return;

    setState(() {
      loadingMore = true;
    });

    _currentPage++;
    await fetchPurchases(isLoadMore: true);
  }

  /// ================= FILTER PURCHASES (LOCAL SEARCH) =================
  void filterPurchases(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredPurchases = purchases;
      } else {
        filteredPurchases =
            purchases.where((purchase) {
              final billNo = purchase['bill_no'].toString().toLowerCase();
              final clientName =
                  purchase['client_name'].toString().toLowerCase();
              final clientContact =
                  purchase['client_contact'].toString().toLowerCase();
              final searchLower = query.toLowerCase();

              return billNo.contains(searchLower) ||
                  clientName.contains(searchLower) ||
                  clientContact.contains(searchLower);
            }).toList();
      }
    });
  }

  /// ================= FORMAT DATE =================
  String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  /// ================= EDIT FUNCTION =================
  void _openEditInventorySheet(
    BuildContext context,
    Map<String, dynamic> purchase,
  ) {
    EditInventorySheet.show(context, purchase: purchase).then((_) {
      // Refresh the list after editing
      fetchPurchases();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeWithAnimatedDrawer()),
          (route) => false,
        );

        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xffF6F6F6),
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                decoration: const BoxDecoration(
                  color: Color(0xffFFA54A),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(26),
                    bottomRight: Radius.circular(26),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: filterPurchases,
                                decoration: const InputDecoration(
                                  hintText: "Search by bill no, name, phone...",
                                  hintStyle: TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            if (searchQuery.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  filterPurchases('');
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap:
                          canAddInventory
                              ? () {
                                AddInventorySheet.show(context).then((_) {
                                  fetchPurchases();
                                });
                              }
                              : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "You don't have permission to add inventory.",
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              },
                      child: Opacity(
                        opacity: canAddInventory ? 1 : 0.4,
                        child: Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // List
              Expanded(
                child:
                    isLoading && purchases.isEmpty
                        ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xffFFA54A),
                          ),
                        )
                        : filteredPurchases.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.inventory,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                searchQuery.isEmpty
                                    ? 'No purchases found'
                                    : 'No results for "$searchQuery"',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              if (searchQuery.isNotEmpty)
                                TextButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    filterPurchases('');
                                  },
                                  child: const Text('Clear search'),
                                ),
                            ],
                          ),
                        )
                        : RefreshIndicator(
                          color: const Color(0xffFFA54A),
                          onRefresh: fetchPurchases,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount:
                                filteredPurchases.length +
                                (loadingMore ? 1 : 0) +
                                (_hasMoreData && !loadingMore ? 1 : 0),
                            itemBuilder: (_, index) {
                              // Loading more indicator
                              if (index >= filteredPurchases.length) {
                                if (loadingMore) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xffFFA54A),
                                      ),
                                    ),
                                  );
                                } else if (!_hasMoreData) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: Text(
                                        "No more purchases",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox(); // For hasMore but not loading
                              }

                              final purchase = filteredPurchases[index];
                              return InventoryCard(
                                purchase: purchase,
                                canDelete: canDeleteInventory,
                                onEdit: () {
                                  _openEditInventorySheet(context, purchase);
                                },
                                onDelete: () {
                                  if (!canDeleteInventory) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "You don't have permission to delete inventory.",
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  showDeleteDialog(context, purchase);
                                },
                                onView: () {
                                  openInventoryView(context, purchase);
                                },
                              );
                            },
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void openInventoryView(BuildContext context, Map<String, dynamic> purchase) {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Purchase Details",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Text("Bill no: ${purchase['bill_no']}"),
                  Text("Client: ${purchase['client_name']}"),
                  Text("Contact: ${purchase['client_contact']}"),
                  Text("Date: ${formatDate(purchase['purchase_date'])}"),

                  // Show all items
                  const SizedBox(height: 16),
                  const Text(
                    "Items:",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  ...(purchase['items'] as List).map(
                    (item) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text("• Product ID: ${item['product_id']}"),
                        Text("  Batch: ${item['batch_no']}"),
                        Text("  Quantity: ${item['qty']}"),
                        Text("  Rate: ₹${item['rate']}"),
                        Text("  Total: ₹${item['total']}"),
                        Text("  Godown: ${item['godown']}"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text("Sub Total: ₹${purchase['subtotal']}"),
                ],
              ),
            ),
          ),
    );
  }

  void showDeleteDialog(BuildContext context, Map<String, dynamic> purchase) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Delete Purchase"),
            content: Text("Delete purchase ${purchase['bill_no']}?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    final response = await _dio.delete(
                      'https://dashboard.theceramicstudio.in/api/purchase/${purchase['id']}',
                    );

                    if (response.statusCode == 200) {
                      Navigator.pop(context);
                      fetchPurchases();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Purchase ${purchase['bill_no']} deleted',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      throw Exception('Failed to delete');
                    }
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
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
}

class InventoryCard extends StatelessWidget {
  final Map<String, dynamic> purchase;
  final bool canDelete;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const InventoryCard({
    super.key,
    required this.purchase,
    required this.canDelete,
    required this.onView,
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
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Bill no. ${purchase['bill_no']}",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'view') onView();
                  if (value == 'edit') {
                    onEdit();
                  }
                },
                itemBuilder:
                    (_) => const [
                      PopupMenuItem(
                        value: 'view',
                        child: ListTile(
                          leading: Icon(Icons.visibility),
                          title: Text("View"),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text("Edit"),
                        ),
                      ),
                    ],
              ),
            ],
          ),

          const SizedBox(height: 8),
          Text(purchase['client_name']),
          Text(purchase['client_contact']),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Date: ${_formatDate(purchase['purchase_date'])}"),
              Text(
                "₹${purchase['subtotal']}",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          // Items summary
          if ((purchase['items'] as List).isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  "Items: ${(purchase['items'] as List).length} item${(purchase['items'] as List).length > 1 ? 's' : ''}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
