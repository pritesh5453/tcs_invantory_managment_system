import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:tcs_invantory_managment_system/dashbard/dashboard/admin/request_screen.dart';
import 'package:tcs_invantory_managment_system/dashbard/dashboard/admin/work_panel_screen.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Dio instance
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://dashboarduat.theceramicstudio.in/api',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ),
  );

  // Dashboard stats data
  Map<String, dynamic> dashboardStats = {};
  List<dynamic> userWiseOrders = [];
  bool isLoading = true;
  String errorMessage = '';

  // Date selection state
  DateTime? fromDate;
  DateTime? toDate;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  // Fetch Dashboard Stats API
  Future<void> _fetchDashboardStats() async {
    try {
      final response = await _dio.get('/dashboard/stats');

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          dashboardStats = response.data['data'];
        });
      } else {
        throw Exception('Failed to load dashboard stats');
      }
    } on DioException catch (e) {
      throw Exception('Dashboard stats error: ${e.message}');
    }
  }

  // Fetch User Wise Orders API
  Future<void> _fetchUserWiseOrders() async {
    try {
      // Use default dates if none selected, otherwise use selected dates
      final startDate = fromDate ?? DateTime(2025, 1, 23);
      final endDate = toDate ?? DateTime(2026, 1, 23);

      final response = await _dio.get(
        '/dashboard/user-wise-orders',
        queryParameters: {
          'start': _formatDateForApi(fromDate),
          'end': _formatDateForApi(toDate),
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          userWiseOrders = response.data['data'];
        });
      } else {
        throw Exception('Failed to load user orders');
      }
    } on DioException catch (e) {
      throw Exception('User orders error: ${e.message}');
    }
  }

  // Fetch all data
  Future<void> _fetchAllData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      await Future.wait([_fetchDashboardStats(), _fetchUserWiseOrders()]);
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Helper function to format date for display
  String _formatDateForDisplay(DateTime? date) {
    if (date == null) return 'Select Date';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Helper function to format date for API
  String _formatDateForApi(DateTime? date) {
    if (date == null) return '';
    return '${date.year.toString()}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Function to show date picker
  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isFromDate
              ? (fromDate ?? DateTime.now())
              : (toDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
    }
  }

  // Submit task function
  Future<void> _submitTask() async {
    // Validate dates
    if (fromDate == null || toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both From Date and To Date'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate date range
    if (fromDate!.isAfter(toDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('From Date cannot be after To Date'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Call the API with selected dates
      final response = await _dio.get(
        '/dashboard/user-wise-orders',
        queryParameters: {
          'start': _formatDateForApi(fromDate),
          'end': _formatDateForApi(toDate),
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          userWiseOrders = response.data['data'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data loaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to load user orders');
      }
    } on DioException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xffF6F6F6),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: const Color(0xffFFA34D)),
              const SizedBox(height: 20),
              Text(
                'Loading Dashboard Data...',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xffF6F6F6),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 50),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchAllData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffFFA34D),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffF6F6F6),
      body: SafeArea(
        child: Column(
          children: [
            _topHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _dashboardOverviewCard(),
                    const SizedBox(height: 16),
                    _assignedTaskCard(context),
                    const SizedBox(height: 16),
                    _statsGrid(),
                    const SizedBox(height: 16),
                    _bottomCharts(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchAllData,
        backgroundColor: const Color(0xffFFA34D),
        foregroundColor: Colors.white,
        child: const Icon(Icons.refresh),
        tooltip: 'Refresh Data',
      ),
    );
  }

  // 🔶 TOP HEADER
  Widget _topHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xffFFA34D),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Row(
              children: [
                Icon(Icons.search),
                SizedBox(width: 8),
                Text("Search..", style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔶 DASHBOARD OVERVIEW CARD
  Widget _dashboardOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffFFA34D), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            child: Text(
              "Dashboard\nOverview",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaymentRequestsPage(),
                ),
              );
            },
            child: _overviewChip(
              label: "Requests",
              color: const Color(0xffFFA34D),
              icon: Icons.notifications,
            ),
          ),
          const SizedBox(width: 8),
          _overviewChip(
            label: "To-Do\nGeneral",
            color: const Color(0xff2D9CDB),
            icon: Icons.checklist,
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AssignTaskPage()),
              );
            },
            child: _overviewChip(
              label: "Work Panel",
              color: const Color(0xff27AE60),
              icon: Icons.work,
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewChip({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 12, color: Colors.black),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  // 🔶 ASSIGNED TASK CARD - Now using dynamic API data
  Widget _assignedTaskCard(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Container(
      padding: EdgeInsets.all(width * 0.035),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                "User Wise Order",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              _dateChip(_formatDateForDisplay(fromDate), width, true),
              _dateChip(_formatDateForDisplay(toDate), width, false),
              GestureDetector(
                onTap: _submitTask,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.04,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Submit",
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.03,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: const Color(0xffFFF6EC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    "Name",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: Text(
                    "Total Attended",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: Text(
                    "Quotation Count",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Dynamic rows from API with Scrollbar
          if (userWiseOrders.isNotEmpty)
            Container(
              height: height * 0.15, // Adjust height as needed
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: Scrollbar(
                thumbVisibility: true, // Always show scrollbar
                trackVisibility: true, // Show track
                thickness: 6.0, // Scrollbar thickness
                radius: const Radius.circular(10), // Rounded corners
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.03,
                    vertical: 4,
                  ),
                  itemCount: userWiseOrders.length,
                  itemBuilder: (context, index) {
                    final employee = userWiseOrders[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border:
                            index < userWiseOrders.length - 1
                                ? const Border(
                                  bottom: BorderSide(
                                    color: Color(0xFFF0F0F0),
                                    width: 1.0,
                                  ),
                                )
                                : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              employee['employeeName'] ?? 'N/A',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              (employee['customerCount'] ?? 0).toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              (employee['quotationCount'] ?? 0).toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            )
          else
            Container(
              height: height * 0.15,
              padding: EdgeInsets.symmetric(horizontal: width * 0.03),
              alignment: Alignment.center,
              child: const Text(
                'No data available',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dateChip(String text, double width, [bool isFromDate = false]) {
    return GestureDetector(
      onTap: () => _selectDate(context, isFromDate),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: width * 0.025, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: const TextStyle(fontSize: 10)),
            const SizedBox(width: 4),
            const Icon(Icons.calendar_today, size: 12),
          ],
        ),
      ),
    );
  }

  // 🔶 STATS GRID - Now using dynamic API data
  Widget _statsGrid() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _StatCard(
          "Monthly Customers",
          (dashboardStats['customerCurrentMonthCount'] ?? 0).toString(),
        ),
        _StatCard(
          "Monthly Purchases",
          '₹${dashboardStats['monthlyPurchasesTotal'] ?? 0}',
        ),
        _StatCard(
          "Quotations",
          (dashboardStats['monthlyQuestionCount'] ?? 0).toString(),
        ),
        _StatCard(
          "Delivery Challans",
          (dashboardStats['deliveryChallanCount'] ?? 0).toString(),
        ),
        _StatCard(
          "New Architects",
          (dashboardStats['architectsCount'] ?? 0).toString(),
        ),
        _StatCard(
          "New Products",
          (dashboardStats['productsCount'] ?? 0).toString(),
        ),
      ],
    );
  }

  // 🔶 BOTTOM CHART PLACEHOLDERS
  Widget _bottomCharts(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    if (isMobile) {
      return Column(
        children: [
          _chartCard(context, title: "Purchase Record", isPurchase: true),
          const SizedBox(height: 16),
          _chartCard(context, title: "Cash Flow Trend", isPurchase: false),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _chartCard(
            context,
            title: "Purchase Record",
            isPurchase: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _chartCard(
            context,
            title: "Cash Flow Trend",
            isPurchase: false,
          ),
        ),
      ],
    );
  }

  Widget _chartCard(
    BuildContext context, {
    required String title,
    required bool isPurchase,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      isPurchase ? Colors.blue.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPurchase ? Icons.bar_chart : Icons.currency_rupee,
                  color: isPurchase ? Colors.blue : Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (isPurchase)
                _filterChip("LAST 4 MONTHS")
              else
                Row(
                  children: [
                    _legendDot(Colors.green, "IN"),
                    const SizedBox(width: 10),
                    _legendDot(Colors.red, "OUT"),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPurchase ? Icons.shopping_cart : Icons.trending_up,
                    color: Colors.grey,
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Chart Here",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    isPurchase ? "Last 4 Months" : "Cash Flow Analysis",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xffF5F7FA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.keyboard_arrow_down, size: 18),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// 🔹 STAT CARD
class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
