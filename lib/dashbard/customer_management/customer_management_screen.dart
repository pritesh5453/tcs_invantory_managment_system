import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tcs_invantory_managment_system/auth/prefs/permission_manager.dart';
import 'package:tcs_invantory_managment_system/dashbard/customer_management/add_customer.dart';
import 'package:tcs_invantory_managment_system/dashbard/customer_management/add_followUp.dart';
import 'package:tcs_invantory_managment_system/dashbard/customer_management/edit_customer.dart';
import 'package:tcs_invantory_managment_system/dashbard/customer_management/history.dart';
import 'package:tcs_invantory_managment_system/dashbard/main_dashbard_screen.dart';

/// =====================
/// MODEL (with all fields from API)
/// =====================
class Customer {
  final int id;
  final String name;
  final String lastName;
  final String phone;
  final String? altphone;
  final String email;
  final String? gstNumber;
  final String? billingName;
  final String? assignedEmployee;
  final String? assignedEmployeeId;
  final String? assignedArchitect;
  final String? assignedArchitectId;
  final String? status;
  final String? notes;
  final String? projectName;
  final String? siteName;
  final String? siteType;
  final String? priority;
  final String? createdAt;
  final String? updatedAt;
  final String? nextFollowupDate;
  final String? walletAmount;

  Customer({
    required this.id,
    required this.name,
    required this.lastName,
    required this.phone,
    this.altphone,
    required this.email,
    this.gstNumber,
    this.billingName,
    this.assignedEmployee,
    this.assignedEmployeeId,
    this.assignedArchitect,
    this.assignedArchitectId,
    this.status,
    this.notes,
    this.projectName,
    this.siteName,
    this.siteType,
    this.priority,
    this.createdAt,
    this.updatedAt,
    this.nextFollowupDate,
    this.walletAmount,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      lastName: json['Last_Name'] ?? '',
      phone: json['phone'] ?? '',
      altphone: json['altphone']?.toString(),
      email: json['email'] ?? '',
      gstNumber: json['GstNumber']?.toString(),
      billingName: json['billingName']?.toString(),
      assignedEmployee: json['assignedEmployee']?.toString(),
      assignedEmployeeId: json['assignedEmployeeId']?.toString(),
      assignedArchitect: json['assignedArchitect']?.toString(),
      assignedArchitectId: json['assignedArchitectId']?.toString(),
      status: json['status']?.toString(),
      notes: json['notes']?.toString(),
      projectName: json['projectName']?.toString(),
      siteName: json['siteName']?.toString(),
      siteType: json['siteType']?.toString(),
      priority: json['priority']?.toString() ?? 'Low',
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      nextFollowupDate: json['nextFollowupDate']?.toString(),
      walletAmount: json['wallet_amount']?.toString(),
    );
  }

  // Convert to map for edit popup
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'Last_Name': lastName,
      'phone': phone,
      'altphone': altphone,
      'email': email,
      'GstNumber': gstNumber,
      'billingName': billingName,
      'assignedEmployee': assignedEmployee,
      'assignedEmployeeId': assignedEmployeeId,
      'assignedArchitect': assignedArchitect,
      'assignedArchitectId': assignedArchitectId,
      'status': status,
      'notes': notes,
      'projectName': projectName,
      'siteName': siteName,
      'siteType': siteType,
      'priority': priority,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'nextFollowupDate': nextFollowupDate,
      'wallet_amount': walletAmount,
    };
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

class CustomerApi {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "https://dashboard.theceramicstudio.in",
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  static Future<CustomerResponse> fetchAllCustomers({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {'page': page, 'limit': limit};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get(
        "/api/users/list",
        queryParameters: queryParams,
      );

      // 🔐 Safe access to response.data
      final data = response.data as Map<String, dynamic>?;
      final List list = data?['customers'] as List? ?? [];
      final customers = list.map((e) => Customer.fromJson(e)).toList();
      customers.sort((a, b) => b.id.compareTo(a.id));

      final pagination = data?['pagination'] as Map<String, dynamic>? ?? {};
      final currentPage = pagination['page'] ?? 1;
      final totalPages = pagination['totalPages'] ?? 1;
      final totalItems = pagination['total'] ?? list.length;
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
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get(
        "/api/users/list/employee",
        queryParameters: queryParams,
      );

      // 🔐 Safe access to response.data
      final data = response.data as Map<String, dynamic>?;
      final List list = data?['customers'] as List? ?? [];
      final customers = list.map((e) => Customer.fromJson(e)).toList();
      customers.sort((a, b) => b.id.compareTo(a.id));

      final pagination = data?['pagination'] as Map<String, dynamic>? ?? {};
      final currentPage = pagination['page'] ?? 1;
      final totalPages = pagination['totalPages'] ?? 1;
      final totalItems = pagination['total'] ?? list.length;
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

  static Future<bool> deleteCustomer(int customerId) async {
    try {
      final response = await _dio.delete("/api/users/delete/$customerId");
      // 🔐 Safe check for response.data and success flag
      final data = response.data as Map<String, dynamic>?;
      if (response.statusCode == 200 && data?['success'] == true) {
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

  bool get isEmployee => widget.userRole == "employee";
  bool get isAdmin =>
      widget.userRole == "admin" || widget.userRole == "superadmin";

  // --------------------- ADMIN VIEW ---------------------
  List<Customer> _adminCustomers = [];
  int _adminCurrentPage = 1;
  bool _adminIsLoading = true;
  bool _adminIsLoadingMore = false;
  bool _adminHasMoreData = true;
  int _adminTotalItems = 0;
  final ScrollController _adminScrollController = ScrollController();
  final int _limit = 10;

  // --------------------- EMPLOYEE VIEW (TABS) ---------------------
  List<Customer> _employeeAssignedCustomers = [];
  List<Customer> _employeeAllCustomers = [];
  bool _isLoadingAssigned = true;
  bool _isLoadingAll = true;
  String _selectedTab = "assigned"; // "assigned" or "all"

  List<Customer> get _displayedCustomers =>
      _selectedTab == "assigned"
          ? _employeeAssignedCustomers
          : _employeeAllCustomers;

  bool get _isLoadingCurrentTab =>
      _selectedTab == "assigned" ? _isLoadingAssigned : _isLoadingAll;

  // --------------------- COMMON SEARCH ---------------------
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();

    canAddCustomer = PermissionManager.hasPermission("Customer Management_Add");
    canEditCustomer = PermissionManager.hasPermission(
      "Customer Management_Edit",
    );
    canDeleteCustomer = PermissionManager.hasPermission(
      "Customer Management_Delete",
    );

    if (isAdmin) {
      _loadAdminCustomers();
      _adminScrollController.addListener(_adminScrollListener);
    } else {
      _loadEmployeeData();
    }
  }

  // --------------------- ADMIN: PAGINATED ALL CUSTOMERS ---------------------
  Future<void> _loadAdminCustomers({
    bool isRefresh = false,
    bool isLoadMore = false,
    String? search,
  }) async {
    if (isRefresh) {
      setState(() {
        _adminCurrentPage = 1;
        _adminHasMoreData = true;
        _adminCustomers = [];
        _adminIsLoading = true;
        _adminTotalItems = 0;
      });
    } else if (isLoadMore) {
      setState(() => _adminIsLoadingMore = true);
    } else if (!isLoadMore) {
      setState(() => _adminIsLoading = true);
    }

    try {
      final response = await CustomerApi.fetchAllCustomers(
        page: _adminCurrentPage,
        limit: _limit,
        search: search ?? _searchQuery,
      );

      setState(() {
        if (isLoadMore) {
          _adminCustomers.addAll(response.customers);
        } else {
          _adminCustomers = response.customers;
        }
        _adminHasMoreData = response.hasMore;
        _adminTotalItems = response.totalItems;
        _adminIsLoading = false;
        _adminIsLoadingMore = false;
      });
    } catch (e) {
      debugPrint("Error loading admin customers: $e");
      setState(() {
        _adminIsLoading = false;
        _adminIsLoadingMore = false;
      });
    }
  }

  void _adminScrollListener() {
    if (_adminScrollController.position.pixels >=
            _adminScrollController.position.maxScrollExtent - 100 &&
        !_adminIsLoadingMore &&
        !_adminIsLoading &&
        _adminHasMoreData) {
      _loadMoreAdminData();
    }
  }

  Future<void> _loadMoreAdminData() async {
    if (!_adminHasMoreData || _adminIsLoadingMore || _adminIsLoading) return;
    setState(() => _adminIsLoadingMore = true);
    _adminCurrentPage++;
    await _loadAdminCustomers(isLoadMore: true);
  }

  // --------------------- EMPLOYEE: LOAD BOTH LISTS ---------------------
  Future<void> _loadEmployeeData({String? search}) async {
    setState(() {
      _isLoadingAssigned = true;
      _isLoadingAll = true;
    });

    try {
      final assignedResponse = await CustomerApi.fetchEmployeeCustomers(
        employeeId: widget.employeeId,
        page: 1,
        limit: 50,
        search: search,
      );

      final allResponse = await CustomerApi.fetchAllCustomers(
        page: 1,
        limit: 50,
        search: search,
      );

      setState(() {
        _employeeAssignedCustomers = assignedResponse.customers;
        _employeeAllCustomers = allResponse.customers;
        _isLoadingAssigned = false;
        _isLoadingAll = false;
      });
    } catch (e) {
      debugPrint("Error loading employee data: $e");
      setState(() {
        _isLoadingAssigned = false;
        _isLoadingAll = false;
      });
    }
  }

  // --------------------- TAB SWITCH ---------------------
  void _switchTab(String tab) {
    if (_selectedTab == tab) return;
    setState(() {
      _selectedTab = tab;
    });
  }

  // --------------------- SEARCH (DEBOUNCED) ---------------------
  void _searchCustomers(String query) {
    setState(() => _searchQuery = query);
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (isAdmin) {
        _loadAdminCustomers(isRefresh: true, search: query);
      } else {
        _loadEmployeeData(search: query);
      }
    });
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
    if (isAdmin) {
      _loadAdminCustomers(isRefresh: true);
    } else {
      _loadEmployeeData();
    }
  }

  Future<void> _onRefresh() async {
    if (isAdmin) {
      await _loadAdminCustomers(isRefresh: true);
    } else {
      await _loadEmployeeData(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
    }
  }

  @override
  void dispose() {
    _adminScrollController.dispose();
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
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
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: RefreshIndicator(
                  color: Colors.orange,
                  onRefresh: _onRefresh,
                  child: isAdmin ? _buildAdminView() : _buildEmployeeView(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------- APP BAR (WITH EMPLOYEE TABS) ---------------------
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: const BoxDecoration(
        color: Color(0xFFFFA54A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Row(
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
                      const Icon(Icons.search, size: 20, color: Colors.grey),
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
                            if (isAdmin) {
                              _loadAdminCustomers(isRefresh: true);
                            } else {
                              _loadEmployeeData(
                                search:
                                    _searchQuery.isNotEmpty
                                        ? _searchQuery
                                        : null,
                              );
                            }
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
          if (isEmployee) ...[const SizedBox(height: 16), _buildTabSelector()],
        ],
      ),
    );
  }

  // --------------------- EMPLOYEE TAB SELECTOR ---------------------
  Widget _buildTabSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTabButton(
            title: "My Customers",
            isSelected: _selectedTab == "assigned",
            onTap: () => _switchTab("assigned"),
          ),
          const SizedBox(width: 4),
          _buildTabButton(
            title: "All Customers",
            isSelected: _selectedTab == "all",
            onTap: () => _switchTab("all"),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? const Color(0xFFFFA54A) : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // --------------------- ADMIN VIEW ---------------------
  Widget _buildAdminView() {
    return _adminIsLoading && _adminCustomers.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : CustomScrollView(
          controller: _adminScrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (_adminCustomers.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "Customers (${_adminCustomers.length} of $_adminTotalItems)",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index < _adminCustomers.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: CustomerCard(
                      customer: _adminCustomers[index],
                      onRefresh: () => _loadAdminCustomers(isRefresh: true),
                      canEditCustomer: canEditCustomer,
                      canDeleteCustomer: canDeleteCustomer,
                      userRole: widget.userRole,
                      employeeId: widget.employeeId,
                    ),
                  );
                }
                return null;
              }, childCount: _adminCustomers.length),
            ),
            if (_adminCustomers.isEmpty && !_adminIsLoading)
              SliverToBoxAdapter(child: _buildEmptyState(isAdmin: true)),
            if (_adminIsLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            if (!_adminHasMoreData && _adminCustomers.isNotEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      "No more customers",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 50)),
          ],
        );
  }

  // --------------------- EMPLOYEE VIEW ---------------------
  Widget _buildEmployeeView() {
    return _isLoadingCurrentTab && _displayedCustomers.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : _displayedCustomers.isEmpty
        ? _buildEmptyState(
          isAdmin: false,
          isAssignedSection: _selectedTab == "assigned",
        )
        : ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: _displayedCustomers.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CustomerCard(
                customer: _displayedCustomers[index],
                onRefresh: () => _loadEmployeeData(search: _searchQuery),
                canEditCustomer: canEditCustomer,
                canDeleteCustomer: canDeleteCustomer,
                userRole: widget.userRole,
                employeeId: widget.employeeId,
              ),
            );
          },
        );
  }

  // --------------------- EMPTY STATE ---------------------
  Widget _buildEmptyState({
    required bool isAdmin,
    bool isAssignedSection = false,
  }) {
    String message;
    if (isAdmin) {
      message =
          _searchQuery.isNotEmpty
              ? "No customers found for '$_searchQuery'"
              : "No customers found";
    } else {
      if (isAssignedSection) {
        message =
            _searchQuery.isNotEmpty
                ? "No assigned customers found for '$_searchQuery'"
                : "No assigned customers found";
      } else {
        message =
            _searchQuery.isNotEmpty
                ? "No customers found for '$_searchQuery'"
                : "No customers found";
      }
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
              size: 60,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ElevatedButton(
                  onPressed: _clearSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA54A),
                  ),
                  child: const Text("Clear Search"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// ================= CUSTOMER CARD =================
/// UI bilkul same hai – sirf edit button mein saara data bhej rahe hain
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
    final bool isAdmin = userRole == "admin" || userRole == "superadmin";
    final bool isEmployee = userRole == "employee";

    bool canEditThisCustomer =
        isAdmin ? canEditCustomer : (isEmployee && canEditCustomer);

    bool canDeleteThisCustomer = isAdmin && canDeleteCustomer;

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

              const SizedBox(width: 120),
              _walletWidget(customer.walletAmount),

              const SizedBox(width: 1),
              if (isAdmin && canDeleteThisCustomer)
                PopupMenuButton<String>(
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
                              const Text(
                                "Delete",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                )
              else
                const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 10),
          _infoRow("Customer Name:", "${customer.name} ${customer.lastName}"),
          _infoRow("Mobile No.", customer.phone),
          _infoRow("Employee:", customer.assignedEmployee ?? "-"),
          _infoRow("Employee ID:", customer.assignedEmployeeId ?? "-"),
          _infoRow("Site Type:", customer.siteType ?? "-"),
          _infoRow("Next FollowUP Date:", customer.nextFollowupDate ?? "-"),
          const SizedBox(height: 14),
          Row(
            children: [
              // EDIT BUTTON
              Expanded(
                child: Opacity(
                  opacity: canEditThisCustomer ? 1 : 0.4,
                  child: InkWell(
                    onTap:
                        canEditThisCustomer
                            ? () async {
                              // 🔥 Send ALL customer data to edit popup
                              await showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder:
                                    (_) => EditCustomerPopup(
                                      customerData: customer.toMap(),
                                      customerId: customer.id,
                                    ),
                              );
                              onRefresh();
                            }
                            : () {
                              if (isEmployee && !canEditCustomer) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "You don't have permission to edit customer.",
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
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
              // HISTORY BUTTON
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
              // FOLLOW UP BUTTON
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

  Widget _walletWidget(String? amount) {
    double wallet = double.tryParse(amount ?? "0") ?? 0;

    bool isNegative = wallet < 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isNegative ? Colors.red.shade100 : Colors.green.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "₹ ${wallet.toStringAsFixed(2)}",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isNegative ? Colors.red.shade800 : Colors.green.shade800,
        ),
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

// --------------------- ACTION BUTTON (History/FollowUp) ---------------------
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
