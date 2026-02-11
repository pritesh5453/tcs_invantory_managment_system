import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:tcs_invantory_managment_system/auth/prefs/permission_manager.dart';
import 'package:tcs_invantory_managment_system/dashbard/customer_management/add_customer.dart';
import 'package:tcs_invantory_managment_system/dashbard/customer_management/add_followUp.dart';
import 'package:tcs_invantory_managment_system/dashbard/customer_management/edit_customer.dart';
import 'package:tcs_invantory_managment_system/dashbard/customer_management/history.dart';

/// =====================
/// MODEL
/// =====================
class Customer {
  final int id;
  final String name;
  final String lastName;
  final String phone;
  final String? assignedEmployee;
  final String? assignedEmployeeId;
  final String? siteType;

  Customer({
    required this.id,
    required this.name,
    required this.lastName,
    required this.phone,
    this.assignedEmployee,
    this.assignedEmployeeId,
    this.siteType,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'] ?? '',
      lastName: json['Last_Name'] ?? '',
      phone: json['phone'] ?? '',
      assignedEmployee: json['assignedEmployee'],
      assignedEmployeeId: json['assignedEmployeeId']?.toString(),
      siteType: json['siteType'],
    );
  }
}

/// =====================
/// API RESPONSE MODEL
/// =====================
class CustomerResponse {
  final List<Customer> customers;
  final bool hasMore;
  final int currentPage;
  final int totalItems;

  CustomerResponse({
    required this.customers,
    required this.hasMore,
    required this.currentPage,
    required this.totalItems,
  });
}

/// =====================
/// API
/// =====================
class CustomerApi {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "https://dashboarduat.theceramicstudio.in",
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  // ✅ ADMIN/Superadmin ke liye (with pagination and search)
  static Future<CustomerResponse> fetchAllCustomers({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {'page': page, 'limit': limit};

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _dio.get(
        "/api/users/list",
        queryParameters: queryParams,
      );

      final List list = response.data['customers'] ?? [];
      final customers = list.map((e) => Customer.fromJson(e)).toList();
      customers.sort((a, b) => b.id.compareTo(a.id));

      // Pagination data extract karein
      final pagination = response.data['pagination'] ?? {};
      final currentPage = pagination['page'] ?? 1;
      final totalPages = pagination['totalPages'] ?? 1;
      final totalItems = pagination['totalItems'] ?? list.length;
      final hasMore = currentPage < totalPages;

      return CustomerResponse(
        customers: customers,
        hasMore: hasMore,
        currentPage: currentPage,
        totalItems: totalItems,
      );
    } catch (e) {
      debugPrint("Error fetching all customers: $e");
      return CustomerResponse(
        customers: [],
        hasMore: false,
        currentPage: 1,
        totalItems: 0,
      );
    }
  }

  // ✅ EMPLOYEE ke liye (assigned customers with pagination and search)
  static Future<CustomerResponse> fetchEmployeeCustomers({
    required int employeeId,
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
        'employeeId': employeeId,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _dio.get(
        "/api/users/list/employee",
        queryParameters: queryParams,
      );

      final List list = response.data['customers'] ?? [];
      final customers = list.map((e) => Customer.fromJson(e)).toList();
      customers.sort((a, b) => b.id.compareTo(a.id));

      final pagination = response.data['pagination'] ?? {};
      final currentPage = pagination['page'] ?? 1;
      final totalPages = pagination['totalPages'] ?? 1;
      final totalItems = pagination['totalItems'] ?? list.length;
      final hasMore = currentPage < totalPages;

      return CustomerResponse(
        customers: customers,
        hasMore: hasMore,
        currentPage: currentPage,
        totalItems: totalItems,
      );
    } catch (e) {
      debugPrint("Error fetching employee customers: $e");
      return CustomerResponse(
        customers: [],
        hasMore: false,
        currentPage: page,
        totalItems: 0,
      );
    }
  }

  // ✅ SMART FETCH METHOD - role aur employeeId ke hisab se API call karega
  static Future<CustomerResponse> fetchCustomers({
    required String userRole,
    required int employeeId,
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    if (userRole == "admin" || userRole == "superadmin") {
      return await fetchAllCustomers(page: page, limit: limit, search: search);
    } else {
      return await fetchEmployeeCustomers(
        employeeId: employeeId,
        page: page,
        limit: limit,
        search: search,
      );
    }
  }

  // ✅ DELETE CUSTOMER METHOD
  static Future<bool> deleteCustomer(int customerId) async {
    try {
      final response = await _dio.delete("/api/users/delete/$customerId");
      if (response.statusCode == 200 && response.data['success'] == true) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Delete customer error: $e");
      return false;
    }
  }
}

/// =====================
/// MAIN SCREEN
/// =====================
class CustomerManagementScreen extends StatefulWidget {
  final int employeeId;
  final String userRole;

  const CustomerManagementScreen({
    super.key,
    required this.employeeId,
    required this.userRole,
  });

  @override
  State<CustomerManagementScreen> createState() =>
      _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  late bool canAddCustomer;
  late bool canEditCustomer;
  late bool canDeleteCustomer;

  List<Customer> _allCustomers = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounceTimer;

  // ✅ PAGINATION VARIABLES
  int _currentPage = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _totalItems = 0;
  final ScrollController _scrollController = ScrollController();
  final int _limit = 10;

  @override
  void initState() {
    super.initState();

    // Permissions
    canAddCustomer = PermissionManager.hasPermission("Customer Management_Add");
    canEditCustomer = PermissionManager.hasPermission(
      "Customer Management_Edit",
    );
    canDeleteCustomer = PermissionManager.hasPermission(
      "Customer Management_Delete",
    );

    // Load initial data
    _loadCustomers();

    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);
  }

  /// 🔄 Load customers (initial or refresh)
  Future<void> _loadCustomers({
    bool isRefresh = false,
    bool isLoadMore = false,
    String? search,
  }) async {
    if (isRefresh) {
      setState(() {
        _currentPage = 1;
        _hasMoreData = true;
        _allCustomers = [];
        _isLoading = true;
        _totalItems = 0;
      });
    } else if (isLoadMore) {
      setState(() {
        _isLoadingMore = true;
      });
    } else if (!isLoadMore) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final response = await CustomerApi.fetchCustomers(
        userRole: widget.userRole,
        employeeId: widget.employeeId,
        page: _currentPage,
        limit: _limit,
        search: search ?? _searchQuery,
      );

      setState(() {
        if (isLoadMore) {
          _allCustomers.addAll(response.customers);
        } else {
          _allCustomers = response.customers;
        }

        _hasMoreData = response.hasMore;
        _totalItems = response.totalItems;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint("Error loading customers: $e");
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  /// 📜 Scroll listener for pagination
  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoadingMore &&
        !_isLoading &&
        _hasMoreData) {
      _loadMoreData();
    }
  }

  /// 🔽 Load more data for pagination
  Future<void> _loadMoreData() async {
    if (!_hasMoreData || _isLoadingMore || _isLoading) return;

    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;
    await _loadCustomers(isLoadMore: true);
  }

  /// 🔍 API-based Search functionality with debounce
  void _searchCustomers(String query) {
    setState(() {
      _searchQuery = query;
    });

    // Cancel previous timer
    _searchDebounceTimer?.cancel();

    // Set new timer for debounce
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadCustomers(isRefresh: true, search: query);
    });
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
    _loadCustomers(isRefresh: true);
  }

  /// 🔄 Pull to refresh handler
  Future<void> _onRefresh() async {
    await _loadCustomers(isRefresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            /// ================= APP BAR =================
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: const BoxDecoration(
                color: Color(0xFFFFA54A),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            size: 20,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: "Search by name or phone...",
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.grey),
                              ),
                              onChanged: _searchCustomers,
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            IconButton(
                              icon: const Icon(
                                Icons.clear,
                                size: 18,
                                color: Colors.grey,
                              ),
                              onPressed: _clearSearch,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap:
                        canAddCustomer
                            ? () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddCustomerScreen(),
                                ),
                              );
                              if (result == true) {
                                _loadCustomers(isRefresh: true);
                              }
                            }
                            : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "You don't have permission to add customer.",
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            },
                    child: Opacity(
                      opacity: canAddCustomer ? 1 : 0.4,
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
                  ),
                ],
              ),
            ),

            /// ================= LIST =================
            Expanded(
              child: RefreshIndicator(
                color: Colors.orange,
                onRefresh: _onRefresh,
                child:
                    _isLoading && _allCustomers.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : CustomScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            /// CUSTOMER COUNT
                            if (_allCustomers.isNotEmpty)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    "Customers (${_allCustomers.length} of $_totalItems)",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),

                            /// CUSTOMER LIST
                            SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                if (index < _allCustomers.length) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: CustomerCard(
                                      customer: _allCustomers[index],
                                      onRefresh:
                                          () => _loadCustomers(isRefresh: true),
                                      canEditCustomer: canEditCustomer,
                                      canDeleteCustomer: canDeleteCustomer,
                                      userRole: widget.userRole,
                                      employeeId: widget.employeeId,
                                    ),
                                  );
                                }
                                return null;
                              }, childCount: _allCustomers.length),
                            ),

                            /// EMPTY STATE
                            if (_allCustomers.isEmpty && !_isLoading)
                              SliverFillRemaining(
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _searchQuery.isNotEmpty
                                              ? Icons.search_off
                                              : Icons.people_outline,
                                          size: 60,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          _searchQuery.isNotEmpty
                                              ? "No customers found for '$_searchQuery'"
                                              : "No customers found",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        if (_searchQuery.isNotEmpty)
                                          const SizedBox(height: 8),
                                        if (_searchQuery.isNotEmpty)
                                          ElevatedButton(
                                            onPressed: _clearSearch,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFFFFA54A,
                                              ),
                                            ),
                                            child: const Text("Clear Search"),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                            /// LOAD MORE INDICATOR
                            if (_isLoadingMore)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              ),

                            /// NO MORE CUSTOMERS MESSAGE
                            if (!_hasMoreData && _allCustomers.isNotEmpty)
                              SliverToBoxAdapter(
                                child: const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: Text(
                                      "No more customers",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ),

                            /// EXTRA SPACE AT BOTTOM
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
}

/// ================= CUSTOMER CARD =================
class CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onRefresh;
  final bool canEditCustomer;
  final bool canDeleteCustomer;
  final String userRole;
  final int employeeId;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.onRefresh,
    required this.canEditCustomer,
    required this.canDeleteCustomer,
    required this.userRole,
    required this.employeeId,
  });

  Future<void> _deleteCustomer(BuildContext context) async {
    if (!canDeleteCustomer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You don't have permission to delete customer."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (userRole == "employee" &&
        customer.assignedEmployeeId != employeeId.toString()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You can only delete your assigned customers."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Delete Customer"),
            content: const Text(
              "Are you sure you want to delete this customer?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete"),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final success = await CustomerApi.deleteCustomer(customer.id);

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Customer deleted successfully"),
              backgroundColor: Colors.green,
            ),
          );
          onRefresh();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to delete customer"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canEditThisCustomer = canEditCustomer;
    bool canDeleteThisCustomer = canDeleteCustomer;

    if (userRole == "employee" &&
        customer.assignedEmployeeId != employeeId.toString()) {
      canEditThisCustomer = false;
      canDeleteThisCustomer = false;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Customer Info",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Opacity(
                opacity: canDeleteThisCustomer ? 1 : 0.4,
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (value) {
                    if (value == "delete") {
                      _deleteCustomer(context);
                    }
                  },
                  itemBuilder:
                      (context) => [
                        PopupMenuItem<String>(
                          value: "delete",
                          child: Row(
                            children: [
                              const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Delete",
                                style: TextStyle(
                                  color:
                                      canDeleteThisCustomer
                                          ? Colors.red
                                          : Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _infoRow("Customer Name:", "${customer.name} ${customer.lastName}"),
          _infoRow("Mobile No.", customer.phone),
          _infoRow("Employee:", customer.assignedEmployee ?? "-"),
          _infoRow("Employee ID:", customer.assignedEmployeeId ?? "-"),
          _infoRow("Site Type:", customer.siteType ?? "-"),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Opacity(
                  opacity: canEditThisCustomer ? 1 : 0.4,
                  child: InkWell(
                    onTap:
                        canEditThisCustomer
                            ? () async {
                              await showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder:
                                    (_) => EditCustomerPopup(
                                      customerId: customer.id,
                                    ),
                              );
                              onRefresh();
                            }
                            : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    userRole == "employee"
                                        ? "You can only edit your assigned customers."
                                        : "You don't have permission to edit customer.",
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit, size: 16, color: Colors.blue),
                          SizedBox(width: 6),
                          Text(
                            "Edit",
                            style: TextStyle(color: Colors.blue, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _actionBtn(
                icon: Icons.history,
                text: "History",
                color: Colors.grey,
                onTap: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (_) => FollowUpHistoryPopup(customerId: customer.id),
                  );
                },
              ),
              const SizedBox(width: 10),
              _actionBtn(
                icon: Icons.phone,
                text: "Follow UP",
                color: Colors.black,
                onTap: () async {
                  await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => AddFollowUpPopup(customerId: customer.id),
                  );
                  onRefresh();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black),
          children: [
            TextSpan(
              text: "$title ",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

Widget _actionBtn({
  required IconData icon,
  required String text,
  required Color color,
  required VoidCallback onTap,
}) {
  return Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(text, style: TextStyle(color: color, fontSize: 13)),
          ],
        ),
      ),
    ),
  );
}
