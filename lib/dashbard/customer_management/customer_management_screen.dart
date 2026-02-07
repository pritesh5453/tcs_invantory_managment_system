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
  final String? siteType;

  Customer({
    required this.id,
    required this.name,
    required this.lastName,
    required this.phone,
    this.assignedEmployee,
    this.siteType,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'] ?? '',
      lastName: json['Last_Name'] ?? '',
      phone: json['phone'] ?? '',
      assignedEmployee: json['assignedEmployee'],
      siteType: json['siteType'],
    );
  }
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

  static Future<List<Customer>> fetchCustomers() async {
    final response = await _dio.get("/api/users/list");
    final List list = response.data['customers'];

    final customers = list.map((e) => Customer.fromJson(e)).toList();

    // 🔥 SORT: latest first (higher ID on top)
    customers.sort((a, b) => b.id.compareTo(a.id));

    return customers;
  }
}

/// =====================
/// MAIN SCREEN
/// =====================
class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  State<CustomerManagementScreen> createState() =>
      _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  late bool canAddCustomer;
  late bool canEditCustomer;
  late Future<List<Customer>> customerFuture;
  List<Customer> _allCustomers = []; // Store all customers
  List<Customer> _filteredCustomers = []; // Store filtered customers
  String _searchQuery = ''; // Search query
  final TextEditingController _searchController =
      TextEditingController(); // Add controller

  @override
  void initState() {
    super.initState();
    debugPrint("ALL PERMISSIONS => ${PermissionManager.allPermissions}");

    canAddCustomer = PermissionManager.hasPermission("Customer Management_Add");

    canEditCustomer = PermissionManager.hasPermission(
      "Customer Management_Edit",
    );
    _allCustomers = [];
    _filteredCustomers = [];
    _loadCustomers();
  }

  /// 🔄 Reload customers
  Future<void> _loadCustomers() async {
    setState(() {
      customerFuture = CustomerApi.fetchCustomers();
    });

    // Update local lists after fetching data
    final customers = await CustomerApi.fetchCustomers();
    setState(() {
      _allCustomers = customers;
      _filteredCustomers = customers;
      _searchQuery = '';
      _searchController.clear(); // Clear search field
    });
  }

  void _filterCustomers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCustomers = _allCustomers;
      } else {
        _filteredCustomers =
            _allCustomers.where((customer) {
              final fullName =
                  '${customer.name} ${customer.lastName}'.toLowerCase();
              final phone = customer.phone.toLowerCase();
              final searchLower = query.toLowerCase();

              return fullName.contains(searchLower) ||
                  phone.contains(searchLower) ||
                  customer.name.toLowerCase().contains(searchLower) ||
                  customer.lastName.toLowerCase().contains(searchLower);
            }).toList();
      }
    });
  }

  // Add this method in _CustomerManagementScreenState
  void _updateCustomerLists(List<Customer> customers) {
    if (mounted) {
      setState(() {
        _allCustomers = customers;
        if (_searchQuery.isEmpty) {
          _filteredCustomers = customers;
        } else {
          _filterCustomers(_searchQuery);
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 🔽 Pull to refresh handler
  Future<void> _onRefresh() async {
    await _loadCustomers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            /// ================= APP BAR =================
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
                              controller: _searchController, // Add controller
                              decoration: const InputDecoration(
                                hintText: "Search by name or phone...",
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.grey),
                              ),
                              onChanged: _filterCustomers, // Trigger search
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
                              onPressed: () {
                                _searchController.clear();
                                _filterCustomers(''); // Clear search
                              },
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
                            }
                            : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "You don't have permission to add employee. Please contact support.",
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
            // Modify FutureBuilder:
            Expanded(
              child: RefreshIndicator(
                color: Colors.orange,
                onRefresh: _onRefresh,
                child: FutureBuilder<List<Customer>>(
                  future: customerFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Text("Failed to load customers"),
                      );
                    }

                    // Update lists after widget is built
                    if (snapshot.hasData) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _updateCustomerLists(snapshot.data!);
                      });
                    }

                    // Decide which list to display
                    List<Customer> displayCustomers;
                    if (_searchQuery.isEmpty) {
                      displayCustomers = snapshot.hasData ? snapshot.data! : [];
                    } else {
                      displayCustomers = _filteredCustomers;
                    }

                    if (displayCustomers.isEmpty) {
                      return Center(
                        child: Text(
                          _searchQuery.isNotEmpty
                              ? "No customers found for '$_searchQuery'"
                              : "No customers found",
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: displayCustomers.length,
                      itemBuilder: (_, index) {
                        return CustomerCard(
                          customer: displayCustomers[index],
                          onRefresh: _loadCustomers,
                          canEditCustomer: canEditCustomer,
                        );
                      },
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

/// ================= CUSTOMER CARD =================
class CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onRefresh;
  final bool canEditCustomer;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.onRefresh,
    required this.canEditCustomer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Customer Info",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),

          infoRow("Customer Name:", "${customer.name} ${customer.lastName}"),
          infoRow("Mobile No.", customer.phone),
          infoRow("Employee:", customer.assignedEmployee ?? "-"),
          infoRow("Site Type:", customer.siteType ?? "-"),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: Opacity(
                  opacity: canEditCustomer ? 1 : 0.4,
                  child: InkWell(
                    onTap:
                        canEditCustomer
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
                                const SnackBar(
                                  content: Text(
                                    "You don't have permission to edit customer.",
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
              actionBtn(
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
              actionBtn(
                icon: Icons.phone,
                text: "Follow UP",
                color: Colors.black,
                onTap: () async {
                  await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => AddFollowUpPopup(customerId: customer.id),
                  );
                  onRefresh(); // ✅ refresh after follow-up
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ================= HELPERS =================
Widget infoRow(String title, String value) {
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

Widget actionBtn({
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
