import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
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
      baseUrl: "https://dashboard.theceramicstudio.in",
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
  late Future<List<Customer>> customerFuture;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  /// 🔄 Reload customers
  Future<void> _loadCustomers() async {
    setState(() {
      customerFuture = CustomerApi.fetchCustomers();
    });
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
                      child: const Row(
                        children: [
                          Icon(Icons.search, size: 20, color: Colors.grey),
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
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddCustomerScreen(),
                          ),
                        );
                        _loadCustomers(); // ✅ refresh after add
                      },
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

                    final customers = snapshot.data!;

                    if (customers.isEmpty) {
                      return const Center(child: Text("No customers found"));
                    }

                    return ListView.builder(
                      physics:
                          const AlwaysScrollableScrollPhysics(), // 🔥 important
                      padding: const EdgeInsets.all(16),
                      itemCount: customers.length,
                      itemBuilder: (_, index) {
                        return CustomerCard(
                          customer: customers[index],
                          onRefresh: _loadCustomers,
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

  const CustomerCard({
    super.key,
    required this.customer,
    required this.onRefresh,
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
              actionBtn(
                icon: Icons.edit,
                text: "Edit",
                color: Colors.blue,
                onTap: () async {
                  await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => EditCustomerPopup(customerId: customer.id),
                  );
                  onRefresh(); // ✅ refresh after edit
                },
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
